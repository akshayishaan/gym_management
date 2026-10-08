import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/plans/presentation/plan_form_sheet.dart';

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      child: const MaterialApp(home: Scaffold(body: PlanFormSheet())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('required labels, rupee prefix and quick pick', (tester) async {
    await _open(tester);

    expect(find.text('*'), findsNWidgets(3)); // Name, Duration, Price
    expect(find.text('Price'), findsOneWidget);
    expect(find.text('₹'), findsOneWidget);
    expect(find.text('Quick pick'), findsOneWidget);

    await tester.tap(find.text('90d'));
    await tester.pump();
    expect(find.text('90'), findsOneWidget);
  });

  testWidgets('features add, reject duplicates and remove', (tester) async {
    await _open(tester);

    Future<void> add(String text) async {
      await tester.enterText(find.byType(TextField).last, text);
      await tester.tap(find.byTooltip('Add feature'));
      await tester.pump();
    }

    await add('Sauna');
    expect(find.bySemanticsLabel('Remove Sauna'), findsOneWidget);
    await add('Sauna');
    expect(find.text('Already added'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Remove Sauna'));
    await tester.pump();
    expect(find.bySemanticsLabel('Remove Sauna'), findsNothing);
  });

  testWidgets('Active plan is a switch inside a card', (tester) async {
    await _open(tester);

    expect(find.byType(Checkbox), findsNothing);
    final sw = find.byType(Switch);
    expect(tester.widget<Switch>(sw).value, isTrue);
    await tester.tap(find.text('Active plan'));
    await tester.pump();
    expect(tester.widget<Switch>(sw).value, isFalse);
  });
}
