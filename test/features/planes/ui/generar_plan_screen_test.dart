import 'dart:async';

import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/features/planes/data/plan.dart';
import 'package:baleadafit/features/planes/data/planes_providers.dart';
import 'package:baleadafit/features/planes/data/planes_repository.dart';
import 'package:baleadafit/features/planes/ui/generar_plan_screen.dart';
import 'package:baleadafit/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the screen sends to `generar` and answers with whatever the
/// test handed in. Everything else is unused here.
class _RepoFalso implements PlanesRepository {
  _RepoFalso({this.respuesta, this.fallo, this.errorCrudo});

  final PlanDetalle? respuesta;
  final ApiFailure? fallo;

  /// A failure that is not an [ApiFailure], to prove the form still comes back.
  final Object? errorCrudo;

  /// When present, `generar` waits on it, so a test can observe the form while
  /// the request is in flight.
  Completer<void>? espera;

  String? nombreRecibido;
  bool? usarIaRecibido;
  String? indicacionesRecibidas;
  DistribucionMacros? macrosRecibidas;
  Map<TipoComida, double>? tiemposRecibidos;

  @override
  Future<PlanDetalle> generar(
    String pacienteId, {
    String? nombre,
    int? kcalObjetivo,
    bool usarIa = true,
    String? indicaciones,
    DistribucionMacros? distribucionMacros,
    Map<TipoComida, double>? distribucionTiempos,
  }) async {
    nombreRecibido = nombre;
    usarIaRecibido = usarIa;
    indicacionesRecibidas = indicaciones;
    macrosRecibidas = distribucionMacros;
    tiemposRecibidos = distribucionTiempos;

    if (espera != null) await espera!.future;
    if (errorCrudo != null) throw errorCrudo!;
    if (fallo != null) throw fallo!;
    return respuesta ?? PlanDetalle.fromJson(_planNuevo());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _planNuevo({String origen = 'REGLAS'}) => {
  'id': 'plan-9',
  'nombre': 'Plan de prueba',
  'estado': 'BORRADOR',
  'origen': origen,
  'dias': <Object?>[],
  'tiempos': <Object?>[],
};

String? _generado;

Future<_RepoFalso> _pump(
  WidgetTester tester, {
  PlanDetalle? respuesta,
  ApiFailure? fallo,
  Object? errorCrudo,
  Completer<void>? espera,
}) async {
  final repo = _RepoFalso(
    respuesta: respuesta,
    fallo: fallo,
    errorCrudo: errorCrudo,
  )..espera = espera;
  _generado = null;

  // The form is long: a tall surface keeps every field built, so a failure
  // means the widget is missing and never that it is merely off screen.
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [planesRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: GenerarPlanScreen(
          pacienteId: 'pac-1',
          onCerrar: () {},
          onGenerado: (id) => _generado = id,
        ),
      ),
    ),
  );
  await tester.pump();
  return repo;
}

/// The text inside the field behind [key], read from the real `TextField` so
/// the assertion does not depend on the wrapper's API.
String _valor(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

Future<void> _escribir(WidgetTester tester, String key, String texto) async {
  await tester.enterText(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField)),
    texto,
  );
  await tester.pump();
}

Future<void> _generar(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(AppButton, 'Generar plan'));
  await tester.pump();
}

void main() {
  testWidgets('opens with the fractions the contract sets by default', (
    tester,
  ) async {
    await _pump(tester);

    expect(_valor(tester, 'macro-proteina'), '25%');
    expect(_valor(tester, 'macro-carbohidrato'), '50%');
    expect(_valor(tester, 'macro-grasa'), '25%');

    // The meal times keep their own contract defaults.
    expect(_valor(tester, 'tiempo-DESAYUNO'), '25%');
    expect(_valor(tester, 'tiempo-ALMUERZO'), '35%');
    expect(_valor(tester, 'tiempo-CENA'), '20%');
  });

  testWidgets('sends the distributions as fractions, not percentages', (
    tester,
  ) async {
    final repo = await _pump(tester);

    await _escribir(tester, 'macro-proteina', '40');
    await _generar(tester);

    expect(repo.macrosRecibidas!.proteina, closeTo(0.4, 0.0001));
    expect(repo.macrosRecibidas!.carbohidrato, closeTo(0.5, 0.0001));
    expect(repo.tiemposRecibidos![TipoComida.almuerzo], closeTo(0.35, 0.0001));
    expect(repo.usarIaRecibido, isTrue);
    expect(_generado, 'plan-9');
  });

  testWidgets('keeps the form read only while the request runs', (
    tester,
  ) async {
    final espera = Completer<void>();
    await _pump(tester, espera: espera);

    await _generar(tester);

    // Up to 25 s with the AI: nothing can be edited or resubmitted meanwhile.
    expect(
      tester.widget<Switch>(find.byKey(const Key('usarIa'))).onChanged,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Cerrar sin generar'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );

    espera.complete();
    await tester.pump();
    await tester.pump();

    // The screen does not clear its loading state on success: the parent
    // replaces it with the detail, so here it just proves the run finished.
    expect(_generado, 'plan-9');
  });

  testWidgets('shows the API message and keeps what was typed', (tester) async {
    await _pump(
      tester,
      fallo: const ApiFailure(
        mensaje: 'El paciente necesita al menos una medición.',
        codigo: 'SIN_MEDICIONES',
        statusCode: 400,
      ),
    );

    await _escribir(tester, 'nombre', 'Plan de agosto');
    await _generar(tester);
    await tester.pump();

    expect(
      find.text('El paciente necesita al menos una medición.'),
      findsOneWidget,
    );
    expect(_valor(tester, 'nombre'), 'Plan de agosto');
    expect(_generado, isNull);
  });

  testWidgets('says so when the AI was asked for and rules came back', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      respuesta: PlanDetalle.fromJson(_planNuevo(origen: 'REGLAS')),
    );

    await _generar(tester);
    await tester.pump();

    // Production falls back to rules today; the screen must not claim the AI
    // proposed a plan it did not propose.
    expect(repo.usarIaRecibido, isTrue);
    expect(
      find.text('Pediste IA, pero este plan se generó por reglas.'),
      findsOneWidget,
    );
    expect(_generado, 'plan-9');
  });

  testWidgets('frees the form when the failure is not from the API', (
    tester,
  ) async {
    await _pump(tester, errorCrudo: StateError('boom'));

    await _generar(tester);
    await tester.pump();

    // A stuck spinner leaves no way to retry and no message to report, so any
    // other error frees the form with its own wording.
    expect(
      find.text('No pudimos generar el plan. Probá de nuevo.'),
      findsOneWidget,
    );
    expect(
      tester.widget<Switch>(find.byKey(const Key('usarIa'))).onChanged,
      isNotNull,
    );
  });

  testWidgets('shows the code of the failure when the API gave one', (
    tester,
  ) async {
    await _pump(
      tester,
      fallo: const ApiFailure(
        mensaje: 'El recomendador no está disponible.',
        codigo: 'IA_NO_DISPONIBLE',
        statusCode: 503,
      ),
    );

    await _generar(tester);
    await tester.pump();

    expect(find.byKey(const Key('fallo-codigo')), findsOneWidget);
    expect(find.text('IA_NO_DISPONIBLE · HTTP 503'), findsOneWidget);
  });
}
