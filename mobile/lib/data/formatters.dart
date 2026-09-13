import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared display + contact helpers, ported from the web `lib/utils.ts`.
///
/// Currency and date formatting mirror the web's `Intl.NumberFormat` /
/// `Intl.DateTimeFormat` (`en-IN`) output. Date handling honors ADR-0005: a
/// `YYYY-MM-DD` date-only string is always interpreted in its own calendar
/// space (UTC) and never round-tripped through a browser/device-local
/// timestamp.
final RegExp _dateOnlyRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Whether [value] is a `YYYY-MM-DD` date-only string (no time component).
bool isDateOnly(String value) => _dateOnlyRe.hasMatch(value);

/// Formats [amount] as a whole-number currency string for [currency]
/// (an ISO 4217 code such as `INR`). `en_IN` gives the Indian digit grouping
/// and the `₹`/`$`/`€`/`£` symbol for known codes (unknown codes fall back to
/// the raw code, matching the web's `currencySymbol` behavior).
String formatCurrency(num amount, String currency) {
  return NumberFormat.simpleCurrency(
    locale: 'en_IN',
    name: currency,
    decimalDigits: 0,
  ).format(amount);
}

/// Formats [value] as `dd MMM yyyy`.
///
/// Date-only strings (`YYYY-MM-DD`) are rendered without timezone conversion
/// (matching the web's explicit `timeZone: "UTC"`), while ISO timestamps are
/// parsed and shown in the device-local timezone.
String formatDate(String value) {
  if (_dateOnlyRe.hasMatch(value)) {
    final List<String> parts = value.split('-');
    final int year = int.parse(parts[0]);
    final int month = int.parse(parts[1]);
    final int day = int.parse(parts[2]);
    return DateFormat('dd MMM yyyy').format(DateTime.utc(year, month, day));
  }
  return DateFormat('dd MMM yyyy').format(DateTime.parse(value).toLocal());
}

/// The uppercased first letter of the first two whitespace-separated words of
/// [name] (max two characters). Empty input yields an empty string.
String getInitials(String name) {
  final List<String> words =
      name.split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  final StringBuffer initials = StringBuffer();
  for (final String word in words.take(2)) {
    initials.write(word[0]);
  }
  return initials.toString().toUpperCase();
}

/// An `sms:` deep link to [phone] with [message] pre-filled.
String buildSmsLink(String phone, String message) {
  final String digits = phone.replaceAll(RegExp(r'\D'), '');
  return 'sms:$digits?body=${Uri.encodeComponent(message)}';
}

/// A `wa.me` link to [phone] with [message] pre-filled. Strips non-digits and
/// a single leading `0` (the web's "add country code if needed" heuristic).
String buildWhatsAppLink(String phone, String message) {
  String clean = phone.replaceAll(RegExp(r'\D'), '');
  if (clean.startsWith('0')) clean = clean.substring(1);
  return 'https://wa.me/$clean?text=${Uri.encodeComponent(message)}';
}

/// Opens [url] in the platform's external handler (browser, SMS app, etc.).
///
/// Returns `false` — never throws — when the URL cannot be launched, so
/// callers may surface a snackbar.
Future<bool> launchExternal(String url) async {
  try {
    return await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}

// ---------------------------------------------------------------------------
// ADR-0005 — form-preview date arithmetic ONLY.
//
// The following two helpers compute `YYYY-MM-DD` strings for **editable form
// inputs and preview-only labels** (e.g. a membership's "expiry = start +
// durationDays - 1" hint, or a smart default start date). They must NEVER be
// used to derive *rendered* status/days/duration for persisted records — the
// backend is the single source of truth for those (see `member.status`,
// `member.daysUntilExpiry`, `membership.expiryStatus`).
// ---------------------------------------------------------------------------

/// Today's date as a `YYYY-MM-DD` string, for seeding a form's default
/// membership-start input. Preview-only (see note above).
String todayDateOnly() {
  final DateTime now = DateTime.now();
  return _dateOnly(now.year, now.month, now.day);
}

/// [dateOnly] (`YYYY-MM-DD`) shifted by [days] calendar days, returned as a
/// `YYYY-MM-DD` string. Used only for preview labels (see note above).
String addDaysToDateOnly(String dateOnly, int days) {
  final DateTime parsed = DateTime.parse(dateOnly);
  final DateTime shifted = parsed.add(Duration(days: days));
  return _dateOnly(shifted.year, shifted.month, shifted.day);
}

String _dateOnly(int year, int month, int day) {
  final String y = year.toString().padLeft(4, '0');
  final String m = month.toString().padLeft(2, '0');
  final String d = day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
