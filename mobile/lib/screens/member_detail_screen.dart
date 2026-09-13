import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/api_exception.dart';
import '../core/api/client_request_id.dart';
import '../core/api/dio_providers.dart';
import '../core/settings/gym_settings_controller.dart';
import '../data/api_helpers.dart';
import '../data/filters.dart';
import '../data/formatters.dart';
import '../data/member_providers.dart';
import '../data/membership_providers.dart';
import '../data/payment_providers.dart';
import '../data/query_scope.dart';
import '../layout/shell.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_surface.dart';
import '../widgets/avatar.dart';
import '../widgets/hide_scrollbar.dart';
import '../widgets/member_form_sheet.dart';
import '../widgets/payment_form_sheet.dart';
import '../widgets/status_badge.dart';

/// Full-screen member detail: profile hero, quick actions, and three tabs
/// (Overview / History / Payments).
///
/// All rendered status/days/duration come from server fields (`member.status`,
/// `member.daysUntilExpiry`, `membership.expiryStatus`, `membership.durationDays`,
/// `payment.status`) — no client-side date arithmetic (ADR-0005).
class MemberDetailScreen extends ConsumerStatefulWidget {
  const MemberDetailScreen({
    super.key,
    required this.memberId,
    this.initialMember,
  });

  final String memberId;
  final MemberResponse? initialMember;

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  int _tab = 0;

  String _reminderMessage(MemberResponse m) {
    final String expiry =
        m.membershipExpiry != null ? formatDate(m.membershipExpiry!) : 'soon';
    return 'Hi ${m.name}, your gym membership expires on $expiry. '
        'Please renew to continue your fitness journey! 💪';
  }

  Future<void> _launch(String url, String failure) async {
    final bool ok = await launchExternal(url);
    if (!ok && mounted) showAppSnackBar(context, failure, isError: true);
  }

  void _openEdit(MemberResponse member) {
    MemberFormSheet.show(
      context,
      initialData: member,
      currency: ref.read(gymSettingsControllerProvider).currency,
    );
  }

  void _openPayment(MemberResponse member) {
    PaymentFormSheet.show(
      context,
      prefillMemberId: member.id,
      prefillMemberName: member.name,
      currency: ref.read(gymSettingsControllerProvider).currency,
    );
  }

