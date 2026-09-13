import 'dart:async';

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
import '../data/member_providers.dart';
import '../data/plan_providers.dart';
import '../data/query_scope.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'app_snackbar.dart';
import 'avatar.dart';
import 'bottom_sheet_form.dart';
import 'payment_breakdown.dart';

/// "Record Payment" form rendered inside a [BottomSheetForm], mirroring the web
/// `PaymentFormDialog`.
///
/// Either clears outstanding dues (no plan) or starts/renews a membership
/// (plan). The member field is locked when [prefillMemberId] is supplied.
class PaymentFormSheet extends ConsumerStatefulWidget {
  const PaymentFormSheet({
    super.key,
    this.prefillMemberId,
    this.prefillMemberName,
    required this.currency,
  });

  final String? prefillMemberId;
  final String? prefillMemberName;
  final String currency;

  /// Shows the sheet as a modal bottom sheet; completes when it is dismissed.
  static Future<void> show(
    BuildContext context, {
    String? prefillMemberId,
    String? prefillMemberName,
    required String currency,
  }) async {
    await showAppBottomSheet<void>(
      context,
      builder: (_) => PaymentFormSheet(
        prefillMemberId: prefillMemberId,
        prefillMemberName: prefillMemberName,
        currency: currency,
      ),
    );
  }

