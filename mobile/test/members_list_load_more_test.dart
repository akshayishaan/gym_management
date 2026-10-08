import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/members/data/member_repository.dart';
import 'package:gym_manager/features/members/domain/member.dart';
import 'package:gym_manager/features/members/presentation/members_list_screen.dart';

const _total = 45;
const _pageSize = 20;

/// Fake backend: 45 members served in pages, like `GET /members?page&limit`.
Future<MemberListResult> _fakePage(int page) async {
  final start = (page - 1) * _pageSize;
  final end = (start + _pageSize).clamp(0, _total);
  return MemberListResult(
    members: [
      for (var i = start; i < end; i++)
        Member(
          id: 'm${i + 1}',
          gymId: 'g1',
          name: 'Member ${i + 1}',
          phone: '90000000${(i + 1).toString().padLeft(2, '0')}',
        ),
    ],
    total: _total,
    page: page,
    limit: _pageSize,
  );
}

Widget _host() {
  return ProviderScope(
    overrides: [
      memberListProvider.overrideWith((ref, query) => _fakePage(query.page)),
    ],
    child: const MaterialApp(home: MembersListScreen()),
  );
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    400,
    scrollable: find.byType(Scrollable).last,
  );
  // "Visible" only means built; bring it fully on screen so taps land.
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the first page with Showing 20 of 45 and Load more', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Load more'));
    expect(find.text('Showing 20 of 45'), findsOneWidget);
    expect(find.text('Member 20'), findsOneWidget);
    expect(find.text('Member 21'), findsNothing);
  });

  testWidgets('Load more appends the next page until all members are shown', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Load more'));
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Showing 40 of 45'));
    expect(find.text('Member 40'), findsOneWidget);

    await _scrollTo(tester, find.text('Load more'));
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    // Last page: everything is shown, so the footer is gone.
    await _scrollTo(tester, find.text('Member 45'));
    expect(find.text('Load more'), findsNothing);
    expect(find.textContaining('Showing'), findsNothing);
  });

  testWidgets('changing a filter goes back to the first page', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Load more'));
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Showing 40 of 45'));

    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Load more'));
    expect(find.text('Showing 20 of 45'), findsOneWidget);
  });
}
