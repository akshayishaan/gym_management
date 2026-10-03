import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../data/gym_repository.dart';
import '../domain/gym.dart';

/// The id of the staff's currently-selected Gym. Synchronous because we
/// hydrate it eagerly from secure storage; the actual [Gym] resolution
/// lives in [activeGymProvider] so it can be async.
class SelectedGymIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    final store = ref.watch(secureStoreProvider);
    // Fire-and-forget hydration; the router waits on the auth controller
    // rather than on this provider, so we don't block here.
    Future.microtask(() async {
      state = await store.readSelectedGymId();
    });
    return null;
  }

  Future<void> select(String gymId) async {
    final store = ref.read(secureStoreProvider);
    await store.writeSelectedGymId(gymId);
    state = gymId;
    // Invalidate the resolved gym so the active-gym provider re-fetches.
    ref.invalidate(activeGymProvider);
  }

  Future<void> clear() async {
    final store = ref.read(secureStoreProvider);
    await store.clearSelectedGymIdFallback();
    state = null;
    ref.invalidate(activeGymProvider);
  }
}

final selectedGymIdProvider =
    NotifierProvider<SelectedGymIdNotifier, String?>(SelectedGymIdNotifier.new);

/// Resolves the currently-selected Gym from the backend. Re-fetches when
/// [selectedGymIdProvider] changes.
final activeGymProvider = FutureProvider<Gym?>((ref) async {
  final gymId = ref.watch(selectedGymIdProvider);
  if (gymId == null) return null;
  final repo = ref.watch(gymRepositoryProvider);
  try {
    return await repo.getGym(gymId);
  } catch (_) {
    // If the gym has been deleted server-side, fall back to null. The
    // router will route the user back to the picker.
    return null;
  }
});