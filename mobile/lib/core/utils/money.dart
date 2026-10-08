import 'package:intl/intl.dart';

/// Rupee amount with Indian digit grouping, e.g. `₹1,00,000.00`.
String formatInr(num amount, {int decimals = 2}) {
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: decimals,
  ).format(amount);
}

/// Whole-number part with Indian digit grouping and no symbol, e.g. `1,00,000`.
String formatInrWhole(num amount) =>
    NumberFormat.decimalPattern('en_IN').format(amount);
