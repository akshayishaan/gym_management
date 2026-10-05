import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/spacing.dart';
import '../application/plan_controller.dart';
import '../data/plan_repository.dart';
import '../domain/plan.dart';

/// Add/edit plan bottom sheet. Mirrors the Figma `plans_create.png` /
/// `plans_edit.png`: drag handle, title + close, PLAN DETAILS section
/// (name, duration w/ quick-pick chips, price, description), features
/// input + chips, Active toggle, full-width lime primary submit button.
///
/// Pass [existingPlan] to switch into edit mode — fields pre-fill, the
/// title becomes "Edit Plan", and the submit label switches to
/// "SAVE CHANGES" so the wire is `PUT /plans/:id` rather than `POST /plans`.
class PlanFormSheet extends ConsumerStatefulWidget {
  const PlanFormSheet({super.key, this.existingPlan});

  /// Non-null switches the sheet into edit mode.
  final Plan? existingPlan;

  bool get isEdit => existingPlan != null;

  @override
  ConsumerState<PlanFormSheet> createState() => _PlanFormSheetState();
}

class _PlanFormSheetState extends ConsumerState<PlanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _featureInputCtrl = TextEditingController();

  int? _durationDays;
  final List<String> _features = [];
  bool _isActive = true;
  bool _isSubmitting = false;

  /// 30 / 90 / 180 / 365 — chips under the Duration field. `1 yr` is
  /// shown in the Figma as the label but is 365 days on the wire.
  static const _durationChips = <(String label, int days)>[
    ('30d', 30),
    ('90d', 90),
    ('180d', 180),
    ('1 yr', 365),
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingPlan;
    if (p != null) {
      _nameCtrl.text = p.name;
      _descriptionCtrl.text = p.description ?? '';
      _priceCtrl.text = p.price == p.price.truncate()
          ? p.price.toInt().toString()
          : p.price.toString();
      _durationCtrl.text = p.durationDays.toString();
      _durationDays = p.durationDays;
      _features.addAll(p.features);
      _isActive = p.isActive;
    } else {
      // Default duration = first chip; keeps the form consistent for new
      // users when they tap a chip without typing first.
      _durationDays = 30;
      _durationCtrl.text = '30';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _featureInputCtrl.dispose();
    super.dispose();
  }

  void _onDurationChanged(String value) {
    final n = int.tryParse(value.trim());
    setState(() {
      _durationDays = n;
      // If the typed value matches a chip, keep the chip highlighted by
      // re-asserting the matching days; otherwise we keep the typed value
      // and the chip selection goes null until they retap.
    });
  }

  void _selectDurationChip(int days) {
    setState(() {
      _durationDays = days;
      _durationCtrl.text = days.toString();
    });
  }

  void _addFeature() {
    final raw = _featureInputCtrl.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      if (!_features.contains(raw) && _features.length < 20) {
        _features.add(raw);
      }
      _featureInputCtrl.clear();
    });
  }

  void _removeFeature(String f) {
    setState(() => _features.remove(f));
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final name = _nameCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final priceText = _priceCtrl.text.trim();
    final price = double.tryParse(priceText);
    final days = _durationDays;
    if (price == null || price <= 0 || days == null || days <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      if (widget.isEdit) {
        await ref.read(planUpdateControllerProvider.notifier).update(
              widget.existingPlan!.id,
              PlanUpdateInput(
                name: name,
                description: description.isEmpty ? null : description,
                durationDays: days,
                price: price,
                features: List<String>.from(_features),
                isActive: _isActive,
              ),
            );
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan updated')),
        );
      } else {
        await ref.read(planCreateControllerProvider.notifier).create(
              PlanCreateInput(
                name: name,
                description: description.isEmpty ? null : description,
                durationDays: days,
                price: price,
                features: List<String>.from(_features),
                isActive: _isActive,
              ),
            );
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan created')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save plan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: LatoColors.surfaceDark,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: LatoSpacing.md),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: LatoColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LatoSpacing.xl,
                LatoSpacing.md,
                LatoSpacing.xl,
                LatoSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.isEdit ? 'Edit Plan' : 'New Plan',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: LatoColors.textSecondaryDark,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  LatoSpacing.xl,
                  0,
                  LatoSpacing.xl,
                  LatoSpacing.xxl,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('PLAN DETAILS'),
                      const SizedBox(height: LatoSpacing.md),
                      _FieldLabel(text: 'Name'),
                      const SizedBox(height: LatoSpacing.sm),
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Monthly, Quarterly',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: LatoSpacing.lg),
                      _FieldLabel(text: 'Description'),
                      const SizedBox(height: LatoSpacing.sm),
                      TextFormField(
                        controller: _descriptionCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Brief description of the plan',
                        ),
                      ),
                      const SizedBox(height: LatoSpacing.lg),
                      // Duration + Price two-column row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _RequiredLabel(text: 'Duration (days)'),
                                const SizedBox(height: LatoSpacing.sm),
                                TextFormField(
                                  controller: _durationCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: '30',
                                  ),
                                  onChanged: _onDurationChanged,
                                  validator: (v) {
                                    final n = int.tryParse(
                                        (v ?? '').trim());
                                    if (n == null || n <= 0) {
                                      return 'Enter duration';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: LatoSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _RequiredLabel(text: 'Price (₹)'),
                                const SizedBox(height: LatoSpacing.sm),
                                TextFormField(
                                  controller: _priceCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: '1499',
                                  ),
                                  validator: (v) {
                                    final n =
                                        double.tryParse((v ?? '').trim());
                                    if (n == null || n <= 0) {
                                      return 'Enter price';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Duration quick-pick chips
                      const SizedBox(height: LatoSpacing.sm),
                      Wrap(
                        spacing: LatoSpacing.sm,
                        runSpacing: LatoSpacing.sm,
                        children: [
                          for (final (label, days) in _durationChips)
                            _DurationChip(
                              label: label,
                              selected: _durationDays == days,
                              onTap: () => _selectDurationChip(days),
                            ),
                        ],
                      ),
                      const SizedBox(height: LatoSpacing.lg),
                      // Features
                      _FieldLabel(text: 'Features'),
                      const SizedBox(height: LatoSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _featureInputCtrl,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _addFeature(),
                              decoration: const InputDecoration(
                                hintText: 'e.g., Personal trainer',
                              ),
                            ),
                          ),
                          const SizedBox(width: LatoSpacing.sm),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: LatoColors.primary,
                              borderRadius: BorderRadius.circular(LatoRadius.md),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.add,
                                color: LatoColors.bgDark,
                                size: 22,
                              ),
                              onPressed: _addFeature,
                              tooltip: 'Add feature',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: LatoSpacing.sm),
                      Text(
                        'Add the benefits members receive with this plan.',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (_features.isNotEmpty) ...[
                        const SizedBox(height: LatoSpacing.md),
                        Wrap(
                          spacing: LatoSpacing.sm,
                          runSpacing: LatoSpacing.sm,
                          children: [
                            for (final f in _features)
                              InputChip(
                                label: Text(f),
                                onDeleted: () => _removeFeature(f),
                                deleteIconColor:
                                    LatoColors.textSecondaryDark,
                                backgroundColor: const Color(0x1AFFFFFF),
                                side: const BorderSide(
                                    color: LatoColors.borderDark),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: LatoSpacing.xxl),
                      // Active toggle row
                      InkWell(
                        onTap: () => setState(() => _isActive = !_isActive),
                        borderRadius: BorderRadius.circular(LatoRadius.md),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: LatoSpacing.xs,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _isActive,
                                  onChanged: (v) =>
                                      setState(() => _isActive = v ?? false),
                                  activeColor: LatoColors.primary,
                                  checkColor: LatoColors.bgDark,
                                  side: BorderSide(
                                    color: _isActive
                                        ? LatoColors.primary
                                        : LatoColors.borderDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: LatoSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Active plan',
                                      style: theme.textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Available for new purchases and renewals',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: LatoSpacing.huge),
                      LatoPrimaryButton(
                        label: widget.isEdit ? 'SAVE CHANGES' : 'CREATE PLAN',
                        loading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                      const SizedBox(height: LatoSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text, style: theme.textTheme.labelLarge);
  }
}

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(text, style: theme.textTheme.labelLarge),
        const SizedBox(width: 4),
        const Text(
          '*',
          style: TextStyle(
            color: LatoColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Quick-pick chip used under the Duration field. Selected = solid lime
/// background + dark text; unselected = neutral surface + secondary text.
class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LatoSpacing.md,
            vertical: LatoSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? LatoColors.primary : const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? LatoColors.primary : LatoColors.borderDark,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? LatoColors.bgDark
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}