import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/api_exception.dart';
import '../core/api/dio_providers.dart';
import '../core/settings/gym_settings_controller.dart';
import '../core/settings/gym_settings_state.dart';
import '../data/api_helpers.dart';
import '../data/query_scope.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'app_section_label.dart';
import 'app_snackbar.dart';
import 'bottom_sheet_form.dart';

/// Create / duplicate / edit plan form rendered inside a [BottomSheetForm].
///
/// CREATE (`plan == null`) adds a plan; DUPLICATE (`duplicate == true`) posts a
/// new plan pre-filled from [plan]; EDIT (`plan != null`, `duplicate == false`)
/// updates the plan in place.
class PlanFormSheet extends ConsumerStatefulWidget {
  const PlanFormSheet({
    super.key,
    this.plan,
    this.duplicate = false,
  });

  final PlanListResponsePlansInner? plan;
  final bool duplicate;

  /// Shows the sheet as a modal bottom sheet; completes when it is dismissed.
  static Future<void> show(
    BuildContext context, {
    PlanListResponsePlansInner? plan,
    bool duplicate = false,
  }) async {
    await showAppBottomSheet<void>(
      context,
      builder: (_) => PlanFormSheet(plan: plan, duplicate: duplicate),
    );
  }

  @override
  ConsumerState<PlanFormSheet> createState() => _PlanFormSheetState();
}

class _PlanFormSheetState extends ConsumerState<PlanFormSheet> {
  static const List<int> kDurationPresets = <int>[30, 90, 180, 365];
  static const int kMaxFeatures = 20;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _duration = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _feature = TextEditingController();

  List<String> _features = <String>[];
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.plan != null && !widget.duplicate;

  String get _title {
    if (_isEdit) return 'Edit Plan';
    if (widget.duplicate) return 'Duplicate Plan';
    return 'Create Plan';
  }

