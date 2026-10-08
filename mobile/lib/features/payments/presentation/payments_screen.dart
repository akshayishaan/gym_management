// Phase 7 — Payments & Ledger. Mirrors the Figma `payments_ledger.png`:
// month selector + TOTAL COLLECTED KPI card + status pills (All / Settled /
// Voided / Refunded, filtered by the backend) + "Recent Payments" list of
// transaction cards (avatar, name + plan, amount + invoice, timestamp +
// method chip, Void/Refund/receipt actions), loaded 50 at a time.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/money.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_fab.dart';
import '../../../design/components/lato_sheet.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_compact_action_button.dart';
import '../../../design/components/lato_empty_state.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_load_more_footer.dart';
import '../../../design/components/lato_status_chip.dart';
import '../../../design/spacing.dart';
import '../application/payment_controller.dart';
import '../data/payment_repository.dart';
import '../domain/payment.dart';
import '../domain/payment_query.dart';
import 'payment_form_sheet.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  /// `null` means "all time"; otherwise holds the first day of the
  /// selected month (UTC-naive — only the year/month fields are read).
  DateTime? _currentMonth;

  /// Status pill: `all`, or the backend `Payment.status` it filters on
  /// (`paid`, `voided`, `refunded`). The backend applies it, so pagination and
  /// the count on the selected pill are exact.
  String _activeStatus = 'all';

  /// Number of 50-payment pages currently shown. Reset to 1 whenever the
  /// month or status changes (see [_loadedFilterKey] in build).
  int _pages = 1;
  String _loadedFilterKey = '';

  Future<void> _openRecordPaymentSheet() async {
    await showLatoFormSheet<void>(
      context: context,
      builder: (_) => const PaymentFormSheet(),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final months = [
      for (var i = 0; i < 12; i++) DateTime(now.year, now.month - i, 1),
    ];
    final choice = await showLatoSheet<_MonthChoice>(
      context: context,
      builder: (sheetCtx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetCtx).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            const LatoSheetTitle('Select Month'),
            _MonthOption(
              label: 'All time',
              selected: _currentMonth == null,
              onTap: () => Navigator.of(sheetCtx).pop(const _MonthChoice(null)),
            ),
            for (final m in months)
              _MonthOption(
                label: DateFormat('MMMM yyyy').format(m),
                selected:
                    _currentMonth != null &&
                    _currentMonth!.year == m.year &&
                    _currentMonth!.month == m.month,
                onTap: () => Navigator.of(sheetCtx).pop(_MonthChoice(m)),
              ),
            const SizedBox(height: LatoSpacing.md),
          ],
        ),
      ),
    );
    if (choice == null) return;
    setState(() => _currentMonth = choice.month);
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
    final theme = Theme.of(context);
    final filterKey = '${_monthQueryParam()}|$_activeStatus';
    if (filterKey != _loadedFilterKey) {
      _loadedFilterKey = filterKey;
      _pages = 1;
    }
    final query = PaymentListQuery(
      month: _monthQueryParam(),
      status: _activeStatus == 'all' ? null : _activeStatus,
    );
    final pageAsyncs = [
      for (var i = 1; i <= _pages; i++)
        ref.watch(paymentListProvider(query.copyWith(page: i))),
    ];
    final async = pageAsyncs.first;
    final lastPage = pageAsyncs.last;
    // Null until this filter's first page arrives; the screen chrome stays
    // mounted and shows skeletons in its place meanwhile.
    final result = async.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        // Payments is a bottom-tab screen (the Figma header has no back
        // arrow), so there is nothing to go back to.
        automaticallyImplyLeading: false,
        title: Text('Payments & Ledger', style: theme.textTheme.headlineSmall),
      ),
      floatingActionButton: LatoFab(
        label: 'New Payment',
        onPressed: _openRecordPaymentSheet,
      ),
      body: Builder(
        builder: (context) {
          // Merge the pages loaded so far, de-duplicated by id in case a
          // payment was recorded while paging shifted the boundaries.
          final seen = <String>{};
          final payments = [
            for (final a in pageAsyncs)
              if (a.valueOrNull != null)
                for (final p in a.valueOrNull!.payments)
                  if (seen.add(p.id)) p,
          ];
          final loadingMore =
              _pages > 1 && lastPage.isLoading && !lastPage.hasValue;
          final loadMoreFailed =
              _pages > 1 && lastPage.hasError && !lastPage.hasValue;
          final hasMore = result != null && payments.length < result.total;
          final showFooter = hasMore || loadingMore || loadMoreFailed;
          String pillLabel(String base, String status) =>
              result != null && _activeStatus == status
              ? '$base (${result.total})'
              : base;
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
                child: _MonthPickerBar(label: _monthLabel(), onTap: _pickMonth),
              ),
              // KPI card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: LatoSpacing.xl),
                child: result == null
                    ? const _KpiSkeleton()
                    : _KpiCard(
                        netAmount: result.netAmount,
                        total: result.total,
                        status: _activeStatus,
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
                      label: pillLabel('All', 'all'),
                      selected: _activeStatus == 'all',
                      onTap: () => setState(() => _activeStatus = 'all'),
                    ),
                    const SizedBox(width: LatoSpacing.sm),
                    _StatusPill(
                      label: pillLabel('Settled', 'paid'),
                      selected: _activeStatus == 'paid',
                      onTap: () => setState(() => _activeStatus = 'paid'),
                    ),
                    const SizedBox(width: LatoSpacing.sm),
                    _StatusPill(
                      label: pillLabel('Voided', 'voided'),
                      selected: _activeStatus == 'voided',
                      onTap: () => setState(() => _activeStatus = 'voided'),
                    ),
                    const SizedBox(width: LatoSpacing.sm),
                    _StatusPill(
                      label: pillLabel('Refunded', 'refunded'),
                      selected: _activeStatus == 'refunded',
                      onTap: () => setState(() => _activeStatus = 'refunded'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LatoSpacing.lg),
              // "Recent Payments" header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: LatoSpacing.xl),
                child: Text(
                  'Recent Payments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: LatoSpacing.md),
              Expanded(
                child: result == null
                    ? (async.hasError
                          ? _errorState(async.error, query)
                          : const _PaymentsSkeletonList())
                    : payments.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(LatoSpacing.lg),
                          child: _activeStatus == 'all' && _currentMonth == null
                              ? const LatoEmptyState(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'No payments yet',
                                  body: 'Recorded payments will appear here.',
                                )
                              : const LatoEmptyState(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'No payments match',
                                  body: 'Try a different month or status.',
                                ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          LatoSpacing.xl,
                          0,
                          LatoSpacing.xl,
                          LatoSpacing.fabClearance,
                        ),
                        itemCount: payments.length + (showFooter ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= payments.length) {
                            return LatoLoadMoreFooter(
                              shown: payments.length,
                              total: result.total,
                              loading: loadingMore,
                              failed: loadMoreFailed,
                              onLoadMore: () => setState(() => _pages++),
                              onRetry: () => ref.invalidate(
                                paymentListProvider(
                                  query.copyWith(page: _pages),
                                ),
                              ),
                            );
                          }
                          final p = payments[i];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: LatoSpacing.md,
                            ),
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

  Widget _errorState(Object? err, PaymentListQuery query) => LatoErrorState(
    message: err is ApiException ? err.message : 'Could not load payments.',
    onRetry: () => ref.invalidate(paymentListProvider(query)),
  );
}

Widget _skeletonBlock(double? width, double height, [double radius = 8]) =>
    Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: LatoColors.surfaceRaisedDark,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

/// Placeholder for [_KpiCard] with the same padding and block heights, so
/// the card does not change size when the numbers arrive.
class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LatoCard(
        key: const Key('payments-kpi-skeleton'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonBlock(104, 12),
            const SizedBox(height: LatoSpacing.sm),
            _skeletonBlock(180, 44),
            const SizedBox(height: LatoSpacing.sm),
            _skeletonBlock(190, 14),
          ],
        ),
      ),
    );
  }
}

