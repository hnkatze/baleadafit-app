import 'dart:async';

import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/core/network/paged.dart';
import 'package:baleadafit/features/patients/data/paciente_resumen.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/patients/data/catalogo_item.dart';
import 'package:baleadafit/features/patients/data/patients_repository.dart';
import 'package:baleadafit/features/patients/ui/alta_paciente/alta_paciente_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:baleadafit/features/patients/data/patients_providers.dart';

const _catalogoCondiciones = [
  CatalogoItem(codigo: 'DIABETES_2', nombre: 'Diabetes tipo 2'),
  CatalogoItem(codigo: 'HIPERTENSION', nombre: 'Hipertensión'),
];

const _catalogoRestricciones = [
  CatalogoItem(codigo: 'SIN_GLUTEN', nombre: 'Sin gluten'),
  CatalogoItem(codigo: 'VEGETARIANO', nombre: 'Vegetariano'),
];

/// Records what the wizard posts and serves the two catalogues, instead of
/// calling the API.
class _FakeRepository implements PatientsRepository {
  _FakeRepository({
    this.failure,
    Future<List<CatalogoItem>> Function()? condicionesLoader,
    Future<List<CatalogoItem>> Function()? restriccionesLoader,
  }) : _condiciones = condicionesLoader ?? (() async => _catalogoCondiciones),
       _restricciones =
           restriccionesLoader ?? (() async => _catalogoRestricciones);

  ApiFailure? failure;
  final Future<List<CatalogoItem>> Function() _condiciones;
  final Future<List<CatalogoItem>> Function() _restricciones;
  final List<Map<String, Object?>> creados = [];
  int cargasDeRestricciones = 0;

  @override
  Future<String> crearPaciente(Map<String, Object?> body) async {
    creados.add(body);
    if (failure != null) throw failure!;
    return 'pac-new';
  }

  @override
  Future<List<CatalogoItem>> condiciones() => _condiciones();

