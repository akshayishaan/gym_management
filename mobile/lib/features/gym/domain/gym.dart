/// Gym record. Mirrors `backend/src/schemas/gym.schema.ts` (which the
/// service layer merges with `_id` for the Mongo document).
class Gym {
  const Gym({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.currency,
    required this.timezone,
    required this.expiryReminderDays,
    required this.isActive,
    this.logo,
    this.address,
    this.phone,
    this.email,
  });

  final String id;
  final String name;
  final String? logo;
  final String primaryColor; // hex, e.g. "#C5F23F"
  final String? address;
  final String? phone;
  final String? email;
  final String currency; // ISO 4217, e.g. "USD"
  final String timezone; // IANA, e.g. "America/Los_Angeles"
  final int expiryReminderDays;
  final bool isActive;

  factory Gym.fromJson(Map<String, dynamic> json) {
    return Gym(
      id: (json['_id'] ?? json['id']) as String,
      name: json['name'] as String,
      logo: json['logo'] as String?,
      primaryColor: json['primaryColor'] as String? ?? '#6366f1',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      currency: json['currency'] as String? ?? 'INR',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      expiryReminderDays: json['expiryReminderDays'] as int? ?? 7,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        if (logo != null) 'logo': logo,
        'primaryColor': primaryColor,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        'currency': currency,
        'timezone': timezone,
        'expiryReminderDays': expiryReminderDays,
        'isActive': isActive,
      };
}