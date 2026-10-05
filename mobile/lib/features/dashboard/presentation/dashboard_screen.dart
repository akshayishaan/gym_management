import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_empty_state.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_loading.dart';
import '../../../design/components/lato_status_chip.dart';
import '../../../design/spacing.dart';
import '../../gym/application/active_gym_controller.dart';
import '../../payments/presentation/payment_form_sheet.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_data.dart';

/// RepiX dashboard. Mirrors the Figma `86:3508` (loaded state) and
/// `86:3269` (empty state).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGymAsync = ref.watch(activeGymProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        // The Figma header is: RepiX logo on the left, gym-picker pill on
        // the right. No notification bell in the loaded-state design — the
        // bell dot was a holdover from an earlier draft.
        title: const _RepiXLogo(),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _GymPickerChip(activeGymAsync: activeGymAsync),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: const _DashboardBody(),
      ),
    );
  }
}

/// Pill-style gym picker. Shows the active gym's name with a chevron. Tapping
/// it opens the gym picker bottom sheet so the user can switch gyms without
/// leaving the dashboard. Mirrors the Figma "AIMfit Gym ▾" header chip.
class _GymPickerChip extends ConsumerWidget {
  const _GymPickerChip({required this.activeGymAsync});
  final AsyncValue<dynamic> activeGymAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: Semantics(
        button: true,
        label: 'Switch active gym',
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            // Phase 9 wires this to the gym picker bottom sheet. For now
            // we just navigate to /gym/picker which the router allows for
            // authenticated multi-gym users.
            // ignore: use_build_context_synchronously
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.go('/gym/picker');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: activeGymAsync.when(
                    data: (gym) => Text(
                      gym?.name ?? 'RepiX',
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    loading: () => Text(
                      'RepiX',
                      style: theme.textTheme.titleSmall,
                    ),
                    error: (_, _) => Text(
                      'RepiX',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String gymNameOrFallback(AsyncValue<dynamic> async, String? fallback) =>
    fallback ?? 'RepiX';

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);
    return async.when(
      data: (data) => _DashboardContent(data: data),
      loading: () => const LatoLoading(),
      error: (err, _) => LatoErrorState(
        message: err is ApiException ? err.message : 'Could not load dashboard.',
        onRetry: () => ref.invalidate(dashboardProvider),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Empty-state branch: no members at all AND no revenue.
    final isEmpty = data.totalMembers == 0 && data.monthRevenue == 0;

    if (isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Still render the revenue card so the user sees the shape.
          _RevenueCard(
            revenue: data.monthRevenue,
            deltaPct: null,
            isSynthetic: false,
          ),
          const SizedBox(height: 16),
          LatoEmptyState(
            icon: Icons.dashboard_outlined,
            title: 'No activity yet',
            body:
                'Members, plans, and payments will appear here as soon as you start adding them.',
            actionLabel: 'Add a member',
            onAction: () => context.go('/members'),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RevenueCard(
          revenue: data.monthRevenue,
          deltaPct: _revenueDeltaPct(data),
          isSynthetic: data.isRevenueDeltaSynthetic,
        ),
        const SizedBox(height: 16),
        _KpiRow(data: data),
        const SizedBox(height: 24),
        Text('QUICK OPERATIONS',
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.4)),
        const SizedBox(height: 12),
        _QuickOpsRow(),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text('Expiring Soon',
                  style: theme.textTheme.titleLarge),
            ),
            TextButton(
              onPressed: () => context.go('/members'),
              child: Text('View All (${data.expiringMembers})'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (data.expiringList.isEmpty)
          LatoEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No memberships expiring soon',
          )
        else
          ...data.expiringList.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ExpiringRow(member: m),
              )),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text('Recent Payments',
                  style: theme.textTheme.titleLarge),
            ),
            TextButton(
              onPressed: () => context.go('/payments'),
              child: const Text('See History'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (data.recentPayments.isEmpty)
          LatoEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No recent payments recorded',
          )
        else
          ...data.recentPayments.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RecentPaymentRow(payment: p),
              )),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Returns the month-over-month revenue delta. The repository fills in
  /// a stable synthetic value when the backend doesn't ship one, so this
  /// always returns a usable number for the chip.
  double? _revenueDeltaPct(DashboardData data) {
    return data.monthRevenueDeltaPct;
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({
    required this.revenue,
    required this.deltaPct,
    required this.isSynthetic,
  });
  final double revenue;
  final double? deltaPct;
  final bool isSynthetic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final whole = revenue.truncate();
    final cents = ((revenue - whole).abs() * 100).round().toString().padLeft(2, '0');
    final formattedWhole = NumberFormat.decimalPattern().format(whole);

    Widget? deltaChip;
    if (deltaPct != null) {
      final isUp = deltaPct! >= 0;
      final chipColor = isUp ? LatoColors.primary : LatoColors.error;
      final chip = Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: chipColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isUp ? '+' : '−'}${deltaPct!.abs().toStringAsFixed(1)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 16,
              color: chipColor,
            ),
          ],
        ),
      );
      // Flag synthetic values with reduced emphasis so users don't take
      // them as ground-truth figures until the backend ships the real one.
      deltaChip = isSynthetic
          ? Opacity(
                  opacity: 0.6,
                  child: Tooltip(
                    message: 'Demo data',
                    child: chip,
                  ),
                )
          : chip;
    }

    return LatoCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MONTHLY REVENUE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              ?deltaChip,
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\$$formattedWhole',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('.$cents',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final totalDelta = data.totalMembers - data.activeMembers;
    final retention =
        data.totalMembers == 0 ? null : (data.activeMembers / data.totalMembers) * 100;
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            title: 'Total\nMembers',
            value: data.totalMembers,
            footer: totalDelta == 0 ? null : '+$totalDelta wk',
            footerTone: LatoChipTone.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiTile(
            title: 'Active\nMembers',
            value: data.activeMembers,
            footer: retention == null
                ? null
                : '${retention.toStringAsFixed(0)}% ret',
            footerTone: LatoChipTone.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiTile(
            title: 'Expiring\nSoon',
            value: data.expiringMembers,
            footer: data.expiringMembers == 0 ? null : '7 days',
            footerTone: LatoChipTone.warning,
            highlight: true,
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.title,
    required this.value,
    this.footer,
    this.footerTone = LatoChipTone.neutral,
    this.highlight = false,
  });

  final String title;
  final int value;
  final String? footer;
  final LatoChipTone footerTone;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // All three tiles share the same dimensions, padding, and font sizes.
    // The only difference is border + value color: the highlight tile uses
    // a full warning-orange border (matches the Figma "expiring" state)
    // and orange value text. No variable-width borders, no overlays — the
    // tile is a single Container that behaves identically to its siblings.
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? LatoColors.warning : theme.colorScheme.outline,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            NumberFormat.decimalPattern().format(value),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: highlight ? LatoColors.warning : null,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 6),
            Text(
              footer!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: footerTone == LatoChipTone.warning
                    ? LatoColors.warning
                    : LatoColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens the same [PaymentFormSheet] used by the Payments screen's "+"
/// button, with no pre-selected member (the sheet's own member picker
/// handles that). Shared by the "Record Pay" quick-op tile here.
Future<void> _openRecordPaymentSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LatoColors.surfaceDark,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(LatoRadius.xl)),
    ),
    builder: (sheetCtx) => const FractionallySizedBox(
      heightFactor: 0.92,
      child: PaymentFormSheet(),
    ),
  );
}

