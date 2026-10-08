import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/money.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_fab.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_load_more_footer.dart';
import '../../../design/components/lato_empty_state.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_skeleton.dart';
import '../../../design/components/lato_sheet.dart';
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

  /// Number of 20-member pages currently shown. Reset to 1 whenever the
  /// search or status filter changes (see [_loadedFilterKey] in build).
  int _pages = 1;
  String _loadedFilterKey = '';

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
    await showLatoFormSheet<void>(
      context: context,
      builder: (_) => const MemberFormSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterKey = '$_searchQuery|$_activeStatus';
    if (filterKey != _loadedFilterKey) {
      _loadedFilterKey = filterKey;
      _pages = 1;
    }
    final query = MemberListQuery(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      status: _activeStatus,
    );
    // Watch every page loaded so far; the list is their concatenation.
    final pageAsyncs = [
      for (var i = 1; i <= _pages; i++)
        ref.watch(memberListProvider(query.copyWith(page: i))),
    ];
    final membersAsync = pageAsyncs.first;
    final lastPage = pageAsyncs.last;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        title: Text('Members', style: theme.textTheme.headlineSmall),
      ),
      floatingActionButton: LatoFab(
        label: 'New Member',
        onPressed: _openAddMemberSheet,
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
              onClear: () {
                _debounce?.cancel();
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
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
                  label: 'Expired',
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
              skipLoadingOnReload: true,
              data: (page) {
                if (page.members.isEmpty &&
                    (_searchQuery.isNotEmpty || _activeStatus != null)) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(LatoSpacing.lg),
                      child: LatoEmptyState(
                        icon: Icons.search_off,
                        title: 'No members match',
                        body: 'Try a different search or filter.',
                        actionLabel: 'Clear filters',
                        onAction: () {
                          _debounce?.cancel();
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _activeStatus = null;
                          });
                        },
                      ),
                    ),
                  );
                }
                if (page.members.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(LatoSpacing.lg),
                      child: LatoEmptyState(
                        icon: Icons.person_outline,
                        title: 'No members yet',
                        body: 'Add your first member to start tracking memberships.',
                        actionLabel: 'Add Member',
                        onAction: _openAddMemberSheet,
                      ),
                    ),
                  );
                }
                // Merge the pages loaded so far; de-duplicate by id in case a
                // member was added while paging shifted the page boundaries.
                final seen = <String>{};
                final members = [
                  for (final a in pageAsyncs)
                    if (a.valueOrNull != null)
                      for (final m in a.valueOrNull!.members)
                        if (seen.add(m.id)) m,
                ];
                final loadingMore =
                    _pages > 1 && lastPage.isLoading && !lastPage.hasValue;
                final loadMoreFailed =
                    _pages > 1 && lastPage.hasError && !lastPage.hasValue;
                final hasMore = lastPage.valueOrNull?.hasMore ?? false;
                final showFooter = hasMore || loadingMore || loadMoreFailed;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    LatoSpacing.xl,
                    0,
                    LatoSpacing.xl,
                    LatoSpacing.fabClearance,
                  ),
                  itemCount: members.length + 1 + (showFooter ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _ListHeader(total: page.total);
                    }
                    if (index > members.length) {
                      return LatoLoadMoreFooter(
                        shown: members.length,
                        total: page.total,
                        loading: loadingMore,
                        failed: loadMoreFailed,
                        onLoadMore: () => setState(() => _pages++),
                        onRetry: () => ref.invalidate(
                          memberListProvider(query.copyWith(page: _pages)),
                        ),
                      );
                    }
                    final member = members[index - 1];
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
              loading: () => const _MembersSkeletonList(),
              error: (err, _) => LatoErrorState(
                message: err is ApiException
                    ? err.message
                    : 'Could not load members.',
                onRetry: () => ref.invalidate(memberListProvider(query)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder list for the first load or a new filter. Mirrors the header row
/// and [_MemberCard] padding and block heights.
class _MembersSkeletonList extends StatelessWidget {
  const _MembersSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ListView(
        key: const Key('members-skeleton'),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          LatoSpacing.xl,
          0,
          LatoSpacing.xl,
          LatoSpacing.fabClearance,
        ),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: LatoSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: LatoSkeletonBlock(width: 140, height: 12),
            ),
          ),
          for (var i = 0; i < 6; i++) ...[
            const _MemberCardSkeleton(),
            const SizedBox(height: LatoSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _MemberCardSkeleton extends StatelessWidget {
  const _MemberCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const LatoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LatoSkeletonBlock(width: 48, height: 48, radius: 24),
          SizedBox(width: LatoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LatoSkeletonBlock(width: 140, height: 16),
                SizedBox(height: 6),
                LatoSkeletonBlock(width: 96, height: 12),
                SizedBox(height: 6),
                LatoSkeletonBlock(width: 104, height: 12),
                SizedBox(height: 6),
                LatoSkeletonBlock(width: 120, height: 12),
              ],
            ),
          ),
          SizedBox(width: LatoSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LatoSkeletonBlock(width: 64, height: 22, radius: LatoRadius.pill),
              SizedBox(height: 40),
              LatoSkeletonBlock(width: 56, height: 22, radius: LatoRadius.pill),
            ],
          ),
        ],
      ),
    );
  }
}

