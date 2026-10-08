import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/reports/data/reports_repository.dart';
import 'package:gym_manager/features/reports/domain/report.dart';
import 'package:gym_manager/features/reports/presentation/reports_screen.dart';
import 'package:gym_manager/features/reports/presentation/reports_widgets.dart';

ReportSeriesPoint _month(int m, {double revenue = 0, int newMembers = 0}) =>
    ReportSeriesPoint(
      month: m,
      revenue: revenue,
      transactions: 0,
      newMembers: newMembers,
      memberships: 0,
      renewals: 0,
    );

ReportComparisonMetric _metric(double v, {double? change}) =>
    ReportComparisonMetric(value: v, previous: 0, changePercent: change);

ReportsResponse _report({
  int expiring = 2,
  int due = 1,
  double dues = 600,
  int expired = 1,
}) => ReportsResponse(
  year: 2026,
  asOf: '2026-10-08',
  timezone: 'Asia/Kolkata',
  summary: ReportSummary(
    revenue: _metric(642050.5),
    transactions: _metric(10),
    newMembers: _metric(4, change: 25),
    renewals: _metric(2, change: -10),
    activeMembers: 3,
    outstandingDues: dues,
    dueMembers: due,
  ),
  series: [
    for (var m = 1; m <= 12; m++)
      _month(
        m,
        revenue: m == 10 ? 380000 : (m == 7 ? 120000 : 0),
        newMembers: m == 7 ? 3 : (m == 10 ? 1 : 0),
      ),
  ],
  planPerformance: const [
    ReportPlanPerformance(
      key: 'p1',
      planId: 'p1',
      name: 'Monthly',
      revenue: 540000,
      sales: 6,
      activeMembers: 3,
    ),
  ],
  paymentMethods: const [
    ReportPaymentMethod(
      method: 'cash',
      amount: 490000,
      count: 7,
      percentage: 77,
    ),
    ReportPaymentMethod(
      method: 'upi',
      amount: 150000,
      count: 1,
      percentage: 23,
    ),
  ],
  insights: ReportInsights(
    expiringSoon: expiring,
    expiredMembers: expired,
    dueMembers: due,
    outstandingDues: dues,
    bestMonth: const ReportBestMonth(month: 10, revenue: 380000),
  ),
);

Future<void> _open(WidgetTester tester, ReportsResponse report) async {
  tester.view.physicalSize = const Size(800, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [reportsProvider.overrideWith((ref, year) async => report)],
      child: const MaterialApp(home: ReportsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('money is rupees with Indian grouping, never dollars', (
    tester,
  ) async {
    await _open(tester, _report());

    expect(find.textContaining('\$'), findsNothing);
    expect(find.text('Reports'), findsOneWidget);
    // Hero: rupees big, paise small.
    expect(
      find.textContaining('₹6,42,050', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('.50', findRichText: true), findsOneWidget);
    expect(find.text('₹600'), findsOneWidget); // outstanding dues
    expect(find.text('₹5,40,000'), findsOneWidget); // plan revenue
    expect(find.text('₹1,80,000 avg per member'), findsOneWidget);
    expect(find.text('Gross: ₹6.4L'), findsOneWidget);
    expect(find.text('₹3.8L'), findsOneWidget); // peak badge
  });

  testWidgets('no dead controls and no fabricated benchmark text', (
    tester,
  ) async {
    await _open(tester, _report());

    expect(find.byIcon(Icons.ios_share), findsNothing);
    expect(find.text('Remind All'), findsNothing);
    expect(find.text('Action Req.'), findsNothing);
    expect(find.textContaining('benchmark'), findsNothing);
    expect(find.textContaining('coming soon'), findsNothing);
  });

  testWidgets('year selector stops at the current year, date range day-first', (
    tester,
  ) async {
    await _open(tester, _report());

    final now = DateTime.now().year;
    expect(find.text('$now'), findsOneWidget);
    expect(find.text('${now - 1}'), findsOneWidget);
    expect(find.text('${now - 2}'), findsOneWidget);
    expect(find.text('${now + 1}'), findsNothing);
    expect(find.text('1 Jan – 31 Dec $now'), findsOneWidget);
  });

  testWidgets('lifecycle copy handles singular, plural and zero', (
    tester,
  ) async {
    await _open(tester, _report());
    expect(
      find.text('2 memberships expire in the next 30 days'),
      findsOneWidget,
    );
    expect(find.text('1 member owes ₹600'), findsOneWidget);
    expect(find.text('Action needed'), findsOneWidget);
    expect(find.text('1 member expired'), findsOneWidget);
    expect(find.text('25.0% churn'), findsOneWidget);

    await _open(tester, _report(expiring: 0, due: 0, dues: 0, expired: 0));
    expect(
      find.text('No memberships expire in the next 30 days'),
      findsOneWidget,
    );
    expect(find.text('No outstanding dues'), findsOneWidget);
    expect(find.text('Action needed'), findsNothing);
    expect(find.text('No expired members'), findsOneWidget);
  });

  testWidgets('labels are spelled out; empty change badge is hidden', (
    tester,
  ) async {
    await _open(tester, _report());

    expect(find.text('Members with dues'), findsOneWidget);
    expect(find.textContaining('w/'), findsNothing);
    expect(find.textContaining('Avg/Yr'), findsNothing);
    // Real changes show; the placeholder dash does not.
    expect(find.text('+25.0%'), findsOneWidget);
    expect(find.text('-10.0%'), findsOneWidget);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('trend title fits one line; Members mode follows its own peak', (
    tester,
  ) async {
    await _open(tester, _report());

    expect(find.text('Monthly trend'), findsOneWidget);
    expect(find.textContaining('Annual trajectory'), findsNothing);
    expect(find.text('Peak Volume: October'), findsOneWidget);

    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();
    // July has the most new members in the fixture, not October.
    expect(find.text('Most new members: July'), findsOneWidget);
    expect(find.text('Peak Volume: October'), findsNothing);
  });

  test('compact money labels', () {
    expect(reportCompactMoney(950), '₹950');
    expect(reportCompactMoney(3800), '₹3.8k');
    expect(reportCompactMoney(5000), '₹5k');
    expect(reportCompactMoney(120000), '₹1.2L');
    expect(reportCompactMoney(25000000), '₹2.5Cr');
  });
}
