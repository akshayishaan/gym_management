import 'dart:async';

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
import '../data/member_repository.dart';
import '../domain/member.dart';
import '../domain/member_query.dart';
import 'member_form_sheet.dart';

/// Phase 5 — Members directory. Mirrors the Figma
/// `members_directory_v1.png` and `members_directory_v2.png` (list state +
/// add-member sheet).
class MembersListScreen extends ConsumerStatefulWidget {
  const MembersListScreen({super.key});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _activeStatus; // null = "all"
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
    });
  }

  Future<void> _openAddMemberSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LatoColors.surfaceDark,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LatoRadius.xl)),
      ),
      builder: (sheetCtx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: const MemberFormSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = MemberListQuery(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      status: _activeStatus,
    );
    final membersAsync = ref.watch(memberListProvider(query));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        title: Text('Members', style: theme.textTheme.headlineSmall),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _AddPillButton(onTap: _openAddMemberSheet),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LatoSpacing.xl,
              LatoSpacing.sm,
              LatoSpacing.xl,
              LatoSpacing.md,
            ),
            child: _SearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
          ),
          // Status filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: LatoSpacing.xl),
              children: [
                _StatusChip(
                  label: 'All Members',
                  selected: _activeStatus == null,
                  onTap: () => setState(() => _activeStatus = null),
                ),
                const SizedBox(width: LatoSpacing.sm),
                _StatusChip(
                  label: 'Active',
                  selected: _activeStatus == 'active',
                  onTap: () => setState(() => _activeStatus = 'active'),
                ),
                const SizedBox(width: LatoSpacing.sm),
                _StatusChip(
                  label: 'Expiring Soon',
                  selected: _activeStatus == 'expiring',
                  onTap: () => setState(() => _activeStatus = 'expiring'),
                ),
                const SizedBox(width: LatoSpacing.sm),
                _StatusChip(
                  label: 'Expiring',
                  selected: _activeStatus == 'expired',
                  onTap: () => setState(() => _activeStatus = 'expired'),
                ),
                const SizedBox(width: LatoSpacing.sm),
                _StatusChip(
                  label: 'Due',
                  selected: _activeStatus == 'due',
                  onTap: () => setState(() => _activeStatus = 'due'),
                ),
              ],
            ),
          ),
          const SizedBox(height: LatoSpacing.lg),
          // List body
          Expanded(
            child: membersAsync.when(
              data: (page) {
                if (page.members.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(LatoSpacing.lg),
                      child: LatoEmptyState(
                        icon: Icons.person_outline,
                        title: 'No members yet',
                        body:
                            'Add your first member to start tracking memberships.',
                        actionLabel: 'Add Member',
                        onAction: _openAddMemberSheet,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    LatoSpacing.xl,
                    0,
                    LatoSpacing.xl,
                    LatoSpacing.xxl,
                  ),
                  itemCount: page.members.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _ListHeader(total: page.total);
                    }
                    final member = page.members[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: LatoSpacing.md),
                      child: _MemberCard(
                        member: member,
                        onTap: () => context.push('/members/${member.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const LatoLoading(),
              error: (err, _) => LatoErrorState(
                message: err is ApiException ? err.message : 'Could not load members.',
                onRetry: () => ref.invalidate(memberListProvider(query)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lime "+" pill button in the AppBar.
class _AddPillButton extends StatelessWidget {
  const _AddPillButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LatoColors.primary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.add, color: LatoColors.bgDark, size: 24),
        ),
      ),
    );
  }
}

/// Search field with leading search icon and trailing filter button.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search members by name, phone, or plan...',
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: LatoColors.textSecondaryDark,
        ),
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.tune,
            size: 18,
            color: LatoColors.textSecondaryDark,
          ),
          onPressed: () {},
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LatoSpacing.md,
          vertical: 0,
        ),
      ),
    );
  }
}

/// Filter pill used for the status row.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
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

/// "TOTAL MEMBERS 1,420 / Sorted by: Expiry Date ⇅" header row.
class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 1.4,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: LatoSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'TOTAL MEMBERS  ${NumberFormat.decimalPattern().format(total)}',
              style: labelStyle,
            ),
          ),
          Text('Sorted by: Expiry Date', style: labelStyle),
          const SizedBox(width: 4),
          const Icon(
            Icons.swap_vert,
            size: 14,
            color: LatoColors.textSecondaryDark,
          ),
        ],
      ),
    );
  }
}

/// One member row — avatar + center column + right column with status chip
/// and Paid/Due pill.
class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onTap});
  final Member member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Member ${member.name}',
      child: LatoCard(
        onTap: onTap,
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InitialsAvatar(member: member),
          const SizedBox(width: LatoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if ((member.planName ?? '').isNotEmpty)
                  Text(member.planName!, style: theme.textTheme.bodySmall),
                Text(member.phone, style: theme.textTheme.bodySmall),
                if ((member.membershipExpiry ?? '').isNotEmpty)
                  Text(
                    'Exp: ${member.membershipExpiry!}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: LatoColors.warning),
                  ),
              ],
            ),
          ),
          const SizedBox(width: LatoSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusChipForMember(status: member.status, daysLeft: member.daysUntilExpiry),
              const SizedBox(height: LatoSpacing.sm),
              _PaymentPill(dueAmount: member.dueAmount),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

/// Lime-tinted initials avatar matching the Figma.
class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: LatoColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        member.initials,
        style: theme.textTheme.titleMedium?.copyWith(
          color: LatoColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Maps a member's `status` (`'active' | 'expiring' | 'expired' | null`)
/// to the right [LatoStatusChip] tone + label.
class _StatusChipForMember extends StatelessWidget {
  const _StatusChipForMember({required this.status, required this.daysLeft});
  final String? status;
  final int? daysLeft;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'active':
        return const LatoStatusChip(
          label: 'ACTIVE',
          tone: LatoChipTone.primary,
          icon: Icons.circle,
        );
      case 'expiring':
        final d = daysLeft ?? 0;
        return LatoStatusChip(
          label: 'EXPIRING: $d D LEFT',
          tone: LatoChipTone.warning,
          icon: Icons.adjust,
        );
      case 'expired':
        return const LatoStatusChip(
          label: 'EXPIRED',
          tone: LatoChipTone.error,
          icon: Icons.warning_amber_rounded,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Right-side solid badge: red "Due:$X" when dueAmount > 0, else green
/// "PAID". Unlike [LatoStatusChip]'s translucent outline, this is a solid
/// fill matching the Figma payment badge (node 2:1890) — colors sampled
/// from the reference: a deep tinted fill with a brighter same-hue text,
/// not a bright fill with white text.
class _PaymentPill extends StatelessWidget {
  const _PaymentPill({required this.dueAmount});
  final double dueAmount;

  static const _dueBg = Color(0xFF93000A);
  static const _dueFg = Color(0xFFE88E89);
  static const _paidBg = Color(0xFF1A301E);
  static const _paidFg = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final isDue = dueAmount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LatoSpacing.sm,
        vertical: LatoSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isDue ? _dueBg : _paidBg,
        borderRadius: BorderRadius.circular(LatoRadius.sm),
      ),
      child: Text(
        isDue ? 'Due:\$${dueAmount.round()}' : 'PAID',
        style: TextStyle(
          color: isDue ? _dueFg : _paidFg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
