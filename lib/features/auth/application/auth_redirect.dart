import '../../../core/router/app_routes.dart';
import '../data/user_role.dart';
import 'session_controller.dart';

/// Location the app should be at, given the session and the requested location.
///
/// Pure so the routing rules are tested without building a router:
/// a signed-in user never sees the login screen, a signed-out user can only
/// reach the login screen, and while a restore is in flight nothing moves.
String? resolveAuthRedirect({
  required SessionState session,
  required Uri location,
}) {
  final path = location.path;
  final isLogin = path == AppRoutes.login;

  switch (session.status) {
    case SessionStatus.unknown:
      return isLogin ? null : AppRoutes.login;
    case SessionStatus.unauthenticated:
      return isLogin ? null : AppRoutes.login;
    case SessionStatus.authenticated:
      if (isLogin) return homeForRole(session.session?.rol);
      return null;
  }
}

/// Landing route for each role.
///
/// Only the clinician shell exists today; the patient shell and the
/// "sin perfil" registration are separate features, so both land on the same
/// placeholder route for now.
String homeForRole(UserRole? role) => switch (role) {
  UserRole.nutricionista => AppRoutes.home,
  UserRole.paciente => AppRoutes.home,
  UserRole.sinPerfil => AppRoutes.home,
  null => AppRoutes.home,
};
