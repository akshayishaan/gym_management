/// Pure builders for gym-scoped query/documentation keys.
///
/// Mirrors the web app's `lib/queryKeys.ts` so the two clients can share
/// logging and invalidation grouping. Phase 2's Riverpod data-fetch providers
/// reuse these; nothing here is a provider.
///
/// Keys carrying a non-[String] payload ([Map] filters, the `year` [int])
/// return `List<Object>`; the homogeneous keys return `List<String>`.
class GymQueryKeys {
  const GymQueryKeys._();

  static List<String> root(String gymId) => <String>['gym', gymId];

  static List<String> dashboard(String gymId) =>
      <String>['gym', gymId, 'dashboard'];

  static List<Object> members(String gymId, [Map<String, dynamic>? filters]) =>
      <Object>['gym', gymId, 'members', if (filters != null) filters];

  static List<String> member(String gymId, String memberId) =>
      <String>['gym', gymId, 'member', memberId];

  static List<String> memberships(String gymId, String memberId) =>
      <String>['gym', gymId, 'memberships', memberId];

  static List<Object> payments(String gymId, [Map<String, dynamic>? filters]) =>
      <Object>['gym', gymId, 'payments', if (filters != null) filters];

  static List<Object> plans(String gymId, [Map<String, dynamic>? filters]) =>
      <Object>['gym', gymId, 'plans', if (filters != null) filters];

  static List<Object> reports(String gymId, int year) =>
      <Object>['gym', gymId, 'reports', year];

  static List<String> activity(String gymId) =>
      <String>['gym', gymId, 'activity'];

  static const List<String> gyms = <String>['gyms'];
}