/// Placeholder list shown while a new month or status loads. Mirrors
/// [_PaymentCard]'s padding and block heights.
class _PaymentsSkeletonList extends StatelessWidget {
  const _PaymentsSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('payments-skeleton'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        LatoSpacing.xl,
        0,
        LatoSpacing.xl,
        LatoSpacing.fabClearance,
      ),
      children: const [
        _PaymentCardSkeleton(),
        SizedBox(height: LatoSpacing.md),
        _PaymentCardSkeleton(),
        SizedBox(height: LatoSpacing.md),
        _PaymentCardSkeleton(),
        SizedBox(height: LatoSpacing.md),
        _PaymentCardSkeleton(),
      ],
    );
  }
}

class _PaymentCardSkeleton extends StatelessWidget {
  const _PaymentCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LatoCard(
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
                _skeletonBlock(40, 40, 20),
                const SizedBox(width: LatoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _skeletonBlock(140, 18),
                      const SizedBox(height: 6),
                      _skeletonBlock(96, 13),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _skeletonBlock(80, 20),
                    const SizedBox(height: 6),
                    _skeletonBlock(64, 11),
                  ],
                ),
              ],
            ),
            const SizedBox(height: LatoSpacing.md),
            Row(
              children: [
                Expanded(child: _skeletonBlock(null, 14)),
                const SizedBox(width: LatoSpacing.xl),
                _skeletonBlock(64, 26, LatoRadius.pill),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Result of the month sheet; a null [month] means "All time".
class _MonthChoice {
  const _MonthChoice(this.month);
  final DateTime? month;
}

class _MonthOption extends StatelessWidget {
  const _MonthOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: selected ? LatoColors.primary : null,
          fontWeight: selected ? FontWeight.w700 : null,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: LatoColors.primary)
          : null,
      onTap: onTap,
    );
  }
}

