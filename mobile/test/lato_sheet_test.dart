import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/design/components/lato_sheet.dart';

Widget _host({required bool form}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () {
              Widget body(BuildContext _) => const Material(
                color: Color(0xFF141414), // opaque child, like the forms
                child: Column(
                  children: [
                    LatoSheetTitle('Add Member'),
                    Expanded(child: SizedBox.shrink()),
                  ],
                ),
              );
              if (form) {
                showLatoFormSheet<void>(context: context, builder: body);
              } else {
                showLatoSheet<void>(context: context, builder: body);
              }
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final form in [true, false]) {
    final kind = form ? 'form sheet' : 'sheet';

    testWidgets('$kind shows its title and has no close button', (
      tester,
    ) async {
      await tester.pumpWidget(_host(form: form));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Add Member'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('$kind clips its content to the rounded top corners', (
      tester,
    ) async {
      await tester.pumpWidget(_host(form: form));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(sheet.clipBehavior, Clip.antiAlias);
      expect(sheet.showDragHandle, isTrue);
    });

    testWidgets('$kind closes when swiped down', (tester) async {
      await tester.pumpWidget(_host(form: form));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      await tester.fling(find.text('Add Member'), const Offset(0, 500), 2000);
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
    });
  }
}