  @override
  void initState() {
    super.initState();
    final PlanListResponsePlansInner? p = widget.plan;
    if (p != null) {
      _name.text = widget.duplicate ? '${p.name} Copy' : p.name;
      _description.text = p.description ?? '';
      _duration.text = p.durationDays.toInt().toString();
      _price.text = p.price.toString();
      _features = List<String>.from(p.features ?? const <String>[]);
      _isActive = p.isActive;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _duration.dispose();
    _price.dispose();
    _feature.dispose();
    super.dispose();
  }

  void _addFeature() {
    final String value = _feature.text.trim();
    if (value.isEmpty) return;
    if (_features.any((String f) => f.toLowerCase() == value.toLowerCase())) {
      showAppSnackBar(context, 'Feature already added', isError: true);
      return;
    }
    if (_features.length >= kMaxFeatures) {
      showAppSnackBar(
        context,
        'A plan can have up to $kMaxFeatures features',
        isError: true,
      );
      return;
    }
    setState(() {
      _features.add(value);
      _feature.clear();
    });
  }

  void _removeFeature(String value) {
    setState(() => _features.remove(value));
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final String name = _name.text.trim();
      final String? description =
          _description.text.trim().isEmpty ? null : _description.text.trim();
      final int durationDays = int.parse(_duration.text.trim());
      final num price = num.parse(_price.text.trim());
      final List<String>? features =
          _features.isEmpty ? null : List<String>.from(_features);

      if (_isEdit) {
        final PlanUpdateInput input = PlanUpdateInput(
          name: name,
          description: description,
          durationDays: durationDays,
          price: price,
          features: features,
          isActive: _isActive,
        );
        await putJson<PlanResponse>(
          dio,
          '/plans/${widget.plan!.id}',
          data: input.toJson(),
          fromJson: PlanResponse.fromJson,
        );
        if (mounted) showAppSnackBar(context, 'Plan updated');
      } else {
        final PlanCreateInput input = PlanCreateInput(
          name: name,
          description: description,
          durationDays: durationDays,
          price: price,
          features: features,
          isActive: _isActive,
        );
        await postJson<PlanResponse>(
          dio,
          '/plans',
          data: input.toJson(),
          fromJson: PlanResponse.fromJson,
        );
        if (mounted) showAppSnackBar(context, 'Plan created');
      }

      if (mounted) {
        invalidateGymScopeFromWidget(ref);
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.userMessage, isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Something went wrong', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final String currency = ref.watch(gymSettingsControllerProvider).currency;

    return BottomSheetForm(
      title: _title,
      description: 'Set the price, duration and features members see.',
      body: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _livePreview(t, currency),
              const SizedBox(height: 24),
              const AppSectionLabel('Plan details'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(t, 'Name *'),
                style: TextStyle(color: t.foreground),
                validator: (String? v) => _required(v, 'Name'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                textInputAction: TextInputAction.next,
                maxLines: 3,
                decoration: _inputDecoration(
                  t,
                  'Description',
                  hint: 'What does this plan include?',
                ),
                style: TextStyle(color: t.foreground),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _duration,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(t, 'Duration (days) *'),
                style: TextStyle(color: t.foreground),
                validator: _validateDuration,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              _durationPresets(t),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: _inputDecoration(
                  t,
                  'Price (${currencySymbol(currency)}) *',
                ),
                style: TextStyle(color: t.foreground),
                validator: _validatePrice,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              const AppSectionLabel('Features'),
              const SizedBox(height: 12),
              _featureInput(t),
              if (_features.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _featureChips(t),
              ],
              const SizedBox(height: 24),
              _activeToggle(t),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
      footer: _buildSubmitButton(t),
    );
  }

  Widget _livePreview(ThemeTokens t, String currency) {
    final String name =
        _name.text.trim().isEmpty ? 'Your plan name' : _name.text.trim();
    final num price = num.tryParse(_price.text.trim()) ?? 0;
    final int duration = int.tryParse(_duration.text.trim()) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.foreground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Live preview',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: withOpacity(t.background, 0.55),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: withOpacity(t.background, 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.fitness_center, size: 22, color: t.background),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: t.background,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${currencySymbol(currency)}$price for $duration days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: withOpacity(t.background, 0.60),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _durationPresets(ThemeTokens t) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final int preset in kDurationPresets)
          _DurationChip(
            label: preset == 365 ? '1 yr' : '$preset',
            selected: _duration.text.trim() == preset.toString(),
            tokens: t,
            onTap: () => setState(() => _duration.text = preset.toString()),
          ),
      ],
    );
  }

  Widget _featureInput(ThemeTokens t) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _feature,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addFeature(),
            decoration: _inputDecoration(
              t,
              'Add feature',
              hint: 'e.g. Unlimited access',
            ),
            style: TextStyle(color: t.foreground),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _addFeature,
          style: IconButton.styleFrom(
            backgroundColor: t.primary.value,
            foregroundColor: t.primary.foreground,
            minimumSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.add, size: 22),
        ),
      ],
    );
  }

  Widget _featureChips(ThemeTokens t) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final String feature in _features)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            decoration: BoxDecoration(
              color: t.muted.value,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: withOpacity(t.border, 0.7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.check, size: 14, color: t.success.value),
                const SizedBox(width: 6),
                Text(
                  feature,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.foreground,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _removeFeature(feature),
                  borderRadius: BorderRadius.circular(999),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: t.muted.foreground,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _activeToggle(ThemeTokens t) {
    return InkWell(
      onTap: () => setState(() => _isActive = !_isActive),
      borderRadius: BorderRadius.circular(t.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: t.card.value,
          borderRadius: BorderRadius.circular(t.radius),
          border: Border.all(color: withOpacity(t.border, 0.7)),
        ),
        child: Row(
          children: <Widget>[
            Checkbox(
              value: _isActive,
              onChanged: (bool? v) =>
                  setState(() => _isActive = v ?? true),
              activeColor: t.primary.value,
            ),
            const SizedBox(width: 8),
            Text(
              'Active plan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeTokens t) {
    final bool disabled = _saving;
    return FilledButton(
      onPressed: disabled ? null : _submit,
      style: FilledButton.styleFrom(
        backgroundColor: t.primary.value,
        foregroundColor: t.primary.foreground,
        disabledBackgroundColor: withOpacity(t.primary.value, 0.5),
        disabledForegroundColor: t.primary.foreground,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radius),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: _saving
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: t.primary.foreground,
              ),
            )
          : Text(_isEdit ? 'Save Changes' : 'Create Plan'),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? t.foreground : t.muted.value,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? t.foreground : withOpacity(t.border, 0.6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? t.background : t.muted.foreground,
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(ThemeTokens t, String label, {String? hint}) {
  final OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(t.radius),
    borderSide: BorderSide(color: withOpacity(t.border, 0.7)),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: t.card.value,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: TextStyle(color: t.muted.foreground),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(t.radius),
      borderSide: BorderSide(color: withOpacity(t.ring, 0.4), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(t.radius),
      borderSide: BorderSide(color: t.destructive.value),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(t.radius),
      borderSide: BorderSide(color: t.destructive.value, width: 2),
    ),
  );
}

String? _required(String? value, String label) {
  if (value == null || value.trim().isEmpty) {
    return '$label is required';
  }
  return null;
}

String? _validateDuration(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Duration is required';
  }
  final int? parsed = int.tryParse(value.trim());
  if (parsed == null || parsed <= 0) {
    return 'Enter a positive number of days';
  }
  return null;
}

String? _validatePrice(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Price is required';
  }
  final num? parsed = num.tryParse(value.trim());
  if (parsed == null || parsed < 0) {
    return 'Enter a valid price';
  }
  return null;
}
