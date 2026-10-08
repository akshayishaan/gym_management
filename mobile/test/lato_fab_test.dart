import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/design/components/lato_fab.dart';

void main() {
  testWidgets('is an icon-only button at the bottom right and taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: LatoFab(
            label: 'New Member',
            onPressed: () => taps++,
          ),
          body: ListView.builder(
            itemCount: 60,
            itemBuilder: (_, i) => ListTile(title: Text('Row $i')),
          ),
        ),
      ),
    );

    expect(find.text('New Member'), findsNothing);
    expect(find.byIcon(Icons.add), findsOneWidget);

    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final rect = tester.getRect(find.byType(FloatingActionButton));
    expect(rect.right, closeTo(size.width - 20, 0.5));
    expect(rect.bottom, closeTo(size.height - 20, 0.5));

    // Stays collapsed after scrolling.
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(FloatingActionButton)).width, 56);

    await tester.tap(find.byType(FloatingActionButton));
    expect(taps, 1);
  });
}
