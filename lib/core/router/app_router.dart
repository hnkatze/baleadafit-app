import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_redirect.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/not_found/ui/not_found_screen.dart';
import '../../features/patients/ui/alta_paciente/alta_paciente_screen.dart';
import '../../features/patients/ui/nueva_medicion_screen.dart';
import '../../features/patients/ui/paciente_ficha_screen.dart';
import '../../features/patients/ui/pacientes_screen.dart';
import '../../features/shell/ui/app_shell.dart';
import '../../features/shell/ui/feature_placeholder.dart';
import '../../features/showcase/ui/theme_gallery_screen.dart';
import 'app_routes.dart';

/// Root navigator, so a route can opt out of the shell and cover the whole app.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Builds the app router. [redirect] and [refreshListenable] are optional so
/// tests can exercise the route table without a session.
GoRouter createAppRouter({
  String initialLocation = AppRoutes.login,
  GoRouterRedirect? redirect,
  Listenable? refreshListenable,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    redirect: redirect,
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.pacientes,
            builder: (context, state) => PacientesScreen(
              onNuevoPaciente: () => context.go(AppRoutes.nuevoPaciente),
            ),
            routes: [
              // Before `:id`, or "nuevo" would be read as a patient id. Like
              // the measurement form, the artboard draws its own header and
              // closes with an `x`, so it covers the shell instead of nesting.
              GoRoute(
                path: AppRoutes.nuevoPacienteSegment,
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) {
                  // Captured now: the wizard's own context is gone by the
                  // time the second navigation below runs.
                  final router = GoRouter.of(context);
                  return MaterialPage<void>(
                    key: state.pageKey,
                    fullscreenDialog: true,
                    child: AltaPacienteScreen(
                      onCerrar: () => router.canPop()
                          ? router.pop()
                          : router.go(AppRoutes.pacientes),
                      // Swaps the wizard for the ficha in one navigation; the
                      // directory stays below, so back from the new ficha
                      // lands on the list that now has the patient.
                      onCreado: (id) =>
                          router.pushReplacement(AppRoutes.paciente(id)),
                    ),
                  );
                },
              ),
              // Nested so the file stacks over the directory inside the shell:
              // the bar and the drawer stay, and back returns to the list.
              GoRoute(
                path: ':${AppRoutes.pacienteIdParam}',
                builder: (context, state) => PacienteFichaScreen(
                  pacienteId: state.pathParameters[AppRoutes.pacienteIdParam]!,
                  // A deep link has nothing to pop to, so it lands on the list.
                  onBack: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.pacientes),
                  // `go` rather than `push`: the location then names the form,
                  // and a deep link to it closes onto the ficha like this does.
                  onNuevaMedicion: () => context.go(
                    AppRoutes.nuevaMedicion(
                      state.pathParameters[AppRoutes.pacienteIdParam]!,
                    ),
                  ),
                ),
                routes: [
                  // The artboard has no shell bar or drawer (it closes with an
                  // `x`), so it goes on the root navigator, as a full-screen
                  // dialog, instead of nesting inside the shell.
                  GoRoute(
                    path: AppRoutes.medicionSegment,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => MaterialPage<bool>(
                      key: state.pageKey,
                      fullscreenDialog: true,
                      child: NuevaMedicionScreen(
                        pacienteId:
                            state.pathParameters[AppRoutes.pacienteIdParam]!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.dietas,
            builder: (context, state) => const FeaturePlaceholder(
              title: 'Diseñador de dietas',
              description:
                  'Recomendador, plan alimenticio y aprobación del plan.',
              icon: Icons.restaurant_menu,
            ),
          ),
          GoRoute(
            path: AppRoutes.catalogo,
            builder: (context, state) => const FeaturePlaceholder(
              title: 'Catálogo de alimentos',
              description: 'Alimentos, porciones y restricciones del TCA-HN.',
              icon: Icons.menu_book_outlined,
            ),
          ),
          GoRoute(
            path: AppRoutes.agenda,
            builder: (context, state) => const FeaturePlaceholder(
              title: 'Agenda de citas',
              description: 'Citas de la nutricionista y su seguimiento.',
              icon: Icons.calendar_today_outlined,
            ),
          ),
          GoRoute(
            path: AppRoutes.configuracion,
            builder: (context, state) => const FeaturePlaceholder(
              title: 'Configuración',
              description: 'Preferencias de la cuenta y del consultorio.',
              icon: Icons.settings_outlined,
            ),
          ),
        ],
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
