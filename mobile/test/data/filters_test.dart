import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/data/filters.dart';

void main() {
  group('MemberFilters', () {
    test('is equal when all fields match and has a matching hashCode', () {
      const a = MemberFilters(
        search: 'x',
        status: 'active',
        page: 2,
        limit: 10,
      );
      const b = MemberFilters(
        search: 'x',
        status: 'active',
        page: 2,
        limit: 10,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when any field differs', () {
      const base = MemberFilters(
        search: 'x',
        status: 'active',
        page: 2,
        limit: 10,
      );
      expect(base, isNot(const MemberFilters(search: 'y')));
      expect(base, isNot(const MemberFilters(status: 'expired')));
      expect(base, isNot(const MemberFilters(page: 3)));
      expect(base, isNot(const MemberFilters(limit: 9)));
    });

    test('copyWith updates only the provided fields', () {
      const base = MemberFilters(
        search: 'x',
        status: 'active',
        page: 2,
        limit: 10,
      );
      expect(
        base.copyWith(page: 3),
        const MemberFilters(search: 'x', status: 'active', page: 3, limit: 10),
      );
      expect(
        base.copyWith(search: 'y'),
        const MemberFilters(search: 'y', status: 'active', page: 2, limit: 10),
      );
      expect(
        base.copyWith(search: null),
        const MemberFilters(status: 'active', page: 2, limit: 10),
      );
    });
  });

  group('PaymentFilters', () {
    test('is equal when all fields match and has a matching hashCode', () {
      const a = PaymentFilters(memberId: 'm1', month: '2026-09');
      const b = PaymentFilters(memberId: 'm1', month: '2026-09');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when any field differs', () {
      const base = PaymentFilters(memberId: 'm1', month: '2026-09');
      expect(base, isNot(const PaymentFilters(memberId: 'm2')));
      expect(base, isNot(const PaymentFilters(month: '2026-10')));
      expect(base, isNot(const PaymentFilters(page: 2)));
      expect(base, isNot(const PaymentFilters(limit: 5)));
    });

    test('copyWith updates only the provided fields', () {
      const base = PaymentFilters(memberId: 'm1', month: '2026-09');
      expect(
        base.copyWith(month: '2026-10'),
        const PaymentFilters(memberId: 'm1', month: '2026-10'),
      );
      expect(
        base.copyWith(memberId: null),
        const PaymentFilters(month: '2026-09'),
      );
    });
  });

  group('PlanFilters', () {
    test('defaults to active status, limit 50, and includeStats true', () {
      const a = PlanFilters();
      expect(a.status, 'active');
      expect(a.page, 1);
      expect(a.limit, 50);
      expect(a.includeStats, isTrue);
    });

    test('is equal when all fields match and has a matching hashCode', () {
      const a = PlanFilters(
        search: 'gold',
        status: 'inactive',
        page: 2,
        limit: 20,
        includeStats: false,
      );
      const b = PlanFilters(
        search: 'gold',
        status: 'inactive',
        page: 2,
        limit: 20,
        includeStats: false,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when any field differs', () {
      const base = PlanFilters();
      expect(base, isNot(const PlanFilters(search: 'gold')));
      expect(base, isNot(const PlanFilters(status: 'all')));
      expect(base, isNot(const PlanFilters(page: 2)));
      expect(base, isNot(const PlanFilters(limit: 10)));
      expect(base, isNot(const PlanFilters(includeStats: false)));
    });

    test('copyWith updates only the provided fields', () {
      const base = PlanFilters();
      expect(
        base.copyWith(status: 'all', includeStats: false),
        const PlanFilters(status: 'all', includeStats: false),
      );
      expect(
        base.copyWith(search: null),
        const PlanFilters(search: null),
      );
    });
  });

  group('ActivityFilters', () {
    test('defaults to page 1 and limit 50', () {
      const a = ActivityFilters();
      expect(a.page, 1);
      expect(a.limit, 50);
    });

    test('is equal when all fields match and has a matching hashCode', () {
      const a = ActivityFilters(page: 2, limit: 100);
      const b = ActivityFilters(page: 2, limit: 100);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when any field differs', () {
      const base = ActivityFilters();
      expect(base, isNot(const ActivityFilters(page: 2)));
      expect(base, isNot(const ActivityFilters(limit: 100)));
    });

    test('copyWith updates only the provided fields', () {
      const base = ActivityFilters();
      expect(base.copyWith(page: 3), const ActivityFilters(page: 3, limit: 50));
      expect(base.copyWith(limit: 200), const ActivityFilters(limit: 200));
    });
  });
}