  @override
  Future<List<CatalogoItem>> restricciones() {
    cargasDeRestricciones++;
    return _restricciones();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  _FakeRepository repository, {
  List<String>? creados,
  VoidCallback? onCerrar,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        patientsRepositoryProvider.overrideWithValue(repository),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: AltaPacienteScreen(
          onCerrar: onCerrar ?? () {},
          onCreado: (id) => creados?.add(id),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Fields are found by key (the body key they feed), since labels sit above
/// the input and not inside it.
Future<void> _escribir(WidgetTester tester, String clave, String texto) async {
  await tester.enterText(find.byKey(ValueKey(clave)), texto);
}

Future<void> _siguiente(WidgetTester tester) async {
  await tester.tap(find.text('Siguiente'));
  await tester.pumpAndSettle();
}

/// Taps the last step's action. A successful submit keeps the button loading
/// (the route is about to be replaced and a second tap must not repost), so
/// the spinner never settles and the frames are pumped by hand.
Future<void> _crear(WidgetTester tester) async {
  await tester.tap(find.text('Crear paciente'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _llenarIdentidad(WidgetTester tester) async {
  await _escribir(tester, 'nombre', 'Ana');
  await _escribir(tester, 'apellido', 'Paz');
  await _escribir(tester, 'correo', 'ana@correo.com');
  await tester.tap(find.text('Femenino'));
  await _escribir(tester, 'fechaNacimiento', '15/03/1994');
  await tester.pump();
}

String _fechaCorta(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
}

String _fechaIso(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${fecha.year}-${dos(fecha.month)}-${dos(fecha.day)}';
}

void main() {
  group('step 1, Identidad', () {
    testWidgets('draws the artboard copy', (tester) async {
      await _pump(tester, _FakeRepository());

      expect(find.text('Nuevo paciente'), findsOneWidget);
      expect(find.text('PASO 1 DE 4'), findsOneWidget);
      // The step name also heads the page, so it shows twice with the stepper.
      expect(find.text('Identidad'), findsNWidgets(2));
      expect(find.text('Objetivo'), findsOneWidget);
      expect(find.text('Clínica'), findsOneWidget);
      expect(find.text('Hábitos'), findsOneWidget);
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Apellido'), findsOneWidget);
      expect(find.text('Correo'), findsOneWidget);
      expect(
        find.text(
          'Con este correo el paciente entra a su app y ve su plan. '
          'Usá el que va a usar para iniciar sesión.',
        ),
        findsOneWidget,
      );
      expect(find.text('Teléfono · opcional'), findsOneWidget);
      expect(find.text('Sexo'), findsOneWidget);
      expect(find.text('Femenino'), findsOneWidget);
      expect(find.text('Masculino'), findsOneWidget);
      expect(find.text('Fecha de nacimiento'), findsOneWidget);
      expect(
        find.text('Con ella se calculan la edad y el requerimiento.'),
        findsOneWidget,
      );
      expect(find.text('Siguiente'), findsOneWidget);
      expect(find.byTooltip('Cerrar sin guardar'), findsOneWidget);
    });

    testWidgets('blocks the advance and sends nothing without the required', (
      tester,
    ) async {
      final repository = _FakeRepository();
      await _pump(tester, repository);

      await _siguiente(tester);

      expect(find.text('PASO 1 DE 4'), findsOneWidget);
      expect(find.text('Ingresá el nombre'), findsOneWidget);
      expect(find.text('Ingresá el apellido'), findsOneWidget);
      expect(find.text('Ingresá el correo'), findsOneWidget);
      expect(find.text('Elegí el sexo'), findsOneWidget);
      expect(find.text('Ingresá la fecha de nacimiento'), findsOneWidget);
      expect(repository.creados, isEmpty);
    });

    testWidgets('rejects a malformed email and a future birth date', (
      tester,
    ) async {
      await _pump(tester, _FakeRepository());
      await _llenarIdentidad(tester);
      await _escribir(tester, 'correo', 'ana@');
      await _escribir(
        tester,
        'fechaNacimiento',
        _fechaCorta(DateTime.now().add(const Duration(days: 30))),
      );

      await _siguiente(tester);

      expect(find.text('PASO 1 DE 4'), findsOneWidget);
      expect(find.text('Revisá el correo'), findsOneWidget);
      expect(find.text('La fecha no puede ser futura'), findsOneWidget);
    });

    testWidgets('closing leaves through onCerrar', (tester) async {
      var cerrado = 0;
      await _pump(tester, _FakeRepository(), onCerrar: () => cerrado++);

      await tester.tap(find.byTooltip('Cerrar sin guardar'));

      expect(cerrado, 1);
    });
  });

  group('step 2, Objetivo', () {
    Future<void> irAlPaso2(WidgetTester tester, _FakeRepository repo) async {
      await _pump(tester, repo);
      await _llenarIdentidad(tester);
      await _siguiente(tester);
    }

    testWidgets('draws the artboard copy', (tester) async {
      await irAlPaso2(tester, _FakeRepository());

      expect(find.text('PASO 2 DE 4'), findsOneWidget);
      expect(find.text('Meta'), findsOneWidget);
      expect(find.text('Bajar'), findsOneWidget);
      expect(find.text('−500 kcal'), findsOneWidget);
      expect(find.text('Mantener'), findsOneWidget);
      expect(find.text('0 kcal'), findsOneWidget);
      expect(find.text('Subir'), findsOneWidget);
      expect(find.text('+300 kcal'), findsOneWidget);
      expect(find.text('Peso objetivo · kg'), findsOneWidget);
      expect(find.text('Para cuándo'), findsOneWidget);
      expect(find.text('Nivel de actividad'), findsOneWidget);
      for (final (nivel, factor) in [
        ('Sedentario', '×1.2'),
        ('Ligero', '×1.375'),
        ('Moderado', '×1.55'),
        ('Intenso', '×1.725'),
        ('Muy intenso', '×1.9'),
      ]) {
        expect(find.text(nivel), findsOneWidget);
        expect(find.text(factor), findsOneWidget);
      }
      expect(find.text('Estado fisiológico'), findsOneWidget);
      expect(find.text('Ninguno'), findsOneWidget);
      expect(find.text('Embarazo'), findsOneWidget);
      expect(find.text('Lactancia'), findsOneWidget);
      expect(
        find.text('Embarazo y lactancia cambian el requerimiento calórico.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Volver al paso anterior'), findsOneWidget);
    });

    testWidgets('blocks the advance on an out-of-range goal weight', (
      tester,
    ) async {
      final repository = _FakeRepository();
      await irAlPaso2(tester, repository);
      await _escribir(tester, 'pesoObjetivoKg', '5');

      await _siguiente(tester);

      expect(find.text('PASO 2 DE 4'), findsOneWidget);
      expect(find.text('Entre 20 y 400'), findsOneWidget);
      expect(repository.creados, isEmpty);
    });

    testWidgets('blocks the advance on a goal date that already passed', (
      tester,
    ) async {
      await irAlPaso2(tester, _FakeRepository());
      await _escribir(tester, 'fechaObjetivo', '01/01/2020');

      await _siguiente(tester);

      expect(find.text('PASO 2 DE 4'), findsOneWidget);
      expect(find.text('Elegí una fecha futura'), findsOneWidget);
    });

    testWidgets('back keeps what was typed in both steps', (tester) async {
      await irAlPaso2(tester, _FakeRepository());
      await _escribir(tester, 'pesoObjetivoKg', '70');
      await tester.tap(find.text('Mantener'));
      await tester.pump();

      await tester.tap(find.byTooltip('Volver al paso anterior'));
      await tester.pumpAndSettle();

      expect(find.text('PASO 1 DE 4'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Paz'), findsOneWidget);
      expect(find.text('ana@correo.com'), findsOneWidget);
      expect(find.text('15/03/1994'), findsOneWidget);

      await _siguiente(tester);

      expect(find.text('PASO 2 DE 4'), findsOneWidget);
      expect(find.text('70'), findsOneWidget);
    });

    testWidgets('the system back goes to the previous step, not out', (
      tester,
    ) async {
      var cerrado = 0;
      await _pump(tester, _FakeRepository(), onCerrar: () => cerrado++);
      await _llenarIdentidad(tester);
      await _siguiente(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('PASO 1 DE 4'), findsOneWidget);
      expect(cerrado, 0);
    });
  });

  group('step 3, Clínica', () {
    Future<void> irAlPaso3(WidgetTester tester, _FakeRepository repo) async {
      await _pump(tester, repo);
      await _llenarIdentidad(tester);
      await _siguiente(tester);
      await _siguiente(tester);
    }

    testWidgets('offers both catalogues and the free-text fields', (
      tester,
    ) async {
      await irAlPaso3(tester, _FakeRepository());

      expect(find.text('PASO 3 DE 4'), findsOneWidget);
      expect(find.text('Condiciones'), findsOneWidget);
      expect(find.text('Diabetes tipo 2'), findsOneWidget);
      expect(find.text('Hipertensión'), findsOneWidget);
      expect(find.text('Restricciones'), findsOneWidget);
      expect(find.text('Sin gluten'), findsOneWidget);
      expect(find.text('Vegetariano'), findsOneWidget);
      expect(find.text('Alergias'), findsOneWidget);
      expect(find.text('Cirugías'), findsOneWidget);
      expect(find.text('Suplementos'), findsOneWidget);
      expect(find.text('Motivo de la consulta'), findsOneWidget);
    });

    testWidgets('each catalogue has its own loading and failure state', (
      tester,
    ) async {
      final cargando = Completer<List<CatalogoItem>>();
      final repository = _FakeRepository(
        condicionesLoader: () => cargando.future,
        restriccionesLoader: () => Future.error(
          const ApiFailure(mensaje: 'No pudimos cargar las restricciones.'),
        ),
      );
      await _pump(tester, repository);
      await _llenarIdentidad(tester);
      await _siguiente(tester);
      // The spinner never stops, so the step is reached without settling.
      await tester.tap(find.text('Siguiente'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No pudimos cargar las restricciones.'), findsOneWidget);
      expect(find.text('Condiciones'), findsOneWidget);
      expect(find.text('Restricciones'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      expect(repository.cargasDeRestricciones, 2);
    });

    testWidgets('a catalogue that failed does not block the advance', (
      tester,
    ) async {
      final repository = _FakeRepository(
        condicionesLoader: () => Future.error(Exception('boom')),
      );
      await irAlPaso3(tester, repository);

      expect(find.text('Algo salió mal. Intentá de nuevo.'), findsOneWidget);

      await _siguiente(tester);

      expect(find.text('PASO 4 DE 4'), findsOneWidget);
    });

    testWidgets('the picked chips survive going back and forth', (
      tester,
    ) async {
      await irAlPaso3(tester, _FakeRepository());
      await tester.tap(find.text('Hipertensión'));
      await tester.pump();
      await _escribir(tester, 'alergias', 'Maní');

      await _siguiente(tester);
      await tester.tap(find.byTooltip('Volver al paso anterior'));
      await tester.pumpAndSettle();

      expect(find.text('Maní'), findsOneWidget);
      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Hipertensión'),
      );
      expect(chip.selected, isTrue);
    });
  });

  group('step 4, Hábitos', () {
    Future<void> irAlPaso4(WidgetTester tester, _FakeRepository repo) async {
      await _pump(tester, repo);
      await _llenarIdentidad(tester);
      await _siguiente(tester);
      await _siguiente(tester);
      await _siguiente(tester);
    }

    testWidgets('draws the habit fields and the submit action', (tester) async {
      await irAlPaso4(tester, _FakeRepository());

      expect(find.text('PASO 4 DE 4'), findsOneWidget);
      expect(find.text('Comidas al día'), findsOneWidget);
      expect(find.text('Agua · litros'), findsOneWidget);
      expect(find.text('Sueño · horas'), findsOneWidget);
      expect(find.text('Alcohol'), findsOneWidget);
      expect(find.text('Tabaco'), findsOneWidget);
      expect(find.text('Quién cocina'), findsOneWidget);
      expect(find.text('Presupuesto'), findsOneWidget);
      expect(find.text('Notas'), findsOneWidget);
      expect(find.text('Crear paciente'), findsOneWidget);
      expect(find.text('Siguiente'), findsNothing);
    });

    testWidgets('blocks the submit on an out-of-range habit', (tester) async {
      final repository = _FakeRepository();
      await irAlPaso4(tester, repository);
      await _escribir(tester, 'horasSueno', '30');

      await tester.tap(find.text('Crear paciente'));
      await tester.pumpAndSettle();

      expect(find.text('Entre 0 y 24'), findsOneWidget);
      expect(repository.creados, isEmpty);
    });

    testWidgets('meals per day must be a whole number', (tester) async {
      final repository = _FakeRepository();
      await irAlPaso4(tester, repository);
      await _escribir(tester, 'comidasAlDia', '0');

      await tester.tap(find.text('Crear paciente'));
      await tester.pumpAndSettle();

      expect(find.text('Entre 1 y 10'), findsOneWidget);
      expect(repository.creados, isEmpty);
    });
  });

  group('submit', () {
    testWidgets('posts once with only the required fields and the defaults', (
      tester,
    ) async {
      final repository = _FakeRepository();
      final creados = <String>[];
      await _pump(tester, repository, creados: creados);
      await _llenarIdentidad(tester);
      await _siguiente(tester);
      await _siguiente(tester);
      await _siguiente(tester);

      await _crear(tester);

      // Empty text, empty selections and untouched numbers are not sent as
      // `""` or `[]`: the API validates what it receives.
      expect(repository.creados, [
        {
          'nombre': 'Ana',
          'apellido': 'Paz',
          'correo': 'ana@correo.com',
          'sexo': 'F',
          'fechaNacimiento': '1994-03-15',
          'nivelActividad': 'SEDENTARIO',
          'meta': 'BAJAR',
          'estadoFisiologico': 'NINGUNO',
        },
      ]);
      expect(creados, ['pac-new']);
    });

    testWidgets('posts every documented field, numbers as numbers', (
      tester,
    ) async {
      final repository = _FakeRepository();
      final creados = <String>[];
      final objetivo = DateTime.now().add(const Duration(days: 90));
      await _pump(tester, repository, creados: creados);

      await _llenarIdentidad(tester);
      await _escribir(tester, 'telefono', '+504 9999-0000');
      await _siguiente(tester);

      await tester.tap(find.text('Mantener'));
      await tester.tap(find.text('Moderado'));
      await tester.tap(find.text('Lactancia'));
      await _escribir(tester, 'pesoObjetivoKg', '62,5');
      await _escribir(tester, 'fechaObjetivo', _fechaCorta(objetivo));
      await tester.pump();
      await _siguiente(tester);

      await tester.tap(find.text('Diabetes tipo 2'));
      await tester.tap(find.text('Sin gluten'));
      await _escribir(tester, 'alergias', 'Maní');
      await _escribir(tester, 'cirugias', 'Cesárea 2020');
      await _escribir(tester, 'suplementos', 'Omega 3');
      await _escribir(tester, 'motivoConsulta', 'Bajar de peso');
      await tester.pump();
      await _siguiente(tester);

      await _escribir(tester, 'comidasAlDia', '4');
      await _escribir(tester, 'aguaLitros', '2,5');
      await _escribir(tester, 'horasSueno', '7');
      await _escribir(tester, 'alcohol', 'Ocasional');
      await _escribir(tester, 'tabaco', 'No');
      await _escribir(tester, 'quienCocina', 'Ella misma');
      await _escribir(tester, 'presupuesto', 'Medio');
      await _escribir(tester, 'notas', 'Prefiere cenar temprano');
      await tester.pump();

      await _crear(tester);

      expect(repository.creados, hasLength(1));
      expect(repository.creados.single, {
        'nombre': 'Ana',
        'apellido': 'Paz',
        'correo': 'ana@correo.com',
        'telefono': '+504 9999-0000',
        'sexo': 'F',
        'fechaNacimiento': '1994-03-15',
        'nivelActividad': 'MODERADO',
        'meta': 'MANTENER',
        'pesoObjetivoKg': 62.5,
        'fechaObjetivo': _fechaIso(objetivo),
        'estadoFisiologico': 'LACTANCIA',
        'condiciones': ['DIABETES_2'],
        'restricciones': ['SIN_GLUTEN'],
        'alergias': 'Maní',
        'cirugias': 'Cesárea 2020',
        'suplementos': 'Omega 3',
        'motivoConsulta': 'Bajar de peso',
        'notas': 'Prefiere cenar temprano',
        'presupuesto': 'Medio',
        'quienCocina': 'Ella misma',
        'alcohol': 'Ocasional',
        'tabaco': 'No',
        'comidasAlDia': 4,
        'aguaLitros': 2.5,
        'horasSueno': 7,
      });
      expect(repository.creados.single['comidasAlDia'], isA<int>());
      expect(creados, ['pac-new']);
    });

    testWidgets('refreshes the directory once the patient exists', (
      tester,
    ) async {
      var cargas = 0;
      await _pump(
        tester,
        _FakeRepository(),
        overrides: [
          pacientesDirectorioProvider.overrideWith((ref, query) {
            cargas++;
            return Future.value(
              const Paged<PacienteResumen>(
                items: [],
                meta: PageMeta(limit: 100, offset: 0, total: 0, hasMore: false),
              ),
            );
          }),
        ],
      );
      // Someone is watching the directory, as the screen under the wizard does.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AltaPacienteScreen)),
      );
      final suscripcion = container.listen(
        pacientesDirectorioProvider(''),
        (_, _) {},
      );
      addTearDown(suscripcion.close);
      await tester.pump();
      expect(cargas, 1);

      await _llenarIdentidad(tester);
      await _siguiente(tester);
      await _siguiente(tester);
      await _siguiente(tester);
      await _crear(tester);

      expect(cargas, 2);
    });

    testWidgets('shows the API refusal, stays on the step and can retry', (
      tester,
    ) async {
      final repository = _FakeRepository(
        failure: const ApiFailure(
          mensaje: 'Ya existe un paciente con ese correo.',
          statusCode: 409,
        ),
      );
      final creados = <String>[];
      await _pump(tester, repository, creados: creados);
      await _llenarIdentidad(tester);
      await _siguiente(tester);
      await _siguiente(tester);
      await _siguiente(tester);

      await _crear(tester);

      expect(
        find.text('Ya existe un paciente con ese correo.'),
        findsOneWidget,
      );
      expect(find.text('PASO 4 DE 4'), findsOneWidget);
      expect(creados, isEmpty);

      repository.failure = null;
      await _crear(tester);

      expect(repository.creados, hasLength(2));
      expect(creados, ['pac-new']);
    });
  });
}