class _QuickOpsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickOpTile(
          assetPath: 'assets/icons/quickop_add_member.svg',
          label: 'Add\nMember',
          iconColor: const Color(0xFF4ADE80), // green
          onTap: () => context.go('/members'),
        ),
        const SizedBox(width: 12),
        _QuickOpTile(
          assetPath: 'assets/icons/quickop_record_pay.svg',
          label: 'Record\nPay',
          iconColor: LatoColors.primary, // lime
          onTap: () => _openRecordPaymentSheet(context),
        ),
        const SizedBox(width: 12),
        _QuickOpTile(
          assetPath: 'assets/icons/quickop_reminders.svg',
          label: 'Send\nAlerts',
          iconColor: const Color(0xFF22D3EE), // cyan
          // No bulk-notification endpoint exists yet (backend exposes no
          // `/alerts` resource) — say so honestly rather than a silent
          // no-op, matching the Plans screen's "Duplicate — coming soon".
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Send Alerts — coming soon')),
          ),
        ),
        const SizedBox(width: 12),
        _QuickOpTile(
          assetPath: 'assets/icons/quickop_reports.svg',
          label: 'Reports',
          iconColor: const Color(0xFF60A5FA), // blue
          onTap: () => context.go('/reports'),
        ),
      ],
    );
  }
}

