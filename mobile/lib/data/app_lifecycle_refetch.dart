import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/dio_providers.dart';
import 'query_scope.dart';

/// Observes the app lifecycle and refetches stale gym-scoped data on resume.
///
/// Phase 3 mounts this at the app root; it renders its [child] unchanged.
class AppLifecycleRefetch extends ConsumerStatefulWidget {
  const AppLifecycleRefetch({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLifecycleRefetch> createState() =>
      _AppLifecycleRefetchState();
}

class _AppLifecycleRefetchState extends ConsumerState<AppLifecycleRefetch>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final String? gymId = ref.read(selectedGymIdProvider);
    if (gymId == null) return;

    final ScopeLastFetch notifier = ref.read(scopeLastFetchProvider.notifier);
    if (!notifier.isStale(gymId, defaultStaleTime)) return;

    ref.read(appResumeTickProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
