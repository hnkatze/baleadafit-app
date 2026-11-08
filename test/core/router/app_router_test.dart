import 'package:baleadafit/app.dart';
import 'package:baleadafit/core/router/app_router.dart';
import 'package:baleadafit/core/router/app_routes.dart';
import 'package:baleadafit/features/auth/application/session_controller.dart';
import 'package:baleadafit/features/auth/data/auth_session.dart';
import 'package:baleadafit/features/auth/data/user_role.dart';
import 'package:baleadafit/features/auth/ui/login_screen.dart';
import 'package:baleadafit/core/network/paged.dart';
import 'package:baleadafit/features/patients/data/catalogo_item.dart';
import 'package:baleadafit/features/patients/data/paciente_ficha.dart';
import 'package:baleadafit/features/patients/data/patients_providers.dart';
import 'package:baleadafit/features/patients/data/patients_repository.dart';
import 'package:baleadafit/features/patients/ui/alta_paciente/alta_paciente_screen.dart';
import 'package:baleadafit/features/patients/ui/nueva_medicion_screen.dart';
import 'package:baleadafit/features/patients/ui/paciente_ficha_screen.dart';
import 'package:baleadafit/features/patients/ui/pacientes_screen.dart';
import 'package:baleadafit/features/shell/ui/app_shell.dart';
import 'package:baleadafit/shared/widgets/app_drawer.dart';
import 'package:baleadafit/features/home/ui/home_screen.dart';
import 'package:baleadafit/features/not_found/ui/not_found_screen.dart';
import 'package:baleadafit/features/showcase/ui/theme_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
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

/// Answers the wizard's submit without the network.
class _FakePatientsRepository implements PatientsRepository {
  final List<Map<String, Object?>> creados = [];

  @override
  Future<String> crearPaciente(Map<String, Object?> body) async {
    creados.add(body);
    return 'pac-new';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  SessionState session = const SessionState(
    status: SessionStatus.unauthenticated,
  ),
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...overrides,
        sessionControllerProvider.overrideWith(
          () => _FixedSessionController(session),
        ),
        // The ficha would otherwise reach for the network too.
        pacienteFichaProvider.overrideWith(
          (ref, id) => Future.value(
            PacienteFicha.fromJson({
              'paciente': {'id': id, 'nombre': 'Ana', 'apellido': 'Martínez'},
            }),
          ),
        ),
        // The wizard's second-to-last step reads both catalogues.
        condicionesProvider.overrideWith(
          (ref) => Future.value(const <CatalogoItem>[]),
        ),
        restriccionesProvider.overrideWith(
          (ref) => Future.value(const <CatalogoItem>[]),
        ),
        // The directory would otherwise reach for the network.
        pacientesDirectorioProvider.overrideWith(
          (ref, query) => Future.value(
            const Paged(
              items: [],
              meta: PageMeta(limit: 100, offset: 0, total: 0, hasMore: false),
            ),
          ),
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

  testWidgets('renders the shell with the section of the current route', (
    tester,
  ) async {
    final router = await _pumpApp(tester, session: _session);

    router.go(AppRoutes.pacientes);
    await pumpStable(tester);

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('Pacientes'), findsWidgets);
    // The shell owns the bar: the screen must not stack a second one.
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(PacientesScreen), findsOneWidget);
    expect(find.text('Mis pacientes'), findsOneWidget);
  });

  testWidgets('opens the drawer and navigates to another section', (
    tester,
  ) async {
    final router = await _pumpApp(tester, session: _session);
    router.go(AppRoutes.home);
    await pumpStable(tester);

    await tester.tap(find.byTooltip('Abrir menú'));
    await pumpStable(tester);

    expect(find.byType(AppDrawer), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(find.text('NUTRICIONISTA'), findsNothing);

    await tester.tap(find.text('Agenda de citas'));
    await pumpStable(tester);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.agenda,
    );
    expect(find.textContaining('Citas de la nutricionista'), findsOneWidget);
  });

  testWidgets('shows the signed-in name in the drawer profile card', (
    tester,
  ) async {
    await _pumpApp(tester, session: _session);

    await tester.tap(find.byTooltip('Abrir menú'));
    await pumpStable(tester);

    final inDrawer = find.descendant(
      of: find.byType(AppDrawer),
      matching: find.text('Nutricionista'),
    );
    expect(find.text('Sofía'), findsOneWidget);
    expect(inDrawer, findsOneWidget);
  });

