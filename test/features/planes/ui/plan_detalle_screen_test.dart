import 'dart:async';

import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/planes/data/plan.dart';
import 'package:baleadafit/features/planes/data/planes_providers.dart';
import 'package:baleadafit/features/planes/ui/plan_detalle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';

Map<String, Object?> _item(String nombre, double porciones, double kcal) => {
  'id': 'i-$nombre',
  'alimentoId': 'a-$nombre',
  'porciones': porciones,
  'alimentoVersionId': null,
  'alimento': {'nombre': nombre, 'porcionDescripcion': '1 taza', 'kcal': kcal},
};

Map<String, Object?> _tiempo(
  String tipo,
  int orden, {
  double pct = 0.25,
  double meta = 375,
  List<Map<String, Object?>> items = const [],
}) => {
  'id': 't-$tipo',
  'planId': 'p1',
  'dia': 'LUNES',
  'tipo': tipo,
  'orden': orden,
  'kcalMeta': meta,
  'pctKcal': pct,
  'items': items,
};

Map<String, Object?> _dia(String dia, List<Map<String, Object?>> tiempos) => {
  'dia': dia,
  'tiempos': tiempos,
  'totales': {'kcal': 1506},
  'desviacion': 0.004,
};

PlanDetalle _plan({
  String estado = 'BORRADOR',
  Object? justificacion = 'Generado por reglas: sin grasa corporal.',
  List<Map<String, Object?>>? dias,
}) => PlanDetalle.fromJson({
  'id': 'p1',
  'nombre': 'Plan 2026-11-07',
  'estado': estado,
  'origen': 'REGLAS',
  'kcalObjetivo': 1500,
  'proteinaG': 93.8,
  'carbohidratoG': 187.5,
  'grasaG': 41.7,
  'justificacion': justificacion,
  'creadoEn': '2026-11-07T15:00:00Z',
  'aprobadoEn': '2026-11-07T15:00:00Z',
  'totales': {'kcal': 10542},
  'desviacion': 0.004,
  'dias':
      dias ??
      [
        _dia('LUNES', [
          // Out of order on purpose: `orden` decides.
          _tiempo(
            'ALMUERZO',
            2,
            pct: 0.35,
            meta: 525,
            items: [
              _item('Arroz blanco', 1, 205),
              _item('Pollo a la plancha', 1.5, 231),
            ],
          ),
          _tiempo('DESAYUNO', 1),
          _tiempo(
            'CENA',
            3,
            pct: 0.195,
            meta: 292.5,
            items: [_item('Pan', 1, 80)],
          ),
        ]),
        _dia('MIERCOLES', [_tiempo('DESAYUNO', 1)]),
      ],
});

