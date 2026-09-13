import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/navigation.dart';
import '../core/settings/gym_settings_controller.dart';
import '../data/dashboard_providers.dart';
import '../data/formatters.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../widgets/app_screen.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_surface.dart';
import '../widgets/avatar.dart';
import '../widgets/hide_scrollbar.dart';
import '../widgets/member_form_sheet.dart';
import '../widgets/payment_form_sheet.dart';
import '../widgets/quick_actions.dart';
import '../widgets/status_badge.dart';

/// The Today (dashboard) tab: revenue hero, quick actions, expiring-memberships
/// and recent-payments cards.
///
/// All rendered status/days/duration come from server fields
/// (`DashboardResponse.expiringList[].daysUntilExpiry`, `monthRevenue`, etc.) —
/// no client-side date arithmetic (ADR-0005).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final String currency = ref.watch(gymSettingsControllerProvider).currency;
    final AsyncValue<DashboardResponse> dash = ref.watch(dashboardProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardProvider.future),
      child: HideScrollBar(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: AppScreen(
            children: dash.when(
              data: (DashboardResponse d) =>
                  _buildDashboard(context, ref, t, currency, d),
              loading: () => _buildLoading(t),
              error: (Object e, StackTrace st) => _buildError(ref, t),
            ),
          ),
        ),
      ),
    );
  }

  void _goToMembers(WidgetRef ref, String status) {
    ref.read(membersStatusProvider.notifier).state = status;
    ref.read(selectedTabIndexProvider.notifier).state = 1;
  }

  List<Widget> _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    ThemeTokens t,
    String currency,
    DashboardResponse d,
  ) {
    return <Widget>[
      _RevenueHero(
        tokens: t,
        revenue: d.monthRevenue,
        currency: currency,
        totalMembers: d.totalMembers,
        activeMembers: d.activeMembers,
        expiringMembers: d.expiringMembers,
      ),
      const SizedBox(height: 24),
      const AppSectionLabel('Quick actions'),
      const SizedBox(height: 12),
      QuickActions(
        onAddMember: () => MemberFormSheet.show(context, currency: currency),
        onRecordPayment: () =>
            PaymentFormSheet.show(context, currency: currency),
        onRemind: () => _goToMembers(ref, 'expiring'),
        onReports: () => showAppSnackBar(context, 'Reports coming soon'),
      ),
      const SizedBox(height: 24),
      _ExpiringCard(
        tokens: t,
        items: d.expiringList,
        onSeeAll: () => _goToMembers(ref, 'expiring'),
      ),
      const SizedBox(height: 16),
      _RecentPaymentsCard(
        tokens: t,
        currency: currency,
        items: d.recentPayments,
        onSeeAll: () => ref.read(selectedTabIndexProvider.notifier).state = 2,
      ),
    ];
  }

  List<Widget> _buildLoading(ThemeTokens t) {
    return <Widget>[
      _Skeleton(tokens: t, height: 208, radius: 32),
      const SizedBox(height: 24),
      _Skeleton(tokens: t, height: 96, radius: 28),
      const SizedBox(height: 16),
      _Skeleton(tokens: t, height: 256, radius: 28),
    ];
  }

  List<Widget> _buildError(WidgetRef ref, ThemeTokens t) {
    return <Widget>[
      AppSurface(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(Icons.error_outline, size: 32, color: t.destructive.value),
            const SizedBox(height: 12),
            Text(
              'Could not load your dashboard',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: t.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please try again.',
              style: TextStyle(fontSize: 13, color: t.muted.foreground),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.invalidate(dashboardProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    ];
  }
}

// -- revenue hero ------------------------------------------------------------

class _RevenueHero extends StatelessWidget {
  const _RevenueHero({
    required this.tokens,
    required this.revenue,
    required this.currency,
    required this.totalMembers,
    required this.activeMembers,
    required this.expiringMembers,
  });

  final ThemeTokens tokens;
  final num revenue;
  final String currency;
  final num totalMembers;
  final num activeMembers;
  final num expiringMembers;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final Color labelColor = withOpacity(t.background, 0.55);

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        decoration: BoxDecoration(
          color: t.foreground,
          borderRadius: BorderRadius.circular(32),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: withOpacity(t.foreground, 0.15),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            // Top-right primary glow.
            Positioned(
              top: -64,
              right: -48,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: withOpacity(t.primary.value, 0.55),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // Bottom-left success glow.
            Positioned(
              bottom: -80,
              left: -32,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 144,
                  height: 144,
                  decoration: BoxDecoration(
                    color: withOpacity(t.success.value, 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Revenue this month',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: labelColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatCurrency(revenue, currency),
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.05 * 32,
                                height: 1,
                                color: t.background,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: withOpacity(t.background, 0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.north_east,
                          size: 22,
                          color: t.primary.value,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: withOpacity(t.background, 0.07),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: <Widget>[
                        _HeroStat(
                          value: totalMembers,
                          label: 'Members',
                          valueColor: t.background,
                          labelColor: labelColor,
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: withOpacity(t.background, 0.10),
                        ),
                        _HeroStat(
                          value: activeMembers,
                          label: 'Active',
                          valueColor: t.success.value,
                          labelColor: labelColor,
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: withOpacity(t.background, 0.10),
                        ),
                        _HeroStat(
                          value: expiringMembers,
                          label: 'Expiring',
                          valueColor: t.warning.value,
                          labelColor: labelColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.labelColor,
  });

  final num value;
  final String label;
  final Color valueColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

// -- expiring soon -----------------------------------------------------------

class _ExpiringCard extends StatelessWidget {
  const _ExpiringCard({
    required this.tokens,
    required this.items,
    required this.onSeeAll,
  });

  final ThemeTokens tokens;
  final List<DashboardResponseExpiringListInner> items;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    return AppSurface(
      borderRadius: BorderRadius.circular(t.radius * 1.55),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionHeader(
            icon: Icons.warning_amber_rounded,
            iconBackground: withOpacity(t.warning.value, 0.15),
            iconColor: t.warning.value,
            title: 'Expiring Soon',
            trailing: _AllLink(
              color: t.warning.value,
              onTap: onSeeAll,
            ),
          ),
          if (items.isEmpty)
            const _EmptyState(
              icon: Icons.group,
              title: 'No members expiring soon',
              subtitle: 'All memberships are up to date',
            )
          else
            Column(
              children: <Widget>[
                for (final DashboardResponseExpiringListInner item in items)
                  _ExpiringRow(item: item, tokens: t),
              ],
            ),
        ],
      ),
    );
  }
}

class _ExpiringRow extends StatelessWidget {
  const _ExpiringRow({required this.item, required this.tokens});

  final DashboardResponseExpiringListInner item;
  final ThemeTokens tokens;

  String get _message => 'Hi ${item.name}, your gym membership expires on '
      '${formatDate(item.membershipExpiry)}. Please renew to continue your '
      'fitness journey! 💪';

  Future<void> _open(BuildContext context, String url, String failure) async {
    final bool ok = await launchExternal(url);
    if (!ok && context.mounted) {
      showAppSnackBar(context, failure, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final int days = item.daysUntilExpiry;
    final BadgeVariant variant =
        days <= 3 ? BadgeVariant.urgent : BadgeVariant.expiring;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: <Widget>[
          Avatar(
            name: item.name,
            size: 40,
            background: withOpacity(t.primary.value, 0.10),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: t.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.planName ?? 'No plan'} · '
                  '${formatDate(item.membershipExpiry)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: t.muted.foreground),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(
            variant: variant,
            label: days == 0 ? 'Today' : '${days}d',
            days: days,
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _open(
              context,
              buildWhatsAppLink(item.phone, _message),
              'Could not open WhatsApp',
            ),
            icon: Icon(Icons.chat_outlined, size: 20, color: t.success.value),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: () => _open(
              context,
              buildSmsLink(item.phone, _message),
              'Could not open SMS',
            ),
            icon: Icon(Icons.sms_outlined, size: 20, color: t.primary.value),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// -- recent payments ---------------------------------------------------------

class _RecentPaymentsCard extends StatelessWidget {
  const _RecentPaymentsCard({
    required this.tokens,
    required this.currency,
    required this.items,
    required this.onSeeAll,
  });

  final ThemeTokens tokens;
  final String currency;
  final List<DashboardResponseRecentPaymentsInner> items;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    return AppSurface(
      borderRadius: BorderRadius.circular(t.radius * 1.55),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionHeader(
            icon: Icons.account_balance_wallet,
            iconBackground: withOpacity(t.success.value, 0.10),
            iconColor: t.success.value,
            title: 'Recent Payments',
            trailing: _AllLink(
              color: t.primary.value,
              onTap: onSeeAll,
            ),
          ),
          if (items.isEmpty)
            const _EmptyState(
              icon: Icons.account_balance_wallet,
              title: 'No payments yet',
              subtitle: 'Record your first payment to see it here',
            )
          else
            Column(
              children: <Widget>[
                for (final DashboardResponseRecentPaymentsInner payment
                    in items)
                  _PaymentRow(
                    payment: payment,
                    tokens: t,
                    currency: currency,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.tokens,
    required this.currency,
  });

  final DashboardResponseRecentPaymentsInner payment;
  final ThemeTokens tokens;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final String method = payment.method.value.replaceAll('_', ' ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: <Widget>[
          Avatar(
            name: payment.memberName,
            size: 40,
            background: withOpacity(t.success.value, 0.10),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  payment.memberName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: t.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$method · ${formatDate(payment.paidAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: t.muted.foreground),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatCurrency(payment.amount, currency),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: t.success.value,
            ),
          ),
        ],
      ),
    );
  }
}

// -- shared card pieces ------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.foreground,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _AllLink extends StatelessWidget {
  const _AllLink({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'All',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(width: 2),
          Icon(Icons.arrow_forward, size: 14, color: color),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(color: t.muted.value, shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: t.muted.foreground),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: t.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: t.muted.foreground),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({
    required this.tokens,
    required this.height,
    required this.radius,
  });

  final ThemeTokens tokens;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: withOpacity(tokens.foreground, 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
