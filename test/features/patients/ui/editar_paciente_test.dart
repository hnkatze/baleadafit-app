import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/core/network/paged.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/patients/data/catalogo_item.dart';
import 'package:baleadafit/features/patients/data/paciente_ficha.dart';
import 'package:baleadafit/features/patients/data/paciente_resumen.dart';
import 'package:baleadafit/features/patients/data/patients_providers.dart';
import 'package:baleadafit/features/patients/data/patients_repository.dart';
import 'package:baleadafit/features/patients/ui/alta_paciente/alta_paciente_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _condiciones = [
  CatalogoItem(codigo: 'DIABETES_2', nombre: 'Diabetes tipo 2'),
  CatalogoItem(codigo: 'HIPERTENSION', nombre: 'Hipertensión'),
];

const _restricciones = [
  CatalogoItem(codigo: 'SIN_GLUTEN', nombre: 'Sin gluten'),
  CatalogoItem(codigo: 'VEGETARIANO', nombre: 'Vegetariano'),
];

/// Records what the edit form patches and serves the two catalogues.
class _FakeRepository implements PatientsRepository {
  _FakeRepository({this.failure});

  ApiFailure? failure;
  final List<(String, Map<String, Object?>)> parches = [];

  @override
  Future<void> actualizarPaciente(
    String pacienteId, {
    required Map<String, Object?> body,
  }) async {
    parches.add((pacienteId, body));
    if (failure != null) throw failure!;
  }

  @override
  Future<List<CatalogoItem>> condiciones() async => _condiciones;

