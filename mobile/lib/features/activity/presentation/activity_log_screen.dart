// Phase 8 Track B — Activity Log & Audit Trail. Mirrors the Figma
// `activity_log.png`. Filtering is client-side because `GET /activity`
// does not accept action query params.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_empty_state.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_loading.dart';
import '../../../design/spacing.dart';
import '../data/activity_repository.dart';
import '../domain/activity_log.dart';
import '../domain/activity_log_query.dart';
import 'activity_event_card.dart';
import 'activity_styles.dart';

/// "Today" / "Past 7 Days" / "Custom" pill in the timeframe toggle.
enum _Timeframe { today, week, custom }

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  /// Selected action chips. `{'all'}` = no filtering; any other value is
  /// the set of [ActionType] strings the user has toggled on.
  Set<String> _selectedActions = {'all'};

  _Timeframe _timeframe = _Timeframe.today;

  /// Page size currently loaded. Doubles on every "Load More" press until
  /// it matches the backend-reported total.
  int _pageLimit = 50;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = ActivityLogQuery(limit: _pageLimit);
    final async = ref.watch(activityLogProvider(query));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Activity Log',
          style: theme.textTheme.headlineSmall?.copyWith(color: Alog.titleBg),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Alog.titleBg),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Filter coming soon')),
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LatoLoading(),
        error: (err, _) => LatoErrorState(
          message: err is ApiException
              ? err.message
              : 'Could not load activity log.',
          onRetry: () => ref.invalidate(activityLogProvider(query)),
        ),
        data: (page) => _ActivityContent(
          page: page,
          selectedActions: _selectedActions,
          timeframe: _timeframe,
          onToggleTimeframe: (t) => setState(() => _timeframe = t),
          onToggleAction: _onToggleAction,
          onLoadMore: () {
            final next = (_pageLimit + 50).clamp(1, page.total);
            if (next == _pageLimit) return;
            setState(() => _pageLimit = next);
          },
        ),
      ),
    );
  }

  void _onToggleAction(String key) {
    setState(() {
      if (key == 'all') {
        _selectedActions = {'all'};
        return;
      }
      final next = Set<String>.from(_selectedActions);
      next.remove('all');
      if (next.contains(key)) {
        next.remove(key);
      } else {
        next.add(key);
      }
      if (next.isEmpty) next.add('all');
      _selectedActions = next;
    });
  }
}

/// Top KPI strip card + filter row + grouped timeline + Load More footer.
class _ActivityContent extends StatelessWidget {
  const _ActivityContent({
    required this.page,
    required this.selectedActions,
    required this.timeframe,
    required this.onToggleTimeframe,
    required this.onToggleAction,
    required this.onLoadMore,
  });

  final ActivityLogPage page;
  final Set<String> selectedActions;
  final _Timeframe timeframe;
  final ValueChanged<_Timeframe> onToggleTimeframe;
  final ValueChanged<String> onToggleAction;
  final VoidCallback onLoadMore;

  bool _matchesTimeframe(ActivityLog log) {
    final ts = log.createdAt;
    if (ts == null) return true; // include undated logs in all timeframes
    final now = DateTime.now();
    final local = ts.toLocal();
    switch (timeframe) {
      case _Timeframe.today:
        return local.year == now.year &&
            local.month == now.month &&
            local.day == now.day;
      case _Timeframe.week:
        final cutoff = now.subtract(const Duration(days: 7));
        return local.isAfter(cutoff);
      case _Timeframe.custom:
        // Custom timeframe is not implemented — fall through to "all time"
        // so the user still sees their data instead of an empty screen.
        return true;
    }
  }

  bool _matchesAction(ActivityLog log) {
    if (selectedActions.length == 1 && selectedActions.contains('all')) {
      return true;
    }
    return selectedActions.contains(log.action);
  }

