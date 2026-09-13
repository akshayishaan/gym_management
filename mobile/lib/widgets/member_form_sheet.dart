import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/api_exception.dart';
import '../core/api/client_request_id.dart';
import '../core/api/dio_providers.dart';
import '../core/settings/gym_settings_state.dart';
import '../data/api_helpers.dart';
import '../data/filters.dart';
import '../data/formatters.dart';
import '../data/plan_providers.dart';
import '../data/query_scope.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'app_section_label.dart';
import 'app_snackbar.dart';
import 'bottom_sheet_form.dart';
import 'payment_breakdown.dart';

/// Add/Edit member form rendered inside a [BottomSheetForm].
///
/// CREATE (no `memberId`/`initialData`) adds a member with an optional
/// onboarding plan + payment; EDIT (`memberId` and/or `initialData`) updates
/// personal info only.
class MemberFormSheet extends ConsumerStatefulWidget {
  const MemberFormSheet({
    super.key,
    this.memberId,
    this.initialData,
    required this.currency,
  });

  final String? memberId;
  final MemberResponse? initialData;
  final String currency;

  /// Shows the sheet as a modal bottom sheet; completes when it is dismissed.
  static Future<void> show(
    BuildContext context, {
    String? memberId,
    MemberResponse? initialData,
    required String currency,
  }) async {
    await showAppBottomSheet<void>(
      context,
      builder: (_) => MemberFormSheet(
        memberId: memberId,
        initialData: initialData,
        currency: currency,
      ),
    );
  }

  @override
  ConsumerState<MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends ConsumerState<MemberFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _emergency = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _amountPaid = TextEditingController();
  final TextEditingController _membershipStart = TextEditingController();

  String _gender = '';
  String _planId = '';
  String _paymentMethod = 'cash';
  bool _saving = false;

  bool get _isEdit => widget.memberId != null || widget.initialData != null;

