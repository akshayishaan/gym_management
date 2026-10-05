// Phase 5 — Member detail. Mirrors the Figma trio under
// `.planning/screenshots/phase5_figma/`:
//   * member_detail_view.png     — Overview tab (default)
//   * member_detail_payment.png  — Payments tab
//   * member_detail_activity.png — History tab (plan history + Reverse Plan)
//
// Identity card, quick actions row, segmented tabs, and key/value rows all
// come straight from those references. Edit launches Track B's
// `MemberFormSheet` (currently add-only); Delete is a confirmation dialog
// that calls `memberDeleteControllerProvider`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_client.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_empty_state.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_loading.dart';
import '../../../design/components/lato_status_chip.dart';
import '../../../design/spacing.dart';
import '../application/member_controller.dart';
import '../data/member_repository.dart';
import '../domain/member.dart';
import 'member_form_sheet.dart';

class MemberDetailScreen extends ConsumerStatefulWidget {
  const MemberDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<MemberDetailScreen> createState() =>
      _MemberDetailScreenState();
}

enum _Tab { overview, history, payments }

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  _Tab _selectedTab = _Tab.overview;

  Future<void> _openEditSheet(Member member) async {
    // TODO(phase 5 — Track B): Track B's `MemberFormSheet` is currently
    // add-only; once it accepts an optional `Member` for edit, pass
    // `existingMember: member` here. For now we open the sheet without
    // pre-fill so the pencil button at least surfaces the screen.
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LatoColors.surfaceDark,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(LatoRadius.xl)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: const MemberFormSheet(),
      ),
    );
  }

  Future<void> _confirmAndDelete(Member member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LatoColors.surfaceDark,
        title: Text('Delete ${member.name}?'),
        content: const Text(
          'They will be marked inactive. You can restore them later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: LatoColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(memberDeleteControllerProvider.notifier)
          .softDelete(member.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member deleted')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Could not delete member.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncMember = ref.watch(memberDetailProvider(widget.id));
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text('Member Profile'),
        actions: [
          asyncMember.maybeWhen(
            data: (member) => IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined,
                  color: LatoColors.primary, size: 22),
              onPressed: () => _openEditSheet(member),
            ),
            orElse: () => const SizedBox(width: 48),
          ),
        ],
      ),
      body: asyncMember.when(
        loading: () => const LatoLoading(),
        error: (err, _) => LatoErrorState(
          message: err is ApiException ? err.message : 'Could not load member.',
          onRetry: () => ref.invalidate(memberDetailProvider(widget.id)),
        ),
        data: (member) => _DetailBody(
          member: member,
          selectedTab: _selectedTab,
          onTabChanged: (t) => setState(() => _selectedTab = t),
          onDelete: () => _confirmAndDelete(member),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.member,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onDelete,
  });

  final Member member;
  final _Tab selectedTab;
  final ValueChanged<_Tab> onTabChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              _IdentityCard(member: member),
              const SizedBox(height: LatoSpacing.md),
              _QuickActionsRow(member: member),
              const SizedBox(height: LatoSpacing.lg),
              _TabsRow(
                selected: selectedTab,
                onChanged: onTabChanged,
              ),
              const SizedBox(height: LatoSpacing.lg),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            LatoSpacing.xl,
            0,
            LatoSpacing.xl,
            LatoSpacing.xxxl,
          ),
          sliver: SliverToBoxAdapter(
            child: switch (selectedTab) {
              _Tab.overview => _OverviewTab(member: member, onDelete: onDelete),
              _Tab.history => _HistoryTab(memberId: member.id),
              _Tab.payments => _PaymentsTab(memberId: member.id),
            },
          ),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueAmount = member.dueAmount;
    final isPaidUp = dueAmount <= 0;

    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(initials: member.initials, size: 64),
              const SizedBox(width: LatoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (member.planName == null || member.planName!.isEmpty)
                          ? '—'
                          : member.planName!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: LatoColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.phone,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              _StatusChip(member: member),
            ],
          ),
          const SizedBox(height: LatoSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: LatoSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ID: #${_shortId(member.id)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: LatoColors.textSecondaryDark,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              _PaymentPill(isPaidUp: isPaidUp, dueAmount: dueAmount),
            ],
          ),
        ],
      ),
    );
  }

  static String _shortId(String id) {
    if (id.length <= 6) return id.toUpperCase();
    final tail = id.substring(id.length - 4);
    return 'MEM-$tail';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, this.size = 64});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LatoColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        initials,
        style: theme.textTheme.titleLarge?.copyWith(
          color: LatoColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    final status = member.status;
    if (status == 'active') {
      return const LatoStatusChip(
        label: 'ACTIVE',
        tone: LatoChipTone.primary,
      );
    }
    if (status == 'expiring') {
      return const LatoStatusChip(
        label: 'EXPIRING',
        tone: LatoChipTone.warning,
      );
    }
    if (status == 'expired') {
      return const LatoStatusChip(
        label: 'EXPIRED',
        tone: LatoChipTone.error,
      );
    }
    return LatoStatusChip(
      label: member.isActive ? 'ACTIVE' : 'INACTIVE',
      tone: member.isActive ? LatoChipTone.primary : LatoChipTone.neutral,
    );
  }
}

