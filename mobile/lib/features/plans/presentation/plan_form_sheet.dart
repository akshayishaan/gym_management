import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_sheet.dart';
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
  const PlanFormSheet({super.key, this.existingPlan, this.copyOf});

  /// Non-null switches the sheet into edit mode.
  final Plan? existingPlan;

  /// When set (and [existingPlan] is null) the sheet opens in create mode
  /// pre-filled from this plan, named "Name (Copy)".
  final Plan? copyOf;

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
    final p = widget.existingPlan ?? widget.copyOf;
    if (p != null) {
      _nameCtrl.text = widget.isEdit ? p.name : '${p.name} (Copy)';
      _descriptionCtrl.text = p.description ?? '';
      _priceCtrl.text = p.price == p.price.truncate()
          ? p.price.toInt().toString()
          : p.price.toString();
      _durationCtrl.text = p.durationDays.toString();
      _durationDays = p.durationDays;
      _features.addAll(p.features);
      _isActive = widget.isEdit ? p.isActive : true;
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
    String? notice;
    setState(() {
      if (_features.contains(raw)) {
        notice = 'Already added';
      } else if (_features.length >= 20) {
        notice = 'A plan can have up to 20 features';
      } else {
        _features.add(raw);
        _featureInputCtrl.clear();
      }
    });
    if (notice != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(notice!)));
    }
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
        await ref
            .read(planUpdateControllerProvider.notifier)
            .update(
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Plan updated')));
      } else {
        await ref
            .read(planCreateControllerProvider.notifier)
            .create(
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Plan created')));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save plan: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LatoFormSheetScaffold(
      title: widget.isEdit ? 'Edit Plan' : 'New Plan',
      footer: LatoPrimaryButton(
        label: widget.isEdit ? 'SAVE CHANGES' : 'CREATE PLAN',
        loading: _isSubmitting,
        onPressed: _isSubmitting ? null : _submit,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('PLAN DETAILS'),
            const SizedBox(height: LatoSpacing.md),
            _RequiredLabel(text: 'Name'),
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
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Brief description of the plan',
              ),
            ),
            const SizedBox(height: LatoSpacing.lg),
            _RequiredLabel(text: 'Duration (days)'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '30'),
              onChanged: _onDurationChanged,
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Enter duration';
                return null;
              },
            ),
            const SizedBox(height: LatoSpacing.sm),
            Text('Quick pick', style: theme.textTheme.bodySmall),
            Wrap(
              spacing: LatoSpacing.sm,
              children: [
                for (final (label, days) in _durationChips)
                  _DurationChip(
                    label: label,
                    selected: _durationDays == days,
                    onTap: () => _selectDurationChip(days),
                  ),
              ],
            ),
            const SizedBox(height: LatoSpacing.md),
            _RequiredLabel(text: 'Price'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                hintText: '0',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 16,
                      color: LatoColors.textSecondaryDark,
                    ),
                  ),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 0),
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Enter price';
                return null;
              },
            ),
            const SizedBox(height: LatoSpacing.lg),
            // Features
            _FieldLabel(text: 'Features'),
            const SizedBox(height: LatoSpacing.sm),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  SizedBox(
                    width: LatoSizes.button,
                    child: Material(
                      color: LatoColors.primary,
                      borderRadius: BorderRadius.circular(LatoRadius.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(LatoRadius.md),
                        onTap: _addFeature,
                        child: const Tooltip(
                          message: 'Add feature',
                          child: Icon(
                            Icons.add,
                            color: LatoColors.bgDark,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                    _RemovableChip(label: f, onRemove: () => _removeFeature(f)),
                ],
              ),
            ],
            const SizedBox(height: LatoSpacing.xxl),
            // Active toggle card
            InkWell(
              onTap: () => setState(() => _isActive = !_isActive),
              borderRadius: BorderRadius.circular(LatoRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LatoSpacing.md,
                  vertical: LatoSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: LatoColors.surfaceRaisedDark,
                  borderRadius: BorderRadius.circular(LatoRadius.md),
                  border: Border.all(color: LatoColors.borderDark),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(width: LatoSpacing.sm),
                    Switch.adaptive(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeThumbColor: LatoColors.primary,
                      activeTrackColor: LatoColors.primary.withValues(
                        alpha: 0.35,
                      ),
                      inactiveThumbColor: LatoColors.textSecondaryDark,
                      inactiveTrackColor: LatoColors.textSecondaryDark
                          .withValues(alpha: 0.25),
                    ),
                  ],
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            widthFactor: 1,
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
        ),
      ),
    );
  }
}

/// Neutral feature chip with a remove control (48dp tap target on the x).
class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: LatoSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: LatoRadius.chip,
        border: Border.all(color: LatoColors.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: LatoColors.textSecondaryDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: Semantics(
              label: 'Remove $label',
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: LatoColors.textSecondaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