  Future<void> _restoreMember(MemberResponse member) async {
    final dio = ref.read(dioProvider);
    try {
      await putJson<MemberResponse>(
        dio,
        '/members/${member.id}',
        data: MemberUpdateInput(isActive: true).toJson(),
        fromJson: MemberResponse.fromJson,
      );
      if (mounted) showAppSnackBar(context, 'Member restored');
      invalidateGymScopeFromWidget(ref);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.userMessage, isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to restore member', isError: true);
      }
    }
  }

  Future<void> _reverseMembership(
    MembershipListResponseMembershipsInner m,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ThemeTokens dt =
            Theme.of(dialogContext).extension<AppThemeTokens>()!.tokens;
        return AlertDialog(
          title: Text('Reverse ${m.planName}?'),
          content: const Text(
            'This Membership period will be reversed and its associated '
            'Payment will be voided. Newer Membership transactions must be '
            'reversed first.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Reverse purchase',
                style: TextStyle(color: dt.destructive.value),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final dio = ref.read(dioProvider);
    try {
      await postJson<LifecycleResultResponse>(
        dio,
        '/memberships/${m.id}/reverse',
        data: PaymentActionInput(requestId: createRequestId()).toJson(),
        fromJson: LifecycleResultResponse.fromJson,
      );
      if (mounted) showAppSnackBar(context, 'Plan purchase reversed');
      invalidateGymScopeFromWidget(ref);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.userMessage, isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Could not reverse Plan purchase',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final String currency = ref.watch(gymSettingsControllerProvider).currency;

    final AsyncValue<MemberResponse> memberAsync =
        ref.watch(memberProvider(widget.memberId));
    final AsyncValue<PaymentListResponse> paymentsAsync =
        ref.watch(paymentsProvider(
      PaymentFilters(memberId: widget.memberId, limit: 100),
    ));
    final AsyncValue<MembershipListResponse> membershipsAsync =
        ref.watch(membershipsProvider(widget.memberId));

    final MemberResponse? member = memberAsync.value;
    final String title = member?.name ?? 'Member';

    return AppShell(
      mode: ShellMode.stack,
      title: title,
      selectedIndex: 1,
      onSelectTab: (_) {},
      actions: <Widget>[
        if (member != null && member.isActive)
          IconButton(
            onPressed: () => _openEdit(member),
            icon: const Icon(Icons.edit_outlined),
          ),
      ],
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: memberAsync.when(
              data: (MemberResponse data) => _buildContent(
                t,
                currency,
                data,
                paymentsAsync.value?.payments ??
                    const <PaymentListResponsePaymentsInner>[],
                membershipsAsync.value?.memberships ??
                    const <MembershipListResponseMembershipsInner>[],
              ),
              loading: () => _buildLoading(t),
              error: (Object e, StackTrace st) => _buildError(t),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeTokens t) {
    return HideScrollBar(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: withOpacity(t.foreground, 0.08),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 20,
                      width: 160,
                      decoration: BoxDecoration(
                        color: withOpacity(t.foreground, 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 96,
                      decoration: BoxDecoration(
                        color: withOpacity(t.foreground, 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Skeleton(tokens: t, height: 160, radius: 28),
          const SizedBox(height: 16),
          _Skeleton(tokens: t, height: 160, radius: 28),
        ],
      ),
    );
  }

  Widget _buildError(ThemeTokens t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 32, color: t.destructive.value),
            const SizedBox(height: 12),
            Text(
              'Member could not load',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w700,
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
              onPressed: () => ref.invalidate(memberProvider(widget.memberId)),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    ThemeTokens t,
    String currency,
    MemberResponse member,
    List<PaymentListResponsePaymentsInner> payments,
    List<MembershipListResponseMembershipsInner> memberships,
  ) {
    return HideScrollBar(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: <Widget>[
          _ProfileHero(
            tokens: t,
            member: member,
            currency: currency,
          ),
          const SizedBox(height: 16),
          _ActionsRow(
            tokens: t,
            member: member,
            onRestore: () => _restoreMember(member),
            onWhatsApp: member.phone.isNotEmpty
                ? () => _launch(
                      buildWhatsAppLink(member.phone, _reminderMessage(member)),
                      'Could not open WhatsApp',
                    )
                : null,
            onSms: member.phone.isNotEmpty
                ? () => _launch(
                      buildSmsLink(member.phone, _reminderMessage(member)),
                      'Could not open SMS',
                    )
                : null,
            onRenew: _canRenew(member) ? () => _openPayment(member) : null,
            onPayment: () => _openPayment(member),
          ),
          const SizedBox(height: 16),
          _SegmentedTabs(
            tokens: t,
            selected: _tab,
            historyCount: memberships.length,
            paymentsCount: payments.length,
            onSelect: (int index) => setState(() => _tab = index),
          ),
          const SizedBox(height: 16),
          switch (_tab) {
            0 => _OverviewTab(tokens: t, member: member, currency: currency),
            1 => _HistoryTab(
                tokens: t,
                currency: currency,
                memberships: memberships,
                onReverse: _reverseMembership,
              ),
            _ => _PaymentsTab(
                tokens: t,
                currency: currency,
                payments: payments,
              ),
          },
        ],
      ),
    );
  }

  bool _canRenew(MemberResponse member) {
    return member.status == MemberDisplayStatus.expired ||
        member.status == MemberDisplayStatus.expiring;
  }
}

// -- profile hero ------------------------------------------------------------

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.tokens,
    required this.member,
    required this.currency,
  });

  final ThemeTokens tokens;
  final MemberResponse member;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final bool deleted = member.isActive == false;
    final Color subColor = withOpacity(t.background, 0.55);

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
            Positioned(
              top: -56,
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: <Widget>[
                  Avatar(
                    name: member.name,
                    size: 64,
                    background: withOpacity(t.background, 0.10),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                member.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  color: t.background,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (deleted)
                              _TintedPill(
                                label: 'Deleted',
                                foreground: t.secondary.foreground,
                                background: t.secondary.value,
                                border: t.secondary.value,
                              )
                            else if (member.status != null)
                              StatusBadge(
                                variant:
                                    variantFromDisplayStatus(member.status),
                                label: displayStatusLabel(member.status),
                                days: member.daysUntilExpiry,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${member.planName ?? 'No plan assigned'}'
                          '${member.phone.isNotEmpty ? ' · ${member.phone}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          member.dueAmount > 0
                              ? '${formatCurrency(member.dueAmount, currency)} outstanding'
                              : 'Account paid in full',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: member.dueAmount > 0
                                ? t.warning.value
                                : t.success.value,
                          ),
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

// -- actions row -------------------------------------------------------------

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.tokens,
    required this.member,
    required this.onRestore,
    this.onWhatsApp,
    this.onSms,
    this.onRenew,
    required this.onPayment,
  });

  final ThemeTokens tokens;
  final MemberResponse member;
  final VoidCallback onRestore;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onSms;
  final VoidCallback? onRenew;
  final VoidCallback onPayment;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;

    if (member.isActive == false) {
      return AppSurface(
        padding: const EdgeInsets.all(8),
        child: FilledButton.icon(
          onPressed: onRestore,
          style: FilledButton.styleFrom(
            backgroundColor: t.primary.value,
            foregroundColor: t.primary.foreground,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(t.radius),
            ),
          ),
          icon: const Icon(Icons.restore, size: 18),
          label: const Text('Restore Member'),
        ),
      );
    }

    return AppSurface(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          if (onWhatsApp != null)
            _ActionTile(
              icon: Icons.chat_outlined,
              iconColor: t.success.value,
              label: 'WhatsApp',
              onTap: onWhatsApp!,
            ),
          if (onSms != null)
            _ActionTile(
              icon: Icons.sms_outlined,
              iconColor: t.primary.value,
              label: 'SMS',
              onTap: onSms!,
            ),
          if (onRenew != null)
            _ActionTile(
              icon: Icons.refresh,
              iconColor: t.primary.value,
              label: 'Renew',
              onTap: onRenew!,
            ),
          _ActionTile(
            icon: Icons.credit_card,
            iconColor: t.foreground,
            label: 'Payment',
            onTap: onPayment,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: t.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- segmented tabs ----------------------------------------------------------

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.tokens,
    required this.selected,
    required this.historyCount,
    required this.paymentsCount,
    required this.onSelect,
  });

  final ThemeTokens tokens;
  final int selected;
  final int historyCount;
  final int paymentsCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.muted.value,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          _TabButton(
            tokens: t,
            label: 'Overview',
            selected: selected == 0,
            onTap: () => onSelect(0),
          ),
          _TabButton(
            tokens: t,
            label: 'History',
            count: historyCount,
            selected: selected == 1,
            onTap: () => onSelect(1),
          ),
          _TabButton(
            tokens: t,
            label: 'Payments',
            count: paymentsCount,
            selected: selected == 2,
            onTap: () => onSelect(2),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tokens,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final ThemeTokens tokens;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final Color foreground = selected ? t.background : t.muted.foreground;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? t.foreground : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
              if (count != null && count! > 0) ...<Widget>[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: t.secondary.value,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.secondary.foreground,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// -- overview tab ------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.tokens,
    required this.member,
    required this.currency,
  });

  final ThemeTokens tokens;
  final MemberResponse member;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _InfoCard(
          title: 'Personal Info',
          children: <Widget>[
            _InfoRow(
                icon: Icons.phone,
                label: 'Phone',
                value: member.phone,
                mono: true),
            _InfoRow(
                icon: Icons.mail_outline, label: 'Email', value: member.email),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Gender',
              value: member.gender == null
                  ? null
                  : _capitalize(member.gender!.value),
            ),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Date of Birth',
              value: member.dateOfBirth == null
                  ? null
                  : formatDate(member.dateOfBirth!),
            ),
            _InfoRow(
                icon: Icons.map_outlined,
                label: 'Address',
                value: member.address),
            _InfoRow(
              icon: Icons.contact_emergency,
              label: 'Emergency Contact',
              value: member.emergencyContact,
              mono: true,
            ),
            _InfoRow(icon: Icons.notes, label: 'Notes', value: member.notes),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Membership',
          children: <Widget>[
            _InfoRow(
                icon: Icons.description_outlined,
                label: 'Plan',
                value: member.planName),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Start Date',
              value: member.membershipStart == null
                  ? null
                  : formatDate(member.membershipStart!),
            ),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Expiry Date',
              value: member.membershipExpiry == null
                  ? null
                  : formatDate(member.membershipExpiry!),
            ),
            if (member.status != null)
              _BadgeRow(
                label: 'Status',
                child: StatusBadge(
                  variant: variantFromDisplayStatus(member.status),
                  label: displayStatusLabel(member.status),
                  days: member.daysUntilExpiry,
                ),
              ),
            _BadgeRow(
              label: 'Outstanding Balance',
              child: member.dueAmount > 0
                  ? _TintedPill(
                      label:
                          '${formatCurrency(member.dueAmount, currency)} due',
                      foreground: t.warning.foreground,
                      background: withOpacity(t.warning.value, 0.15),
                      border: withOpacity(t.warning.value, 0.25),
                    )
                  : _TintedPill(
                      label: 'Paid in full',
                      foreground: t.success.value,
                      background: withOpacity(t.success.value, 0.10),
                      border: withOpacity(t.success.value, 0.20),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

// -- history tab -------------------------------------------------------------

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.tokens,
    required this.currency,
    required this.memberships,
    required this.onReverse,
  });

  final ThemeTokens tokens;
  final String currency;
  final List<MembershipListResponseMembershipsInner> memberships;
  final ValueChanged<MembershipListResponseMembershipsInner> onReverse;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;

    if (memberships.isEmpty) {
      return const _EmptyState(
        icon: Icons.history,
        title: 'No membership history yet',
        subtitle:
            'Membership periods are recorded when a payment with a plan is created',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MembershipListResponseMembershipsInner m in memberships)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MembershipRow(
              tokens: t,
              currency: currency,
              membership: m,
              onReverse: () => onReverse(m),
            ),
          ),
      ],
    );
  }
}