/// Calendar-icon + month label + chevron. Tapping opens the month sheet.
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
    required this.status,
    required this.monthLabel,
  });

  final double netAmount;
  final int total;
  final String status;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final whole = netAmount.truncate();
    final cents = ((netAmount - whole).abs() * 100).round().toString().padLeft(
      2,
      '0',
    );
    final wholeFmt = formatInrWhole(whole);
    final one = total == 1;
    final summary = switch (status) {
      'paid' => one ? 'settled payment' : 'settled payments',
      'voided' => one ? 'voided payment' : 'voided payments',
      'refunded' => one ? 'refunded payment' : 'refunded payments',
      _ => one ? 'payment recorded' : 'payments recorded',
    };

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
                '₹$wholeFmt',
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
            '$total $summary • $monthLabel',
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
/// + timestamp/method row + Void/Refund actions.
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

  String get _initials => _computeInitials(payment.memberName);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = payment.paidAt ?? payment.createdAt;
    final timestampLabel = timestamp != null
        ? '${DateFormat('d MMM y').format(timestamp.toLocal())} • '
              '${DateFormat.jm().format(timestamp.toLocal())}'
        : '—';
    final isActionable = payment.status == 'paid';
    final isVoided = payment.status == 'voided';
    final isRefunded = payment.status == 'refunded';

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
                      if (isVoided || isRefunded) ...[
                        const SizedBox(height: LatoSpacing.sm),
                        LatoStatusChip(
                          label: isVoided ? 'VOIDED' : 'REFUNDED',
                          tone: isVoided
                              ? LatoChipTone.error
                              : LatoChipTone.warning,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: LatoSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${formatInr(payment.amount)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isActionable
                            ? LatoColors.success
                            : theme.colorScheme.onSurfaceVariant,
                        decoration: isActionable
                            ? null
                            : TextDecoration.lineThrough,
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
              ],
            ),
            const SizedBox(height: LatoSpacing.md),
            // Timestamp + method chip row.
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
                  const SizedBox(width: LatoSpacing.sm),
                  IconButton.outlined(
                    tooltip: 'View receipt',
                    onPressed: onTap,
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    style: IconButton.styleFrom(
                      foregroundColor: LatoColors.primary,
                      side: const BorderSide(
                        color: LatoColors.borderStrongDark,
                      ),
                      minimumSize: const Size(36, 36),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      shape: const RoundedRectangleBorder(
                        borderRadius: LatoRadius.button,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