Future<void> _pump(
  WidgetTester tester, {
  required Future<PlanDetalle> Function() cargar,
  VoidCallback? onBack,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [planDetalleProvider.overrideWith((ref, id) => cargar())],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PlanDetalleScreen(planId: 'p1', onBack: onBack ?? () {}),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {});

  testWidgets('shows a spinner while the plan loads', (tester) async {
    await _pump(tester, cargar: () => Completer<PlanDetalle>().future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the API message and retries by invalidating', (
    tester,
  ) async {
    var llamadas = 0;
    await _pump(
      tester,
      cargar: () async {
        llamadas++;
        if (llamadas == 1) {
          throw const ApiFailure(mensaje: 'Plan no encontrado');
        }
        return _plan();
      },
    );
    await pumpStable(tester);

    expect(find.text('Plan no encontrado'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await pumpStable(tester);

    expect(llamadas, 2);
    expect(find.text('Plan 2026-11-07'), findsOneWidget);
  });

  testWidgets('draws the header, the goals and the week totals', (
    tester,
  ) async {
    await _pump(tester, cargar: () async => _plan());
    await pumpStable(tester);

    expect(find.text('Plan 2026-11-07'), findsOneWidget);
    expect(find.text('Borrador · sin publicar'), findsOneWidget);
    expect(find.text('BORRADOR'), findsOneWidget);
    expect(find.text('Por reglas'), findsOneWidget);
    expect(find.text('KCAL / DÍA'), findsOneWidget);
    expect(find.text('1.500'), findsOneWidget);
    expect(find.text('93.8g'), findsOneWidget);
    expect(find.text('187.5g'), findsOneWidget);
    expect(find.text('41.7g'), findsOneWidget);
    expect(
      find.text('Generado por reglas: sin grasa corporal.'),
      findsOneWidget,
    );
    expect(find.text('Totales de la semana'), findsOneWidget);
    // Fraction 0.004 is +0.4%, with no space and a dot.
    expect(find.text('+0.4%'), findsOneWidget);
    // Two days carried: the goal is 1.500 × 2, never a fixed week of seven.
    expect(
      find.text('10.542 kcal reales de 3.000 kcal meta (2 días)'),
      findsOneWidget,
    );
  });

  testWidgets('hides the justification when it is null', (tester) async {
    await _pump(tester, cargar: () async => _plan(justificacion: null));
    await pumpStable(tester);

    expect(find.textContaining('Generado por reglas'), findsNothing);
  });

  testWidgets('draws only the days the plan carries', (tester) async {
    await _pump(tester, cargar: () async => _plan());
    await pumpStable(tester);

    expect(find.text('DÍA'), findsOneWidget);
    expect(find.text('LUN'), findsOneWidget);
    expect(find.text('MIE'), findsOneWidget);
    for (final ausente in ['MAR', 'JUE', 'VIE', 'SAB', 'DOM']) {
      expect(find.text(ausente), findsNothing);
    }
    // The first day is expanded with its own totals and deviation.
    expect(find.text('Lunes'), findsOneWidget);
    expect(find.text('1.506 kcal · +0.4%'), findsOneWidget);

    await tester.tap(find.text('MIE'));
    await pumpStable(tester);

    expect(find.text('Miércoles'), findsOneWidget);
    expect(find.text('Lunes'), findsNothing);
  });

  testWidgets('labels the meal time figure as a goal and converts pctKcal', (
    tester,
  ) async {
    await _pump(tester, cargar: () async => _plan());
    await pumpStable(tester);

    // 0.25 → 25% and kcalMeta labelled `meta`; no items line for an empty one.
    expect(find.text('35% · meta 525 kcal · 2 alimentos'), findsOneWidget);
    expect(find.text('19.5% · meta 293 kcal · 1 alimento'), findsOneWidget);
    expect(find.textContaining('0.35'), findsNothing);
    expect(find.textContaining(' %'), findsNothing);
  });

  testWidgets('orders the meal times by orden', (tester) async {
    await _pump(tester, cargar: () async => _plan());
    await pumpStable(tester);

    final desayuno = tester.getTopLeft(find.text('Desayuno')).dy;
    final almuerzo = tester.getTopLeft(find.text('Almuerzo')).dy;
    expect(desayuno, lessThan(almuerzo));
  });

  testWidgets(
    'an empty meal time reads Sin alimentos with no invented totals',
    (tester) async {
      await _pump(tester, cargar: () async => _plan());
      await pumpStable(tester);

      expect(find.text('Sin alimentos'), findsOneWidget);
      expect(find.text('25% · meta 375 kcal'), findsOneWidget);
    },
  );

  testWidgets('draws each food with its kcal per portion, never multiplied', (
    tester,
  ) async {
    await _pump(tester, cargar: () async => _plan());
    await pumpStable(tester);

    expect(find.text('Arroz blanco'), findsOneWidget);
    expect(find.text('1 taza · 205 kcal por porción'), findsOneWidget);
    expect(find.text('1 porción'), findsWidgets);
    expect(find.text('Pollo a la plancha'), findsOneWidget);
    expect(find.text('1.5 porciones'), findsOneWidget);
    // 231 × 1.5 would be 347: the app does not multiply.
    expect(find.textContaining('347'), findsNothing);
    expect(find.text('1 taza · 231 kcal por porción'), findsOneWidget);
  });

  testWidgets('a plan with one day says (1 día)', (tester) async {
    await _pump(
      tester,
      cargar: () async => _plan(
        dias: [
          _dia('LUNES', [_tiempo('DESAYUNO', 1)]),
        ],
      ),
    );
    await pumpStable(tester);

    expect(
      find.text('10.542 kcal reales de 1.500 kcal meta (1 día)'),
      findsOneWidget,
    );
  });

  testWidgets('a plan with no days draws no strip and no week totals', (
    tester,
  ) async {
    await _pump(tester, cargar: () async => _plan(dias: const []));
    await pumpStable(tester);

    expect(find.text('Este plan todavía no tiene días.'), findsOneWidget);
    expect(find.text('DÍA'), findsNothing);
    expect(find.text('Totales de la semana'), findsNothing);
    expect(find.text('BORRADOR'), findsOneWidget);
  });

  testWidgets('an active plan has no actions, only the date line', (
    tester,
  ) async {
    await _pump(tester, cargar: () async => _plan(estado: 'ACTIVO'));
    await pumpStable(tester);

    expect(find.text('ACTIVO'), findsOneWidget);
    expect(find.textContaining('Activo el'), findsOneWidget);
    expect(find.text('Activar plan'), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('an archived plan reads solo lectura', (tester) async {
    await _pump(tester, cargar: () async => _plan(estado: 'ARCHIVADO'));
    await pumpStable(tester);

    expect(find.text('ARCHIVADO'), findsOneWidget);
    expect(find.textContaining('· solo lectura'), findsOneWidget);
  });

  testWidgets('the back arrow calls onBack', (tester) async {
    var volvio = false;
    await _pump(
      tester,
      cargar: () async => _plan(),
      onBack: () => volvio = true,
    );
    await pumpStable(tester);

    await tester.tap(find.byTooltip('Volver a planes'));

    expect(volvio, isTrue);
  });

  testWidgets('collapses a long justification behind Ver más', (tester) async {
    // The assistant writes paragraphs; the design expected a line.
    final largo = List.generate(200, (i) => 'palabra$i').join(' ');
    await _pump(
      tester,
      cargar: () async => PlanDetalle.fromJson({
        'id': 'p1',
        'nombre': 'Plan de prueba',
        'estado': 'BORRADOR',
        'origen': 'IA',
        'justificacion': largo,
        'dias': <Object?>[],
        'tiempos': <Object?>[],
      }),
    );
    await tester.pumpAndSettle();

    // Cut at 150 words, and not one more.
    expect(find.text('Ver más'), findsOneWidget);
    expect(find.textContaining('palabra149'), findsOneWidget);
    expect(find.textContaining('palabra150'), findsNothing);

    // The card scrolls with the screen: the control has to be on screen for the
    // tap to land on it.
    await tester.ensureVisible(find.text('Ver más'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver más'));
    await tester.pumpAndSettle();

    expect(find.text('Ver menos'), findsOneWidget);
    expect(find.textContaining('palabra199'), findsOneWidget);
  });

  testWidgets('draws a short justification with no control', (tester) async {
    await _pump(
      tester,
      cargar: () async => PlanDetalle.fromJson({
        'id': 'p1',
        'nombre': 'Plan de prueba',
        'estado': 'BORRADOR',
        'origen': 'IA',
        'justificacion': 'Cinco comidas al día, sin frituras.',
        'dias': <Object?>[],
        'tiempos': <Object?>[],
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cinco comidas al día, sin frituras.'), findsOneWidget);
    expect(find.text('Ver más'), findsNothing);
  });
}
