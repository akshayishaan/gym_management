// Phase 7 — Receipt / invoice detail. Mirrors the Figma `invoice_receipt.png`:
// back arrow + "Receipt #INV-XXXX", status pill row (PAID + SETTLED + segmented
// Paid/Void/Refund), member + invoice side-by-side cards, itemized charges
// card with breakdown, and Download PDF / Print Receipt actions.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_loading.dart';
import '../../../design/components/lato_status_chip.dart';
import '../../../design/spacing.dart';
import '../application/payment_controller.dart';
import '../data/payment_repository.dart';
import '../domain/payment.dart';

class PaymentInvoiceScreen extends ConsumerStatefulWidget {
  const PaymentInvoiceScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<PaymentInvoiceScreen> createState() =>
      _PaymentInvoiceScreenState();
}

class _PaymentInvoiceScreenState extends ConsumerState<PaymentInvoiceScreen> {
  /// Bound to the segmented control in the status header card. Kept
  /// local because the screen is read-only — there's no need to push it
  /// into a provider.
  _Action _selectedAction = _Action.paid;

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
    final asyncPayment = ref.watch(paymentDetailProvider(widget.id));
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: asyncPayment.maybeWhen(
          data: (p) => Text('Receipt #${p.invoiceNumber}'),
          orElse: () => const Text('Receipt'),
        ),
      ),
      body: asyncPayment.when(
        loading: () => const LatoLoading(),
        error: (err, _) => LatoErrorState(
          message: err is ApiException
              ? err.message
              : 'Could not load receipt.',
          onRetry: () => ref.invalidate(paymentDetailProvider(widget.id)),
        ),
        data: (payment) {
          return _InvoiceBody(
            payment: payment,
            selectedAction: _selectedAction,
            onActionChanged: (a) {
              setState(() => _selectedAction = a);
              if (a == _Action.markVoid) _confirmAndVoid(payment);
              if (a == _Action.refunded) _confirmAndRefund(payment);
            },
          );
        },
      ),
    );
  }
}

enum _Action { paid, markVoid, refunded }

class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({
    required this.payment,
    required this.selectedAction,
    required this.onActionChanged,
  });

  final Payment payment;
  final _Action selectedAction;
  final ValueChanged<_Action> onActionChanged;

  @override
  Widget build(BuildContext context) {
    final timestamp = payment.paidAt ?? payment.createdAt;
    final settledLabel = timestamp != null
        ? 'Settled on ${DateFormat.yMMMd().add_jm().format(timestamp.toLocal())}'
        : 'Settled date unknown';
    final billingPeriod =
        timestamp != null ? _billingPeriodLabel(timestamp.toLocal()) : '—';

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            LatoSpacing.xl,
            LatoSpacing.lg,
            LatoSpacing.xl,
            LatoSpacing.md,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _StatusHeaderCard(
                payment: payment,
                selectedAction: selectedAction,
                onActionChanged: onActionChanged,
              ),
              const SizedBox(height: LatoSpacing.md),
              _TotalCard(
                payment: payment,
                settledLabel: settledLabel,
              ),
              const SizedBox(height: LatoSpacing.md),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _MemberCard(payment: payment),
                    ),
                    const SizedBox(width: LatoSpacing.md),
                    Expanded(
                      child: _InvoiceCodeCard(
                        payment: payment,
                        billingPeriod: billingPeriod,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LatoSpacing.md),
              _ItemizedCard(payment: payment),
              const SizedBox(height: LatoSpacing.lg),
              _BottomActions(payment: payment),
              const SizedBox(height: LatoSpacing.xxl),
            ]),
          ),
        ),
      ],
    );
  }

  /// "Oct 28 - Nov 28, 2024" — first day of paidAt's month through the
  /// same day next month (covers the typical monthly membership span the
  /// design renders).
  static String _billingPeriodLabel(DateTime paid) {
    final fmt = DateFormat('MMM d');
    final next = DateTime(paid.year, paid.month + 1, paid.day);
    return '${fmt.format(paid)} - ${fmt.format(next)}, ${paid.year}';
  }
}

