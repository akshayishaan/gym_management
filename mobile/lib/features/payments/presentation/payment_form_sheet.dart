import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/money.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_sheet.dart';
import '../../../design/components/lato_balance_line.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_payment_method_pills.dart';
import '../../../design/spacing.dart';
import '../../members/data/member_repository.dart';
import '../../members/domain/member.dart';
import '../../members/domain/member_query.dart';
import '../../plans/data/plan_repository.dart';
import '../../plans/domain/plan.dart';
import '../../plans/domain/plans_response.dart';
import '../application/payment_controller.dart';
import '../data/payment_repository.dart';

/// Record-payment bottom sheet. Mirrors the form-sheet pattern from
/// `member_form_sheet.dart` and `plan_form_sheet.dart`: drag handle, title
/// + close, PAYMENT DETAILS section (member picker, plan picker, amount,
/// method, notes), full-width lime primary CTA.
///
/// Pass [member] to pre-select the member — the picker is then skipped
/// and the section shows their name + plan + due amount. Leave it null
/// when the form is opened from a context where the user must pick a
/// member first (the dashboard "Record Pay" tile, for example).
class PaymentFormSheet extends ConsumerStatefulWidget {
  const PaymentFormSheet({super.key, this.member});

  /// Optional pre-selected member. When non-null the picker is hidden.
  final Member? member;

  @override
  ConsumerState<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Member? _selectedMember;
  Plan? _selectedPlan;

  /// Optional custom start date for a plan purchase. Null means "use the
  /// server default" (the latest active period's end, else today). The backend
  /// only accepts `membershipStart` alongside a plan, so this stays null for a
  /// dues payment and the field is hidden then.
  DateTime? _startDate;
  String _method = 'cash';

  bool _isSubmitting = false;

  static const _planQuery = PlanListQuery(status: 'active', limit: 100);

  @override
  void initState() {
    super.initState();
    // Start loading plans as soon as the sheet opens and keep the
    // auto-dispose provider alive while it is shown, so the picker opens
    // from cache instead of waiting on the network at tap time.
    ref.listenManual(planListProvider(_planQuery), (_, _) {});
    final m = widget.member;
    if (m != null) {
      _selectedMember = m;
      _prefillDues();
    }
  }

  double get _due => _selectedMember?.dueAmount ?? 0;

  /// A member is chosen, no plan is attached, and nothing is owed: the backend
  /// rejects a dues payment in that case, so the form says so up front.
  bool get _noDues =>
      _selectedMember != null && _selectedPlan == null && _due <= 0;

  /// Dues mode: offer the outstanding balance as the amount (editable).
  void _prefillDues() {
    _amountCtrl.text = _due > 0 ? _due.toStringAsFixed(2) : '';
  }

  static String _money(num v) => formatInr(v, decimals: v % 1 == 0 ? 0 : 2);

