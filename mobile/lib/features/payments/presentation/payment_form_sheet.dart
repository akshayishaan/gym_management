import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
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
  final _notesCtrl = TextEditingController();

  String? _selectedMemberId;
  String? _selectedMemberName;
  String? _selectedPlanId;
  String? _selectedPlanName;
  String _method = 'cash';

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    if (m != null) {
      _selectedMemberId = m.id;
      _selectedMemberName = m.name;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Loads the full member list (gym-scoped via the active-gym provider)
  /// and presents it as a `ListTile` picker.
  Future<void> _pickMember() async {
    List<Member> members = const [];
    String? errorMessage;
    try {
      final result = await ref.read(memberListProvider(
        const MemberListQuery(limit: 100),
      ).future);
      members = result.members;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Could not load members';
    }

    if (!mounted) return;

    final selected = await showModalBottomSheet<Member>(
      context: context,
      backgroundColor: LatoColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LatoRadius.xl)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LatoSpacing.xl,
                  LatoSpacing.md,
                  LatoSpacing.xl,
                  LatoSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Member',
                        style: Theme.of(sheetCtx).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: LatoColors.textSecondaryDark,
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: errorMessage != null && members.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(LatoSpacing.lg),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: LatoColors.error),
                        ),
                      )
                    : members.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(LatoSpacing.lg),
                            child: Text(
                              'No members yet',
                              style: Theme.of(sheetCtx).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: members.length,
                            itemBuilder: (_, i) {
                              final m = members[i];
                              final subtitleParts = <String>[
                                if (m.phone.isNotEmpty) m.phone,
                                if (m.planName != null && m.planName!.isNotEmpty)
                                  m.planName!,
                              ];
                              return ListTile(
                                title: Text(m.name),
                                subtitle: subtitleParts.isEmpty
                                    ? null
                                    : Text(
                                        subtitleParts.join(' · '),
                                        style: Theme.of(sheetCtx)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                trailing: m.dueAmount > 0
                                    ? Text(
                                        '₹${_formatAmount(m.dueAmount)}',
                                        style: const TextStyle(
                                          color: LatoColors.warning,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                                onTap: () => Navigator.of(sheetCtx).pop(m),
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
        _selectedMemberId = selected.id;
        _selectedMemberName = selected.name;
        // Reset plan when the member changes — the previous plan price
        // doesn't carry over to a different member.
        _selectedPlanId = null;
        _selectedPlanName = null;
        _amountCtrl.clear();
      });
    }
  }

  /// Loads the plan list and presents a picker whose first option is
  /// "Dues payment (no plan)" — selecting it clears the plan and the
  /// pre-fill.
  Future<void> _pickPlan() async {
    List<Plan> plans = const [];
    String? errorMessage;
    try {
      final result = await ref.read(planListProvider(
        const PlanListQuery(limit: 100),
      ).future);
      plans = result.plans;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Could not load plans';
    }

    if (!mounted) return;

    final selected = await showModalBottomSheet<_PlanChoice>(
      context: context,
      backgroundColor: LatoColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LatoRadius.xl)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LatoSpacing.xl,
                  LatoSpacing.md,
                  LatoSpacing.xl,
                  LatoSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Plan',
                        style: Theme.of(sheetCtx).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: LatoColors.textSecondaryDark,
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Dues payment (no plan)'),
                subtitle: const Text(
                  'Settle the member\'s outstanding balance',
                ),
                onTap: () => Navigator.of(sheetCtx).pop(const _PlanChoice.dues()),
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
                            title: Text(p.name),
                            subtitle: Text(
                              '${p.durationDays}d · ${p.formattedPrice}',
                              style:
                                  Theme.of(sheetCtx).textTheme.bodySmall,
                            ),
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
        if (selected.plan != null) {
          _selectedPlanId = selected.plan!.id;
          _selectedPlanName = selected.plan!.name;
          // Pre-fill the amount with the plan price (editable).
          _amountCtrl.text = selected.plan!.price.toStringAsFixed(2);
        } else {
          _selectedPlanId = null;
          _selectedPlanName = null;
          _amountCtrl.clear();
        }
      });
    }
  }

  Future<void> _pickMethod() async {
    const options = <(String value, String label)>[
      ('cash', 'Cash'),
      ('card', 'Card'),
      ('upi', 'UPI'),
      ('bank_transfer', 'Bank Transfer'),
      ('other', 'Other'),
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: LatoColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LatoRadius.xl)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LatoSpacing.xl,
                  LatoSpacing.md,
                  LatoSpacing.xl,
                  LatoSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Payment Method',
                        style: Theme.of(sheetCtx).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: LatoColors.textSecondaryDark,
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (final (value, label) in options)
                ListTile(
                  title: Text(label),
                  trailing: _method == value
                      ? const Icon(Icons.check, color: LatoColors.primary)
                      : null,
                  onTap: () => Navigator.of(sheetCtx).pop(value),
                ),
              const SizedBox(height: LatoSpacing.md),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _method = selected);
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      final payment = await ref
          .read(paymentRecordControllerProvider.notifier)
          .record(PaymentCreateInput(
            memberId: _selectedMemberId!,
            amount: amount,
            method: _method,
            planId: _selectedPlanId,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          ));
      if (!mounted) return;
      Navigator.of(context).pop();
      final invoice = payment.invoiceNumber;
      final snack = invoice.isEmpty ? 'Payment recorded' : 'Payment recorded: $invoice';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snack)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not record payment: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _methodLabel(String value) {
    switch (value) {
      case 'card':
        return 'Card';
      case 'upi':
        return 'UPI';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'other':
        return 'Other';
      case 'cash':
      default:
        return 'Cash';
    }
  }

  static String _formatAmount(double v) {
    final whole = v.toInt();
    final hasCents = (v - whole).abs() > 0.005;
    return hasCents ? v.toStringAsFixed(2) : whole.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = widget.member;
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
                      'Record Payment',
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
                      const _SectionLabel('PAYMENT DETAILS'),
                      const SizedBox(height: LatoSpacing.md),
                      // Member picker (only when not pre-selected)
                      if (member == null) ...[
                        const _RequiredLabel(text: 'Member'),
                        const SizedBox(height: LatoSpacing.sm),
                        _PickerField(
                          hint: 'Select member',
                          value: _selectedMemberName,
                          icon: Icons.person_outline,
                          onTap: _pickMember,
                        ),
                        const SizedBox(height: LatoSpacing.lg),
                      ] else ...[
                        _FieldLabel(text: 'Member'),
                        const SizedBox(height: LatoSpacing.sm),
                        LatoCard(
                          padding: const EdgeInsets.all(LatoSpacing.md),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: LatoColors.primary,
                                  borderRadius:
                                      BorderRadius.circular(LatoRadius.md),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  member.initials,
                                  style: const TextStyle(
                                    color: LatoColors.bgDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: LatoSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        if (member.planName != null &&
                                            member.planName!.isNotEmpty)
                                          member.planName!,
                                        if (member.phone.isNotEmpty)
                                          member.phone,
                                      ].join(' · '),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (member.dueAmount > 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Due',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    Text(
                                      '₹${_formatAmount(member.dueAmount)}',
                                      style: const TextStyle(
                                        color: LatoColors.warning,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: LatoSpacing.lg),
                      ],
                      // Plan picker (only when a member is selected)
                      if (_selectedMemberId != null) ...[
                        const _FieldLabel(text: 'Plan (Optional)'),
                        const SizedBox(height: LatoSpacing.sm),
                        _PickerField(
                          hint: 'Dues payment (no plan)',
                          value: _selectedPlanName,
                          icon: Icons.card_membership_outlined,
                          onTap: _pickPlan,
                        ),
                        const SizedBox(height: LatoSpacing.lg),
                      ],
                      // Amount
                      _RequiredLabel(text: 'Amount (\$)'),
                      const SizedBox(height: LatoSpacing.sm),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          hintText: '99.00',
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Amount is required';
                          final n = double.tryParse(value);
                          if (n == null) return 'Enter a valid amount';
                          if (n <= 0) return 'Amount must be greater than 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: LatoSpacing.lg),
                      // Payment method
                      const _RequiredLabel(text: 'Payment Method'),
                      const SizedBox(height: LatoSpacing.sm),
                      _PickerField(
                        hint: 'Select method',
                        value: _methodLabel(_method),
                        icon: Icons.payments_outlined,
                        onTap: _pickMethod,
                      ),
                      const SizedBox(height: LatoSpacing.lg),
                      // Notes
                      _FieldLabel(text: 'Notes'),
                      const SizedBox(height: LatoSpacing.sm),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Optional context for this payment',
                        ),
                      ),
                      const SizedBox(height: LatoSpacing.huge),
                      LatoPrimaryButton(
                        label: 'RECORD PAYMENT',
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

/// Discriminated result returned from the plan picker bottom sheet —
/// either the user wants to record a plan purchase (carries the chosen
/// `Plan`) or a dues-only payment (no plan).
class _PlanChoice {
  const _PlanChoice.plan(Plan this.plan) : isDues = false;
  const _PlanChoice.dues()
      : plan = null,
        isDues = true;

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
        decoration: InputDecoration(
          hintText: value == null ? hint : null,
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
        ),
        child: Row(
          children: [
            if (value != null)
              Expanded(
                child: Text(
                  value!,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Spacer(),
            const Icon(
              Icons.expand_more,
              size: 18,
              color: LatoColors.textSecondaryDark,
            ),
          ],
        ),
      ),
    );
  }
}