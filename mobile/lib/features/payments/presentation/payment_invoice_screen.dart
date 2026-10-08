// Receipt / invoice detail: status chip with Void / Refund actions, amount
// card, member + invoice cards, charges card, and Share / Print actions.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/money.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_compact_action_button.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_skeleton.dart';
import '../../../design/components/lato_status_chip.dart';
import '../../../design/spacing.dart';
import '../../gym/application/active_gym_controller.dart';
import '../application/payment_controller.dart';
import '../application/receipt_pdf.dart';
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
  bool _busy = false;

  /// Builds the receipt PDF and hands it to [action] (share sheet or print).
  Future<void> _withPdf(
    Payment payment,
    Future<void> Function(Uint8List bytes, String filename) action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      String? gymName;
      try {
        gymName = (await ref.read(activeGymProvider.future))?.name;
      } catch (_) {}
      final bytes = await buildReceiptPdf(payment: payment, gymName: gymName);
      await action(bytes, 'Receipt-${payment.invoiceNumber}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create the receipt PDF')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndVoid(Payment payment) async {
    final confirmed = await _confirmAction(
      title: 'Void payment #${payment.invoiceNumber}?',
      body: 'This cancels the payment and removes its accounting effect. The audit record is preserved.',
      confirmLabel: 'Void',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(paymentVoidControllerProvider.notifier)
          .voidPayment(payment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment voided')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not void payment: $e')));
    }
  }

  Future<void> _confirmAndRefund(Payment payment) async {
    final confirmed = await _confirmAction(
      title: 'Refund payment #${payment.invoiceNumber}?',
      body: 'This returns the funds to the member and contributes a negative cash movement at the refund timestamp.',
      confirmLabel: 'Refund',
      destructive: false,
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(paymentRefundControllerProvider.notifier)
          .refund(payment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment refunded')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not refund payment: $e')));
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
              foregroundColor: destructive
                  ? LatoColors.error
                  : LatoColors.primary,
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
        loading: () => const _InvoiceSkeleton(),
        error: (err, _) => LatoErrorState(
          message: err is ApiException
              ? err.message
              : 'Could not load receipt.',
          onRetry: () => ref.invalidate(paymentDetailProvider(widget.id)),
        ),
        data: (payment) {
          return _InvoiceBody(
            payment: payment,
            busy: _busy,
            onVoid: () => _confirmAndVoid(payment),
            onRefund: () => _confirmAndRefund(payment),
            onShare: () => _withPdf(
              payment,
              (bytes, name) => Printing.sharePdf(bytes: bytes, filename: name),
            ),
            onPrint: () => _withPdf(
              payment,
              (bytes, name) =>
                  Printing.layoutPdf(onLayout: (_) => bytes, name: name),
            ),
          );
        },
      ),
    );
  }
}

final _dateFmt = DateFormat('d MMM y');

String _dateTime(DateTime t) =>
    '${_dateFmt.format(t.toLocal())} • ${DateFormat.jm().format(t.toLocal())}';

/// Placeholder for [_InvoiceBody]: status card, total, member + invoice-code
/// cards, itemized card and the bottom actions.
class _InvoiceSkeleton extends StatelessWidget {
  const _InvoiceSkeleton();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ListView(
        key: const Key('invoice-skeleton'),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          LatoSpacing.xl,
          LatoSpacing.lg,
          LatoSpacing.xl,
          LatoSpacing.xxl,
        ),
        children: const [
          LatoSkeletonBlock(height: 108, radius: LatoRadius.lg),
          SizedBox(height: LatoSpacing.md),
          LatoSkeletonBlock(height: 120, radius: LatoRadius.lg),
          SizedBox(height: LatoSpacing.md),
          Row(
            children: [
              Expanded(child: LatoSkeletonBlock(height: 96, radius: LatoRadius.lg)),
              SizedBox(width: LatoSpacing.md),
              Expanded(child: LatoSkeletonBlock(height: 96, radius: LatoRadius.lg)),
            ],
          ),
          SizedBox(height: LatoSpacing.md),
          LatoSkeletonBlock(height: 180, radius: LatoRadius.lg),
          SizedBox(height: LatoSpacing.lg),
          LatoSkeletonBlock(height: 52, radius: LatoRadius.md),
        ],
      ),
    );
  }
}

class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({
    required this.payment,
    required this.busy,
    required this.onVoid,
    required this.onRefund,
    required this.onShare,
    required this.onPrint,
  });

  final Payment payment;
  final bool busy;
  final VoidCallback onVoid;
  final VoidCallback onRefund;
  final VoidCallback onShare;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
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
                onVoid: onVoid,
                onRefund: onRefund,
              ),
              const SizedBox(height: LatoSpacing.md),
              _TotalCard(payment: payment),
              const SizedBox(height: LatoSpacing.md),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _MemberCard(payment: payment)),
                    const SizedBox(width: LatoSpacing.md),
                    Expanded(child: _InvoiceCodeCard(payment: payment)),
                  ],
                ),
              ),
              const SizedBox(height: LatoSpacing.md),
              _ItemizedCard(payment: payment),
              const SizedBox(height: LatoSpacing.lg),
              _BottomActions(
                payment: payment,
                busy: busy,
                onShare: onShare,
                onPrint: onPrint,
              ),
              const SizedBox(height: LatoSpacing.xxl),
            ]),
          ),
        ),
      ],
    );
  }
}

/// Real status chip, plus Void / Refund for a paid payment.
class _StatusHeaderCard extends StatelessWidget {
  const _StatusHeaderCard({
    required this.payment,
    required this.onVoid,
    required this.onRefund,
  });

