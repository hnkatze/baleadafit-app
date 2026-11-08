import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/core/router/app_routes.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/patients/data/paciente_ficha.dart';
import 'package:baleadafit/features/patients/data/patients_providers.dart';
import 'package:baleadafit/features/patients/data/patients_repository.dart';
import 'package:baleadafit/features/patients/ui/nueva_medicion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Records what the form posts instead of calling the API.
class _FakeRepository implements PatientsRepository {
  _FakeRepository({this.failure});

  final ApiFailure? failure;
  final List<(String, Map<String, Object?>)> calls = [];

  @override
  Future<void> registrarMedicion(
    String pacienteId, {
    required Map<String, Object?> body,
  }) async {
    calls.add((pacienteId, body));
    if (failure != null) throw failure!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, Object?> _ficha({required bool conMediciones}) => {
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
  'evolucion': conMediciones
      ? [
          {
            'id': 'med-1',
            'fecha': '2025-11-07T08:00:00',
            'pesoKg': 72.4,
            'tallaCm': 174,
            'pctGrasa': 19.5,
          },
        ]
      : <Object?>[],
  'consultas': {'proximas': <Object?>[]},
  'planes': <Object?>[],
};

int _cargasDeFicha = 0;

/// Mounts a home page whose button opens the form, so popping is observable.
Future<void> _pump(
  WidgetTester tester,
  _FakeRepository repository, {
  bool conMediciones = true,
}) async {
  _cargasDeFicha = 0;
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        patientsRepositoryProvider.overrideWithValue(repository),
        pacienteFichaProvider.overrideWith((ref, id) async {
          _cargasDeFicha++;
          return PacienteFicha.fromJson(_ficha(conMediciones: conMediciones));
        }),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              // Watching the ficha like the real screen under the form does,
              // so an invalidation is visible as a second load.
              builder: (context, state) => Consumer(
                builder: (context, ref, _) {
                  ref.watch(pacienteFichaProvider('pac-1'));
                  return Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () =>
                            context.push(AppRoutes.nuevaMedicion('pac-1')),
                        child: const Text('abrir'),
                      ),
                    ),
                  );
                },
              ),
              routes: [
                GoRoute(
                  path: 'pacientes/:id/medicion',
                  builder: (context, state) => NuevaMedicionScreen(
                    pacienteId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

/// Types into the field whose label is [etiqueta]; labels sit above the field,
/// not inside it, so the field is found by its key.
Future<void> _escribir(WidgetTester tester, String clave, String texto) async {
  await tester.enterText(find.byKey(ValueKey(clave)), texto);
}

String _hoy() {
  final ahora = DateTime.now();
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${ahora.year}-${dos(ahora.month)}-${dos(ahora.day)}';
}

void main() {
  testWidgets('draws the artboard copy with the previous values as hints', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository());

    expect(find.text('Nueva medición'), findsOneWidget);
    expect(find.text('Paciente De Prueba'), findsOneWidget);
    expect(find.text('Fecha'), findsOneWidget);
    expect(find.text('Fuente'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
    expect(find.text('Básicos'), findsOneWidget);
    expect(find.text('Peso · kg'), findsOneWidget);
    expect(find.text('Talla · cm'), findsOneWidget);
    expect(find.text('% grasa'), findsOneWidget);
    expect(find.text('antes 72.4'), findsOneWidget);
    expect(find.text('antes 174'), findsOneWidget);
    expect(find.text('antes 19.5'), findsOneWidget);
    expect(
      find.text('Composición corporal · opcional', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('Pliegues · 4 campos · mm', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('Perímetros · 3 campos · cm', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('Tensión arterial · 2 campos · mmHg', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Notas'), findsOneWidget);
    expect(find.text('Guardar medición'), findsOneWidget);
  });

  testWidgets('optional sections start collapsed', (tester) async {
    await _pump(tester, _FakeRepository());

    expect(find.text('Cintura · cm'), findsNothing);
    expect(find.text('Tricipital · mm'), findsNothing);

    await tester.tap(
      find.text('Composición corporal · opcional', findRichText: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cintura · cm'), findsOneWidget);
    expect(find.text('Grasa visceral · 1–20'), findsOneWidget);
  });

  testWidgets('omits the hint when there is no previous value', (tester) async {
    await _pump(tester, _FakeRepository(), conMediciones: false);

    expect(find.textContaining('antes'), findsNothing);
  });

  testWidgets('blocks the submit and sends nothing without the basics', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);

    await tester.tap(find.text('Guardar medición'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresá el peso'), findsOneWidget);
    expect(find.text('Ingresá la talla'), findsOneWidget);
    expect(repository.calls, isEmpty);
    expect(find.text('Nueva medición'), findsOneWidget);
  });

  testWidgets('rejects a value outside the range the API accepts', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);

    await _escribir(tester, 'pesoKg', '5');
    await _escribir(tester, 'tallaCm', '174');
    await tester.tap(find.text('Guardar medición'));
    await tester.pumpAndSettle();

    expect(find.text('Entre 20 y 400'), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('saves once with only the filled fields and pops', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);

    await _escribir(tester, 'pesoKg', '71,8');
    await _escribir(tester, 'tallaCm', '174');
    await tester.tap(find.text('Guardar medición'));
    await tester.pumpAndSettle();

    expect(repository.calls, hasLength(1));
    expect(repository.calls.single.$1, 'pac-1');
    expect(repository.calls.single.$2, {
      'fecha': _hoy(),
      'pesoKg': 71.8,
      'tallaCm': 174,
      'fuente': 'MANUAL',
    });
    expect(find.text('Guardar medición'), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('reloads the ficha after a successful save', (tester) async {
    await _pump(tester, _FakeRepository());
    expect(_cargasDeFicha, 1);

    await _escribir(tester, 'pesoKg', '71.8');
    await _escribir(tester, 'tallaCm', '174');
    await tester.tap(find.text('Guardar medición'));
    await tester.pumpAndSettle();

    expect(_cargasDeFicha, 2);
  });

  testWidgets('sends an optional field once its section is filled', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);

    await tester.tap(
      find.text('Composición corporal · opcional', findRichText: true),
    );
    await tester.pumpAndSettle();
    await _escribir(tester, 'pesoKg', '71.8');
    await _escribir(tester, 'tallaCm', '174');
    await _escribir(tester, 'cinturaCm', '88');
    await tester.tap(find.text('Guardar medición'));
    await tester.pumpAndSettle();

    expect(repository.calls.single.$2['cinturaCm'], 88);
  });

  testWidgets('keeps the form and what was typed when the API refuses', (
    tester,
  ) async {
    final repository = _FakeRepository(
      failure: const ApiFailure(mensaje: 'Datos inválidos.'),
    );
    await _pump(tester, repository);

    await _escribir(tester, 'pesoKg', '71.8');
    await _escribir(tester, 'tallaCm', '174');
    await tester.tap(find.text('Guardar medición'));
    await tester.pumpAndSettle();

    expect(repository.calls, hasLength(1));
    expect(find.text('Datos inválidos.'), findsOneWidget);
    expect(find.text('Guardar medición'), findsOneWidget);
    expect(find.text('71.8'), findsOneWidget);
    expect(find.text('174'), findsOneWidget);
  });
}
