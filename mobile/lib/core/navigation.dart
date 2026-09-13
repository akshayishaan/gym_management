import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The currently selected bottom-tab index (0 = Today, 1 = Members,
/// 2 = Payments, 3 = More).
///
/// Held in shared state rather than widget-local `setState` so tab-root
/// screens can deep-link to one another (e.g. the Today dashboard's "Remind"
/// action jumps to the Members tab pre-filtered to `expiring`).
final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

/// The Members list's current status filter, shared so the Today dashboard can
/// deep-link into a pre-filtered Members tab.
///
/// `null` means "no filter" (all members); any other value is a backend status
/// key (`active`, `expiring`, `expiring30`, `expired`, `due`).
final membersStatusProvider = StateProvider<String?>((ref) => null);