/// Search field with a leading search icon and a clear button that appears
/// while there is text.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
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
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: LatoColors.textSecondaryDark,
                  ),
                  onPressed: onClear,
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LatoSpacing.md,
            vertical: 0,
          ),
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

/// "TOTAL MEMBERS 1,420" header row, with the count in lime.
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
          Text('TOTAL MEMBERS', style: labelStyle),
          const SizedBox(width: LatoSpacing.sm),
          Text(
            NumberFormat.decimalPattern().format(total),
            style: labelStyle?.copyWith(
              color: LatoColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// End-of-list footer: "Showing X of Y" with a Load more button, a spinner
/// while the next page loads, or a retry row if it failed.

/// One member row — avatar + center column + right column with status chip
/// and Paid/Due pill.
class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onTap});
  final Member member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expiryColor = switch (member.status) {
      'expired' => LatoColors.error,
      'expiring' => LatoColors.warning,
      _ => theme.colorScheme.onSurfaceVariant,
    };
    return Semantics(
      button: true,
      label: 'Member ${member.name}',
      child: LatoCard(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: _InitialsAvatar(member: member),
              ),
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
                      Text(
                        member.planName!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(member.phone, style: theme.textTheme.bodySmall),
                    if ((member.membershipExpiry ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Exp: ${_formatDate(member.membershipExpiry!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: expiryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusChipForMember(
                    status: member.status,
                    daysLeft: member.daysUntilExpiry,
                  ),
                  _PaymentPill(dueAmount: member.dueAmount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Display-only reformat of the server's `YYYY-MM-DD` date, e.g. `4 Oct 2026`.
  /// Falls back to the raw string if it can't be parsed.
  static String _formatDate(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    return DateFormat('d MMM yyyy').format(parsed);
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

/// Right-side badge: "Due: ₹X" in the error tint when dueAmount > 0, else
/// "PAID" in the success tint. No border, unlike [LatoStatusChip], so it reads
/// as a quieter secondary badge under the status chip.
class _PaymentPill extends StatelessWidget {
  const _PaymentPill({required this.dueAmount});
  final double dueAmount;

  @override
  Widget build(BuildContext context) {
    final isDue = dueAmount > 0;
    final color = isDue ? LatoColors.error : LatoColors.success;
    final due = formatInr(dueAmount, decimals: dueAmount % 1 == 0 ? 0 : 2);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LatoSpacing.sm,
        vertical: LatoSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: LatoColors.tint(color),
        borderRadius: BorderRadius.circular(LatoRadius.sm),
      ),
      child: Text(
        isDue ? 'Due: $due' : 'PAID',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
