import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_manager/main.dart';

void main() {
  testWidgets('RepiX app boots and lands on the splash brand screen',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RepiXApp()));
    // The router redirects on the next microtask after auth rehydration.
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Splash screen brand mark.
    expect(find.text('RepiX'), findsWidgets);
    // The CTA from Figma's "01 login" screen.
    expect(find.text('Get started'), findsOneWidget);
    // Tagline text.
    expect(find.textContaining('TRACK'), findsOneWidget);
  });
}