  List<ActivityLog> get _filtered {
    return page.logs
        .where(_matchesAction)
        .where(_matchesTimeframe)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final grouped = _groupByDay(filtered);
    final hasMore = page.logs.length < page.total;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        LatoSpacing.xl,
        64,
        LatoSpacing.xl,
        96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KpiStrip(total: filtered.length),
          const SizedBox(height: LatoSpacing.lg),
          _TimeframeToggle(
            current: timeframe,
            onChanged: onToggleTimeframe,
          ),
          const SizedBox(height: LatoSpacing.md),
          _ActionFilterChips(
            selected: selectedActions,
            onToggle: onToggleAction,
          ),
          const SizedBox(height: LatoSpacing.lg),
          if (filtered.isEmpty)
            const _Empty()
          else
            for (final entry in grouped) ...[
              _Section(dayKey: entry.key, logs: entry.value),
              const SizedBox(height: LatoSpacing.lg),
            ],
          _LoadMoreFooter(
            showing: filtered.length,
            total: page.total,
            hasMore: hasMore,
            onLoadMore: onLoadMore,
          ),
        ],
      ),
    );
  }

  /// Group filtered logs into a Map keyed by `dayKey` with the day-keys
  /// already in descending order (so "Today" comes first). Logs without a
  /// `createdAt` are bucketed under an empty key at the end.
  List<MapEntry<String, List<ActivityLog>>> _groupByDay(
    List<ActivityLog> logs,
  ) {
    if (logs.isEmpty) return const [];
    final sorted = [...logs]
      ..sort((a, b) {
        final ta = a.createdAt;
        final tb = b.createdAt;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });
    final byDay = <String, List<ActivityLog>>{};
    for (final log in sorted) {
      byDay.putIfAbsent(log.dayKey, () => <ActivityLog>[]).add(log);
    }
    final keys = byDay.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty) return 1;
        if (b.isEmpty) return -1;
        return b.compareTo(a);
      });
    return [for (final k in keys) MapEntry(k, byDay[k]!)];
  }
}

/// "OPERATIONS LOGS" + total + "recorded today" header card.
class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return LatoCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OPERATIONS LOGS', style: Alog.eyebrow),
          const SizedBox(height: LatoSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                NumberFormat.decimalPattern().format(total),
                style: Alog.bigNumber,
              ),
              const SizedBox(width: 6),
              const Text('recorded today', style: Alog.sage12),
            ],
          ),
        ],
      ),
    );
  }
}

/// 3-button segmented toggle: Today / Past 7 Days / Custom.
class _TimeframeToggle extends StatelessWidget {
  const _TimeframeToggle({
    required this.current,
    required this.onChanged,
  });
  final _Timeframe current;
  final ValueChanged<_Timeframe> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Alog.railTrackBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Alog.pillBg),
      ),
      child: Row(
        children: [
          for (final t in _Timeframe.values)
            Expanded(
              child: _TimeframeButton(
                label: _label(t),
                selected: t == current,
                onTap: () => onChanged(t),
              ),
            ),
        ],
      ),
    );
  }

  String _label(_Timeframe t) {
    switch (t) {
      case _Timeframe.today:
        return 'Today';
      case _Timeframe.week:
        return 'Past 7 Days';
      case _Timeframe.custom:
        return 'Custom';
    }
  }
}