  testWidgets(
    'opens a patient file inside the shell and backs out to the list',
    (tester) async {
      final router = await _pumpApp(tester, session: _session);

      router.go(AppRoutes.paciente('pac-1'));
      await pumpStable(tester);

      // The shell keeps the bar: the file draws its own back row, not an AppBar.
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(PacienteFichaScreen), findsOneWidget);
      expect(find.text('Ana Martínez'), findsOneWidget);

      await tester.tap(find.byTooltip('Volver a Mis pacientes'));
      await pumpStable(tester);

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.pacientes,
      );
      expect(find.byType(PacientesScreen), findsOneWidget);
    },
  );

  testWidgets('opens the measurement form from the ficha and pops back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = await _pumpApp(tester, session: _session);

    router.go(AppRoutes.paciente('pac-1'));
    await pumpStable(tester);
    await tester.tap(find.text('Registrar primera medición'));
    await pumpStable(tester);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.nuevaMedicion('pac-1'),
    );
    expect(find.byType(NuevaMedicionScreen), findsOneWidget);
    // The artboard has no shell bar: the form sits above the shell, not in it.
    expect(
      find.ancestor(
        of: find.byType(NuevaMedicionScreen),
        matching: find.byType(AppShell),
      ),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Cerrar sin guardar'));
    // The slide-out of a full-screen dialog outlasts the default frames.
    await pumpStable(tester, frames: 15);

    expect(find.byType(NuevaMedicionScreen), findsNothing);
    expect(find.byType(PacienteFichaScreen), findsOneWidget);
  });

  testWidgets('reaches the measurement form through a deep link', (
    tester,
  ) async {
    final router = await _pumpApp(tester, session: _session);

    router.go(AppRoutes.nuevaMedicion('pac-1'));
    await pumpStable(tester);

    expect(find.byType(NuevaMedicionScreen), findsOneWidget);
  });

  testWidgets('opens the new-patient wizard from the directory and closes it', (
    tester,
  ) async {
    final router = await _pumpApp(tester, session: _session);
    router.go(AppRoutes.pacientes);
    await pumpStable(tester);

    // The directory is empty in this harness, so the action is the empty state's.
    await tester.tap(find.text('Nuevo paciente'));
    await pumpStable(tester, frames: 15);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.nuevoPaciente,
    );
    expect(find.byType(AltaPacienteScreen), findsOneWidget);
    // The artboard has its own header with a close action: no shell around it.
    expect(
      find.ancestor(
        of: find.byType(AltaPacienteScreen),
        matching: find.byType(AppShell),
      ),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Cerrar sin guardar'));
    await pumpStable(tester, frames: 15);

    expect(find.byType(AltaPacienteScreen), findsNothing);
    expect(find.byType(PacientesScreen), findsOneWidget);
  });

  testWidgets('the wizard route is not mistaken for a patient id', (
    tester,
  ) async {
    final router = await _pumpApp(tester, session: _session);

    router.go(AppRoutes.nuevoPaciente);
    await pumpStable(tester);

    expect(find.byType(AltaPacienteScreen), findsOneWidget);
    expect(find.byType(PacienteFichaScreen), findsNothing);
  });

  testWidgets('a created patient lands on its ficha, over the directory', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _FakePatientsRepository();
    final router = await _pumpApp(
      tester,
      session: _session,
      overrides: [patientsRepositoryProvider.overrideWithValue(repository)],
    );
    router.go(AppRoutes.nuevoPaciente);
    await pumpStable(tester);

    await tester.enterText(find.byKey(const ValueKey('nombre')), 'Ana');
    await tester.enterText(find.byKey(const ValueKey('apellido')), 'Paz');
    await tester.enterText(
      find.byKey(const ValueKey('correo')),
      'ana@correo.com',
    );
    await tester.tap(find.text('Femenino'));
    await tester.enterText(
      find.byKey(const ValueKey('fechaNacimiento')),
      '15/03/1994',
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Siguiente'));
      await pumpStable(tester);
    }
    await tester.tap(find.text('Crear paciente'));
    await pumpStable(tester, frames: 15);

    expect(repository.creados, hasLength(1));
    expect(find.byType(PacienteFichaScreen), findsOneWidget);
    // The harness ficha is named after the id it was asked for.
    expect(find.text('Ana Martínez'), findsOneWidget);
    expect(find.byType(AltaPacienteScreen), findsNothing);

    // The ficha sits on the directory: back returns to the refreshed list.
    await tester.tap(find.byTooltip('Volver a Mis pacientes'));
    await pumpStable(tester, frames: 15);

    expect(find.byType(PacientesScreen), findsOneWidget);
  });

  testWidgets('Editar datos opens the prefilled form over the ficha', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = await _pumpApp(tester, session: _session);
    router.go(AppRoutes.paciente('pac-1'));
    await pumpStable(tester);

    await tester.tap(find.byTooltip('Más opciones'));
    await pumpStable(tester);
    await tester.tap(find.text('Editar datos'));
    await pumpStable(tester, frames: 15);

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      AppRoutes.editarPaciente('pac-1'),
    );
    expect(find.byType(AltaPacienteScreen), findsOneWidget);
    expect(find.text('Editar paciente'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Martínez'), findsOneWidget);
    // Full-screen like the wizard: no shell around it, the file stays below.
    expect(
      find.ancestor(
        of: find.byType(AltaPacienteScreen),
        matching: find.byType(AppShell),
      ),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Cerrar sin guardar'));
    await pumpStable(tester, frames: 15);

    expect(find.byType(AltaPacienteScreen), findsNothing);
    expect(find.byType(PacienteFichaScreen), findsOneWidget);
  });

  testWidgets('reaches the edit form through a deep link', (tester) async {
    final router = await _pumpApp(tester, session: _session);

    router.go(AppRoutes.editarPaciente('pac-1'));
    await pumpStable(tester);

    expect(find.byType(AltaPacienteScreen), findsOneWidget);
    expect(find.text('Editar paciente'), findsOneWidget);
  });
}
