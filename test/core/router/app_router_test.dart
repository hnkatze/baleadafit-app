import 'package:baleadafit/app.dart';
import 'package:baleadafit/core/router/app_router.dart';
import 'package:baleadafit/core/router/app_routes.dart';
import 'package:baleadafit/features/auth/application/session_controller.dart';
import 'package:baleadafit/features/auth/data/auth_session.dart';
import 'package:baleadafit/features/auth/data/user_role.dart';
import 'package:baleadafit/features/auth/ui/login_screen.dart';
import 'package:baleadafit/features/home/ui/home_screen.dart';
import 'package:baleadafit/features/not_found/ui/not_found_screen.dart';
import 'package:baleadafit/features/showcase/ui/theme_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../../support/pump.dart';

/// Session that never talks to Firebase: the router tests only care about the
/// redirect rules, which read the state.
class _FixedSessionController extends SessionController {
  _FixedSessionController(this._initial);

  final SessionState _initial;

  @override
  SessionState build() => _initial;

  @override
  Future<void> restore() async {}
}

const _session = SessionState(
  status: SessionStatus.authenticated,
  session: AuthSession(rol: UserRole.nutricionista, displayName: 'Sofía'),
);

GoRouter _routerOf(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  return ProviderScope.containerOf(context).read(routerProvider);
}

Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  SessionState session = const SessionState(status: SessionStatus.unauthenticated),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(
          () => _FixedSessionController(session),
        ),
      ],
      child: const BaleadaFitApp(),
    ),
  );
  await pumpStable(tester);
  return _routerOf(tester);
}

void main() {
  testWidgets('boots at the login route when nobody is signed in', (
    tester,
  ) async {
    final router = await _pumpApp(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.login,
    );
  });

  testWidgets('sends a signed-out user from home back to the login form', (
    tester,
  ) async {
    final router = await _pumpApp(tester);

    router.go(AppRoutes.home);
    await pumpStable(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('lands a signed-in user on home instead of the login form', (
    tester,
  ) async {
    await _pumpApp(tester, session: _session);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('keeps the design showcase reachable for a signed-in user', (
    tester,
  ) async {
    final router = await _pumpApp(tester, session: _session);

    router.go(AppRoutes.showcase);
    await pumpStable(tester);

    expect(find.byType(ThemeGalleryScreen), findsOneWidget);
  });

  testWidgets('shows a not-found screen for an unknown route', (tester) async {
    final router = await _pumpApp(tester, session: _session);

    router.go('/ruta-inexistente');
    await pumpStable(tester);

    expect(find.byType(NotFoundScreen), findsOneWidget);
  });

  test('exposes a single router through Riverpod', () {
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(
          () => _FixedSessionController(
            const SessionState(status: SessionStatus.unauthenticated),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(routerProvider),
      same(container.read(routerProvider)),
    );
  });
}
