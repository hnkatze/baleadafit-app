import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_redirect.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/not_found/ui/not_found_screen.dart';
import '../../features/showcase/ui/theme_gallery_screen.dart';
import 'app_routes.dart';

/// Builds the app router.
///
/// [initialLocation] exists so tests can start on any route; the app always
/// starts at the login form. [redirect] is nullable on purpose: it lets tests
/// exercise the route table without a session.
GoRouter createAppRouter({
  String initialLocation = AppRoutes.login,
  GoRouterRedirect? redirect,
  Listenable? refreshListenable,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: redirect,
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.showcase,
        builder: (context, state) => const ThemeGalleryScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}

/// Single router instance for the whole app.
///
/// The router reads the session on every navigation and rebuilds its redirect
/// when the session changes, so signing in and out moves the app without any
/// screen calling `context.go` itself.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionListenable(ref);
  ref.onDispose(refresh.dispose);

  return createAppRouter(
    redirect: (context, state) => resolveAuthRedirect(
      session: ref.read(sessionControllerProvider),
      location: state.uri,
    ),
    refreshListenable: refresh,
  );
});

/// Turns session state changes into the [Listenable] GoRouter needs.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    _subscription = ref.listen<SessionState>(
      sessionControllerProvider,
      (_, _) => notifyListeners(),
    );
  }

  late final ProviderSubscription<SessionState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