  final Payment payment;
  final VoidCallback onVoid;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    final status = payment.status;
    final (label, tone) = switch (status) {
      'voided' => ('VOIDED', LatoChipTone.error),
      'refunded' => ('REFUNDED', LatoChipTone.warning),
      _ => ('PAID', LatoChipTone.success),
    };
    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LatoStatusChip(label: label, tone: tone),
          if (status == 'paid') ...[
            const SizedBox(height: LatoSpacing.md),
            Row(
              children: [
                Expanded(
                  child: LatoCompactActionButton(
                    label: 'Void',
                    color: LatoColors.error,
                    borderColor: LatoColors.error.withValues(alpha: 0.5),
                    onTap: onVoid,
                  ),
                ),
                const SizedBox(width: LatoSpacing.sm),
                Expanded(
                  child: LatoCompactActionButton(
                    label: 'Refund',
                    color: LatoColors.textPrimaryDark,
                    borderColor: LatoColors.borderStrongDark,
                    onTap: onRefund,
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

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = payment.status == 'paid';
    final label = switch (payment.status) {
      'voided' => 'AMOUNT (VOIDED)',
      'refunded' => 'AMOUNT (REFUNDED)',
      _ => 'TOTAL AMOUNT CAPTURED',
    };
    final whole = payment.amount.truncate();
    final cents = ((payment.amount - whole).abs() * 100)
        .round()
        .toString()
        .padLeft(2, '0');
    final muted = theme.colorScheme.onSurfaceVariant;
    final strike = active ? null : TextDecoration.lineThrough;
    final at = payment.paidAt ?? payment.createdAt;
    final dateLine = at == null
        ? 'Date unknown'
        : '${active ? 'Settled' : 'Paid'} on ${_dateTime(at)}';

    return LatoCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: muted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: LatoSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹${formatInrWhole(whole)}',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? null : muted,
                  decoration: strike,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  '.$cents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: muted,
                    decoration: strike,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LatoSpacing.md),
          Row(
            children: [
              Icon(
                active ? Icons.check_circle : Icons.schedule,
                size: 16,
                color: active ? LatoColors.success : muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dateLine,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Only a real, staff-entered reference is shown here: cash
          // payments (and any payment recorded without one) have none.
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('REF copied')));
                  },
                  icon: const Icon(Icons.content_copy, size: 14),
                  label: const Text(
                    'Copy',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: LatoColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: LatoSpacing.sm,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.padded,
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
      onTap: payment.memberId.isEmpty
          ? null
          : () => context.push('/members/${payment.memberId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MEMBER',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
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
  const _InvoiceCodeCard({required this.payment});
  final Payment payment;

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
            'PAYMENT TYPE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: LatoSpacing.xs),
          Text(
            payment.typeLabel,
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
    final active = payment.status == 'paid';
    final muted = theme.colorScheme.onSurfaceVariant;
    final lineName = (payment.planName ?? '').isNotEmpty
        ? payment.planName!
        : (payment.kind == 'dues' ? 'Dues Payment' : 'Membership Payment');
    // Real snapshot of what the plan included at purchase time; falls back to
    // the staff's own notes; nothing invented when neither exists.
    final features = payment.planFeatures ?? const <String>[];
    final description = features.isNotEmpty
        ? features.join(' • ')
        : (payment.notes != null && payment.notes!.isNotEmpty)
        ? payment.notes!
        : null;
    final amount = formatInr(payment.amount);

    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Itemized Charges',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: LatoSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  lineName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: LatoSpacing.md),
              Text(
                amount,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? null : muted,
                  decoration: active ? null : TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: LatoSpacing.xs),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
          if (payment.planDurationDays != null) ...[
            const SizedBox(height: LatoSpacing.sm),
            LatoStatusChip(
              label: 'Cycle: ${_cycleLabel(payment.planDurationDays!)}',
              tone: LatoChipTone.neutral,
            ),
          ],
          const SizedBox(height: LatoSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: LatoSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  switch (payment.status) {
                    'voided' => 'Amount (Voided)',
                    'refunded' => 'Amount (Refunded)',
                    _ => 'Amount Paid',
                  },
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: active ? LatoColors.primary : muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                amount,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: active ? LatoColors.primary : muted,
                  decoration: active ? null : TextDecoration.lineThrough,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.payment,
    required this.busy,
    required this.onShare,
    required this.onPrint,
  });
  final Payment payment;
  final bool busy;
  final VoidCallback onShare;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final status = payment.status;
    if (status == 'voided') {
      return _StatusFooterChip(
        icon: Icons.block_outlined,
        label: 'Voided on ${_formatDate(payment.voidedAt) ?? '—'}',
        tint: LatoColors.error,
      );
    }
    if (status == 'refunded') {
      return _StatusFooterChip(
        icon: Icons.replay_outlined,
        label: 'Refunded on ${_formatDate(payment.refundedAt) ?? '—'}',
        tint: LatoColors.info,
      );
    }
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onShare,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            label: const Text(
              'Share Receipt',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(LatoSizes.button),
              backgroundColor: LatoColors.primary,
              foregroundColor: LatoColors.bgDark,
            ),
          ),
        ),
        const SizedBox(height: LatoSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: busy ? null : onPrint,
            icon: const Icon(Icons.print_outlined),
            label: const Text(
              'Print Receipt',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(LatoSizes.button),
              side: BorderSide(color: LatoColors.borderDark),
              foregroundColor: LatoColors.textPrimaryDark,
            ),
          ),
        ),
      ],
    );
  }

  static String? _formatDate(DateTime? raw) =>
      raw == null ? null : _dateFmt.format(raw.toLocal());
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