  /// What the member will still owe once this payment is recorded, or null
  /// when it can't be worked out yet (no member, no valid amount, or an
  /// amount the form will reject anyway).
  ///
  /// A plan purchase adds its price to what is owed (the ledger is
  /// "sum of memberships - sum of payments"), so earlier dues carry over.
  double? get _dueAfter {
    if (_selectedMember == null) return null;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return null;
    final plan = _selectedPlan;
    if (plan != null) {
      return amount > plan.price ? null : _due + plan.price - amount;
    }
    if (_due <= 0 || amount > _due) return null;
    return _due - amount;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMember() async {
    final selected = await showLatoSheet<Member>(
      context: context,
      builder: (_) => _MemberPickerSheet(selectedId: _selectedMember?.id),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedMember = selected;
        // The previous plan price doesn't carry over to a different member.
        _selectedPlan = null;
        _startDate = null;
        _prefillDues();
      });
    }
  }

  /// Loads the plan list and presents a picker whose first option is
  /// "Dues payment (no plan)": selecting it clears the plan and offers the
  /// member's outstanding balance as the amount.
  Future<void> _pickPlan() async {
    List<Plan> plans = const [];
    String? errorMessage;
    try {
      final result = await ref.read(planListProvider(_planQuery).future);
      plans = result.plans;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Could not load plans';
    }

    if (!mounted) return;

    const check = Icon(Icons.check, color: LatoColors.primary);
    final selected = await showLatoSheet<_PlanChoice>(
      context: context,
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LatoSheetTitle('Select Plan'),
              const Divider(height: 1),
              ListTile(
                contentPadding: _tilePadding,
                title: const Text('Dues payment (no plan)'),
                subtitle: const Text(
                  'Settle the member\'s outstanding balance',
                ),
                trailing: _selectedPlan == null ? check : null,
                onTap: () =>
                    Navigator.of(sheetCtx).pop(const _PlanChoice.dues()),
              ),
              if (plans.isNotEmpty) const Divider(height: 1),
              Flexible(
                child: errorMessage != null && plans.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(LatoSpacing.lg),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: LatoColors.error),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: plans.length,
                        itemBuilder: (_, i) {
                          final p = plans[i];
                          return ListTile(
                            contentPadding: _tilePadding,
                            title: Text(p.name),
                            subtitle: Text(
                              '${p.durationDays}d · ${_money(p.price)}',
                              style: Theme.of(sheetCtx).textTheme.bodySmall,
                            ),
                            trailing: _selectedPlan?.id == p.id ? check : null,
                            onTap: () =>
                                Navigator.of(sheetCtx).pop(_PlanChoice.plan(p)),
                          );
                        },
                      ),
              ),
              const SizedBox(height: LatoSpacing.md),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedPlan = selected.plan;
        if (selected.plan != null) {
          // Pre-fill the amount with the plan price (editable).
          _amountCtrl.text = selected.plan!.price.toStringAsFixed(2);
        } else {
          // Dues payment: a start date has no meaning, and the backend
          // rejects it without a plan.
          _startDate = null;
          _prefillDues();
        }
      });
    }
  }

  /// Themed date picker for the optional plan start date, within one year
  /// either side of today (matching the member onboarding form).
  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: LatoColors.primary,
            onPrimary: LatoColors.bgDark,
            surface: LatoColors.surfaceDark,
            onSurface: LatoColors.textPrimaryDark,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null && mounted) setState(() => _startDate = picked);
  }

  /// `YYYY-MM-DD` in the device's local date, matching the Gym-local date-only
  /// contract the backend validates.
  static String _isoDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_selectedMember == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a member')));
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      final payment = await ref
          .read(paymentRecordControllerProvider.notifier)
          .record(
            PaymentCreateInput(
              memberId: _selectedMember!.id,
              amount: amount,
              method: _method,
              planId: _selectedPlan?.id,
              // Only a plan purchase carries a start date; null lets the
              // backend default it.
              membershipStart: _selectedPlan == null || _startDate == null
                  ? null
                  : _isoDate(_startDate!),
              reference: _method == 'cash' || _referenceCtrl.text.trim().isEmpty
                  ? null
                  : _referenceCtrl.text.trim(),
              notes: _notesCtrl.text.trim().isEmpty
                  ? null
                  : _notesCtrl.text.trim(),
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      final invoice = payment.invoiceNumber;
      final snack = invoice.isEmpty
          ? 'Payment recorded'
          : 'Payment recorded: $invoice';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(snack)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not record payment: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = _selectedPlan;
    return LatoFormSheetScaffold(
      title: 'Record Payment',
      footer: LatoPrimaryButton(
        label: 'RECORD PAYMENT',
        loading: _isSubmitting,
        onPressed: _isSubmitting || _noDues ? null : _submit,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('PAYMENT DETAILS'),
            const SizedBox(height: LatoSpacing.md),
            // Member: one card for both entry points. Before a choice the
            // user sees the picker field; afterwards the same card is shown
            // whether the member was picked here or passed in. It is tappable
            // (to change) only when the member was picked here.
            if (_selectedMember == null) ...[
              const _RequiredLabel(text: 'Member'),
              const SizedBox(height: LatoSpacing.sm),
              _PickerField(
                hint: 'Select member',
                value: null,
                icon: Icons.person_outline,
                onTap: _pickMember,
              ),
            ] else ...[
              widget.member == null
                  ? const _RequiredLabel(text: 'Member')
                  : const _FieldLabel(text: 'Member'),
              const SizedBox(height: LatoSpacing.sm),
              _MemberCard(
                member: _selectedMember!,
                money: _money,
                onTap: widget.member == null ? _pickMember : null,
              ),
            ],
            const SizedBox(height: LatoSpacing.lg),
            // Plan picker (only when a member is selected)
            if (_selectedMember != null) ...[
              const _FieldLabel(text: 'Plan (Optional)'),
              const SizedBox(height: LatoSpacing.sm),
              _PickerField(
                hint: 'Select plan',
                value: plan?.name ?? 'Dues payment (no plan)',
                icon: Icons.card_membership_outlined,
                onTap: _pickPlan,
              ),
              const SizedBox(height: LatoSpacing.lg),
            ],
            // Start date (plan purchase only) — mirrors the member onboarding
            // form. Hidden for a dues payment, which has no membership period.
            if (plan != null) ...[
              const _FieldLabel(text: 'Start date'),
              const SizedBox(height: LatoSpacing.sm),
              _PickerField(
                hint: 'Today',
                value: _startDate == null
                    ? null
                    : DateFormat('d MMM y').format(_startDate!),
                icon: Icons.calendar_today_outlined,
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
              const SizedBox(height: LatoSpacing.lg),
            ],
            // Amount
            const _RequiredLabel(text: 'Amount (₹)'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 16,
                      color: LatoColors.textSecondaryDark,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0),
                helperText: _selectedMember != null && plan == null && _due > 0
                    ? 'Outstanding: ${_money(_due)}'
                    : null,
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Amount is required';
                final n = double.tryParse(value);
                if (n == null) return 'Enter a valid amount';
                if (n <= 0) return 'Amount must be greater than 0';
                if (plan != null && n > plan.price) {
                  return 'Cannot exceed the plan price (${_money(plan.price)})';
                }
                if (plan == null && _due > 0 && n > _due) {
                  return 'Cannot exceed the outstanding ${_money(_due)}';
                }
                return null;
              },
            ),
            if (_dueAfter != null) ...[
              const SizedBox(height: LatoSpacing.sm),
              LatoBalanceLine.afterPayment(
                dueAfter: _dueAfter!,
                clearedText: plan == null ? 'All dues cleared' : 'Paid in full',
              ),
              // A plan bought while earlier dues are open: say where the
              // remaining balance comes from.
              if (plan != null && _due > 0 && _dueAfter! > 0) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    'Includes ${_money(_due)} from earlier dues.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
            if (_noDues) ...[
              const SizedBox(height: LatoSpacing.sm),
              Text(
                'No dues to settle. Pick a plan to record a purchase.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: LatoColors.warning,
                ),
              ),
            ],
            const SizedBox(height: LatoSpacing.lg),
            // Payment method
            const _RequiredLabel(text: 'Payment Method'),
            const SizedBox(height: LatoSpacing.xs),
            LatoPaymentMethodPills(
              selected: _method,
              onSelected: (value) => setState(() {
                _method = value;
                if (value == 'cash') _referenceCtrl.clear();
              }),
            ),
            // Reference: paper trail for non-cash methods only (UPI txn ID,
            // card auth code, bank transfer ref). Shown on the receipt only
            // when filled in; never fabricated.
            if (_method != 'cash') ...[
              const SizedBox(height: LatoSpacing.md),
              const _FieldLabel(text: 'Reference / Transaction ID'),
              const SizedBox(height: LatoSpacing.sm),
              TextFormField(
                controller: _referenceCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. UPI txn ID, card auth code, cheque #',
                ),
              ),
            ],
            const SizedBox(height: LatoSpacing.lg),
            // Notes
            const _FieldLabel(text: 'Notes'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Optional context for this payment',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _tilePadding = EdgeInsets.symmetric(horizontal: LatoSpacing.xl);

/// Chosen member: avatar, name, "Plan · phone" and the outstanding due.
/// Shown the same way whether the member was picked in the form or passed in;
/// [onTap] (change member) is null when the member is fixed.
class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.money,
    required this.onTap,
  });

  final Member member;
  final String Function(num) money;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (member.planName != null && member.planName!.isNotEmpty)
        member.planName!,
      if (member.phone.isNotEmpty) member.phone,
    ].join(' \u00b7 ');
    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: LatoColors.tint(LatoColors.primary),
              borderRadius: BorderRadius.circular(LatoRadius.md),
            ),
            alignment: Alignment.center,
            child: Text(
              member.initials,
              style: const TextStyle(
                color: LatoColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: LatoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (member.dueAmount > 0) ...[
            const SizedBox(width: LatoSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Due', style: theme.textTheme.bodySmall),
                Text(
                  money(member.dueAmount),
                  style: const TextStyle(
                    color: LatoColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          if (onTap != null) ...[
            const SizedBox(width: LatoSpacing.sm),
            const Icon(
              Icons.expand_more,
              size: 18,
              color: LatoColors.textSecondaryDark,
            ),
          ],
        ],
      ),
    );
  }
}

/// Select Member sheet: server-side search (name / phone / email), debounced.
/// Fixed height so it does not jump while results load.
class _MemberPickerSheet extends ConsumerStatefulWidget {
  const _MemberPickerSheet({this.selectedId});
  final String? selectedId;

  @override
  ConsumerState<_MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends ConsumerState<_MemberPickerSheet> {
  static const _pageSize = 50;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = MemberListQuery(
      search: _query.isEmpty ? null : _query,
      limit: _pageSize,
    );
    final result = ref.watch(memberListProvider(query));
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.6;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              const LatoSheetTitle('Select Member'),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LatoSpacing.xl,
                  0,
                  LatoSpacing.xl,
                  LatoSpacing.md,
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or phone',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: result.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(LatoSpacing.lg),
                      child: Text(
                        e is ApiException
                            ? e.message
                            : 'Could not load members',
                        style: const TextStyle(color: LatoColors.error),
                      ),
                    ),
                  ),
                  data: (data) {
                    if (data.members.isEmpty) {
                      return Center(
                        child: Text(
                          _query.isEmpty
                              ? 'No members yet'
                              : 'No members found',
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: data.members.length + 1,
                      itemBuilder: (_, i) {
                        if (i == data.members.length) {
                          return data.total > data.members.length
                              ? Padding(
                                  padding: const EdgeInsets.all(LatoSpacing.lg),
                                  child: Text(
                                    'Showing ${data.members.length} of '
                                    '${data.total}. Search to narrow down.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                )
                              : const SizedBox(height: LatoSpacing.md);
                        }
                        final m = data.members[i];
                        final subtitle = [
                          if (m.phone.isNotEmpty) m.phone,
                          if (m.planName != null && m.planName!.isNotEmpty)
                            m.planName!,
                        ].join(' · ');
                        return ListTile(
                          contentPadding: _tilePadding,
                          title: Text(m.name),
                          subtitle: subtitle.isEmpty
                              ? null
                              : Text(
                                  subtitle,
                                  style: theme.textTheme.bodySmall,
                                ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (m.dueAmount > 0)
                                Text(
                                  formatInr(
                                    m.dueAmount,
                                    decimals: m.dueAmount % 1 == 0 ? 0 : 2,
                                  ),
                                  style: const TextStyle(
                                    color: LatoColors.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              if (m.id == widget.selectedId) ...[
                                const SizedBox(width: LatoSpacing.sm),
                                const Icon(
                                  Icons.check,
                                  color: LatoColors.primary,
                                ),
                              ],
                            ],
                          ),
                          onTap: () => Navigator.of(context).pop(m),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Discriminated result returned from the plan picker bottom sheet —
/// either the user wants to record a plan purchase (carries the chosen
/// `Plan`) or a dues-only payment (no plan).
class _PlanChoice {
  const _PlanChoice.plan(Plan this.plan) : isDues = false;
  const _PlanChoice.dues() : plan = null, isDues = true;

  final Plan? plan;
  final bool isDues;
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

/// Read-only text-field shaped picker used for member / plan / method
/// dropdowns. Mirrors the private picker in `member_form_sheet.dart`.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.hint,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String hint;
  final String? value;
  final IconData? icon;
  final VoidCallback onTap;

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
          suffixIcon: const Icon(
            Icons.expand_more,
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
