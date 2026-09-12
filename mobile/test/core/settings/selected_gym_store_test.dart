import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/settings/selected_gym_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('write then read round-trips the id', () async {
    final SharedPrefsSelectedGymStore store = SharedPrefsSelectedGymStore();

    await store.write('abc');

    expect(await store.read(), 'abc');
  });

  test('write(null) clears the persisted id', () async {
    final SharedPrefsSelectedGymStore store = SharedPrefsSelectedGymStore();

    await store.write('abc');
    await store.write(null);

    expect(await store.read(), isNull);
  });
}
