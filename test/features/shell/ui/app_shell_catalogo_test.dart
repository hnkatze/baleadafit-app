import 'package:baleadafit/core/router/app_routes.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/auth/application/session_controller.dart';
import 'package:baleadafit/features/auth/data/auth_session.dart';
import 'package:baleadafit/features/auth/data/user_role.dart';
import 'package:baleadafit/features/shell/ui/app_shell.dart';
import 'package:baleadafit/shared/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sesion extends SessionController {
  @override
  SessionState build() => const SessionState(
    status: SessionStatus.authenticated,
    session: AuthSession(rol: UserRole.nutricionista, displayName: 'Sofía'),
  );

  @override
  Future<void> restore() async {}
}

Future<void> _pump(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sessionControllerProvider.overrideWith(_Sesion.new)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: AppShell(location: location, child: const SizedBox()),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _abrirDrawer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Abrir menú'));
  await tester.pumpAndSettle();
}

Finder _entrada() => find.descendant(
  of: find.byType(AppDrawer),
  matching: find.text('Catálogo de alimentos'),
);

bool _activa(WidgetTester tester) {
  final semantics = find.ancestor(of: _entrada(), matching: find.byType(Semantics));
  return tester
      .widgetList<Semantics>(semantics)
      .any((s) => s.properties.selected == true);
}

void main() {
  testWidgets('the drawer has a Catálogo entry', (tester) async {
    await _pump(tester, AppRoutes.home);
    await _abrirDrawer(tester);

    expect(_entrada(), findsOneWidget);
    expect(_activa(tester), isFalse);
  });

  testWidgets('the entry is active on /catalogo', (tester) async {
    await _pump(tester, AppRoutes.catalogo);
    await _abrirDrawer(tester);

    expect(_activa(tester), isTrue);
  });

  testWidgets('the entry stays active below /catalogo', (tester) async {
    await _pump(tester, AppRoutes.historialAlimento('al-1'));
    await _abrirDrawer(tester);

    expect(_activa(tester), isTrue);
  });

  testWidgets('the top bar names the section on /catalogo', (tester) async {
    await _pump(tester, AppRoutes.alimento('al-1'));

    expect(find.text('Catálogo de alimentos'), findsOneWidget);
  });
}
