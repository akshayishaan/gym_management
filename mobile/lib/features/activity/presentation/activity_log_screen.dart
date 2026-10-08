// Activity Log & Audit Trail. Date range and action filters are applied by the
// server in the Gym's own timezone (`GET /activity?range=&from=&to=&actions=`),
// so counts and paging are always for the filter the user sees.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/router/back_navigation.dart';
import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_empty_state.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_skeleton.dart';
import '../../../design/components/lato_status_chip.dart';
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

  /// Range chosen with the date picker (used when [_timeframe] is custom).
  DateTimeRange? _customRange;

  /// Page size currently loaded. Grows on every "Load More" press.
  int _pageLimit = 50;

  /// The last page shown, kept on screen while a Load More request is in
  /// flight. [_lastKey] is the filter it belongs to.
  ActivityLogPage? _lastPage;
  String? _lastKey;

  ActivityLogQuery get _query {
    final actions = _selectedActions.contains('all')
        ? null
        : Set<String>.from(_selectedActions);
    switch (_timeframe) {
      case _Timeframe.today:
        return ActivityLogQuery(
          range: 'today',
          actions: actions,
          limit: _pageLimit,
        );
      case _Timeframe.week:
        return ActivityLogQuery(
          range: 'week',
          actions: actions,
          limit: _pageLimit,
        );
      case _Timeframe.custom:
        final r = _customRange;
        return ActivityLogQuery(
          from: r == null ? null : _dateOnly(r.start),
          to: r == null ? null : _dateOnly(r.end),
          actions: actions,
          limit: _pageLimit,
        );
    }
  }

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  Future<void> _onTimeframe(_Timeframe t) async {
    if (t == _Timeframe.custom) {
      final today = _lastPage?.today;
      final last = today == null
          ? DateTime.now()
          : (DateTime.tryParse(today) ?? DateTime.now());
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: last,
        initialDateRange: _customRange,
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: LatoColors.primary,
              onPrimary: LatoColors.bgDark,
              surface: LatoColors.surfaceDark,
              onSurface: LatoColors.textPrimaryDark,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      );
      if (picked == null || !mounted) return; // keep the previous timeframe
      setState(() {
        _customRange = picked;
        _timeframe = _Timeframe.custom;
        _pageLimit = 50;
      });
      return;
    }
    if (t == _timeframe) return;
    setState(() {
      _timeframe = t;
      _pageLimit = 50;
    });
  }

  void _onToggleAction(String key) {
    setState(() {
      _pageLimit = 50;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query;
    final async = ref.watch(activityLogProvider(query));

    final fresh = async.valueOrNull;
    if (fresh != null) {
      _lastPage = fresh;
      _lastKey = query.filterKey;
    }
    // While a different filter loads, show the screen with skeleton cards
    // instead of replacing it with a spinner. While more rows of the same
    // filter load, keep the rows already shown.
    final shown = fresh ?? (_lastKey == query.filterKey ? _lastPage : null);
    final switching = async.isLoading && shown == null && _lastPage != null;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrGo(context, kMoreMenuRoute),
        ),
        title: Text('Activity Log', style: theme.textTheme.headlineSmall),
      ),
      body: _body(async, query, shown, switching),
    );
  }

  Widget _body(
    AsyncValue<ActivityLogPage> async,
    ActivityLogQuery query,
    ActivityLogPage? shown,
    bool switching,
  ) {
    if (shown != null || switching) {
      return _ActivityContent(
        page: shown ?? _lastPage!,
        loading: switching,
        selectedActions: _selectedActions,
        timeframe: _timeframe,
        customRange: _customRange,
        onTimeframe: _onTimeframe,
        onToggleAction: _onToggleAction,
        onLoadMore: () {
          final page = shown;
          if (page == null) return;
          setState(() => _pageLimit = _pageLimit + 50);
        },
      );
    }
    return async.when(
      loading: () => const _ActivityPageSkeleton(),
      error: (err, _) => LatoErrorState(
        message: err is ApiException
            ? err.message
            : 'Could not load activity log.',
        onRetry: () => ref.invalidate(activityLogProvider(query)),
      ),
      data: (_) => const SizedBox.shrink(),
    );
  }
}

/// Top KPI strip card + filter row + grouped timeline + Load More footer.
class _ActivityContent extends StatelessWidget {
  const _ActivityContent({
    required this.page,
    required this.loading,
    required this.selectedActions,
    required this.timeframe,
    required this.customRange,
    required this.onTimeframe,
    required this.onToggleAction,
    required this.onLoadMore,
  });

