import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/features/dashboard/domain/dashboard_data.dart';

Map<String, dynamic> _json({Map<String, dynamic>? previous}) => {
  'totalMembers': 6,
  'activeMembers': 3,
  'expiredMembers': 3,
  'expiringMembers': 0,
  'monthRevenue': 3000,
  'recentPayments': [],
  'expiringList': [],
  'previous': ?previous,
};

void main() {
  test('percent and change are relative to last month', () {
    const up = Comparison(current: 6, previous: 4);
    expect(up.change, 2);
    expect(up.percent, closeTo(50, 1e-9));

    const down = Comparison(current: 3, previous: 4);
    expect(down.change, -1);
    expect(down.percent, closeTo(-25, 1e-9));

    const flat = Comparison(current: 4, previous: 4);
    expect(flat.change, 0);
    expect(flat.percent, 0);
  });

  test('percent is null when last month was zero', () {
    const c = Comparison(current: 5, previous: 0);
    expect(c.change, 5);
    expect(c.percent, isNull);
  });

  test('parses the previous block and builds comparisons', () {
    final data = DashboardData.fromJson(
      _json(
        previous: {'totalMembers': 4, 'activeMembers': 4, 'monthRevenue': 2400},
      ),
    );
    expect(data.totalMembersComparison!.change, 2);
    expect(data.activeMembersComparison!.percent, closeTo(-25, 1e-9));
    expect(data.monthRevenueComparison!.percent, closeTo(25, 1e-9));
  });

  test('no previous block means no comparisons', () {
    final data = DashboardData.fromJson(_json());
    expect(data.previous, isNull);
    expect(data.totalMembersComparison, isNull);
    expect(data.monthRevenueComparison, isNull);
  });
}
