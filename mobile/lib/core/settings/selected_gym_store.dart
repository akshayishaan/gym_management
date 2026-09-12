import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence boundary for the last-selected gym id — the Flutter equivalent
/// of the web app's `selectedGymId` cookie.
abstract class SelectedGymStore {
  Future<String?> read();

  Future<void> write(String? id);
}

/// [SelectedGymStore] backed by `shared_preferences` under the key
/// `'selectedGymId'`.
class SharedPrefsSelectedGymStore implements SelectedGymStore {
  static const String _key = 'selectedGymId';

  @override
  Future<String?> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> write(String? id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, id);
    }
  }
}

/// The app's [SelectedGymStore]. Overridden with an in-memory fake in tests.
final selectedGymStoreProvider = Provider<SelectedGymStore>(
  (ref) => SharedPrefsSelectedGymStore(),
);