  final ActivityLogPage page;

  /// A different filter is loading: show skeleton rows in the list area.
  final bool loading;
  final Set<String> selectedActions;
  final _Timeframe timeframe;
  final DateTimeRange? customRange;
  final ValueChanged<_Timeframe> onTimeframe;
  final ValueChanged<String> onToggleAction;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay(page.logs);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        LatoSpacing.xl,
        LatoSpacing.sm,
        LatoSpacing.xl,
        LatoSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KpiStrip(
            total: loading ? null : page.total,
            caption: _caption(timeframe, page.total),
          ),
          const SizedBox(height: LatoSpacing.lg),
          _TimeframeToggle(current: timeframe, onChanged: onTimeframe),
          if (timeframe == _Timeframe.custom && customRange != null)
            Padding(
              padding: const EdgeInsets.only(top: LatoSpacing.sm),
              child: Text(
                _rangeLabel(customRange!),
                style: Alog.sage12,
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: LatoSpacing.sm),
          _ActionFilterChips(
            selected: selectedActions,
            onToggle: onToggleAction,
          ),
          const SizedBox(height: LatoSpacing.md),
          if (loading)
            const _ActivitySkeleton()
          else if (page.logs.isEmpty)
            const _Empty()
          else ...[
            for (final entry in grouped) ...[
              _Section(dayKey: entry.key, logs: entry.value, today: page.today),
              const SizedBox(height: LatoSpacing.lg),
            ],
            _LoadMoreFooter(
              showing: page.logs.length,
              total: page.total,
              hasMore: page.logs.length < page.total,
              onLoadMore: onLoadMore,
            ),
          ],
        ],
      ),
    );
  }

  static String _caption(_Timeframe t, int total) {
    final noun = total == 1 ? 'event' : 'events';
    switch (t) {
      case _Timeframe.today:
        return '$noun today';
      case _Timeframe.week:
        return '$noun in the last 7 days';
      case _Timeframe.custom:
        return '$noun in this range';
    }
  }

  static String _rangeLabel(DateTimeRange r) {
    final s = r.start;
    final e = r.end;
    if (s.year == e.year && s.month == e.month && s.day == e.day) {
      return DateFormat('d MMM y').format(s);
    }
    final startFmt = s.year == e.year
        ? DateFormat('d MMM')
        : DateFormat('d MMM y');
    return '${startFmt.format(s)} – ${DateFormat('d MMM y').format(e)}';
  }

  /// Group logs into days, newest first. Logs without a day go last.
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

