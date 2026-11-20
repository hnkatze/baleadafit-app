import 'dart:async';

import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/core/network/paged.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/core/theme/app_typography.dart';
import 'package:baleadafit/features/planes/data/plan.dart';
import 'package:baleadafit/features/planes/data/planes_providers.dart';
import 'package:baleadafit/features/planes/ui/plan_lista_screen.dart';
import 'package:baleadafit/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _paciente = 'pac-1';

List<Plan> _planes = const [];

Paged<Plan> _paged(List<Plan> items) => Paged(
  items: items,
  meta: PageMeta(limit: 100, offset: 0, total: items.length, hasMore: false),
);

Plan _plan({
  String id = 'plan-1',
  String nombre = 'Plan 2026-11-07',
  EstadoPlan estado = EstadoPlan.activo,
  OrigenPlan origen = OrigenPlan.reglas,
  DateTime? creadoEn,
  DateTime? aprobadoEn,
}) => Plan(
  id: id,
  nombre: nombre,
  estado: estado,
  origen: origen,
  pacienteId: _paciente,
  kcalObjetivo: 1500,
  proteinaG: 93.75,
  carbohidratoG: 187.5,
  grasaG: 41.7,
  creadoEn: creadoEn,
  aprobadoEn: aprobadoEn,
);

String? _abierto;
int _generados = 0;
int _volver = 0;

