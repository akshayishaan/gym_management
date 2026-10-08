import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/members/data/member_repository.dart';
import 'package:gym_manager/features/members/domain/member.dart';
import 'package:gym_manager/features/members/presentation/member_detail_screen.dart';

Widget _host(Member member) {
  return ProviderScope(
    overrides: [
      memberDetailProvider(member.id).overrideWith((ref) async => member),
    ],
    child: MaterialApp(home: MemberDetailScreen(id: member.id)),
  );
}

const _paid = Member(
  id: 'm1',
  gymId: 'g1',
  name: 'Akshay Kumar',
  phone: '8866325411',
  gender: 'male',
  dateOfBirth: '2002-10-07',
  dueAmount: 0,
);

void main() {
  testWidgets('Overview has a single edit entry and a separate DOB row', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_paid));
    await tester.pumpAndSettle();

    // The text "Edit" link is gone; only the app bar pencil remains.
    expect(find.text('Edit'), findsNothing);
    expect(find.byTooltip('Edit'), findsOneWidget);

    expect(find.text('Date of Birth'), findsOneWidget);
    expect(find.text('7 Oct 2002'), findsOneWidget);
    expect(find.text('Paid in Full'), findsOneWidget);
  });

  testWidgets('shows the due amount in rupees', (tester) async {
    await tester.pumpWidget(
      _host(
        const Member(
          id: 'm2',
          gymId: 'g1',
          name: 'Sumit Raj',
          phone: '8866325411',
          dueAmount: 2500,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Due: ₹2,500'), findsOneWidget);
    expect(find.textContaining('\$'), findsNothing);
  });

  testWidgets('tabs expose selected state to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(_paid));
    await tester.pumpAndSettle();

    final overview = tester.getSemantics(find.text('Overview'));
    expect(overview.flagsCollection.isSelected == Tristate.isTrue, isTrue);
    final history = tester.getSemantics(find.text('History'));
    expect(history.flagsCollection.isSelected == Tristate.isTrue, isFalse);
    handle.dispose();
  });
}
