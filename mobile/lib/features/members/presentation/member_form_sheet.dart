import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../plans/data/plan_repository.dart';
import '../../plans/domain/plan.dart';
import '../../plans/domain/plans_response.dart';
import '../../../design/colors.dart';
import '../../../core/utils/money.dart';
import '../../../design/components/lato_balance_line.dart';
import '../../../design/components/lato_payment_method_pills.dart';
import '../../../design/components/lato_sheet.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/spacing.dart';
import '../application/member_controller.dart';
import '../data/member_repository.dart';
import '../domain/member.dart';

/// Add/edit-member bottom sheet. Mirrors the Figma `members_directory_v2.png`
/// sheet: drag handle, title + close, PERSONAL INFO section, MEMBERSHIP
/// section, full-width lime primary CTA.
///
/// Pass [existingMember] to edit it in place (`PUT /members/:id`) — the
/// form pre-fills from it and the Plan picker becomes a read-only display
/// of the current plan, since plan changes go through the payment/renewal
/// flow (`membershipLifecycle.ts`), not a raw member update. Leave it null
/// to create a new member (`POST /members`), which is the only mode this
/// sheet supported until now.
class MemberFormSheet extends ConsumerStatefulWidget {
  const MemberFormSheet({super.key, this.existingMember});

  final Member? existingMember;

  @override
  ConsumerState<MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends ConsumerState<MemberFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  String? _selectedPlanId;
  String? _selectedPlanName;
  double? _planPrice;
  DateTime? _startDate;
  String _method = 'cash';

  bool _isSubmitting = false;

  bool get _isEditing => widget.existingMember != null;