  @override
  ConsumerState<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<PaymentFormSheet> {
  final TextEditingController _search = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _membershipStart = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  Timer? _debounce;
  String _deferredSearch = '';

  String? _memberId;
  String? _memberName;
  num _selectedDue = 0;
  String? _selectedExpiry;
  String _planId = '';
  String _method = 'cash';
  bool _saving = false;

  bool get _isLocked => widget.prefillMemberId != null;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _deferredSearch = value.trim());
    });
  }

  PlanListResponsePlansInner? _findPlan(
    List<PlanListResponsePlansInner> plans,
    String id,
  ) {
    for (final PlanListResponsePlansInner p in plans) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _selectMember(MemberResponse m) {
    _debounce?.cancel();
    setState(() {
      _memberId = m.id;
      _memberName = m.name;
      _selectedDue = m.dueAmount;
      _selectedExpiry = m.membershipExpiry;
      _deferredSearch = '';
      _search.clear();
    });
  }

  void _clearMember() {
    _debounce?.cancel();
    setState(() {
      _memberId = null;
      _memberName = null;
      _selectedDue = 0;
      _selectedExpiry = null;
      _planId = '';
      _membershipStart.clear();
      _amount.clear();
      _deferredSearch = '';
      _search.clear();
    });
  }

  // ADR-0005 note: the smart default below is an editable form input, not a
  // rendered value. `today`/`expiry + 1` are compared/shifted as YYYY-MM-DD
  // strings (which sort chronologically) purely to seed a default start date.
  String _defaultStart(String today, String? memberExpiry) {
    if (memberExpiry != null && memberExpiry.compareTo(today) >= 0) {
      return addDaysToDateOnly(memberExpiry, 1);
    }
    return today;
  }

  void _onPlanChanged(
    String? id,
    List<PlanListResponsePlansInner> plans,
    String today,
    String? memberExpiry,
  ) {
    setState(() {
      _planId = id ?? '';
      final PlanListResponsePlansInner? plan =
          id != null && id.isNotEmpty ? _findPlan(plans, id) : null;
      if (plan != null) {
        if (_membershipStart.text.trim().isEmpty) {
          _membershipStart.text = _defaultStart(today, memberExpiry);
        }
        _amount.text = plan.price.toString();
      } else {
        _membershipStart.clear();
        _amount.clear();
      }
    });
  }

  PaymentCreateInputMethodEnum _methodEnum(String m) => switch (m) {
        'card' => PaymentCreateInputMethodEnum.card,
        'upi' => PaymentCreateInputMethodEnum.upi,
        'bank_transfer' => PaymentCreateInputMethodEnum.bankTransfer,
        'other' => PaymentCreateInputMethodEnum.other,
        _ => PaymentCreateInputMethodEnum.cash,
      };

  Future<void> _submit(
    num amountNum,
    num totalOwed,
    bool blockedNoDues,
    bool hasPlan,
  ) async {
    if (_saving) return;
    if (_memberId == null) {
      showAppSnackBar(context, 'Please select a member', isError: true);
      return;
    }
    if (blockedNoDues) {
      showAppSnackBar(
        context,
        'No outstanding dues. Select a plan to record a payment.',
        isError: true,
      );
      return;
    }
    if (_amount.text.trim().isEmpty ||
        (!hasPlan && amountNum <= 0) ||
        amountNum < 0) {
      showAppSnackBar(context, 'Enter a valid amount', isError: true);
      return;
    }
    if (amountNum > totalOwed) {
      showAppSnackBar(
        context,
        hasPlan
            ? 'Amount exceeds total owed'
            : 'Amount exceeds outstanding dues',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final PaymentCreateInput input = PaymentCreateInput(
        requestId: createRequestId(),
        memberId: _memberId!,
        planId: hasPlan ? _planId : null,
        amount: amountNum,
        method: _methodEnum(_method),
        membershipStart: hasPlan && _membershipStart.text.trim().isNotEmpty
            ? _membershipStart.text.trim()
            : null,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      await postJson<PaymentCreateResponse>(
        dio,
        '/payments',
        data: input.toJson(),
        fromJson: PaymentCreateResponse.fromJson,
      );
      if (mounted) showAppSnackBar(context, 'Payment recorded!');
      invalidateGymScopeFromWidget(ref);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.userMessage, isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to record payment', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    final AsyncValue<PlanListResponse> plansAsync =
        ref.watch(plansProvider(const PlanFilters()));
    final List<PlanListResponsePlansInner> plans =
        plansAsync.value?.plans ?? const <PlanListResponsePlansInner>[];

    final AsyncValue<MemberListResponse>? membersAsync = _deferredSearch.isEmpty
        ? null
        : ref.watch(
            membersProvider(MemberFilters(search: _deferredSearch, limit: 20)),
          );
    final List<MemberResponse> members =
        membersAsync?.value?.members ?? const <MemberResponse>[];

    final AsyncValue<MemberResponse>? lockedAsync =
        _isLocked ? ref.watch(memberProvider(widget.prefillMemberId!)) : null;

    final num memberDue =
        _isLocked ? (lockedAsync?.value?.dueAmount ?? 0) : _selectedDue;
    final String? memberExpiry =
        _isLocked ? lockedAsync?.value?.membershipExpiry : _selectedExpiry;

    final String today = todayDateOnly();
    final PlanListResponsePlansInner? selectedPlan = _findPlan(plans, _planId);
    final num amountNum = num.tryParse(_amount.text.trim()) ?? 0;
    final num planPrice = selectedPlan?.price ?? 0;
    final int durationDays = (selectedPlan?.durationDays ?? 0).toInt();
    final num totalOwed = selectedPlan != null ? planPrice : memberDue;
    final bool hasMember = _memberId != null;
    final bool blockedNoDues =
        hasMember && selectedPlan == null && memberDue <= 0;
    final bool hasPlan = selectedPlan != null;

    final String startText = _membershipStart.text.trim();
    final String? validUntil = (hasPlan && isDateOnly(startText))
        ? addDaysToDateOnly(startText, durationDays - 1)
        : null;

    return BottomSheetForm(
      title: 'Record Payment',
      description:
          'Clear outstanding dues, or select a plan to start / renew a membership.',
      body: <Widget>[
        // ── Member ────────────────────────────────────────────────────────
        _SectionLabel(t, 'Member *'),
        const SizedBox(height: 8),
        if (_isLocked)
          _LockedMember(
            name: widget.prefillMemberName ?? '?',
            tokens: t,
          )
        else if (_memberId != null)
          _SelectedMemberChip(
            name: _memberName ?? '',
            tokens: t,
            onClear: _clearMember,
          )
        else
          _MemberSearch(
            controller: _search,
            tokens: t,
            onChanged: _onSearchChanged,
            members: members,
            currency: widget.currency,
            onSelect: _selectMember,
          ),
        if (hasMember) ...<Widget>[
          const SizedBox(height: 20),
          Divider(height: 1, color: withOpacity(t.border, 0.6)),
          const SizedBox(height: 20),
          // ── Plan (optional) ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: _SectionLabel(t, 'Membership Plan (optional)'),
              ),
              if (selectedPlan != null)
                TextButton(
                  onPressed: () =>
                      _onPlanChanged('', plans, today, memberExpiry),
                  child: Text(
                    'Clear',
                    style: TextStyle(fontSize: 12, color: t.muted.foreground),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            // ValueKey re-syncs the field when "Clear" resets _planId
            // externally (DropdownButtonFormField only reads initialValue once).
            key: ValueKey<String>(_planId),
            initialValue: _planId,
            decoration: _inputDecoration(t, 'Plan'),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem<String>(
                value: '',
                child: Text('No plan — clear dues only'),
              ),
              for (final PlanListResponsePlansInner p in plans)
                DropdownMenuItem<String>(
                  value: p.id,
                  child: Text(
                    '${p.name} — ${formatCurrency(p.price, widget.currency)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (String? v) =>
                _onPlanChanged(v, plans, today, memberExpiry),
          ),
          if (selectedPlan != null) ...<Widget>[
            const SizedBox(height: 16),
            // ── PLAN PATH ───────────────────────────────────────────────
            TextField(
              controller: _membershipStart,
              decoration: _inputDecoration(
                t,
                'Membership Start Date',
                hint: 'YYYY-MM-DD',
              ),
              style: TextStyle(color: t.foreground),
              onChanged: (_) => setState(() {}),
            ),
            if (validUntil != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Active from ${formatDate(startText)} until ${formatDate(validUntil)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: t.success.value,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                t,
                'Amount (${currencySymbol(widget.currency)}) *',
              ),
              style: TextStyle(color: t.foreground),
            ),
            const SizedBox(height: 16),
            PaymentBreakdown(
              items: <PaymentBreakdownItem>[
                PaymentBreakdownItem(label: 'Plan price', value: planPrice),
              ],
              amountPaid: amountNum,
              currency: widget.currency,
            ),
            if (memberDue > 0) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'This member also has ${formatCurrency(memberDue, widget.currency)} in '
                'outstanding dues — record a separate payment (no plan) to clear them.',
                style: TextStyle(fontSize: 12, color: t.warning.value),
              ),
            ],
          ] else ...<Widget>[
            const SizedBox(height: 16),
            // ── NO-PLAN PATH (clear dues) ────────────────────────────────
            if (memberDue > 0) ...<Widget>[
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  t,
                  'Amount (${currencySymbol(widget.currency)}) *',
                ),
                style: TextStyle(color: t.foreground),
              ),
              const SizedBox(height: 16),
              PaymentBreakdown(
                items: <PaymentBreakdownItem>[
                  PaymentBreakdownItem(
                    label: 'Outstanding dues',
                    value: memberDue,
                  ),
                ],
                amountPaid: amountNum,
                currency: widget.currency,
                balanceLabel: 'Remaining due',
                settledLabel: 'Cleared',
              ),
            ] else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  color: withOpacity(t.muted.value, 0.50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: withOpacity(t.border, 0.6)),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      'No outstanding dues',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: t.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a plan above to start or renew a membership.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: t.muted.foreground,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          // ── Method + Notes (hidden when nothing to record) ─────────────
          if (!blockedNoDues) ...<Widget>[
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: _inputDecoration(t, 'Method *'),
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
              onChanged: (String? v) => setState(() => _method = v ?? 'cash'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              decoration:
                  _inputDecoration(t, 'Notes', hint: 'Any additional notes…'),
              style: TextStyle(color: t.foreground),
            ),
          ],
        ],
        const SizedBox(height: 8),
      ],
      footer: _buildFooter(t, hasMember, blockedNoDues, amountNum, totalOwed),
    );
  }

  Widget _buildFooter(
    ThemeTokens t,
    bool hasMember,
    bool blockedNoDues,
    num amountNum,
    num totalOwed,
  ) {
    final bool disabled = _saving || !hasMember || blockedNoDues;
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: t.foreground,
              side: BorderSide(color: t.border),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radius),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: disabled
                ? null
                : () => _submit(
                    amountNum, totalOwed, blockedNoDues, _planId.isNotEmpty),
            style: FilledButton.styleFrom(
              backgroundColor: t.primary.value,
              foregroundColor: t.primary.foreground,
              disabledBackgroundColor: withOpacity(t.primary.value, 0.5),
              disabledForegroundColor: t.primary.foreground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radius),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
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
                : const Text('Record Payment'),
          ),
        ),
      ],
    );
  }
}

