import 'payment.dart';

/// Immutable filter/pagination shape used as the family argument for
/// `paymentListProvider`. The list screen passes a copy with a new
/// `month` (YYYY-MM) or `page` whenever the user changes the picker or
/// scrolls.
///
/// The Figma design only exposes a month filter (no free-text search), so
/// we don't carry one. Add a `status` filter when the Figma evidence for
/// the chip cluster ("All / Settled / Pending / Refunded") lands on a
/// backend-supported query param.
class PaymentListQuery {
  const PaymentListQuery({
    this.month,
    this.status,
    this.page = 1,
    this.limit = 50,
  });

  /// `YYYY-MM` per the backend's `month` query param in
  /// `payment.service.ts`. Null means "no month filter".
  final String? month;

  /// `paid` | `voided` | `refunded`; null means every status.
  final String? status;

  final int page;
  final int limit;

  PaymentListQuery copyWith({
    Object? month = _kSentinel,
    Object? status = _kSentinel,
    int? page,
    int? limit,
  }) {
    return PaymentListQuery(
      month: identical(month, _kSentinel) ? this.month : month as String?,
      status: identical(status, _kSentinel) ? this.status : status as String?,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentListQuery &&
        other.month == month &&
        other.status == status &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(month, status, page, limit);
}

/// Result envelope for the paginated `GET /payments` response. The
/// backend returns `{ payments, total, page, limit, summary: { netAmount } }`
/// — we flatten `summary.netAmount` into `netAmount` here so the list
/// screen can read it without digging through a nested map.
class PaymentsListResult {
  const PaymentsListResult({
    required this.payments,
    required this.total,
    required this.page,
    required this.limit,
    required this.netAmount,
  });

  final List<Payment> payments;
  final int total;
  final int page;
  final int limit;

  /// Sum of `paid - refunded` payments in the current filter window (or
  /// all-time when no `month` is supplied). Rendered as the "TOTAL
  /// COLLECTED" KPI in the Figma list design.
  final double netAmount;

  bool get hasMore => page * limit < total;
}

const Object _kSentinel = Object();
