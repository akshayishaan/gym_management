import 'package:gym_api/gym_api.dart';

/// Authentication lifecycle status.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// The authenticated user, mapped from the generated [AuthSessionResponseUser].
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.gymIds,
  });

  factory AuthUser.fromSessionUser(AuthSessionResponseUser user) => AuthUser(
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        gymIds: user.gymIds,
      );

  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> gymIds;

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.role == role &&
      _listEquals(other.gymIds, gymIds);

  @override
  int get hashCode =>
      Object.hash(id, name, email, role, Object.hashAll(gymIds));

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The app's authentication state.
///
/// Deliberately minimal: it carries only [status] and [user]. The access token
/// is NOT stored here — [TokenManager] is the canonical access-token holder
/// (memory only), so a single source of truth avoids divergence.
class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user});

  final AuthStatus status;
  final AuthUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Sentinel marking an absent argument in [copyWith], so `null` can be used
  /// to explicitly clear [user] (e.g. on logout).
  static const Object _unset = Object();

  AuthState copyWith({AuthStatus? status, Object? user = _unset}) {
    return AuthState(
      status: status ?? this.status,
      user: identical(user, _unset) ? this.user : user as AuthUser?,
    );
  }
}
