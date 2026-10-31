import 'package:baleadafit/app.dart';
import 'package:baleadafit/core/router/app_router.dart';
import 'package:baleadafit/core/router/app_routes.dart';
import 'package:baleadafit/features/auth/ui/login_screen.dart';
import 'package:baleadafit/features/home/ui/home_screen.dart';
import 'package:baleadafit/features/not_found/ui/not_found_screen.dart';
import 'package:baleadafit/features/showcase/ui/theme_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _routerOf(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  return ProviderScope.containerOf(context).read(routerProvider);
}

Future<GoRouter> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: BaleadaFitApp()));
  await tester.pumpAndSettle();
  return _routerOf(tester);
}

void main() {
  testWidgets('boots at the login route', (tester) async {
    final router = await _pumpApp(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.toString(), AppRoutes.login);
  });

  testWidgets('navigates to the home route', (tester) async {
    final router = await _pumpApp(tester);

    router.go(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('keeps the design showcase reachable', (tester) async {
    final router = await _pumpApp(tester);

    router.go(AppRoutes.showcase);
    await tester.pumpAndSettle();

    expect(find.byType(ThemeGalleryScreen), findsOneWidget);
  });

  testWidgets('shows a not-found screen for an unknown route', (tester) async {
    final router = await _pumpApp(tester);

    router.go('/ruta-inexistente');
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundScreen), findsOneWidget);
  });

  test('exposes a single router through Riverpod', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(routerProvider),
      same(container.read(routerProvider)),
    );
  });
}