class _PaymentPill extends StatelessWidget {
  const _PaymentPill({required this.isPaidUp, required this.dueAmount});
  final bool isPaidUp;
  final double dueAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isPaidUp) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LatoSpacing.md,
          vertical: LatoSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: LatoColors.primary.withValues(alpha: 0.16),
          borderRadius: LatoRadius.chip,
          border: Border.all(color: LatoColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: LatoColors.primary),
            const SizedBox(width: 4),
            Text(
              'Paid in Full',
              style: theme.textTheme.labelMedium?.copyWith(
                color: LatoColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LatoSpacing.md,
        vertical: LatoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: LatoColors.warning.withValues(alpha: 0.16),
        borderRadius: LatoRadius.chip,
        border: Border.all(color: LatoColors.warning),
      ),
      child: Text(
        'Due: \$${dueAmount.toStringAsFixed(2)}',
        style: theme.textTheme.labelMedium?.copyWith(
          color: LatoColors.warning,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.member});
  final Member member;

  void _launchUrl(BuildContext context, String url) {
    // The backend exposes no contact APIs yet so these shortcuts are
    // visible shortcuts that hand off to the platform handlers.
    // Intentional no-op for now (placeholder for Phase 6+).
    if (url.isEmpty) return;
    // We can't depend on `url_launcher` here without modifying pubspec;
    // leaving a no-op so the tiles render but don't crash.
    // ignore: avoid_print
    print('quick-action: $url');
  }

  @override
  Widget build(BuildContext context) {
    final cleanPhone = member.phone.replaceAll(RegExp(r'\s+'), '');
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: Icons.chat_bubble_outline,
            tint: LatoColors.primary,
            label: 'WhatsApp',
            onTap: () =>
                _launchUrl(context, 'https://wa.me/${_stripPlus(cleanPhone)}'),
          ),
        ),
        const SizedBox(width: LatoSpacing.md),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.message_outlined,
            tint: LatoColors.info,
            label: 'SMS',
            onTap: () => _launchUrl(context, 'sms:$cleanPhone'),
          ),
        ),
        const SizedBox(width: LatoSpacing.md),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.autorenew,
            tint: LatoColors.primary,
            label: 'Renew',
            onTap: () {},
          ),
        ),
        const SizedBox(width: LatoSpacing.md),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.credit_card_outlined,
            tint: LatoColors.primary,
            label: 'Payment',
            onTap: () {},
          ),
        ),
      ],
    );
  }

  String _stripPlus(String phone) =>
      phone.startsWith('+') ? phone.substring(1) : phone;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.tint,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(vertical: LatoSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: tint),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabsRow extends StatelessWidget {
  const _TabsRow({required this.selected, required this.onChanged});
  final _Tab selected;
  final ValueChanged<_Tab> onChanged;

  String _label(_Tab t) {
    switch (t) {
      case _Tab.overview:
        return 'Overview';
      case _Tab.history:
        return 'History';
      case _Tab.payments:
        return 'Payments';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: _Tab.values.map((t) {
          final isSel = t == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? LatoColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _label(t),
                  style: theme.textTheme.titleMedium?.copyWith(
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
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.member, required this.onDelete});
  final Member member;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dob = _parseDate(member.dateOfBirth);
    final ageLabel = dob != null ? _ageFromDob(dob) : null;
    final dobLabel = dob != null
        ? DateFormat.yMMMd().format(dob)
        : (member.dateOfBirth ?? '—');
    final emergency = member.emergencyContact;
    final address = member.address;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LatoCard(
          padding: const EdgeInsets.all(LatoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Personal Profile',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Edit',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: LatoColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 14,
                              color: LatoColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LatoSpacing.md),
              if ((member.email ?? '').isNotEmpty)
                _KeyValueRow(label: 'Email', value: member.email!),
              _KeyValueRow(
                label: 'Gender / Age',
                value: '${_genderLabel(member.gender)} • '
                    '${ageLabel != null ? '$ageLabel yrs' : '—'} '
                    '($dobLabel)',
              ),
              _KeyValueRow(
                label: 'Residential',
                value: (address == null || address.isEmpty) ? '—' : address,
                alignTop: true,
              ),
              if (emergency != null && emergency.isNotEmpty)
                _KeyValueRow(
                  label: 'Emergency Contact',
                  value: emergency,
                  valueColor: LatoColors.primary,
                  alignTop: true,
                )
              else
                _KeyValueRow(label: 'Emergency Contact', value: '—'),
            ],
          ),
        ),
        if ((member.notes ?? '').isNotEmpty) ...[
          const SizedBox(height: LatoSpacing.lg),
          LatoCard(
            padding: const EdgeInsets.all(LatoSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: LatoSpacing.sm),
                Text(
                  member.notes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: LatoSpacing.xxl),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: LatoColors.error,
              side: const BorderSide(color: LatoColors.error, width: 1),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: onDelete,
            child: const Text(
              'Delete member',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  static String _genderLabel(String? g) {
    switch (g) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return '—';
    }
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  static int _ageFromDob(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age -= 1;
    }
    return age;
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.alignTop = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: valueColor,
      fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LatoSpacing.sm),
      child: Row(
        crossAxisAlignment:
            alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: LatoColors.textSecondaryDark,
              ),
            ),
          ),
          const SizedBox(width: LatoSpacing.md),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              textAlign: TextAlign.right,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------- History tab --------------------------------

final _memberMembershipsProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>((ref, memberId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(
    '/memberships',
    queryParameters: {'memberId': memberId},
  );
  final data = res.data ?? const {};
  return (data['memberships'] as List?) ?? const [];
});

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.memberId});
  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_memberMembershipsProvider(memberId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: LatoSpacing.xxxl),
        child: LatoLoading(),
      ),
      error: (err, _) => LatoEmptyState(
        icon: Icons.error_outline,
        title: 'Could not load history',
        body: err is ApiException ? err.message : null,
      ),
      data: (raw) {
        final list = raw.whereType<Map<String, dynamic>>().toList();
        if (list.isEmpty) {
          return const LatoEmptyState(
            icon: Icons.history_toggle_off_outlined,
            title: 'No membership history',
            body: 'Plan purchases will appear here once recorded.',
          );
        }
        return Column(
          children: [
            for (final m in list) ...[
              _MembershipCard(json: m),
              const SizedBox(height: LatoSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.json});
  final Map<String, dynamic> json;

  String _planName() {
    final name = json['planName'];
    if (name is String && name.isNotEmpty) return name;
    return 'Plan';
  }

  String _startDate() => _formatYmd(json['startDate']);
  String _expiryDate() => _formatYmd(json['expiryDate']);

  LatoStatusChip _chip() {
    // Server attaches `status` ('paid'|'reversed'|'voided') and
    // `expiryStatus` ('active'|'expiring'|'expired'). The Figma uses
    // ACTIVE / EXPIRING: Xd LEFT / EXPIRED on the right side.
    final expiryStatus = json['expiryStatus'];
    final rawStatus = json['status'];
    if (rawStatus == 'reversed') {
      return const LatoStatusChip(
        label: 'REVERSED',
        tone: LatoChipTone.error,
      );
    }
    if (expiryStatus == 'expired' || rawStatus == 'voided') {
      return const LatoStatusChip(
        label: 'EXPIRED',
        tone: LatoChipTone.error,
      );
    }
    if (expiryStatus == 'expiring') {
      return const LatoStatusChip(
        label: 'EXPIRING',
        tone: LatoChipTone.warning,
      );
    }
    return const LatoStatusChip(
      label: 'ACTIVE',
      tone: LatoChipTone.primary,
    );
  }

  bool _isCurrentActive() {
    final expiryStatus = json['expiryStatus'];
    final rawStatus = json['status'];
    return expiryStatus == 'active' && rawStatus != 'reversed';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LatoColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: LatoColors.primary,
                ),
              ),
              const SizedBox(width: LatoSpacing.md),
              Expanded(
                child: Text(
                  _planName(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              _chip(),
            ],
          ),
          const SizedBox(height: LatoSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DateLabel(
                  label: 'START DATE',
                  value: _startDate(),
                ),
              ),
              Expanded(
                child: _DateLabel(
                  label: 'EXPIRY (AUTO-RENEWS)',
                  value: _expiryDate(),
                ),
              ),
            ],
          ),
          if (_isCurrentActive()) ...[
            const SizedBox(height: LatoSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: LatoColors.error.withValues(alpha: 0.10),
                  foregroundColor: LatoColors.error,
                  side: BorderSide(
                    color: LatoColors.error.withValues(alpha: 0.5),
                  ),
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Reverse Plan is not wired up yet (Phase 6+).',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Reverse Plan',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: LatoColors.textSecondaryDark,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ----------------------------- Payments tab -------------------------------

final _memberPaymentsProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>((ref, memberId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(
    '/payments',
    queryParameters: {'memberId': memberId, 'limit': 50},
  );
  final data = res.data ?? const {};
  return (data['payments'] as List?) ?? const [];
});

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.memberId});
  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_memberPaymentsProvider(memberId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: LatoSpacing.xxxl),
        child: LatoLoading(),
      ),
      error: (err, _) => LatoEmptyState(
        icon: Icons.error_outline,
        title: 'Could not load payments',
        body: err is ApiException ? err.message : null,
      ),
      data: (raw) {
        final list = raw.whereType<Map<String, dynamic>>().toList();
        if (list.isEmpty) {
          return const LatoEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No payments yet',
            body: 'Recorded payments will appear here.',
          );
        }
        return Column(
          children: [
            for (final p in list) ...[
              _PaymentCard(json: p),
              const SizedBox(height: LatoSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.json});
  final Map<String, dynamic> json;

  String _planName() {
    final name = json['planName'];
    if (name is String && name.isNotEmpty) return name;
    final mname = json['memberName'];
    if (mname is String && mname.isNotEmpty) return mname;
    return 'Payment';
  }

  String _invoiceNumber() {
    final n = json['invoiceNumber'];
    if (n is String && n.isNotEmpty) return n;
    return '';
  }

  String _methodLabel() {
    final m = json['method'];
    if (m is! String) return 'Payment';
    switch (m) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'upi':
        return 'UPI';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return m;
    }
  }

  IconData _methodIcon() {
    final m = json['method'];
    switch (m) {
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

  String _when() {
    final raw = json['paidAt'];
    if (raw is! String) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    return '${DateFormat.yMMMd().format(local)} • '
        '${DateFormat.jm().format(local)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = (json['amount'] as num?)?.toDouble() ?? 0;
    final invoice = _invoiceNumber();
    return LatoCard(
      padding: const EdgeInsets.all(LatoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _planName(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+\$${amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: LatoColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (invoice.isNotEmpty)
                    Text(
                      '#$invoice',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: LatoColors.textSecondaryDark,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: LatoSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 14,
                color: LatoColors.textSecondaryDark,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _when(),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LatoSpacing.md,
                  vertical: LatoSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: LatoColors.primary.withValues(alpha: 0.16),
                  borderRadius: LatoRadius.chip,
                  border: Border.all(
                    color: LatoColors.primary.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_methodIcon(), size: 12, color: LatoColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      _methodLabel(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: LatoColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatYmd(dynamic raw) {
  if (raw is! String || raw.isEmpty) return '—';
  // Server emits 'YYYY-MM-DD' (date-only) already; just render as-is.
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return raw;
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  return DateFormat.yMMMd().format(dt);
}

