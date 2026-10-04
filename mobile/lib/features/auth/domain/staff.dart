/// Authenticated staff member record. Mirrors the `Staff` document from the
/// backend (`backend/src/schemas/staff.schema.ts`).
class Staff {
  const Staff({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'admin',
    this.gymIds = const [],
  });

  final String id;
  final String name;
  final String email;
  /// Server-set role (e.g. "admin"). Currently only "admin" is issued by
  /// the backend signup flow.
  final String role;
  final List<String> gymIds;

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: (json['id'] ?? json['_id']) as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'admin',
      gymIds: (json['gymIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'gymIds': gymIds,
      };
}
