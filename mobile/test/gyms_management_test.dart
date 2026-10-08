import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/core/api/api_exception.dart';
import 'package:gym_manager/core/storage/secure_storage.dart';
import 'package:gym_manager/features/gym/application/active_gym_controller.dart';
import 'package:gym_manager/features/gym/data/gym_repository.dart';
import 'package:gym_manager/features/gym/domain/gym.dart';
import 'package:gym_manager/features/gym/domain/gym_deletion_summary.dart';
import 'package:gym_manager/features/gym/presentation/gym_form_sheet.dart';
import 'package:gym_manager/features/gym/presentation/gym_switcher_sheet.dart';
import 'package:gym_manager/features/gym/presentation/gyms_screen.dart';

class _Selected extends SelectedGymIdNotifier {
  @override
  String? build() => 'g1';

  @override
  Future<void> select(String gymId) async => state = gymId;
}

const _g1 = Gym(
  id: 'g1',
  name: 'Muscle Gym',
  address: '18 Main Road',
  primaryColor: '#C5F23F',
  currency: 'INR',
  timezone: 'Asia/Kolkata',
  expiryReminderDays: 7,
  isActive: true,
);
const _g2 = Gym(
  id: 'g2',
  name: 'Iron Works',
  primaryColor: '#C5F23F',
  currency: 'INR',
  timezone: 'Asia/Kolkata',
  expiryReminderDays: 7,
  isActive: true,
);

class _FakeRepo extends GymRepository {
  _FakeRepo() : super(Dio());

  Map<String, dynamic>? updated;
  ({String id, String name, String password})? deleted;
  ApiException? deleteError;

  @override
  Future<Gym> updateGym(String id, Map<String, dynamic> patch) async {
    updated = patch;
    return _g1;
  }

  @override
  Future<GymDeletionSummary> deletionSummary(String id) async =>
      const GymDeletionSummary(
        name: 'Muscle Gym',
        members: 1280,
        payments: 342,
        plans: 6,
        memberships: 410,
        activity: 1904,
        staff: 2,
      );

  @override
  Future<void> deleteGym(
    String id, {
    required String confirmName,
    required String password,
  }) async {
    if (deleteError != null) throw deleteError!;
    deleted = (id: id, name: confirmName, password: password);
  }
}

Widget _host(
  Widget child,
  _FakeRepo repo, {
  List<Gym> gyms = const [_g1, _g2],
}) {
  return ProviderScope(
    overrides: [
      gymRepositoryProvider.overrideWithValue(repo),
      selectedGymIdProvider.overrideWith(_Selected.new),
      userGymsProvider.overrideWith((ref) async => gyms),
    ],
    child: MaterialApp(home: child),
  );
}

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}

/// Opens [sheet] the way the app does, from a button.
Widget _opener(Widget sheet) => Builder(
  builder: (context) => Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () => showModalBottomSheet<Object>(
          context: context,
          isScrollControlled: true,
          builder: (_) =>
              FractionallySizedBox(heightFactor: 0.92, child: sheet),
        ),
        child: const Text('open'),
      ),
    ),
  ),
);

