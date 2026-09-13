import 'package:flutter_test/flutter_test.dart';
import 'package:gym_manager/data/formatters.dart';

void main() {
  group('monthName', () {
    test('maps 1..12 to English month names', () {
      expect(monthName(1), 'January');
      expect(monthName(3), 'March');
      expect(monthName(12), 'December');
    });
  });

  group('monthLabel', () {
    test('formats a YYYY-MM key', () {
      expect(monthLabel('2026-03'), 'March 2026');
      expect(monthLabel('2025-12'), 'December 2025');
    });

    test('falls back to "All months" for empty/invalid input', () {
      expect(monthLabel(null), 'All months');
      expect(monthLabel(''), 'All months');
      expect(monthLabel('nonsense'), 'All months');
      expect(monthLabel('2026-13'), 'All months');
    });
  });

  group('capitalizeWords', () {
    test('capitalizes each word', () {
      expect(capitalizeWords('bank transfer'), 'Bank Transfer');
      expect(capitalizeWords('upi'), 'Upi');
      expect(capitalizeWords('cash'), 'Cash');
    });

    test('collapses and trims whitespace', () {
      expect(capitalizeWords('  hello   world '), 'Hello World');
    });
  });

  group('currentMonthKey', () {
    test('returns a YYYY-MM key matching today', () {
      final String key = currentMonthKey();
      expect(RegExp(r'^\d{4}-\d{2}$').hasMatch(key), isTrue);
      expect(key, todayDateOnly().substring(0, 7));
    });
  });

  group('formatDate', () {
    test('renders date-only strings without timezone conversion', () {
      expect(formatDate('2026-01-13'), '13 Jan 2026');
    });
  });
}
