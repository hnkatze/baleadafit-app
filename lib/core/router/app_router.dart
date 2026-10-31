import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/ui/login_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/not_found/ui/not_found_screen.dart';
import '../../features/showcase/ui/theme_gallery_screen.dart';
import 'app_routes.dart';

/// Builds the app router.
///
/// [initialLocation] exists so tests can start on any route; the app always
/// starts at the login form.
GoRouter createAppRouter({String initialLocation = AppRoutes.login}) {
  return GoRouter(
    initialLocation: initialLocation,
    // The session redirect (auth state, role-based landing) belongs to issue
    // #4. Until then every route is reachable, which keeps the gallery and the
    // home placeholder inspectable.
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
/// Kept in Riverpod so a later session provider can make the router rebuild
/// with the signed-in user without touching `MaterialApp.router`.
final routerProvider = Provider<GoRouter>((ref) => createAppRouter());