void main() {
  testWidgets('My Gyms lists gyms, marks the active one, tap switches', (
    tester,
  ) async {
    _bigScreen(tester);
    await tester.pumpWidget(_host(const GymsScreen(), _FakeRepo()));
    await tester.pumpAndSettle();

    expect(find.text('Muscle Gym'), findsOneWidget);
    expect(find.text('Iron Works'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.byTooltip('Edit Iron Works'), findsOneWidget);
    expect(find.byTooltip('Add Gym'), findsOneWidget);

    await tester.tap(find.text('Iron Works'));
    await tester.pumpAndSettle();
    expect(find.text('Switched to Iron Works'), findsOneWidget);
    // The Active chip moved to the gym we switched to.
    final chip = find.ancestor(
      of: find.text('Active'),
      matching: find.byType(Container),
    );
    expect(chip, findsWidgets);
    expect(
      find.descendant(
        of: find
            .ancestor(of: find.text('Iron Works'), matching: find.byType(Row))
            .first,
        matching: find.text('Active'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('edit: Save is disabled until a field changes', (tester) async {
    _bigScreen(tester);
    final repo = _FakeRepo();
    await tester.pumpWidget(
      _host(_opener(const GymFormSheet(existing: _g1)), repo),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    FilledButton save() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'SAVE CHANGES'),
    );
    expect(save().onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Muscle Gym'),
      'Muscle Gym 2',
    );
    await tester.pump();
    expect(save().onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'SAVE CHANGES'));
    await tester.pumpAndSettle();
    expect(repo.updated?['name'], 'Muscle Gym 2');
    expect(repo.updated?['currency'], 'INR');
    expect(find.text('Gym updated'), findsOneWidget);
  });

  testWidgets('create: name is required, no danger zone', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(_host(_opener(const GymFormSheet()), _FakeRepo()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('DANGER ZONE'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'CREATE GYM'));
    await tester.pumpAndSettle();
    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('edit: timezone picker offers a searchable list', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(
      _host(_opener(const GymFormSheet(existing: _g1)), _FakeRepo()),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('gym-timezone-field')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'tokyo');
    await tester.pumpAndSettle();
    expect(find.text('Asia/Tokyo'), findsOneWidget);
    await tester.tap(find.text('Asia/Tokyo'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('gym-timezone-field')),
        matching: find.text('Asia/Tokyo'),
      ),
      findsOneWidget,
    );
  });

  group('delete flow', () {
    Future<_FakeRepo> openDelete(WidgetTester tester) async {
      _bigScreen(tester);
      final repo = _FakeRepo();
      await tester.pumpWidget(
        _host(_opener(const GymFormSheet(existing: _g1)), repo),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Delete gym...'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Delete gym...'));
      await tester.pumpAndSettle();
      return repo;
    }

    FilledButton button(WidgetTester tester, String label) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

    testWidgets('step 1 shows counts and needs acknowledgement', (
      tester,
    ) async {
      await openDelete(tester);
      expect(find.text('Delete gym?'), findsOneWidget);
      expect(find.text('1,280'), findsOneWidget);
      expect(find.text('1,904'), findsOneWidget);
      expect(find.textContaining('1 other staff member'), findsOneWidget);
      expect(button(tester, 'CONTINUE').onPressed, isNull);

      await tester.tap(find.byKey(const Key('gym-delete-ack')));
      await tester.pump();
      expect(button(tester, 'CONTINUE').onPressed, isNotNull);
    });

    testWidgets('step 2 needs the exact name and a password', (tester) async {
      final repo = await openDelete(tester);
      await tester.tap(find.byKey(const Key('gym-delete-ack')));
      await tester.pump();
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      const label = 'DELETE GYM PERMANENTLY';
      expect(button(tester, label).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('gym-delete-name')),
        'muscle gym',
      );
      await tester.enterText(
        find.byKey(const Key('gym-delete-password')),
        'pw',
      );
      await tester.pump();
      expect(button(tester, label).onPressed, isNull, reason: 'case matters');

      await tester.enterText(
        find.byKey(const Key('gym-delete-name')),
        'Muscle Gym',
      );
      await tester.pump();
      expect(button(tester, label).onPressed, isNotNull);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(repo.deleted, (id: 'g1', name: 'Muscle Gym', password: 'pw'));
    });

    testWidgets('wrong password shows the server message and stays open', (
      tester,
    ) async {
      final repo = await openDelete(tester);
      repo.deleteError = ValidationException('Incorrect password');
      await tester.tap(find.byKey(const Key('gym-delete-ack')));
      await tester.pump();
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('gym-delete-name')),
        'Muscle Gym',
      );
      await tester.enterText(
        find.byKey(const Key('gym-delete-password')),
        'nope',
      );
      await tester.pump();
      await tester.tap(find.text('DELETE GYM PERMANENTLY'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect password'), findsOneWidget);
      expect(repo.deleted, isNull);
    });
  });

  test(
    'selecting a gym updates the active gym without a circular error',
    () async {
      final store = _MemoryStore();
      final repo = _FakeRepo();
      final container = ProviderContainer(
        overrides: [
          secureStoreProvider.overrideWithValue(store),
          gymRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Keep the active-gym provider alive, as the app does.
      container.listen(activeGymProvider, (_, _) {});
      await container.read(selectedGymIdProvider.notifier).select('g2');
      expect(container.read(selectedGymIdProvider), 'g2');
      expect(store.selected, 'g2');

      await container.read(selectedGymIdProvider.notifier).clear();
      expect(container.read(selectedGymIdProvider), isNull);
    },
  );
}

class _MemoryStore extends SecureStore {
  _MemoryStore() : super(const FlutterSecureStorage());
  String? selected;

  @override
  Future<void> writeSelectedGymId(String id) async => selected = id;

  @override
  Future<String?> readSelectedGymId() async => selected;

  @override
  Future<void> clearSelectedGymIdFallback() async => selected = null;
}