  @override
  void initState() {
    super.initState();
    final member = widget.existingMember;
    if (member == null) return;
    _nameCtrl.text = member.name;
    _phoneCtrl.text = member.phone;
    _emailCtrl.text = member.email ?? '';
    _addressCtrl.text = member.address ?? '';
    _notesCtrl.text = member.notes ?? '';
    _gender = member.gender;
    _dateOfBirth = DateTime.tryParse(member.dateOfBirth ?? '');
    // Display-only in edit mode (see class doc) — not sent on submit.
    _selectedPlanId = member.planId;
    _selectedPlanName = member.planName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await _showThemedDatePicker(
      initial: _dateOfBirth ?? now.subtract(const Duration(days: 365 * 25)),
      first: DateTime(1900),
      last: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await _showThemedDatePicker(
      initial: _startDate ?? now,
      first: now.subtract(const Duration(days: 365)),
      last: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<DateTime?> _showThemedDatePicker({
    required DateTime initial,
    required DateTime first,
    required DateTime last,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (ctx, c) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: LatoColors.primary,
            onPrimary: LatoColors.bgDark,
            surface: LatoColors.surfaceDark,
            onSurface: LatoColors.textPrimaryDark,
          ),
        ),
        child: c ?? const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _pickGender() async {
    final selected = await showLatoSheet<String>(
      context: context,
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LatoSheetTitle('Select Gender'),
              for (final value in const ['Male', 'Female', 'Other'])
                ListTile(
                  title: Text(value),
                  onTap: () => Navigator.of(sheetCtx).pop(value),
                ),
              const SizedBox(height: LatoSpacing.md),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        _gender = selected.toLowerCase();
      });
    }
  }

  static const _plansQuery = PlanListQuery(status: 'active', limit: 100);

  Future<void> _pickPlan() async {
    const check = Icon(Icons.check, color: LatoColors.primary);
    // Opens at once; the list fills in from the (usually prefetched) query.
    // A Plan result means "chosen"; the sentinel means "No plan".
    final selected = await showLatoSheet<Object>(
      context: context,
      builder: (sheetCtx) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final plansAsync = ref.watch(planListProvider(_plansQuery));
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LatoSheetTitle('Select Plan'),
                  ListTile(
                    title: const Text('No plan'),
                    trailing: _selectedPlanId == null ? check : null,
                    onTap: () => Navigator.of(sheetCtx).pop(_noPlan),
                  ),
                  ...plansAsync.when(
                    loading: () => const [
                      Padding(
                        padding: EdgeInsets.all(LatoSpacing.lg),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ],
                    error: (e, _) => [
                      Padding(
                        padding: const EdgeInsets.all(LatoSpacing.lg),
                        child: Text(
                          e is ApiException
                              ? e.message
                              : 'Could not load plans',
                          style: const TextStyle(color: LatoColors.error),
                        ),
                      ),
                    ],
                    data: (result) => [
                      if (result.plans.isNotEmpty) const Divider(height: 1),
                      for (final p in result.plans)
                        ListTile(
                          title: Text(p.name),
                          subtitle: Text(
                            '${p.formattedPrice} \u00b7 ${p.durationDays} days',
                          ),
                          trailing: p.id == _selectedPlanId ? check : null,
                          onTap: () => Navigator.of(sheetCtx).pop(p),
                        ),
                    ],
                  ),
                  const SizedBox(height: LatoSpacing.md),
                ],
              );
            },
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() {
      if (selected is Plan) {
        if (selected.id != _selectedPlanId) {
          // New plan: offer its full price as the amount paid.
          _amountCtrl.text = _plain(selected.price);
        }
        _selectedPlanId = selected.id;
        _selectedPlanName = selected.name;
        _planPrice = selected.price;
      } else {
        _selectedPlanId = null;
        _selectedPlanName = null;
        _planPrice = null;
        _amountCtrl.clear();
        _referenceCtrl.clear();
        _startDate = null;
        _method = 'cash';
      }
    });
  }

  static const Object _noPlan = Object();

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      if (_isEditing) {
        final controller = ref.read(memberUpdateControllerProvider.notifier);
        await controller.update(
          widget.existingMember!.id,
          MemberUpdateInput(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            dateOfBirth: _dateOfBirth == null
                ? null
                : _formatDate(_dateOfBirth!),
            gender: _gender,
            notes: _notesCtrl.text.trim(),
          ),
        );
      } else {
        final controller = ref.read(memberCreateControllerProvider.notifier);
        await controller.create(
          MemberCreateInput(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            dateOfBirth: _dateOfBirth == null
                ? null
                : _formatDate(_dateOfBirth!),
            gender: _gender,
            planId: _selectedPlanId,
            membershipStart: _startDate == null
                ? null
                : _formatDate(_startDate!),
            amountPaid: _selectedPlanId == null ? null : _paid,
            paymentMethod: _selectedPlanId != null && (_paid ?? 0) > 0
                ? _method
                : null,
            reference:
                _selectedPlanId != null && (_paid ?? 0) > 0 && _method != 'cash'
                ? _referenceCtrl.text.trim()
                : null,
            notes: _notesCtrl.text.trim(),
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Member updated' : 'Member added')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not create member: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Start loading plans now (and keep them alive while the form is open)
    // so the Plan picker opens with its list already in hand.
    if (!_isEditing) ref.watch(planListProvider(_plansQuery));
    return LatoFormSheetScaffold(
      title: _isEditing ? 'Edit Member' : 'Add Member',
      footer: LatoPrimaryButton(
        label: _isEditing ? 'SAVE CHANGES' : 'ADD MEMBER',
        loading: _isSubmitting,
        onPressed: _isSubmitting ? null : _submit,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('PERSONAL INFO'),
            const SizedBox(height: LatoSpacing.md),
            _RequiredLabel(text: 'Full Name'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'e.g., Rahul Sharma'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: LatoSpacing.lg),
            _RequiredLabel(text: 'Phone Number'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
              ],
              decoration: const InputDecoration(hintText: '98765 43210'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Phone is required';
                }
                if (v.replaceAll(RegExp(r'\D'), '').length < 10) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: LatoSpacing.lg),
            const _FieldLabel('Email'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'name@example.com'),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return null;
                if (!value.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: LatoSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Date of Birth'),
                      const SizedBox(height: LatoSpacing.sm),
                      _PickerField(
                        hint: 'Select',
                        value: _dateOfBirth == null
                            ? null
                            : DateFormat('d MMM y').format(_dateOfBirth!),
                        icon: null,
                        trailingIcon: Icons.calendar_today_outlined,
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: LatoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Gender'),
                      const SizedBox(height: LatoSpacing.sm),
                      _PickerField(
                        hint: 'Select',
                        value: _gender == null ? null : _capitalize(_gender!),
                        icon: null,
                        onTap: _pickGender,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: LatoSpacing.lg),
            const _FieldLabel('Address'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _addressCtrl,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Street, area, city'),
            ),
            const SizedBox(height: LatoSpacing.lg),
            const _FieldLabel('Notes'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _notesCtrl,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Any extra context for this member',
              ),
            ),
            const SizedBox(height: LatoSpacing.xxl),
            const _SectionLabel('MEMBERSHIP'),
            const SizedBox(height: LatoSpacing.md),
            _FieldLabel(_isEditing ? 'Current Plan' : 'Plan (Optional)'),
            const SizedBox(height: LatoSpacing.sm),
            if (_isEditing)
              // Plan changes go through Renew/Payment (a plan
              // purchase), not a raw member update — see
              // `membershipLifecycle.ts`. Show it, don't offer
              // to edit it here.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PickerField(
                    hint: 'No plan',
                    value: _selectedPlanName,
                    icon: Icons.lock_outline,
                    onTap: null,
                  ),
                  const SizedBox(height: LatoSpacing.sm),
                  Text(
                    'To change the plan, use Record Payment.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            else
              _PickerField(
                hint: 'No plan',
                value: _selectedPlanName,
                icon: null,
                onTap: _pickPlan,
              ),
            if (!_isEditing && _selectedPlanId != null && _planPrice != null)
              ..._paymentSection(context, _planPrice!),
          ],
        ),
      ),
    );
  }

  /// Start date, amount paid now, method and the live balance for a plan
  /// bought while adding the member (Add mode only).
  List<Widget> _paymentSection(BuildContext context, double price) {
    final theme = Theme.of(context);
    final paid = _paid;
    final valid = paid != null && paid >= 0 && paid <= price;
    final due = valid ? price - paid : null;
    final hasPayment = valid && paid > 0;

    final Widget balance;
    if (due == null) {
      balance = const SizedBox.shrink();
    } else if (!hasPayment) {
      balance = LatoBalanceLine(
        text: 'No payment recorded. ${_money(price)} will be due.',
        color: LatoColors.warning,
        icon: Icons.info_outline,
      );
    } else {
      balance = LatoBalanceLine.afterPayment(dueAfter: due);
    }

    return [
      const SizedBox(height: LatoSpacing.lg),
      const _FieldLabel('Start date'),
      const SizedBox(height: LatoSpacing.sm),
      _PickerField(
        hint: 'Today',
        value: _startDate == null
            ? null
            : DateFormat('d MMM y').format(_startDate!),
        icon: null,
        trailingIcon: Icons.calendar_today_outlined,
        onTap: _pickStartDate,
      ),
      if (_startDate != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _startDate = null),
            child: const Text('Use today'),
          ),
        ),
      const SizedBox(height: LatoSpacing.xxl),
      const _SectionLabel('PAYMENT'),
      const SizedBox(height: LatoSpacing.md),
      Row(
        children: [
          Expanded(
            child: Text('Plan price', style: theme.textTheme.bodyMedium),
          ),
          Text(_money(price), style: theme.textTheme.labelLarge),
        ],
      ),
      const SizedBox(height: LatoSpacing.lg),
      const _FieldLabel('Amount paid now'),
      const SizedBox(height: LatoSpacing.sm),
      TextFormField(
        controller: _amountCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: '0',
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Text(
              '\u20b9',
              style: TextStyle(
                fontSize: 16,
                color: LatoColors.textSecondaryDark,
              ),
            ),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 0),
        ),
        validator: (v) {
          final n = _paid;
          if (n == null) return 'Enter a valid amount';
          if (n > price) {
            return 'Cannot exceed the plan price (${_money(price)})';
          }
          return null;
        },
      ),
      const SizedBox(height: LatoSpacing.sm),
      balance,
      if (hasPayment) ...[
        const SizedBox(height: LatoSpacing.md),
        const _FieldLabel('Payment Method'),
        const SizedBox(height: LatoSpacing.xs),
        LatoPaymentMethodPills(
          selected: _method,
          onSelected: (value) => setState(() {
            _method = value;
            if (value == 'cash') _referenceCtrl.clear();
          }),
        ),
        if (_method != 'cash') ...[
          const SizedBox(height: LatoSpacing.md),
          const _FieldLabel('Reference / Transaction ID'),
          const SizedBox(height: LatoSpacing.sm),
          TextFormField(
            controller: _referenceCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. UPI txn ID, card auth code, cheque #',
            ),
          ),
        ],
      ],
    ];
  }

  /// Amount typed in the payment field; an empty field means nothing paid.
  /// Null when the text is not a number.
  double? get _paid {
    final text = _amountCtrl.text.trim();
    if (text.isEmpty) return 0;
    return double.tryParse(text);
  }

  static String _plain(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  static String _money(double v) => formatInr(v, decimals: v % 1 == 0 ? 0 : 2);

  static String _capitalize(String v) =>
      v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);

  /// Formats a [DateTime] as the YYYY-MM-DD string the backend expects for
  /// the `dateOfBirth` field.
  static String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
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
  const _FieldLabel(this.text);
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

/// Read-only text-field shaped picker used for date/gender/plan dropdowns.
/// A null [onTap] renders it as read-only (no chevron).
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.hint,
    required this.value,
    required this.icon,
    required this.onTap,
    this.trailingIcon = Icons.expand_more,
  });

  final String hint;
  final String? value;
  final IconData? icon;
  final VoidCallback? onTap;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: LatoRadius.button,
      onTap: onTap,
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: icon == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    icon,
                    size: 18,
                    color: LatoColors.textSecondaryDark,
                  ),
                ),
          suffixIcon: onTap == null
              ? null
              : Icon(
                  trailingIcon,
                  size: 18,
                  color: LatoColors.textSecondaryDark,
                ),
        ),
        child: value == null
            ? null
            : Text(
                value!,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