class _StatusHeaderCard extends StatelessWidget {
  const _StatusHeaderCard({
    required this.payment,
    required this.selectedAction,
    required this.onActionChanged,
  });

  final Payment payment;
  final _Action selectedAction;
  final ValueChanged<_Action> onActionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paidTone = payment.status == 'paid'
        ? LatoChipTone.primary
        : LatoChipTone.neutral;
    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: status pills (PAID + SETTLED)
          Row(
            children: [
              const _LimeDot(),
              const SizedBox(width: 6),
              LatoStatusChip(label: 'PAID', tone: paidTone),
              const SizedBox(width: LatoSpacing.sm),
              const LatoStatusChip(
                label: 'SETTLED',
                tone: LatoChipTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: LatoSpacing.md),
          // Row 2: segmented Paid / Void / Refund
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: _Action.values.map((a) {
                final isSel = a == selectedAction;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onActionChanged(a),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? LatoColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _actionLabel(a),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isSel
                              ? LatoColors.bgDark
                              : LatoColors.textSecondaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static String _actionLabel(_Action a) {
    switch (a) {
      case _Action.paid:
        return 'Paid';
      case _Action.markVoid:
        return 'Void';
      case _Action.refunded:
        return 'Refund';
    }
  }
}

/// Small lime dot used as the leading bullet on the PAID pill row.
class _LimeDot extends StatelessWidget {
  const _LimeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: LatoColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.payment,
    required this.settledLabel,
  });

  final Payment payment;
  final String settledLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final whole = payment.amount.truncate();
    final cents =
        ((payment.amount - whole).abs() * 100).round().toString().padLeft(2, '0');
    final wholeFmt = NumberFormat.decimalPattern().format(whole);

    return LatoCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL AMOUNT CAPTURED',
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
                padding: const EdgeInsets.only(top: 8, left: 6),
                child: Text(
                  '.$cents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'USD',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: LatoColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LatoSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 16,
                color: LatoColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  settledLabel,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Only a real, staff-entered reference is shown here — cash
          // payments (and any payment recorded without one) have no
          // transaction reference, so there is nothing honest to display.
          if (payment.reference != null && payment.reference!.isNotEmpty) ...[
            const SizedBox(height: LatoSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'REF: ${payment.reference}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: LatoColors.textSecondaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: payment.reference!),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('REF copied')),
                    );
                  },
                  icon: const Icon(Icons.content_copy, size: 14),
                  label: const Text(
                    'Copy',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: LatoColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: LatoSpacing.sm,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memShort = payment.memberId.length >= 4
        ? payment.memberId.substring(payment.memberId.length - 4)
        : payment.memberId;
    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MEMBER ACCOUNT',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: LatoSpacing.sm),
          Text(
            payment.memberName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: LatoSpacing.md),
          Wrap(
            spacing: LatoSpacing.sm,
            runSpacing: LatoSpacing.xs,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LatoSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: LatoColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#MEM-$memShort',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: LatoColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Real plan name (when this payment is a plan purchase) —
              // was a hardcoded 'TIER 1' chip with no backing concept.
              if (payment.planName != null && payment.planName!.isNotEmpty)
                LatoStatusChip(
                  label: payment.planName!,
                  tone: LatoChipTone.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceCodeCard extends StatelessWidget {
  const _InvoiceCodeCard({
    required this.payment,
    required this.billingPeriod,
  });
  final Payment payment;
  final String billingPeriod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inv = payment.invoiceNumber.isEmpty ? '—' : payment.invoiceNumber;
    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INVOICE CODE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: LatoSpacing.sm),
          Text(
            inv.startsWith('INV-') ? '#$inv' : '#INV-$inv',
            style: theme.textTheme.titleMedium?.copyWith(
              color: LatoColors.primary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: LatoSpacing.md),
          Text(
            'BILLING PERIOD',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: LatoSpacing.xs),
          Text(
            billingPeriod,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly label for a plan's billing cycle from its real `durationDays`
/// snapshot. Falls back to "N days" for anything that isn't one of the
/// common buckets rather than guessing.
String _cycleLabel(int durationDays) {
  switch (durationDays) {
    case 1:
      return 'Daily';
    case 7:
      return 'Weekly';
    case 30:
    case 31:
      return 'Monthly';
    case 90:
    case 91:
      return 'Quarterly';
    case 365:
    case 366:
      return 'Annual';
    default:
      return '$durationDays days';
  }
}

class _ItemizedCard extends StatelessWidget {
  const _ItemizedCard({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planName = (payment.planName == null || payment.planName!.isEmpty)
        ? 'Membership Payment'
        : payment.planName!;
    // Prefer the real snapshot of what the plan actually included at
    // purchase time; fall back to the staff's own notes; show nothing
    // invented when neither exists (e.g. a dues payment, or a payment
    // recorded before planFeatures existed).
    final features = payment.planFeatures ?? const <String>[];
    final description = features.isNotEmpty
        ? features.join(' • ')
        : (payment.notes != null && payment.notes!.isNotEmpty)
            ? payment.notes!
            : null;
    final amount = payment.amount;

    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Itemized Charges',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '1 item',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: LatoSpacing.md),
          // Line item
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  planName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: LatoSpacing.md),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: LatoSpacing.xs),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: LatoSpacing.sm),
          Wrap(
            spacing: LatoSpacing.sm,
            runSpacing: LatoSpacing.xs,
            children: [
              // Real snapshot of the plan's duration at purchase time —
              // was a hardcoded 'Cycle: Monthly' shown regardless of the
              // plan's actual billing cycle.
              if (payment.planDurationDays != null)
                LatoStatusChip(
                  label: 'Cycle: ${_cycleLabel(payment.planDurationDays!)}',
                  tone: LatoChipTone.neutral,
                ),
              const LatoStatusChip(
                label: 'Qty: 1',
                tone: LatoChipTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: LatoSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: LatoSpacing.md),
          // Breakdown
          _BreakdownRow(
            label: 'Subtotal',
            value: '\$${amount.toStringAsFixed(2)}',
          ),
          const SizedBox(height: LatoSpacing.sm),
          _BreakdownRow(
            label: 'Tax / VAT (0.0%)',
            value: '\$0.00',
          ),
          const SizedBox(height: LatoSpacing.sm),
          _BreakdownRow(
            label: 'Processing Fees',
            value: 'Waived (\$0.00)',
            valueColor: LatoColors.primary,
          ),
          const SizedBox(height: LatoSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: LatoSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Net Paid Amount',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: LatoColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: LatoColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'USD Currency',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final status = payment.status;
    if (status == 'voided') {
      final d = _formatDate(payment.voidedAt);
      return _StatusFooterChip(
        icon: Icons.block_outlined,
        label: 'Voided on ${d ?? '—'}',
        tint: LatoColors.error,
      );
    }
    if (status == 'refunded') {
      final d = _formatDate(payment.refundedAt);
      return _StatusFooterChip(
        icon: Icons.replay_outlined,
        label: 'Refunded on ${d ?? '—'}',
        tint: LatoColors.info,
      );
    }
    // 'paid' (default) — show the Download / Print CTAs.
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF export coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.download_outlined),
            label: const Text(
              'Download PDF Receipt',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: LatoColors.primary,
              foregroundColor: LatoColors.bgDark,
            ),
          ),
        ),
        const SizedBox(height: LatoSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Print handoff coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.print_outlined),
            label: const Text(
              'Print Receipt',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: LatoColors.borderDark),
              foregroundColor: LatoColors.textPrimaryDark,
            ),
          ),
        ),
      ],
    );
  }

  static String? _formatDate(DateTime? raw) {
    if (raw == null) return null;
    return DateFormat.yMMMd().format(raw.toLocal());
  }
}

class _StatusFooterChip extends StatelessWidget {
  const _StatusFooterChip({
    required this.icon,
    required this.label,
    required this.tint,
  });
  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LatoSpacing.md,
        vertical: LatoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: tint,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}