/// A RepiX Member as returned by `GET /members`, `GET /members/:id`, and
/// `PUT /members/:id`. The backend's `Member.schema.ts` is the source of
/// truth; this model mirrors it with camelCase Dart fields.
///
/// The backend attaches `status` and `daysUntilExpiry` to list/detail
/// responses when the member has a `membershipExpiry` (see
/// `backend/src/members/member.service.ts#withDisplayStatus`). Members
/// without an expiry return those fields absent.
///
/// Kept as a plain Dart class (no freezed) to match the project's
/// existing `DashboardData` style and avoid pulling freezed codegen into
/// a repo that doesn't currently use it.
class Member {
  const Member({
    required this.id,
    required this.gymId,
    required this.name,
    this.email,
    required this.phone,
    this.address,
    this.photo,
    this.dateOfBirth,
    this.gender, // 'male' | 'female' | 'other'
    this.planId,
    this.planName,
    this.membershipStart, // YYYY-MM-DD per the gym's timezone
    this.membershipExpiry, // YYYY-MM-DD per the gym's timezone
    this.notes,
    this.emergencyContact,
    this.dueAmount = 0,
    this.isActive = true,
    this.status, // 'active' | 'expiring' | 'expired' (when expiry is set)
    this.daysUntilExpiry, // negative when already expired
    this.createdAt,
    this.updatedAt,
  });

  /// Mongoose `_id` mapped to `id` on the wire.
  final String id;
  final String gymId;
  final String name;
  final String? email;
  final String phone;
  final String? address;
  final String? photo;

  /// `dateOfBirth` arrives as an ISO-8601 string from the backend's
  /// `.lean()` JSON serialization. We keep it as a string here so the
  /// caller decides how to render it (the rest of the app renders dates
  /// as server-owned strings or as the device locale, not as DateTimes).
  final String? dateOfBirth;
  final String? gender;
  final String? planId;
  final String? planName;
  final String? membershipStart;
  final String? membershipExpiry;
  final String? notes;
  final String? emergencyContact;
  final double dueAmount;
  final bool isActive;
  final String? status;
  final int? daysUntilExpiry;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Initials shown in the avatar circle on the member card and detail
  /// header. Falls back to a single question mark when the name is blank
  /// or contains no letter characters.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = <String>[];
    for (final p in parts) {
      if (p.isEmpty) continue;
      final first = p.runes.firstWhere(
        (r) => (r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A),
        orElse: () => -1,
      );
      if (first != -1) {
        letters.add(String.fromCharCode(first).toUpperCase());
      }
      if (letters.length == 2) break;
    }
    if (letters.isEmpty) return '?';
    return letters.join();
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: (json['_id'] ?? json['id']) as String,
      gymId: (json['gymId'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String?,
      photo: json['photo'] as String?,
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: json['gender'] as String?,
      planId: json['planId']?.toString(),
      planName: json['planName'] as String?,
      membershipStart: json['membershipStart'] as String?,
      membershipExpiry: json['membershipExpiry'] as String?,
      notes: json['notes'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      dueAmount: (json['dueAmount'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      status: json['status'] as String?,
      daysUntilExpiry: (json['daysUntilExpiry'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}