Future<void> _pump(
  WidgetTester tester, {
  List<Plan>? planes,
  Object? error,
  Completer<void>? espera,
}) async {
  _abierto = null;
  _generados = 0;
  _volver = 0;
  _planes = planes ?? const [];

  // The list is long enough to scroll: a tall surface keeps every card built,
  // so a missing widget never means "off screen".
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        planesDePacienteProvider(_paciente).overrideWith((ref) async {
          if (espera != null) await espera.future;
          if (error != null) throw error;
          return _paged(_planes);
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PlanListaScreen(
            pacienteId: _paciente,
            onAbrir: (id) => _abierto = id,
            onGenerar: () => _generados++,
            onBack: () => _volver++,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ColorScheme _colores(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(PlanListaScreen))).colorScheme;

BoxDecoration _decoracion(WidgetTester tester, Finder f) =>
    tester.widget<Container>(f).decoration! as BoxDecoration;

Color? _colorDelTexto(WidgetTester tester, String texto) =>
    tester.widget<Text>(find.text(texto)).style?.color;

void main() {
  testWidgets('draws one card per plan with its metrics', (tester) async {
    await _pump(tester, planes: [_plan()]);

    expect(find.text('Plan 2026-11-07'), findsOneWidget);
    expect(find.text('ACTIVO'), findsOneWidget);
    expect(find.text('Por reglas'), findsOneWidget);
    expect(find.text('KCAL'), findsOneWidget);
    expect(find.text('1,500'), findsOneWidget);
    expect(find.text('93.8g'), findsOneWidget);
    expect(find.text('187.5g'), findsOneWidget);
    expect(find.text('41.7g'), findsOneWidget);
  });

  testWidgets('colours the state badge: ACTIVO in the secondary container', (
    tester,
  ) async {
    await _pump(tester, planes: [_plan()]);
    final c = _colores(tester);

    final deco = _decoracion(tester, find.byKey(const Key('insignia-estado')));
    expect(deco.color, c.secondaryContainer);
    expect(_colorDelTexto(tester, 'ACTIVO'), c.onSecondaryContainer);
  });

  testWidgets('colours BORRADOR and ARCHIVADO in the neutral container', (
    tester,
  ) async {
    await _pump(
      tester,
      planes: [
        _plan(id: 'b', nombre: 'Borrador', estado: EstadoPlan.borrador),
        _plan(id: 'a', nombre: 'Archivado', estado: EstadoPlan.archivado),
      ],
    );
    final c = _colores(tester);

    final insignias = find.byKey(const Key('insignia-estado'));
    expect(insignias, findsNWidgets(2));
    for (final i in [0, 1]) {
      final deco = _decoracion(tester, insignias.at(i));
      expect(deco.color, c.surfaceContainer);
    }
    expect(_colorDelTexto(tester, 'BORRADOR'), c.onSurfaceVariant);
    expect(_colorDelTexto(tester, 'ARCHIVADO'), c.onSurfaceVariant);
  });

  testWidgets('draws the origin as a bordered pill', (tester) async {
    await _pump(tester, planes: [_plan()]);
    final c = _colores(tester);

    final deco = _decoracion(tester, find.byKey(const Key('etiqueta-origen')));
    expect(deco.border, Border.all(color: c.outlineVariant));
    expect(deco.color, isNull);
    expect(_colorDelTexto(tester, 'Por reglas'), c.onSurfaceVariant);
  });

  testWidgets('draws the figures in the mono style', (tester) async {
    await _pump(tester, planes: [_plan()]);

    for (final valor in ['1,500', '93.8g', '187.5g', '41.7g']) {
      expect(
        tester.widget<Text>(find.text(valor)).style?.fontFamily,
        AppTypography.monoFamily,
      );
    }
  });

  testWidgets('attenuates the title and figures of an archived plan', (
    tester,
  ) async {
    await _pump(
      tester,
      planes: [
        _plan(),
        _plan(id: 'v', nombre: 'Viejo', estado: EstadoPlan.archivado),
      ],
    );
    final c = _colores(tester);

    expect(_colorDelTexto(tester, 'Viejo'), c.onSurfaceVariant);
    expect(_colorDelTexto(tester, 'Plan 2026-11-07'), c.onSurface);
    final valores = find.text('1,500');
    expect(tester.widget<Text>(valores.at(0)).style?.color, c.onSurface);
    expect(tester.widget<Text>(valores.at(1)).style?.color, c.onSurfaceVariant);
  });

  testWidgets('the fixed Generar plan button carries the add icon', (
    tester,
  ) async {
    await _pump(tester, planes: [_plan()]);

    expect(
      find.descendant(
        of: find.widgetWithText(AppButton, 'Generar plan'),
        matching: find.byIcon(Icons.add),
      ),
      findsOneWidget,
    );
  });

  testWidgets('opens the plan that was tapped', (tester) async {
    await _pump(
      tester,
      planes: [_plan(id: 'plan-7', nombre: 'Plan siete')],
    );

    await tester.tap(find.text('Plan siete'));
    await tester.pump();

    expect(_abierto, 'plan-7');
  });

  testWidgets('says an archived plan is read only', (tester) async {
    await _pump(
      tester,
      planes: [
        _plan(
          id: 'plan-9',
          nombre: 'Plan viejo',
          estado: EstadoPlan.archivado,
          creadoEn: DateTime.utc(2026, 10, 20, 12),
        ),
      ],
    );

    expect(find.text('ARCHIVADO'), findsOneWidget);
    expect(find.text('Creado el 20 oct · solo lectura'), findsOneWidget);
  });

  testWidgets('keeps an archived plan read only without a date', (
    tester,
  ) async {
    await _pump(
      tester,
      planes: [_plan(estado: EstadoPlan.archivado, nombre: 'Plan sin fecha')],
    );

    expect(find.text('solo lectura'), findsOneWidget);
  });

  testWidgets('offers to generate the first plan when there is none', (
    tester,
  ) async {
    await _pump(tester, planes: const []);

    expect(find.text('Todavía no tiene un plan'), findsOneWidget);
    expect(
      find.text(
        'Generá el primero con sus metas y restricciones. Va a quedar en '
        'borrador hasta que lo revisés y lo activés.',
      ),
      findsOneWidget,
    );

    // The empty state carries the only action, so it is not drawn twice.
    expect(find.widgetWithText(AppButton, 'Generar plan'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Generar plan'));
    await tester.pump();
    expect(_generados, 1);
  });

  testWidgets('keeps the fixed action under a real list', (tester) async {
    await _pump(tester, planes: [_plan()]);

    expect(find.widgetWithText(AppButton, 'Generar plan'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Generar plan'));
    await tester.pump();
    expect(_generados, 1);
  });

  testWidgets('shows the API message when the list fails', (tester) async {
    await _pump(
      tester,
      error: const ApiFailure(
        mensaje: 'No se pudo leer el paciente.',
        statusCode: 500,
      ),
    );
    await tester.pump();

    expect(find.text('No pudimos cargar los planes.'), findsOneWidget);
    expect(find.text('No se pudo leer el paciente.'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Reintentar'), findsOneWidget);
  });

  testWidgets('spins while the plans are on their way', (tester) async {
    final espera = Completer<void>();
    await _pump(tester, espera: espera);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    espera.complete();
    await tester.pump();
  });

  testWidgets('goes back to the patient file', (tester) async {
    await _pump(tester, planes: [_plan()]);

    await tester.tap(find.byTooltip('Volver a la ficha'));
    await tester.pump();

    expect(_volver, 1);
  });
}