/// "ACTIVITY" + event count for the selected range.
class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.total, required this.caption});

  /// Null while a different filter is loading.
  final int? total;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return LatoCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACTIVITY', style: Alog.eyebrow),
          const SizedBox(height: LatoSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                total == null
                    ? '–'
                    : NumberFormat.decimalPattern('en_IN').format(total),
                style: Alog.bigNumber,
              ),
              const SizedBox(width: 6),
              Flexible(child: Text(caption, style: Alog.sage12)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 3-button segmented toggle: Today / Past 7 Days / Custom.
class _TimeframeToggle extends StatelessWidget {
  const _TimeframeToggle({required this.current, required this.onChanged});
  final _Timeframe current;
  final ValueChanged<_Timeframe> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: LatoColors.bgDark,
        borderRadius: BorderRadius.circular(LatoRadius.md),
        border: Border.all(color: LatoColors.borderDark),
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
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(LatoRadius.sm),
          onTap: onTap,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Alog.pillBg : Colors.transparent,
              borderRadius: BorderRadius.circular(LatoRadius.sm),
              border: Border.all(
                color: selected
                    ? LatoColors.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? LatoColors.primary
                    : LatoColors.textSecondaryDark,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontally-scrolling action filter pills. Selected = lime, otherwise
/// neutral (same look as the Payments and Members filters).
class _ActionFilterChips extends StatelessWidget {
  const _ActionFilterChips({required this.selected, required this.onToggle});
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
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: LatoSpacing.sm),
        itemBuilder: (context, i) {
          final e = _entries[i];
          final isSelected = selected.contains(e.key);
          return Semantics(
            button: true,
            selected: isSelected,
            child: InkWell(
              borderRadius: LatoRadius.chip,
              onTap: () => onToggle(e.key),
              child: Center(
                child: LatoStatusChip(
                  label: e.label,
                  tone: isSelected
                      ? LatoChipTone.primary
                      : LatoChipTone.neutral,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One day group: date header + vertical rail + list of event cards.
class _Section extends StatelessWidget {
  const _Section({
    required this.dayKey,
    required this.logs,
    required this.today,
  });
  final String dayKey;
  final List<ActivityLog> logs;

  /// The Gym's current date from the server (null on very old servers).
  final String? today;

  @override
  Widget build(BuildContext context) {
    final isToday = today != null && dayKey == today;
    final isYesterday = today != null && dayKey == _shift(today!, -1);
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
              Expanded(child: Text(headerLabel, style: Alog.dateHeader)),
              Text('$eventCount $eventWord', style: Alog.sage13),
            ],
          ),
        ),
        const SizedBox(height: LatoSpacing.lg),
        for (var i = 0; i < logs.length; i++) ...[
          ActivityEventCard(log: logs[i]),
          if (i < logs.length - 1) const SizedBox(height: LatoSpacing.lg),
        ],
      ],
    );
  }

  /// Calendar arithmetic on a `YYYY-MM-DD` string (no clock involved).
  static String _shift(String day, int days) {
    final d = DateTime.tryParse(day);
    if (d == null) return '';
    final s = DateTime(d.year, d.month, d.day + days);
    final y = s.year.toString().padLeft(4, '0');
    final m = s.month.toString().padLeft(2, '0');
    final dd = s.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }
}

/// "Today, 8 Oct 2026" / "Yesterday, 7 Oct 2026" / "6 Oct 2026".
String _dayHeaderLabel({
  required String dayKey,
  required bool isToday,
  required bool isYesterday,
}) {
  final parsed = DateTime.tryParse(dayKey);
  if (parsed == null) return dayKey.isEmpty ? 'Undated' : dayKey;
  final date = DateFormat('d MMM y').format(parsed);
  if (isToday) return 'Today, $date';
  if (isYesterday) return 'Yesterday, $date';
  return date;
}

/// "Load More Events" (only when there is more) + "Showing X of Y events".
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
    return Column(
      children: [
        if (hasMore)
          SizedBox(
            width: double.infinity,
            height: LatoSizes.button,
            child: OutlinedButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Load More Events'),
            ),
          ),
        if (hasMore) const SizedBox(height: LatoSpacing.sm),
        Text('Showing $showing of $total events', style: Alog.showingCount),
      ],
    );
  }
}

/// Placeholder cards while a different filter loads.
/// First-load placeholder for the whole page (no response yet): KPI strip,
/// timeframe toggle, action chips and the timeline cards.
class _ActivityPageSkeleton extends StatelessWidget {
  const _ActivityPageSkeleton();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SingleChildScrollView(
        key: const Key('activity-page-skeleton'),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          LatoSpacing.xl,
          LatoSpacing.sm,
          LatoSpacing.xl,
          LatoSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LatoSkeletonBlock(height: 96, radius: LatoRadius.lg),
            const SizedBox(height: LatoSpacing.lg),
            const LatoSkeletonBlock(height: 44, radius: LatoRadius.pill),
            const SizedBox(height: LatoSpacing.sm),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  LatoSkeletonBlock(width: 72, height: 36, radius: LatoRadius.pill),
                  SizedBox(width: LatoSpacing.sm),
                  LatoSkeletonBlock(width: 88, height: 36, radius: LatoRadius.pill),
                  SizedBox(width: LatoSpacing.sm),
                  LatoSkeletonBlock(width: 88, height: 36, radius: LatoRadius.pill),
                  SizedBox(width: LatoSpacing.sm),
                  LatoSkeletonBlock(width: 88, height: 36, radius: LatoRadius.pill),
                ],
              ),
            ),
            const SizedBox(height: LatoSpacing.md),
            const _ActivitySkeleton(),
          ],
        ),
      ),
    );
  }
}

class _ActivitySkeleton extends StatelessWidget {
  const _ActivitySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('activity-skeleton'),
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 112,
            decoration: BoxDecoration(
              color: LatoColors.surfaceDark,
              borderRadius: LatoRadius.card,
              border: Border.all(color: LatoColors.borderDark),
            ),
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(140, 12),
                const SizedBox(height: 14),
                _block(200, 16),
                const SizedBox(height: 10),
                _block(double.infinity, 12),
              ],
            ),
          ),
          const SizedBox(height: LatoSpacing.lg),
        ],
      ],
    );
  }

  static Widget _block(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: LatoColors.surfaceRaisedDark,
      borderRadius: BorderRadius.circular(4),
    ),
  );
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
        body: 'There are no events matching this filter.',
      ),
    );
  }
}
