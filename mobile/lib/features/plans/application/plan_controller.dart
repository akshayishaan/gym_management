import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/plan_repository.dart';
import '../domain/plan.dart';

/// Controller state shared by the create / update / activate notifiers.
class PlanMutationState {
  const PlanMutationState({this.loading = false, this.lastError});
  final bool loading;
  final Object? lastError;

  PlanMutationState copyWith({bool? loading, Object? lastError}) {
    return PlanMutationState(
      loading: loading ?? this.loading,
      lastError: lastError,
    );
  }
}

/// `POST /plans`. On success, invalidates the paginated list so the
/// new row appears immediately.
class PlanCreateController
    extends AutoDisposeNotifier<PlanMutationState> {
  @override
  PlanMutationState build() => const PlanMutationState();

  Future<Plan> create(PlanCreateInput input) async {
    state = const PlanMutationState(loading: true);
    try {
      final created = await ref.read(planRepositoryProvider).createPlan(input);
      ref.invalidate(planListProvider);
      state = const PlanMutationState();
      return created;
    } catch (e) {
      state = PlanMutationState(lastError: e);
      rethrow;
    }
  }
}

final planCreateControllerProvider =
    AutoDisposeNotifierProvider<PlanCreateController, PlanMutationState>(
  PlanCreateController.new,
);

/// `PUT /plans/:id`. On success, invalidates the list so the edited row
/// reflects the new values. There is no per-id detail provider — the
/// edit sheet is populated from the list cache, not from a separate
/// fetch.
class PlanUpdateController
    extends AutoDisposeNotifier<PlanMutationState> {
  @override
  PlanMutationState build() => const PlanMutationState();

  Future<Plan> update(String id, PlanUpdateInput input) async {
    state = const PlanMutationState(loading: true);
    try {
      final updated =
          await ref.read(planRepositoryProvider).updatePlan(id, input);
      ref.invalidate(planListProvider);
      state = const PlanMutationState();
      return updated;
    } catch (e) {
      state = PlanMutationState(lastError: e);
      rethrow;
    }
  }
}

final planUpdateControllerProvider =
    AutoDisposeNotifierProvider<PlanUpdateController, PlanMutationState>(
  PlanUpdateController.new,
);

/// Active-state toggle. The backend has no DELETE on plans, so
/// deactivation is a `PUT /plans/:id` with `{isActive: bool}`. On
/// success, invalidates the list so the row's card chip + stat
/// columns refresh.
class PlanDeactivateController
    extends AutoDisposeNotifier<PlanMutationState> {
  @override
  PlanMutationState build() => const PlanMutationState();

  Future<void> setActive(String id, bool isActive) async {
    state = const PlanMutationState(loading: true);
    try {
      await ref.read(planRepositoryProvider).updatePlan(
            id,
            PlanUpdateInput(isActive: isActive),
          );
      ref.invalidate(planListProvider);
      state = const PlanMutationState();
    } catch (e) {
      state = PlanMutationState(lastError: e);
      rethrow;
    }
  }
}

final planDeactivateControllerProvider =
    AutoDisposeNotifierProvider<PlanDeactivateController, PlanMutationState>(
  PlanDeactivateController.new,
);