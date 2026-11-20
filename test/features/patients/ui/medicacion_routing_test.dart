import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/router/app_router.dart';
import 'package:baleadafit/core/router/app_routes.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/auth/application/session_controller.dart';
import 'package:baleadafit/features/auth/data/auth_session.dart';
import 'package:baleadafit/features/auth/data/user_role.dart';
import 'package:baleadafit/features/patients/data/patients_providers.dart';
import 'package:baleadafit/features/patients/data/patients_repository.dart';
import 'package:baleadafit/features/patients/ui/medicacion/medicacion_screen.dart';
import 'package:baleadafit/features/patients/ui/medicacion/medicamento_form_screen.dart';
import 'package:baleadafit/features/patients/ui/paciente_ficha_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/pump.dart';

class _Sesion extends SessionController {
  @override
  SessionState build() => const SessionState(
    status: SessionStatus.authenticated,
    session: AuthSession(rol: UserRole.nutricionista, displayName: 'Sofía'),
  );

  @override
  Future<void> restore() async {}
}

Map<String, Object?> _ficha() => {
  'ok': true,
  'data': {
    'paciente': {
      'id': 'pac-1',
      'nombre': 'Paciente',
      'apellido': 'De Prueba',
      'sexo': 'M',
      'activo': true,
    },
    'cabecera': <String, Object?>{},
    'progreso': <String, Object?>{},
    'requerimiento': null,
    'adherencia30d': {'porcentaje': null, 'cumplidos': 0, 'total': 0},
    'alertas': <Object?>[],
    'evolucion': <Object?>[],
    'consultas': {'proximas': <Object?>[]},
    'planes': <Object?>[],
    'situacion': {
      'medicacion': [
        {
          'id': 'med-1',
          'nombre': 'Metformina',
          'dosis': '500 mg',
          'frecuencia': 'Cada 12 horas con comida',
          'activo': true,
        },
      ],
    },
  },
};

Future<GoRouter> _pump(
  WidgetTester tester,
  FakeHttpAdapter adapter, {
  String location = '/pacientes/pac-1',
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(_Sesion.new),
        patientsRepositoryProvider.overrideWithValue(
          PatientsRepository(ApiClient(dioWith(adapter))),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await pumpStable(tester);
  return router;
}

FakeHttpAdapter _adapter() => FakeHttpAdapter((options) async {
  if (options.method == 'DELETE') {
    return jsonBody({
      'ok': true,
      'data': {'id': 'med-1', 'nombre': 'Metformina', 'activo': false},
    });
  }
  return jsonBody(_ficha());
});

String _ubicacion(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

void main() {
  group('rutas (S13)', () {
    test('nest under the patient file', () {
      expect(AppRoutes.medicacion('pac-1'), '/pacientes/pac-1/medicacion');
      expect(
        AppRoutes.nuevaMedicacion('pac-1'),
        '/pacientes/pac-1/medicacion/nueva',
      );
      expect(
        AppRoutes.medicamento('pac-1', 'med-1'),
        '/pacientes/pac-1/medicacion/med-1',
      );
    });

    test('encode the ids', () {
      expect(
        AppRoutes.medicamento('a b', 'c/d'),
        '/pacientes/a%20b/medicacion/c%2Fd',
      );
    });
  });

  group('ruteo (S13, S15)', () {
    testWidgets('the menu entry opens the medication list and back returns', (
      tester,
    ) async {
      final adapter = _adapter();
      final router = await _pump(tester, adapter);
      expect(find.byType(PacienteFichaScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Más opciones'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medicamentos'));
      await pumpStable(tester);

      expect(_ubicacion(router), AppRoutes.medicacion('pac-1'));
      expect(find.byType(MedicacionScreen), findsOneWidget);
      expect(find.text('Metformina'), findsOneWidget);
      expect(find.text('Paciente De Prueba'), findsOneWidget);
      // Only the ficha was asked for: the list needs no call of its own.
      expect(
        adapter.requests.where((r) => !r.path.endsWith('/ficha')),
        isEmpty,
      );

      await tester.tap(find.byTooltip('Volver a la ficha'));
      await pumpStable(tester);

      expect(_ubicacion(router), AppRoutes.paciente('pac-1'));
      expect(find.byType(PacienteFichaScreen), findsOneWidget);
      expect(find.byType(MedicacionScreen), findsNothing);
    });

    testWidgets('a deep link to the list backs out onto the ficha', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        _adapter(),
        location: AppRoutes.medicacion('pac-1'),
      );
      expect(find.byType(MedicacionScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Volver a la ficha'));
      await pumpStable(tester);

      expect(_ubicacion(router), AppRoutes.paciente('pac-1'));
    });

    testWidgets('Registrar medicamento opens the empty form, x closes it', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        _adapter(),
        location: AppRoutes.medicacion('pac-1'),
      );

      await tester.tap(find.text('Registrar medicamento'));
      await pumpStable(tester);

      expect(_ubicacion(router), AppRoutes.nuevaMedicacion('pac-1'));
      expect(find.byType(MedicamentoFormScreen), findsOneWidget);
      expect(find.text('Dar de baja'), findsNothing);

      await tester.tap(find.byTooltip('Cerrar sin guardar'));
      await pumpStable(tester);

      expect(_ubicacion(router), AppRoutes.medicacion('pac-1'));
      expect(find.byType(MedicacionScreen), findsOneWidget);
    });

    testWidgets('a row opens the editor with the medication loaded', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        _adapter(),
        location: AppRoutes.medicacion('pac-1'),
      );

      await tester.tap(find.text('Metformina'));
      await pumpStable(tester);

      expect(_ubicacion(router), AppRoutes.medicamento('pac-1', 'med-1'));
      expect(find.text('Editar medicamento'), findsOneWidget);
      expect(find.text('Dar de baja'), findsWidgets);
    });

    testWidgets('an id that is not in the ficha falls back to the list', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        _adapter(),
        location: AppRoutes.medicamento('pac-1', 'no-existe'),
      );

      expect(_ubicacion(router), AppRoutes.medicacion('pac-1'));
      expect(find.byType(MedicacionScreen), findsOneWidget);
      expect(find.byType(MedicamentoFormScreen), findsNothing);
    });

    testWidgets('deactivating from the editor returns to the list', (
      tester,
    ) async {
      final adapter = _adapter();
      final router = await _pump(
        tester,
        adapter,
        location: AppRoutes.medicamento('pac-1', 'med-1'),
      );

      final baja = find.widgetWithText(OutlinedButton, 'Dar de baja');
      final boton = baja.evaluate().isNotEmpty
          ? baja
          : find.text('Dar de baja');
      await tester.ensureVisible(boton.first);
      await tester.tap(boton.first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Dar de baja'),
        ),
      );
      await pumpStable(tester);

      expect(
        adapter.requests.where((r) => r.method == 'DELETE').single.path,
        '/medicamentos/med-1',
      );
      expect(_ubicacion(router), AppRoutes.medicacion('pac-1'));
    });
  });
}
