import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/design/components/lato_sheet.dart';

Widget _host() {
  return MaterialApp(
    home: Scaffold(
      body: LatoFormSheetScaffold(
        title: 'Add Member',
        // Much taller than the 600px test screen.
        body: Column(
          children: [
            for (var i = 0; i < 40; i++)
              SizedBox(height: 60, child: Text('Field $i')),
          ],
        ),
        footer: ElevatedButton(onPressed: () {}, child: const Text('Save')),
      ),
    ),
  );
}

void main() {
  testWidgets('footer button is on screen without scrolling a long form', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final save = tester.getRect(find.text('Save'));
    expect(save.bottom, lessThanOrEqualTo(screen.height));
    expect(save.top, greaterThanOrEqualTo(0));
    expect(find.text('Add Member'), findsOneWidget);
  });

  testWidgets('footer stays put while the body scrolls', (tester) async {
    await tester.pumpWidget(_host());
    final before = tester.getRect(find.text('Save'));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();

    // The body scrolled (its first field moved off the top)...
    expect(tester.getRect(find.text('Field 0')).bottom, lessThan(0));
    // ...but the footer did not move.
    expect(tester.getRect(find.text('Save')), before);
  });

  testWidgets('footer rides above the keyboard', (tester) async {
    await tester.pumpWidget(_host());
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    tester.view.viewInsets = FakeViewPadding(
      bottom: 300 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    final save = tester.getRect(find.text('Save'));
    expect(save.bottom, lessThanOrEqualTo(screen.height - 300));
  });
}