class _MembershipRow extends StatelessWidget {
  const _MembershipRow({
    required this.tokens,
    required this.currency,
    required this.membership,
    required this.onReverse,
  });

  final ThemeTokens tokens;
  final String currency;
  final MembershipListResponseMembershipsInner membership;
  final VoidCallback onReverse;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final MembershipListResponseMembershipsInner m = membership;
    final bool reversed =
        m.status == MembershipListResponseMembershipsInnerStatusEnum.reversed;

    final Widget statusBadge = reversed
        ? const StatusBadge(variant: BadgeVariant.reversed, label: 'Reversed')
        : StatusBadge(
            variant: variantFromDisplayStatus(m.expiryStatus),
            label: displayStatusLabel(m.expiryStatus),
          );

    final String? durationText = m.durationDays == null
        ? null
        : '${m.durationDays} day${m.durationDays == 1 ? '' : 's'}';

    return AppSurface(
      borderRadius: BorderRadius.circular(t.radius * 1.33),
      padding: const EdgeInsets.all(16),
      color: reversed ? withOpacity(t.muted.value, 0.40) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  m.planName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              statusBadge,
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  '${formatDate(m.startDate)} – ${formatDate(m.expiryDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: t.muted.foreground),
                ),
              ),
              if (durationText != null) ...<Widget>[
                const SizedBox(width: 8),
                Text(
                  durationText,
                  style: TextStyle(fontSize: 12, color: t.muted.foreground),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Purchased ${formatDate(m.createdAt)}',
                style: TextStyle(fontSize: 12, color: t.muted.foreground),
              ),
              m.planPrice == null && m.amount == null
                  ? Text(
                      '—',
                      style: TextStyle(fontSize: 12, color: t.muted.foreground),
                    )
                  : Text(
                      formatCurrency(m.planPrice ?? m.amount!, currency),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t.foreground,
                      ),
                    ),
            ],
          ),
          if (!reversed) ...<Widget>[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onReverse,
              style: OutlinedButton.styleFrom(
                foregroundColor: t.destructive.value,
                side: BorderSide(color: withOpacity(t.destructive.value, 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(t.radius),
                ),
              ),
              icon: const Icon(Icons.undo, size: 16),
              label: const Text(
                'Reverse Plan purchase',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -- payments tab ------------------------------------------------------------

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({
    required this.tokens,
    required this.currency,
    required this.payments,
  });

  final ThemeTokens tokens;
  final String currency;
  final List<PaymentListResponsePaymentsInner> payments;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;

    if (payments.isEmpty) {
      return const _EmptyState(
        icon: Icons.credit_card,
        title: 'No payments yet',
        subtitle: 'Record the first payment to see it here',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final PaymentListResponsePaymentsInner p in payments)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PaymentRow(
              tokens: t,
              currency: currency,
              payment: p,
            ),
          ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.tokens,
    required this.currency,
    required this.payment,
  });

  final ThemeTokens tokens;
  final String currency;
  final PaymentListResponsePaymentsInner payment;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final PaymentListResponsePaymentsInner p = payment;
    final bool paid =
        p.status == PaymentListResponsePaymentsInnerStatusEnum.paid;
    final String method = p.method.value.replaceAll('_', ' ');

    Widget? statusBadge;
    if (!paid) {
      if (p.status == PaymentListResponsePaymentsInnerStatusEnum.refunded) {
        statusBadge = _TintedPill(
          label: 'Refunded',
          foreground: t.warning.foreground,
          background: withOpacity(t.warning.value, 0.15),
          border: withOpacity(t.warning.value, 0.25),
        );
      } else {
        statusBadge = _TintedPill(
          label: 'Voided',
          foreground: t.secondary.foreground,
          background: t.secondary.value,
          border: t.secondary.value,
        );
      }
    }

    return AppSurface(
      borderRadius: BorderRadius.circular(t.radius * 1.33),
      padding: const EdgeInsets.all(16),
      color: paid ? null : withOpacity(t.muted.value, 0.40),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        p.invoiceNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: t.foreground,
                        ),
                      ),
                    ),
                    if (statusBadge != null) ...<Widget>[
                      const SizedBox(width: 8),
                      statusBadge,
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${p.planName != null ? '${p.planName} · ' : ''}'
                  '$method · ${formatDate(p.paidAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: t.muted.foreground),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatCurrency(p.amount, currency),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: paid ? t.success.value : t.muted.foreground,
              decoration:
                  paid ? TextDecoration.none : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}

// -- shared pieces -----------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;
    return AppSurface(
      borderRadius: BorderRadius.circular(t.radius * 1.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: t.foreground,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;
    if (value == null || value!.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: withOpacity(t.border, 0.6), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: t.muted.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: t.muted.foreground),
                ),
                const SizedBox(height: 2),
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: t.foreground,
                    fontFamily: mono ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: withOpacity(t.border, 0.6), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child:
                Icon(Icons.info_outline, size: 16, color: t.muted.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: t.muted.foreground),
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TintedPill extends StatelessWidget {
  const _TintedPill({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: foreground,
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
            textAlign: TextAlign.center,
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
