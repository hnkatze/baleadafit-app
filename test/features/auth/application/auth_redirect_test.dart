import 'package:baleadafit/features/auth/application/auth_redirect.dart';
import 'package:baleadafit/features/auth/application/session_controller.dart';
import 'package:baleadafit/features/auth/data/auth_session.dart';
import 'package:baleadafit/features/auth/data/user_role.dart';
import 'package:baleadafit/core/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

const _signedIn = SessionState(
  status: SessionStatus.authenticated,
  session: AuthSession(rol: UserRole.nutricionista, displayName: 'Sofía'),
);
const _signedOut = SessionState(status: SessionStatus.unauthenticated);
const _restoring = SessionState();

void main() {
  group('resolveAuthRedirect', () {
    test('keeps a signed-out user on the login form', () {
      expect(
        resolveAuthRedirect(
          session: _signedOut,
          location: Uri.parse(AppRoutes.login),
        ),
        isNull,
      );
    });

    test('sends a signed-out user back to the login form', () {
      expect(
        resolveAuthRedirect(
          session: _signedOut,
          location: Uri.parse(AppRoutes.home),
        ),
        AppRoutes.login,
      );
    });

    test('keeps a restore in flight on the login form', () {
      expect(
        resolveAuthRedirect(
          session: _restoring,
          location: Uri.parse(AppRoutes.home),
        ),
        AppRoutes.login,
      );
    });

    test('moves a signed-in user off the login form', () {
      expect(
        resolveAuthRedirect(
          session: _signedIn,
          location: Uri.parse(AppRoutes.login),
        ),
        AppRoutes.home,
      );
    });

    test('lets a signed-in user stay where they are', () {
      expect(
        resolveAuthRedirect(
          session: _signedIn,
          location: Uri.parse(AppRoutes.showcase),
        ),
        isNull,
      );
    });
  });

  test('homeForRole always answers a route', () {
    for (final role in [...UserRole.values, null]) {
      expect(homeForRole(role), AppRoutes.home);
    }
  });
}
