import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_providers.dart';
import 'dashboard_providers.dart';
import 'gym_providers.dart';
import 'member_providers.dart';
import 'membership_providers.dart';
import 'payment_providers.dart';
import 'plan_providers.dart';
import 'report_providers.dart';

/// How long a gym's scoped data is considered fresh before a resume refetches
/// it.
const Duration defaultStaleTime = Duration(minutes: 5);

/// A monotonically increasing tick. Gym-scoped providers watch this; bumping it
/// (e.g. on app resume when data is stale) refetches every live scoped
/// provider.
final appResumeTickProvider = StateProvider<int>((ref) => 0);

/// Tracks the last successful fetch time per gym id, keyed by `gymId`.
class ScopeLastFetch extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => <String, DateTime>{};

  void touch(String gymId) {
    state = <String, DateTime>{...state, gymId: DateTime.now()};
  }

  bool isStale(String gymId, Duration staleTime) {
    final DateTime? lastFetch = state[gymId];
    return lastFetch == null ||
        DateTime.now().difference(lastFetch) > staleTime;
  }
}

final scopeLastFetchProvider =
    NotifierProvider<ScopeLastFetch, Map<String, DateTime>>(
  ScopeLastFetch.new,
);

/// Invalidates every gym-scoped family for the selected gym.
///
/// Relies on `ref.invalidate(family)` which, in riverpod 2.6.1, invalidates
/// all currently-alive instances of a family (see `container.invalidate`).
void invalidateGymScope(Ref ref) {
  ref.invalidate(dashboardProvider);
  ref.invalidate(membersProvider);
  ref.invalidate(memberProvider);
  ref.invalidate(membershipsProvider);
  ref.invalidate(paymentsProvider);
  ref.invalidate(plansProvider);
  ref.invalidate(reportsProvider);
  ref.invalidate(activityProvider);
}

/// Invalidates the (non-gym-scoped) gyms list.
void invalidateGyms(Ref ref) {
  ref.invalidate(gymsProvider);
}