  @override
  Future<List<CatalogoItem>> restricciones() async => _restricciones;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _iso(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${fecha.year}-${dos(fecha.month)}-${dos(fecha.day)}';
}

PacienteFicha _ficha({bool conRelaciones = true, String? fechaObjetivo}) =>
    PacienteFicha.fromJson({
      'paciente': {
        'id': 'pac-1',
        'nombre': 'Ana',
        'apellido': 'Paz',
        'sexo': 'F',
        'fechaNacimiento': '1994-03-15T00:00:00.000Z',
        'correo': 'ana@correo.com',
        'telefono': '+504 9999-0000',
        'meta': 'MANTENER',
        'nivelActividad': 'MODERADO',
        'estadoFisiologico': 'LACTANCIA',
        'pesoObjetivoKg': 62.5,
        'fechaObjetivo': ?fechaObjetivo,
        'notas': 'Cena temprano',
      },
      'situacion': {
        // Both shapes the relation may arrive in: nested object and bare code.
        'condiciones': conRelaciones
            ? [
                {
                  'condicion': {'codigo': 'DIABETES_2'},
                },
              ]
            : <Object?>[],
        'restricciones': conRelaciones ? ['SIN_GLUTEN'] : <Object?>[],
        'alergias': 'Maní',
        'cirugias': 'Cesárea 2020',
        'suplementos': 'Omega 3',
        'motivoConsulta': 'Bajar de peso',
      },
      'habitos': {
        'comidasAlDia': 4,
        'aguaLitros': 2.5,
        'horasSueno': 7,
        'alcohol': 'Ocasional',
        'tabaco': 'No',
        'quienCocina': 'Ella misma',
        'presupuesto': 'Medio',
      },
    });

int _cargasFicha = 0;
int _cargasDirectorio = 0;

Future<void> _pump(
  WidgetTester tester,
  _FakeRepository repository,
  PacienteFicha ficha, {
  VoidCallback? onGuardado,
}) async {
  _cargasFicha = 0;
  _cargasDirectorio = 0;
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        patientsRepositoryProvider.overrideWithValue(repository),
        pacienteFichaProvider.overrideWith((ref, id) async {
          _cargasFicha++;
          return ficha;
        }),
        pacientesDirectorioProvider.overrideWith((ref, q) async {
          _cargasDirectorio++;
          return const Paged<PacienteResumen>(
            items: [],
            meta: PageMeta(limit: 100, offset: 0, total: 0, hasMore: false),
          );
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Consumer(
          builder: (context, ref, _) {
            // Someone watches both, as the ficha and the list under the form do.
            ref.watch(pacienteFichaProvider('pac-1'));
            ref.watch(pacientesDirectorioProvider(''));
            return AltaPacienteScreen.editar(
              pacienteId: 'pac-1',
              ficha: ficha,
              onCerrar: () {},
              onGuardado: onGuardado ?? () {},
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _siguiente(WidgetTester tester) async {
  await tester.tap(find.text('Siguiente'));
  await tester.pumpAndSettle();
}

Future<void> _alPaso4(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await _siguiente(tester);
  }
}

Future<void> _guardar(WidgetTester tester) async {
  await tester.tap(find.text('Guardar cambios'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('opens prefilled from the ficha, step by step', (tester) async {
    await _pump(tester, _FakeRepository(), _ficha());

    expect(find.text('Editar paciente'), findsOneWidget);
    expect(find.text('PASO 1 DE 4'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Paz'), findsOneWidget);
    expect(find.text('ana@correo.com'), findsOneWidget);
    expect(find.text('+504 9999-0000'), findsOneWidget);
    expect(find.text('15/03/1994'), findsOneWidget);

    await _siguiente(tester);
    expect(find.text('62.5'), findsOneWidget);

    await _siguiente(tester);
    expect(
      tester
          .widget<FilterChip>(
            find.widgetWithText(FilterChip, 'Diabetes tipo 2'),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Hipertensión'))
          .selected,
      isFalse,
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Sin gluten'))
          .selected,
      isTrue,
    );
    expect(find.text('Maní'), findsOneWidget);

    await _siguiente(tester);
    expect(find.text('PASO 4 DE 4'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsOneWidget);
    expect(find.text('Crear paciente'), findsNothing);
    expect(find.text('Cena temprano'), findsOneWidget);
  });

  testWidgets('saves once with the complete selections, even untouched', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final objetivo = DateTime.now().add(const Duration(days: 90));
    var guardado = 0;
    await _pump(
      tester,
      repository,
      _ficha(fechaObjetivo: '${_iso(objetivo)}T00:00:00.000Z'),
      onGuardado: () => guardado++,
    );
    await _alPaso4(tester);

    await _guardar(tester);

    expect(repository.parches, hasLength(1));
    final (id, body) = repository.parches.single;
    expect(id, 'pac-1');
    expect(body, {
      'nombre': 'Ana',
      'apellido': 'Paz',
      'correo': 'ana@correo.com',
      'telefono': '+504 9999-0000',
      'sexo': 'F',
      'fechaNacimiento': '1994-03-15',
      'nivelActividad': 'MODERADO',
      'meta': 'MANTENER',
      'pesoObjetivoKg': 62.5,
      'fechaObjetivo': _iso(objetivo),
      'estadoFisiologico': 'LACTANCIA',
      'condiciones': ['DIABETES_2'],
      'restricciones': ['SIN_GLUTEN'],
      'alergias': 'Maní',
      'cirugias': 'Cesárea 2020',
      'suplementos': 'Omega 3',
      'motivoConsulta': 'Bajar de peso',
      'notas': 'Cena temprano',
      'presupuesto': 'Medio',
      'quienCocina': 'Ella misma',
      'alcohol': 'Ocasional',
      'tabaco': 'No',
      'comidasAlDia': 4,
      'aguaLitros': 2.5,
      'horasSueno': 7,
    });
    expect(guardado, 1);
  });

  testWidgets('a patient with no relations still sends both lists, empty', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository, _ficha(conRelaciones: false));
    await _alPaso4(tester);

    await _guardar(tester);

    final body = repository.parches.single.$2;
    expect(body['condiciones'], <String>[]);
    expect(body['restricciones'], <String>[]);
  });

  testWidgets('a toggled chip is sent along with the untouched ones', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository, _ficha());
    await _siguiente(tester);
    await _siguiente(tester);
    await tester.tap(find.text('Hipertensión'));
    await tester.tap(find.text('Sin gluten'));
    await tester.pump();
    await _siguiente(tester);

    await _guardar(tester);

    final body = repository.parches.single.$2;
    expect(body['condiciones'], ['DIABETES_2', 'HIPERTENSION']);
    expect(body['restricciones'], <String>[]);
  });

  testWidgets(
    'a goal date that already passed does not block an untouched save',
    (tester) async {
      final repository = _FakeRepository();
      await _pump(
        tester,
        repository,
        _ficha(fechaObjetivo: '2020-01-01T00:00:00.000Z'),
      );
      await _siguiente(tester);

      await _siguiente(tester);

      expect(find.text('PASO 3 DE 4'), findsOneWidget);
    },
  );

  testWidgets('a 409 keeps the form open with the message and the values', (
    tester,
  ) async {
    final repository = _FakeRepository(
      failure: const ApiFailure(
        mensaje: 'Ese correo ya es de otro paciente.',
        statusCode: 409,
      ),
    );
    var guardado = 0;
    await _pump(tester, repository, _ficha(), onGuardado: () => guardado++);
    await tester.enterText(find.byKey(const ValueKey('correo')), 'otra@x.com');
    await _alPaso4(tester);

    await _guardar(tester);

    expect(find.text('Ese correo ya es de otro paciente.'), findsOneWidget);
    expect(find.text('PASO 4 DE 4'), findsOneWidget);
    expect(guardado, 0);

    await tester.tap(find.byTooltip('Volver al paso anterior'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Volver al paso anterior'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Volver al paso anterior'));
    await tester.pumpAndSettle();
    expect(find.text('otra@x.com'), findsOneWidget);

    repository.failure = null;
    await _alPaso4(tester);
    await _guardar(tester);

    expect(repository.parches, hasLength(2));
    expect(repository.parches.last.$2['correo'], 'otra@x.com');
    expect(guardado, 1);
  });

  testWidgets('a saved patient refreshes the ficha and the directory', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository(), _ficha());
    expect(_cargasFicha, 1);
    expect(_cargasDirectorio, 1);
    await _alPaso4(tester);

    await _guardar(tester);

    expect(_cargasFicha, 2);
    expect(_cargasDirectorio, 2);
  });
}
