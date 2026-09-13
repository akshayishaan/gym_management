import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../data/activity_providers.dart';
import '../data/filters.dart';
import '../layout/shell.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../widgets/activity_row.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_surface.dart';
import '../widgets/hide_scrollbar.dart';

/// The Activity Log drill-in screen: a paginated timeline of every action in
/// the selected gym. Ported from the web `app/dashboard/activity/page.tsx`.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  int _pages = 1;
  final List<ActivityListResponseLogsInner> _loaded = <ActivityListResponseLogsInner>[];
  bool _loadingMore = false;

  static const int _limit = 20;

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final ActivityListResponse next = await ref.read(
        activityProvider(ActivityFilters(page: _pages + 1, limit: _limit)).future,
      );
      if (mounted) {
        setState(() {
          _pages += 1;
          _loaded.addAll(next.logs);
        });
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Could not load more activity', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    final AsyncValue<ActivityListResponse> firstAsync = ref.watch(
      activityProvider(const ActivityFilters(page: 1, limit: _limit)),
    );

    ref.listen(
      activityProvider(const ActivityFilters(page: 1, limit: _limit)),
      (AsyncValue<ActivityListResponse>? prev, AsyncValue<ActivityListResponse> next) {
        if (next.hasValue && !identical(next.value, prev?.value)) {
          _loaded.clear();
          _pages = 1;
        }
      },
    );

    return AppShell(
      mode: ShellMode.stack,
      title: 'Activity Log',
      selectedIndex: 3,
      onSelectTab: (_) {},
      onBack: () => Navigator.of(context).maybePop(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: HideScrollBar(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const AppSectionLabel('Team timeline'),
                        Text(
                          '${firstAsync.valueOrNull?.total.toInt() ?? 0} total',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: t.muted.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...firstAsync.when(
                    data: (ActivityListResponse first) => _buildData(t, first),
                    loading: () => _buildLoading(t),
                    error: (Object e, StackTrace st) => _buildError(t),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildData(ThemeTokens t, ActivityListResponse first) {
    final List<ActivityListResponseLogsInner> shown =
        _loaded.isEmpty ? first.logs : <ActivityListResponseLogsInner>[
      ...first.logs,
      ..._loaded,
    ];
    final int total = first.total.toInt();
    final bool hasNext = shown.length < total;

    if (shown.isEmpty) {
      return <Widget>[
        AppSurface(
          borderRadius: BorderRadius.circular(32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: withOpacity(t.primary.value, 0.10),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.list_alt_outlined,
                  size: 28,
                  color: t.primary.value,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No activity yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: t.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Actions will appear here as they happen',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: t.muted.foreground),
              ),
            ],
          ),
        ),
      ];
    }

    return <Widget>[
      AppSurface(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < shown.length; i++) ...<Widget>[
              ActivityRow(log: shown[i], t: t),
              if (i != shown.length - 1)
                Container(height: 1, color: withOpacity(t.border, 0.58)),
            ],
          ],
        ),
      ),
      if (hasNext) ...<Widget>[
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _loadingMore ? null : _loadMore,
          child: Text(_loadingMore ? 'Loading…' : 'Load more'),
        ),
      ],
    ];
  }

  List<Widget> _buildLoading(ThemeTokens t) {
    return <Widget>[
      for (int i = 0; i < 6; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: withOpacity(t.foreground, 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildError(ThemeTokens t) {
    return <Widget>[
      AppSurface(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(Icons.error_outline, size: 32, color: t.destructive.value),
            const SizedBox(height: 12),
            Text(
              'Activity could not load',
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
              onPressed: () => ref.invalidate(
                activityProvider(const ActivityFilters(page: 1, limit: _limit)),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    ];
  }
}