  @override
  void initState() {
    super.initState();
    final MemberResponse? d = widget.initialData;
    if (_isEdit && d != null) {
      _name.text = d.name;
      _phone.text = d.phone;
      _email.text = d.email ?? '';
      _dob.text = d.dateOfBirth ?? '';
      _gender = d.gender?.value ?? '';
      _address.text = d.address ?? '';
      _emergency.text = d.emergencyContact ?? '';
      _notes.text = d.notes ?? '';
    } else {
      // ADR-0005 note: this is an editable form-input default, not a derived
      // rendered value.
      _membershipStart.text = todayDateOnly();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _dob.dispose();
    _address.dispose();
    _emergency.dispose();
    _notes.dispose();
    _amountPaid.dispose();
    _membershipStart.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  MemberCreateInputGenderEnum? _createGender(String g) => switch (g) {
        'male' => MemberCreateInputGenderEnum.male,
        'female' => MemberCreateInputGenderEnum.female,
        'other' => MemberCreateInputGenderEnum.other,
        _ => null,
      };

  MemberUpdateInputGenderEnum? _updateGender(String g) => switch (g) {
        'male' => MemberUpdateInputGenderEnum.male,
        'female' => MemberUpdateInputGenderEnum.female,
        'other' => MemberUpdateInputGenderEnum.other,
        _ => null,
      };

  MemberCreateInputPaymentMethodEnum _paymentMethodEnum(String m) => switch (m) {
        'card' => MemberCreateInputPaymentMethodEnum.card,
        'upi' => MemberCreateInputPaymentMethodEnum.upi,
        'bank_transfer' => MemberCreateInputPaymentMethodEnum.bankTransfer,
        'other' => MemberCreateInputPaymentMethodEnum.other,
        _ => MemberCreateInputPaymentMethodEnum.cash,
      };

  PlanListResponsePlansInner? _findPlan(
    List<PlanListResponsePlansInner> plans,
    String id,
  ) {
    for (final PlanListResponsePlansInner p in plans) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _onPlanChanged(
    String? id,
    List<PlanListResponsePlansInner> plans,
  ) {
    setState(() {
      _planId = id ?? '';
      final PlanListResponsePlansInner? plan =
          id != null && id.isNotEmpty ? _findPlan(plans, id) : null;
      if (plan != null) {
        _amountPaid.text = plan.price.toString();
      } else {
        _amountPaid.clear();
      }
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      if (_isEdit) {
        final String id = widget.memberId ?? widget.initialData!.id;
        final MemberUpdateInput input = MemberUpdateInput(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          email: _nullIfEmpty(_email.text),
          dateOfBirth: _nullIfEmpty(_dob.text),
          gender: _updateGender(_gender),
          address: _nullIfEmpty(_address.text),
          emergencyContact: _nullIfEmpty(_emergency.text),
          notes: _nullIfEmpty(_notes.text),
        );
        await putJson<MemberResponse>(
          dio,
          '/members/$id',
          data: input.toJson(),
          fromJson: MemberResponse.fromJson,
        );
        if (mounted) showAppSnackBar(context, 'Member updated');
      } else {
        final bool hasPlan = _planId.isNotEmpty;
        final String amountText = _amountPaid.text.trim();
        final num? amountPaid =
            hasPlan && amountText.isNotEmpty ? num.tryParse(amountText) : null;

        final MemberCreateInput input = MemberCreateInput(
          requestId: createRequestId(),
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          email: _nullIfEmpty(_email.text),
          dateOfBirth: _nullIfEmpty(_dob.text),
          gender: _createGender(_gender),
          address: _nullIfEmpty(_address.text),
          emergencyContact: _nullIfEmpty(_emergency.text),
          notes: _nullIfEmpty(_notes.text),
          planId: hasPlan ? _planId : null,
          membershipStart: hasPlan && _membershipStart.text.trim().isNotEmpty
              ? _membershipStart.text.trim()
              : null,
          amountPaid: amountPaid,
          paymentMethod: amountPaid != null
              ? _paymentMethodEnum(_paymentMethod)
              : null,
        );
        await postJson<MemberCreateResponse>(
          dio,
          '/members',
          data: input.toJson(),
          fromJson: MemberCreateResponse.fromJson,
        );
        if (mounted) showAppSnackBar(context, 'Member added');
      }

      invalidateGymScopeFromWidget(ref);
      if (mounted) Navigator.of(context).pop();
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

  String _submitLabel() {
    if (_saving) return _isEdit ? 'Saving…' : 'Adding…';
    return _isEdit ? 'Save Changes' : 'Add Member';
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    final AsyncValue<PlanListResponse> plansAsync =
        ref.watch(plansProvider(const PlanFilters()));
    final List<PlanListResponsePlansInner> plans =
        plansAsync.value?.plans ?? const <PlanListResponsePlansInner>[];
    final PlanListResponsePlansInner? selectedPlan =
        _findPlan(plans, _planId);
    final num planPrice = selectedPlan?.price ?? 0;
    final int durationDays = (selectedPlan?.durationDays ?? 0).toInt();

    final String startText = _membershipStart.text.trim();
    final String? expiryPreview = (selectedPlan != null && isDateOnly(startText))
        ? addDaysToDateOnly(startText, durationDays - 1)
        : null;

    final bool showMembership = !_isEdit;

    return BottomSheetForm(
      title: _isEdit ? 'Edit Member' : 'Add Member',
      body: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppSectionLabel('Personal Info'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(t, 'Full Name *'),
                style: TextStyle(color: t.foreground),
                validator: (String? v) => _required(v, 'Name'),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(t, 'Phone *'),
                      style: TextStyle(color: t.foreground),
                      validator: (String? v) => _required(v, 'Phone'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(t, 'Email'),
                      style: TextStyle(color: t.foreground),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _dob,
                      decoration: _inputDecoration(
                        t,
                        'Date of Birth',
                        hint: 'YYYY-MM-DD',
                      ),
                      style: TextStyle(color: t.foreground),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: _inputDecoration(t, 'Gender'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text('Select'),
                        ),
                        DropdownMenuItem<String>(value: 'male', child: Text('Male')),
                        DropdownMenuItem<String>(
                          value: 'female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem<String>(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (String? v) => setState(() => _gender = v ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(t, 'Address'),
                style: TextStyle(color: t.foreground),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergency,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(t, 'Emergency Contact'),
                style: TextStyle(color: t.foreground),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                textInputAction: TextInputAction.done,
                decoration: _inputDecoration(t, 'Notes'),
                style: TextStyle(color: t.foreground),
              ),
              if (showMembership) ...<Widget>[
                const SizedBox(height: 24),
                const AppSectionLabel('Membership'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _planId,
                  decoration: _inputDecoration(t, 'Plan'),
                  items: <DropdownMenuItem<String>>[
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('No plan (optional)'),
                    ),
                    for (final PlanListResponsePlansInner p in plans)
                      DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(
                          '${p.name} — ${currencySymbol(widget.currency)}${p.price} / ${p.durationDays}d',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (String? v) => _onPlanChanged(v, plans),
                ),
                if (selectedPlan != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _membershipStart,
                          decoration: _inputDecoration(
                            t,
                            'Start Date',
                            hint: 'YYYY-MM-DD',
                          ),
                          style: TextStyle(color: t.foreground),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          // ValueKey forces a fresh controller when the preview
                          // changes, so the readOnly field tracks the computed
                          // expiry as the start date / plan are edited.
                          key: ValueKey<String?>(expiryPreview),
                          initialValue: expiryPreview != null
                              ? formatDate(expiryPreview)
                              : '',
                          readOnly: true,
                          decoration: _inputDecoration(t, 'Expiry Date'),
                          style: TextStyle(
                            color: expiryPreview != null
                                ? t.foreground
                                : t.muted.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const AppSectionLabel('Payment'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _amountPaid,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            t,
                            'Amount Paid (${currencySymbol(widget.currency)})',
                          ),
                          style: TextStyle(color: t.foreground),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _paymentMethod,
                          decoration: _inputDecoration(t, 'Method'),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(value: 'cash', child: Text('Cash')),
                            DropdownMenuItem<String>(value: 'card', child: Text('Card')),
                            DropdownMenuItem<String>(value: 'upi', child: Text('UPI')),
                            DropdownMenuItem<String>(
                              value: 'bank_transfer',
                              child: Text('Bank Transfer'),
                            ),
                            DropdownMenuItem<String>(value: 'other', child: Text('Other')),
                          ],
                          onChanged: (String? v) =>
                              setState(() => _paymentMethod = v ?? 'cash'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PaymentBreakdown(
                    items: <PaymentBreakdownItem>[
                      PaymentBreakdownItem(label: 'Plan price', value: planPrice),
                    ],
                    amountPaid: num.tryParse(_amountPaid.text.trim()) ?? 0,
                    currency: widget.currency,
                  ),
                ],
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
      footer: _buildSubmitButton(t),
    );
  }

  Widget _buildSubmitButton(ThemeTokens t) {
    return FilledButton(
      onPressed: _saving ? null : _submit,
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
          : Text(_submitLabel()),
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
