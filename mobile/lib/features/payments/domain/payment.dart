/// A RepiX Payment as returned by `GET /payments`, `GET /payments/:id`,
/// and the lifecycle envelopes from `POST /payments`,
/// `POST /payments/:id/void`, and `POST /payments/:id/refund`.
///
/// The backend's `Payment.schema.ts` is the source of truth; this model
/// mirrors it with camelCase Dart fields.
///
/// `kind`, `status`, and `method` are left as raw strings rather than
/// enums so the wire format and the display label stay decoupled (the
/// label mapping lives in the UI layer). The list endpoint also attaches
/// `membershipId` / `membershipStatus` per row, which we expose here so
/// Track B's invoice screen can show the linked membership context.
///
/// Kept as a plain Dart class (no freezed) to match `Member`/`Plan`.
class Payment {
  const Payment({
    required this.id,
    required this.gymId,
    required this.memberId,
    required this.memberName,
    this.planId,
    this.planName,
    required this.amount,
    this.kind, // 'plan_purchase' | 'dues'
    required this.method, // 'cash' | 'card' | 'upi' | 'bank_transfer' | 'other'
    required this.status, // 'paid' | 'voided' | 'refunded'
    required this.invoiceNumber,
    this.notes,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
    this.voidedAt,
    this.voidReason,
    this.refundedAt,
    this.refundReason,
    this.membershipId,
    this.membershipStatus,
  });

  /// Mongoose `_id` mapped to `id` on the wire.
  final String id;
  final String gymId;
  final String memberId;
  final String memberName;
  final String? planId;
  final String? planName;
  final double amount;
  final String? kind;
  final String method;
  final String status;
  final String invoiceNumber;
  final String? notes;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? voidedAt;
  final String? voidReason;
  final DateTime? refundedAt;
  final String? refundReason;

  /// Attached by the backend list response when this Payment is linked to
  /// a Membership (see `payment.service.ts` list enrichment). Absent on
  /// detail reads.
  final String? membershipId;
  final String? membershipStatus;

  /// Human-readable label for the [method] enum. The display layer
  /// renders this on the list cards and the invoice screen.
  String get methodLabel {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'upi':
        return 'UPI';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'other':
        return 'Other';
      default:
        return method;
    }
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: (json['_id'] ?? json['id']) as String,
      gymId: (json['gymId'] ?? '').toString(),
      memberId: (json['memberId'] ?? '').toString(),
      memberName: json['memberName'] as String? ?? '',
      planId: json['planId']?.toString(),
      planName: json['planName'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      kind: json['kind'] as String?,
      method: json['method'] as String? ?? 'other',
      status: json['status'] as String? ?? 'paid',
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      notes: json['notes'] as String?,
      paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      voidedAt: DateTime.tryParse(json['voidedAt']?.toString() ?? ''),
      voidReason: json['voidReason'] as String?,
      refundedAt: DateTime.tryParse(json['refundedAt']?.toString() ?? ''),
      refundReason: json['refundReason'] as String?,
      membershipId: json['membershipId']?.toString(),
      membershipStatus: json['membershipStatus'] as String?,
    );
  }
}