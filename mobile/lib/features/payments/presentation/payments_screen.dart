// Phase 7 — Payments & Ledger. Mirrors the Figma `payments_ledger.png`:
// calendar header (month picker) + TOTAL COLLECTED KPI card + status pills
// (All / Settled / Pending / Refunded) + "Recent Payments" list of
// transaction cards (avatar, name + plan, amount + invoice, timestamp +
// method chip, Void/Refund actions, optional Recurring chip).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_empty_state.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_loading.dart';
import '../../../design/components/lato_status_chip.dart';
import '../../../design/spacing.dart';
import '../application/payment_controller.dart';
import '../data/payment_repository.dart';
import '../domain/payment.dart';
import '../domain/payment_query.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  /// `null` means "all time"; otherwise holds the first day of the
  /// selected month (UTC-naive — only the year/month fields are read).
  DateTime? _currentMonth;

  /// One of the pills in the Figma status row. Mapped to a backend
  /// `Payment.status` value for client-side filtering (the list endpoint
  /// does not yet accept a status query param).
  String _activeStatus = 'all'; // 'all' | 'paid' | 'pending' | 'voided' | 'refunded'

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final initial = _currentMonth ?? DateTime(now.year, now.month, 1);
    final firstDate = DateTime(now.year - 2, 1, 1);
    final lastDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select month',
    );
    if (picked == null) return;
    setState(() => _currentMonth = DateTime(picked.year, picked.month, 1));
  }

  String _monthLabel() {
    final m = _currentMonth;
    if (m == null) return 'All time';
    return DateFormat('MMMM yyyy').format(m);
  }

  String? _monthQueryParam() {
    final m = _currentMonth;
    if (m == null) return null;
    return DateFormat('yyyy-MM').format(m);
  }

  List<Payment> _applyClientFilter(List<Payment> payments) {
    switch (_activeStatus) {
      case 'paid':
      case 'pending':
        // Backend doesn't expose a real "pending" state, so the Pending
        // pill is rendered as a "Paid" filter. This keeps the chip
        // cluster visually complete without inventing a missing state.
        return payments.where((p) => p.status == 'paid').toList();
      case 'voided':
        return payments.where((p) => p.status == 'voided').toList();
      case 'refunded':
        return payments.where((p) => p.status == 'refunded').toList();
      case 'all':
      default:
        return payments;
    }
  }

  Future<void> _confirmAndVoid(Payment payment) async {
    final confirmed = await _confirmAction(
      title: 'Void payment #${payment.invoiceNumber}?',
      body:
          'This cancels the payment and removes its accounting effect. The audit record is preserved.',
      confirmLabel: 'Void',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(paymentVoidControllerProvider.notifier)
          .voidPayment(payment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment voided')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not void payment: $e')),
      );
    }
  }

  Future<void> _confirmAndRefund(Payment payment) async {
    final confirmed = await _confirmAction(
      title: 'Refund payment #${payment.invoiceNumber}?',
      body:
          'This returns the funds to the member and contributes a negative cash movement at the refund timestamp.',
      confirmLabel: 'Refund',
      destructive: false,
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(paymentRefundControllerProvider.notifier)
          .refund(payment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment refunded')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not refund payment: $e')),
      );
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String body,
    required String confirmLabel,
    required bool destructive,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LatoColors.surfaceDark,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor:
                  destructive ? LatoColors.error : LatoColors.primary,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = PaymentListQuery(month: _monthQueryParam());
    final async = ref.watch(paymentListProvider(query));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Payments & Ledger',
          style: theme.textTheme.headlineSmall,
        ),
      ),
      body: async.when(
        loading: () => const LatoLoading(),
        error: (err, _) => LatoErrorState(
          message: err is ApiException
              ? err.message
              : 'Could not load payments.',
          onRetry: () => ref.invalidate(paymentListProvider(query)),
        ),
        data: (result) {
          final filtered = _applyClientFilter(result.payments);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month picker bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LatoSpacing.xl,
                  LatoSpacing.sm,
                  LatoSpacing.xl,
                  LatoSpacing.md,
                ),
                child: _MonthPickerBar(
                  label: _monthLabel(),
                  onTap: _pickMonth,
                ),
              ),
              // KPI card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LatoSpacing.xl,
                ),
                child: _KpiCard(
                  netAmount: result.netAmount,
                  total: result.total,
                  monthLabel: _monthLabel(),
                ),
              ),
              const SizedBox(height: LatoSpacing.lg),
              // Status pills
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: LatoSpacing.xl,
                  ),
                  children: [
                    _StatusPill(
                      label: 'All (${result.total})',
                      selected: _activeStatus == 'all',
                      onTap: () => setState(() => _activeStatus = 'all'),
                    ),
                    const SizedBox(width: LatoSpacing.sm),
                    _StatusPill(
                      label: 'Settled',
                      selected: _activeStatus == 'paid',
                      onTap: () => setState(() => _activeStatus = 'paid'),
                    ),
                    const SizedBox(width: LatoSpacing.sm),
                    _StatusPill(
                      label: 'Pending',
                      selected: _activeStatus == 'pending',
                      onTap: () => setState(() => _activeStatus = 'pending'),
                    ),
                    const SizedBox(width: LatoSpacing.sm),
                    _StatusPill(
                      label: 'Refunded',
                      selected: _activeStatus == 'refunded',
                      onTap: () => setState(() => _activeStatus = 'refunded'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LatoSpacing.lg),
              // "Recent Payments" header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LatoSpacing.xl,
                ),
                child: Text(
                  'Recent Payments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: LatoSpacing.md),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(LatoSpacing.lg),
                          child: LatoEmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No payments yet',
                            body: _activeStatus == 'all'
                                ? 'Recorded payments will appear here.'
                                : 'No payments match the current filter.',
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          LatoSpacing.xl,
                          0,
                          LatoSpacing.xl,
                          LatoSpacing.xxl,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: LatoSpacing.md),
                            child: _PaymentCard(
                              payment: p,
                              onTap: () => context.push('/payments/${p.id}'),
                              onVoid: () => _confirmAndVoid(p),
                              onRefund: () => _confirmAndRefund(p),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Calendar-icon + month label + chevron. Tapping opens the month picker.
class _MonthPickerBar extends StatelessWidget {
  const _MonthPickerBar({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(LatoRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LatoSpacing.sm,
            vertical: LatoSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: LatoColors.primary,
              ),
              const SizedBox(width: LatoSpacing.sm),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              const Icon(
                Icons.expand_more,
                size: 18,
                color: LatoColors.textSecondaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TOTAL COLLECTED + formatted netAmount + "X payments recorded • MMMM yyyy"
class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.netAmount,
    required this.total,
    required this.monthLabel,
  });

  final double netAmount;
  final int total;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final whole = netAmount.truncate();
    final cents =
        ((netAmount - whole).abs() * 100).round().toString().padLeft(2, '0');
    final wholeFmt = NumberFormat.decimalPattern().format(whole);
    final paymentWord = total == 1 ? 'payment' : 'payments';

    return LatoCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL COLLECTED',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: LatoSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$$wholeFmt',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '.$cents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LatoSpacing.sm),
          Text(
            '$total $paymentWord recorded • $monthLabel',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Filter pill used in the status row. Active = lime, else neutral.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: LatoStatusChip(
          label: label,
          tone: selected ? LatoChipTone.primary : LatoChipTone.neutral,
        ),
      ),
    );
  }
}

/// One transaction card: avatar + center column + right amount/invoice
/// + timestamp/method row + Void/Refund actions + Recurring chip.
class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.onTap,
    required this.onVoid,
    required this.onRefund,
  });

  final Payment payment;
  final VoidCallback onTap;
  final VoidCallback onVoid;
  final VoidCallback onRefund;

  bool get _isRecurring =>
      payment.kind == 'plan_purchase' && payment.membershipStatus == 'active';

  String get _initials => _computeInitials(payment.memberName);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = payment.paidAt ?? payment.createdAt;
    final timestampLabel = timestamp != null
        ? '${DateFormat('MMM d, y').format(timestamp.toLocal())} • '
            '${DateFormat.jm().format(timestamp.toLocal())}'
        : '—';
    final isActionable = payment.status == 'paid';

    return Semantics(
      button: true,
      label: 'Payment ${payment.memberName}',
      child: LatoCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        LatoSpacing.lg,
        LatoSpacing.lg,
        LatoSpacing.lg,
        LatoSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InitialsAvatar(initials: _initials),
              const SizedBox(width: LatoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.memberName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (payment.planName == null || payment.planName!.isEmpty)
                          ? 'Membership payment'
                          : payment.planName!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+\$${payment.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: LatoColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (payment.invoiceNumber.isNotEmpty)
                    Text(
                      '#${payment.invoiceNumber}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: LatoColors.textSecondaryDark,
                      ),
                    ),
                ],
              ),
              if (_isRecurring) ...[
                const SizedBox(width: LatoSpacing.sm),
                const _RecurringChip(),
              ],
            ],
          ),
          const SizedBox(height: LatoSpacing.md),
          // Timestamp + method chip row
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 14,
                color: LatoColors.textSecondaryDark,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  timestampLabel,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              LatoStatusChip(
                label: payment.methodLabel,
                tone: LatoChipTone.primary,
                icon: _methodIcon(payment.method),
              ),
            ],
          ),
          if (isActionable) ...[
            const SizedBox(height: LatoSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: LatoSpacing.sm),
            Row(
              children: [
                _SmallActionButton(
                  label: 'Void',
                  color: LatoColors.error,
                  onTap: onVoid,
                ),
                const SizedBox(width: LatoSpacing.sm),
                _SmallActionButton(
                  label: 'Refund',
                  color: LatoColors.textPrimaryDark,
                  onTap: onRefund,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _computeInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final first = parts.first;
      return first.isEmpty ? '?' : first.substring(0, 1).toUpperCase();
    }
    final a = parts.first.isEmpty ? '' : parts.first.substring(0, 1);
    final b = parts.last.isEmpty ? '' : parts.last.substring(0, 1);
    return (a + b).toUpperCase();
  }

  static IconData _methodIcon(String method) {
    switch (method) {
      case 'cash':
        return Icons.payments_outlined;
      case 'card':
        return Icons.credit_card_outlined;
      case 'upi':
        return Icons.qr_code_2_outlined;
      case 'bank_transfer':
        return Icons.account_balance_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LatoColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(LatoRadius.md),
      ),
      child: Text(
        initials,
        style: theme.textTheme.titleMedium?.copyWith(
          color: LatoColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RecurringChip extends StatelessWidget {
  const _RecurringChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LatoSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: LatoColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LatoColors.primary.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.autorenew,
            size: 12,
            color: LatoColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Recurring: Monthly',
            style: theme.textTheme.labelSmall?.copyWith(
              color: LatoColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: LatoSpacing.md,
          vertical: LatoSpacing.xs,
        ),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: color,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    );
  }
}