import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/patients/data/paciente_ficha.dart';
import 'package:baleadafit/features/patients/data/paciente_resumen.dart';
import 'package:baleadafit/core/network/paged.dart';
import 'package:baleadafit/features/patients/data/patients_providers.dart';
import 'package:baleadafit/features/patients/data/patients_repository.dart';
import 'package:baleadafit/features/patients/ui/paciente_ficha_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the deactivations instead of calling the API.
class _FakeRepository implements PatientsRepository {
  _FakeRepository({this.failure});

  final ApiFailure? failure;
  final List<String> bajas = [];

  @override
  Future<void> darDeBaja(String pacienteId) async {
    bajas.add(pacienteId);
    if (failure != null) throw failure!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, Object?> _ficha() => {
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
};

int _cargasFicha = 0;
int _cargasDirectorio = 0;

Future<void> _pump(
  WidgetTester tester,
  _FakeRepository repository, {
  VoidCallback? onBack,
}) async {
  _cargasFicha = 0;
  _cargasDirectorio = 0;
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        patientsRepositoryProvider.overrideWithValue(repository),
        pacienteFichaProvider.overrideWith((ref, id) async {
          _cargasFicha++;
          return PacienteFicha.fromJson(_ficha());
        }),
        pacientesDirectorioProvider.overrideWith((ref, q) async {
          _cargasDirectorio++;
          return Paged<PacienteResumen>(
            items: const [],
            meta: const PageMeta(
              limit: 100,
              offset: 0,
              total: 0,
              hasMore: false,
            ),
          );
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              // Keeps the directory alive so its invalidation is observable.
              ref.watch(pacientesDirectorioProvider(''));
              return PacienteFichaScreen(
                pacienteId: 'pac-1',
                onBack: onBack ?? () {},
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _abrirMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Más opciones'));
  await tester.pumpAndSettle();
}

Future<void> _abrirConfirmacion(WidgetTester tester) async {
  await _abrirMenu(tester);
  await tester.tap(find.text('Dar de baja'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the overflow menu offers edit, medication and deactivate', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository());
    await _abrirMenu(tester);

    expect(find.text('Editar datos'), findsOneWidget);
    expect(find.text('Medicamentos'), findsOneWidget);
    expect(find.text('Dar de baja'), findsOneWidget);
  });

  testWidgets('deactivating asks first, naming the patient', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);
    await _abrirConfirmacion(tester);

    expect(find.text('¿Dar de baja a Paciente De Prueba?'), findsOneWidget);
    expect(
      find.text(
        'Deja de aparecer en tus pacientes activos. Su ficha, mediciones y '
        'planes se conservan, y lo encontrás en el filtro «Dados de baja».',
      ),
      findsOneWidget,
    );
    expect(find.text('Cancelar'), findsOneWidget);
    expect(repository.bajas, isEmpty);
  });

  testWidgets('cancel closes the dialog without calling the API', (
    tester,
  ) async {
    final repository = _FakeRepository();
    var salio = false;
    await _pump(tester, repository, onBack: () => salio = true);
    await _abrirConfirmacion(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Dar de baja a Paciente De Prueba?'), findsNothing);
    expect(repository.bajas, isEmpty);
    expect(salio, isFalse);
  });

  testWidgets('confirming deactivates once, refreshes and leaves the ficha', (
    tester,
  ) async {
    final repository = _FakeRepository();
    var salio = false;
    await _pump(tester, repository, onBack: () => salio = true);
    final fichaAntes = _cargasFicha;
    final directorioAntes = _cargasDirectorio;

    await _abrirConfirmacion(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Dar de baja'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.bajas, ['pac-1']);
    expect(salio, isTrue);
    expect(find.text('¿Dar de baja a Paciente De Prueba?'), findsNothing);
    expect(_cargasFicha, greaterThan(fichaAntes));
    expect(_cargasDirectorio, greaterThan(directorioAntes));
  });

  testWidgets('a refusal stays on the ficha and shows the API message', (
    tester,
  ) async {
    final repository = _FakeRepository(
      failure: const ApiFailure(
        mensaje: 'No existe o no pertenece al usuario.',
      ),
    );
    var salio = false;
    await _pump(tester, repository, onBack: () => salio = true);
    await _abrirConfirmacion(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Dar de baja'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.bajas, ['pac-1']);
    expect(salio, isFalse);
    expect(find.text('¿Dar de baja a Paciente De Prueba?'), findsNothing);
    expect(find.text('No existe o no pertenece al usuario.'), findsOneWidget);
  });
}