// -- small presentational helpers -------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.t, this.text);

  final ThemeTokens t;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: t.foreground,
      ),
    );
  }
}

class _LockedMember extends StatelessWidget {
  const _LockedMember({required this.name, required this.tokens});

  final String name;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: withOpacity(tokens.muted.value, 0.50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: withOpacity(tokens.border, 0.7)),
      ),
      child: Row(
        children: <Widget>[
          Avatar(name: name, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: tokens.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedMemberChip extends StatelessWidget {
  const _SelectedMemberChip({
    required this.name,
    required this.tokens,
    required this.onClear,
  });

  final String name;
  final ThemeTokens tokens;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: withOpacity(tokens.primary.value, 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: withOpacity(tokens.primary.value, 0.30)),
      ),
      child: Row(
        children: <Widget>[
          Avatar(name: name, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: tokens.foreground,
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Change',
              style: TextStyle(fontSize: 12, color: tokens.muted.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberSearch extends StatelessWidget {
  const _MemberSearch({
    required this.controller,
    required this.tokens,
    required this.onChanged,
    required this.members,
    required this.currency,
    required this.onSelect,
  });

  final TextEditingController controller;
  final ThemeTokens tokens;
  final ValueChanged<String> onChanged;
  final List<MemberResponse> members;
  final String currency;
  final ValueChanged<MemberResponse> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search members…',
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: tokens.muted.foreground,
            ),
            filled: true,
            fillColor: tokens.card.value,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            hintStyle: TextStyle(color: tokens.muted.foreground),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radius),
              borderSide: BorderSide(color: withOpacity(tokens.border, 0.7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radius),
              borderSide: BorderSide(color: withOpacity(tokens.border, 0.7)),
            ),
          ),
          style: TextStyle(color: tokens.foreground),
        ),
        if (controller.text.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No members found',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: tokens.muted.foreground),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: withOpacity(tokens.border, 0.7)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  for (final MemberResponse m in members)
                    _MemberResultTile(
                      member: m,
                      tokens: tokens,
                      currency: currency,
                      onTap: () => onSelect(m),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _MemberResultTile extends StatelessWidget {
  const _MemberResultTile({
    required this.member,
    required this.tokens,
    required this.currency,
    required this.onTap,
  });

  final MemberResponse member;
  final ThemeTokens tokens;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Avatar(name: member.name, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: tokens.foreground,
                    ),
                  ),
                  if (member.phone.isNotEmpty)
                    Text(
                      member.phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.muted.foreground,
                      ),
                    ),
                ],
              ),
            ),
            if (member.dueAmount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: withOpacity(tokens.warning.value, 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${formatCurrency(member.dueAmount, currency)} due',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tokens.warning.foreground,
                  ),
                ),
              ),
          ],
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
