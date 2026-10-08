/// What deleting a Gym would erase. Mirrors `GET /gyms/:id/deletion-summary`.
class GymDeletionSummary {
  const GymDeletionSummary({
    required this.name,
    required this.members,
    required this.payments,
    required this.plans,
    required this.memberships,
    required this.activity,
    required this.staff,
  });

  final String name;
  final int members;
  final int payments;
  final int plans;
  final int memberships;
  final int activity;

  /// Staff with access to the Gym, including the person deleting it.
  final int staff;

  int get otherStaff => staff > 0 ? staff - 1 : 0;

  factory GymDeletionSummary.fromJson(Map<String, dynamic> json) {
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return GymDeletionSummary(
      name: json['name'] as String? ?? '',
      members: n('members'),
      payments: n('payments'),
      plans: n('plans'),
      memberships: n('memberships'),
      activity: n('activity'),
      staff: n('staff'),
    );
  }
}