class _QuickOpTile extends StatelessWidget {
  const _QuickOpTile({
    required this.assetPath,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cleanLabel = label.replaceAll('\n', ' ');
    return Expanded(
      child: Semantics(
        button: true,
        label: cleanLabel,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 96,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LatoColors.borderDark),
            ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    // The SVGs ship with a fill color baked in. We tint
                    // them by overlaying a colorFilter so the brand
                    // stays the design color in any theme.
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  height: 1.15,
                ),
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _ExpiringRow extends StatelessWidget {
  const _ExpiringRow({required this.member});
  final ExpiringMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(member.name);
    final chipTone = member.daysUntilExpiry <= 3
        ? LatoChipTone.error
        : LatoChipTone.neutral;
    final chipLabel = member.daysUntilExpiry <= 0
        ? 'Expired'
        : '${member.daysUntilExpiry} day${member.daysUntilExpiry == 1 ? '' : 's'} left';
    return Semantics(
      label: 'Member ${member.name}',
      child: LatoCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: LatoColors.primary.withValues(alpha: 0.15),
              child: Text(
                initials,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: LatoColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.name,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      LatoStatusChip(label: chipLabel, tone: chipTone),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (member.planName != null && member.planName!.isNotEmpty)
                        member.planName,
                      member.membershipExpiry,
                    ].whereType<String>().join(' • '),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _IconAction(
              icon: Icons.chat_bubble_outline,
              color: LatoColors.success,
              onTap: () {
                final phone = member.phone;
                if (phone == null || phone.isEmpty) return;
                final clean = phone.replaceAll(RegExp(r'\s+'), '');
                final stripped =
                    clean.startsWith('+') ? clean.substring(1) : clean;
                launchContactUrl(context, 'https://wa.me/$stripped');
              },
            ),
            const SizedBox(width: 4),
            _IconAction(
              icon: Icons.call_outlined,
              color: LatoColors.info,
              onTap: () {
                final phone = member.phone;
                if (phone == null || phone.isEmpty) return;
                launchContactUrl(
                  context,
                  'tel:${phone.replaceAll(RegExp(r'\s+'), '')}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _RecentPaymentRow extends StatelessWidget {
  const _RecentPaymentRow({required this.payment});
  final RecentPayment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFmt = DateFormat.jm();
    final dayFmt = DateFormat.yMMMd();
    final isToday = _isSameDay(payment.paidAt, DateTime.now());
    final when = isToday
        ? 'Today, ${timeFmt.format(payment.paidAt.toLocal())}'
        : '${dayFmt.format(payment.paidAt.toLocal())}, ${timeFmt.format(payment.paidAt.toLocal())}';

    return Semantics(
      label: 'Payment ${payment.memberName}',
      child: LatoCard(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: LatoColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _methodIcon(payment.method),
                size: 18,
                color: LatoColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payment.memberName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${_methodLabel(payment.method)} • $when',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              '+\$${payment.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: LatoColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  IconData _methodIcon(String method) {
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

  String _methodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'upi':
        return 'UPI';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return 'Other';
    }
  }
}

/// SVG (1033×341 viewBox; the full mark with the neon chartreuse X is one
/// cohesive path, so we render it as a single SvgPicture).
class _RepiXLogo extends StatelessWidget {
  const _RepiXLogo();

  @override
  Widget build(BuildContext context) {
    // The logo's native aspect ratio is 1033:341 (~3.03:1). At height=26
    // the natural width is ~78.8, comfortably fitting in the AppBar's
    // left title slot.
    return SizedBox(
      width: 80,
      height: 26,
      child: SvgPicture.asset(
        'assets/logo/repix_logo.svg',
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}