class _TimeframeButton extends StatelessWidget {
  const _TimeframeButton({
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
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Alog.pillBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? LatoColors.primary
                  : Alog.sage,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontally-scrolling action filter pills. `All` is rendered first
/// and uses the solid-lime treatment; everything else is the bordered
/// neutral pill. Order matches the Figma.
class _ActionFilterChips extends StatelessWidget {
  const _ActionFilterChips({
    required this.selected,
    required this.onToggle,
  });
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  static const List<({String key, String label})> _entries = [
    (key: 'all', label: 'All'),
    (key: ActionType.created, label: 'Created'),
    (key: ActionType.updated, label: 'Updated'),
    (key: ActionType.voided, label: 'Voided'),
    (key: ActionType.refunded, label: 'Refunded'),
    (key: ActionType.reversed, label: 'Reversed'),
    (key: ActionType.deleted, label: 'Deleted'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _entries.length; i++) ...[
              if (i > 0) const SizedBox(width: LatoSpacing.sm),
              _ActionChip(
                label: _entries[i].label,
                isAll: _entries[i].key == 'all',
                selected:
                    _entries[i].key == 'all' ? selected.contains('all') : selected.contains(_entries[i].key),
                onTap: () => onToggle(_entries[i].key),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.isAll,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool isAll;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSolidAll = isAll && selected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
          decoration: BoxDecoration(
            color: isSolidAll ? Alog.allChipBg : Alog.pillBg,
            borderRadius: BorderRadius.circular(999),
            border: isSolidAll ? null : Border.all(color: Alog.pillBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSolidAll ? Alog.allChipFg : Alog.titleFg,
              fontSize: 12,
              fontWeight: isSolidAll ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// One day group: sticky date header + vertical rail + list of event cards.
class _Section extends StatelessWidget {
  const _Section({required this.dayKey, required this.logs});
  final String dayKey;
  final List<ActivityLog> logs;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = dayKey == _dayKey(today);
    final isYesterday =
        dayKey == _dayKey(today.subtract(const Duration(days: 1)));
    final headerLabel = _dayHeaderLabel(
      dayKey: dayKey,
      isToday: isToday,
      isYesterday: isYesterday,
    );
    final eventCount = logs.length;
    final eventWord = eventCount == 1 ? 'event' : 'events';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sticky date header
        Container(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 9),
          decoration: const BoxDecoration(
            color: Alog.railHeaderBg,
            border: Border(
              bottom: BorderSide(color: Alog.railHeaderBorder, width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isToday ? LatoColors.primary : Alog.pastDot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: LatoSpacing.sm),
              Expanded(
                child: Text(headerLabel, style: Alog.dateHeader),
              ),
              Text('$eventCount $eventWord', style: Alog.sage13),
            ],
          ),
        ),
        const SizedBox(height: LatoSpacing.lg),
        // Rail + cards
        for (var i = 0; i < logs.length; i++) ...[
          ActivityEventCard(log: logs[i]),
          if (i < logs.length - 1) const SizedBox(height: LatoSpacing.lg),
        ],
      ],
    );
  }

  static String _dayKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }
}

/// "Today - Oct 28, 2024" / "Yesterday - Oct 27, 2024" / "Oct 26, 2024".
String _dayHeaderLabel({
  required String dayKey,
  required bool isToday,
  required bool isYesterday,
}) {
  if (isToday) return 'Today - ${DateFormat.yMMMd().format(DateTime.now())}';
  if (isYesterday) {
    return 'Yesterday - '
        '${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 1)))}';
  }
  final parts = dayKey.split('-');
  if (parts.length != 3) return dayKey;
  final parsed = DateTime(
    int.tryParse(parts[0]) ?? 0,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[2]) ?? 1,
  );
  return DateFormat.yMMMd().format(parsed);
}

/// "Load More Events" button + "Showing X of Y events" caption.
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.showing,
    required this.total,
    required this.hasMore,
    required this.onLoadMore,
  });
  final int showing;
  final int total;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final canLoad = hasMore;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, LatoSpacing.lg, 0, LatoSpacing.xxxl),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Alog.footerBg,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: canLoad ? onLoadMore : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Alog.pillBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 16,
                        color: canLoad
                            ? LatoColors.primary
                            : LatoColors.textTertiaryDark,
                      ),
                      const SizedBox(width: LatoSpacing.sm),
                      Text(
                        'Load More Events',
                        style: canLoad ? Alog.loadMore : Alog.loadMoreDim,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: LatoSpacing.sm),
          Text(
            'Showing $showing of $total events',
            style: Alog.showingCount,
          ),
        ],
      ),
    );
  }
}

/// Empty state for "no logs match the current filter".
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: LatoSpacing.xl),
      child: LatoEmptyState(
        icon: Icons.history_toggle_off,
        title: 'No activity recorded',
        body: 'There are no events matching this filter yet.',
      ),
    );
  }
}