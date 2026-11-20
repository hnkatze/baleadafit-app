import 'dart:async';

import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/core/network/paged.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/planes/data/plan.dart';
import 'package:baleadafit/features/planes/data/planes_providers.dart';
import 'package:baleadafit/features/planes/data/planes_repository.dart';
import 'package:baleadafit/features/planes/ui/plan_detalle_screen.dart';
import 'package:dio/dio.dart' show ResponseBody;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
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
}) => PlanDetalle.fromJson(
  _planJson(estado: estado, justificacion: justificacion, dias: dias),
);

Map<String, Object?> _planJson({
  String estado = 'BORRADOR',
  Object? justificacion = 'Generado por reglas: sin grasa corporal.',
  List<Map<String, Object?>>? dias,
  String aprobadoEn = '2026-11-07T15:00:00Z',
}) => {
  'id': 'p1',
  'pacienteId': 'pac1',
  'nombre': 'Plan 2026-11-07',
  'estado': estado,
  'origen': 'REGLAS',
  'kcalObjetivo': 1500,
  'proteinaG': 93.8,
  'carbohidratoG': 187.5,
  'grasaG': 41.7,
  'justificacion': justificacion,
  'creadoEn': '2026-11-07T15:00:00Z',
  'aprobadoEn': aprobadoEn,
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
};

Future<void> _pump(
  WidgetTester tester, {
  required Future<PlanDetalle> Function() cargar,
  VoidCallback? onBack,
  void Function(DiaSemana, TipoComida)? onEditarTiempo,
  VoidCallback? onVolverALista,
  FakeHttpAdapter? adapter,
  void Function()? alCargarLista,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        planDetalleProvider.overrideWith((ref, id) => cargar()),
        if (adapter != null)
          planesRepositoryProvider.overrideWithValue(
            PlanesRepository(ApiClient(dioWith(adapter))),
          ),
        planesDePacienteProvider.overrideWith((ref, id) {
          alCargarLista?.call();
          return const Paged<Plan>(
            items: [],
            meta: PageMeta(limit: 100, offset: 0, total: 0, hasMore: false),
          );
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PlanDetalleScreen(
            planId: 'p1',
            onBack: onBack ?? () {},
            onEditarTiempo: onEditarTiempo,
            onVolverALista: onVolverALista,
          ),
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

  testWidgets('a draft draws the chevron and a row opens the editor', (
    tester,
  ) async {
    final llamadas = <(DiaSemana, TipoComida)>[];
    await _pump(
      tester,
      cargar: () async => _plan(),
      onEditarTiempo: (dia, tipo) => llamadas.add((dia, tipo)),
    );
    await pumpStable(tester);

    for (final tipo in ['DESAYUNO', 'ALMUERZO', 'CENA']) {
      expect(find.byKey(Key('editar-$tipo')), findsOneWidget);
    }

    await tester.ensureVisible(find.byKey(const Key('tiempo-ALMUERZO')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tiempo-ALMUERZO')));
    await pumpStable(tester);

    expect(llamadas, [(DiaSemana.lunes, TipoComida.almuerzo)]);
  });

  testWidgets('an active or archived plan has neither chevron nor tap', (
    tester,
  ) async {
    for (final estado in ['ACTIVO', 'ARCHIVADO']) {
      var llamadas = 0;
      await _pump(
        tester,
        cargar: () async => _plan(estado: estado),
        onEditarTiempo: (dia, tipo) => llamadas++,
      );
      await pumpStable(tester);

      expect(find.byKey(const Key('editar-DESAYUNO')), findsNothing);

      await tester.tap(find.byKey(const Key('tiempo-DESAYUNO')));
      await pumpStable(tester);

      expect(llamadas, 0, reason: estado);
    }
  });

  testWidgets('tapping a draft row leaves what the screen drew untouched', (
    tester,
  ) async {
    await _pump(
      tester,
      cargar: () async => _plan(),
      onEditarTiempo: (dia, tipo) {},
    );
    await pumpStable(tester);

    await tester.tap(find.byKey(const Key('tiempo-DESAYUNO')));
    await pumpStable(tester);

    // Nothing is patched locally: the detail only changes by re-reading.
    expect(find.text('MIE'), findsOneWidget);
  });

  testWidgets('the day chips share the width and the strip does not scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(tester, cargar: () async => _plan());
    await pumpStable(tester);

    for (final abreviatura in ['LUN', 'MIE']) {
      final chip = find.ancestor(
        of: find.text(abreviatura),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(chip).width, greaterThan(40));
      expect(tester.getSize(chip).height, 40);
    }
    final lun = tester.getRect(
      find.ancestor(of: find.text('LUN'), matching: find.byType(InkWell)),
    );
    final mie = tester.getRect(
      find.ancestor(of: find.text('MIE'), matching: find.byType(InkWell)),
    );
    expect(mie.right - lun.left, greaterThan(800));
    expect(
      find.ancestor(
        of: find.text('LUN'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('every meal time draws its icon in its tinted circle', (
    tester,
  ) async {
    await _pump(
      tester,
      cargar: () async => _plan(
        dias: [
          _dia('LUNES', [
            _tiempo('DESAYUNO', 1),
            _tiempo('MERIENDA_AM', 2),
            _tiempo('ALMUERZO', 3),
            _tiempo('MERIENDA_PM', 4),
            _tiempo('CENA', 5),
          ]),
        ],
      ),
    );
    await pumpStable(tester);
    final colors = Theme.of(tester.element(find.byType(PlanDetalleScreen)))
        .colorScheme;

    final esperado = {
      'DESAYUNO': (
        Icons.breakfast_dining,
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      'MERIENDA_AM': (
        Icons.local_cafe,
        colors.surfaceContainer,
        colors.onSurfaceVariant,
      ),
      'ALMUERZO': (
        Icons.lunch_dining,
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      'MERIENDA_PM': (
        Icons.cookie,
        colors.surfaceContainer,
        colors.onSurfaceVariant,
      ),
      'CENA': (
        Icons.dinner_dining,
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
    };
    for (final MapEntry(key: codigo, value: (icono, fondo, frente))
        in esperado.entries) {
      final circulo = find.byKey(Key('icono-$codigo'));
      expect(circulo, findsOneWidget, reason: codigo);
      expect(tester.getSize(circulo), const Size(36, 36), reason: codigo);
      final decoracion =
          tester.widget<Container>(circulo).decoration! as BoxDecoration;
      expect(decoracion.color, fondo, reason: codigo);
      final dibujado = tester.widget<Icon>(
        find.descendant(of: circulo, matching: find.byType(Icon)),
      );
      expect(dibujado.icon, icono, reason: codigo);
      expect(dibujado.color, frente, reason: codigo);
      expect(
        find.ancestor(of: circulo, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
        reason: codigo,
      );
    }
  });

  testWidgets('a draft draws Activar plan, its notice and the delete menu', (
    tester,
  ) async {
    await _pump(tester, cargar: () async => _plan());
    await pumpStable(tester);

    expect(find.text('Activar plan'), findsOneWidget);
    expect(
      find.text(
        'Lo va a ver el paciente en su app; el plan activo anterior pasa a '
        'archivado.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byTooltip('Eliminar borrador'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await pumpStable(tester);

    expect(find.text('Eliminar borrador'), findsOneWidget);
  });

  testWidgets('Cancelar on the activation dialog sends nothing', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({'ok': true, 'data': _planJson(estado: 'ACTIVO')}),
    );
    await _pump(tester, cargar: () async => _plan(), adapter: adapter);
    await pumpStable(tester);

    await tester.tap(find.text('Activar plan'));
    await pumpStable(tester);

    final dialogo = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialogo, matching: find.text('¿Activar este plan?')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dialogo,
        matching: find.text(
          'Lo va a ver el paciente en su app; el plan activo anterior pasa a '
          'archivado.',
        ),
      ),
      findsOneWidget,
    );
    expect(adapter.requests, isEmpty);

    await tester.tap(
      find.descendant(of: dialogo, matching: find.text('Cancelar')),
    );
    await pumpStable(tester);

    expect(adapter.requests, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('BORRADOR'), findsOneWidget);
    expect(find.text('Activar plan'), findsOneWidget);
  });

  testWidgets('confirming activates and the screen becomes read only', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({
        'ok': true,
        'data': _planJson(estado: 'ACTIVO', aprobadoEn: '2026-11-09T15:00:00Z'),
      }, status: 201),
    );
    var volvio = false;
    await _pump(
      tester,
      cargar: () async => _plan(),
      adapter: adapter,
      onEditarTiempo: (dia, tipo) {},
      onVolverALista: () => volvio = true,
    );
    await pumpStable(tester);
    expect(find.byIcon(Icons.chevron_right), findsWidgets);

    await tester.tap(find.text('Activar plan'));
    await pumpStable(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Activar plan'),
      ),
    );
    await pumpStable(tester);

    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.path, '/planes/p1/activar');
    expect(find.text('ACTIVO'), findsOneWidget);
    expect(find.text('BORRADOR'), findsNothing);
    expect(find.textContaining('Activo el'), findsOneWidget);
    expect(find.text('Borrador · sin publicar'), findsNothing);
    expect(find.text('Activar plan'), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(volvio, isFalse);
  });

  testWidgets('a refresh drops the plan replaced locally', (tester) async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({'ok': true, 'data': _planJson(estado: 'ACTIVO')}),
    );
    await _pump(tester, cargar: () async => _plan(), adapter: adapter);
    await pumpStable(tester);
    await tester.tap(find.text('Activar plan'));
    await pumpStable(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Activar plan'),
      ),
    );
    await pumpStable(tester);
    expect(find.text('ACTIVO'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await pumpStable(tester, frames: 30);

    // The provider still says BORRADOR: the refresh shows what the API says.
    expect(find.text('BORRADOR'), findsOneWidget);
    expect(find.text('Activar plan'), findsOneWidget);
  });

  testWidgets('a 400 on activate shows the API message and keeps working', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({
        'ok': false,
        'error': {
          'codigo': 'REGLA_X',
          'mensaje': 'El plan no se puede activar.',
        },
      }, status: 400),
    );
    await _pump(tester, cargar: () async => _plan(), adapter: adapter);
    await pumpStable(tester);

    await tester.tap(find.text('Activar plan'));
    await pumpStable(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Activar plan'),
      ),
    );
    await pumpStable(tester);

    expect(find.text('El plan no se puede activar.'), findsOneWidget);
    expect(find.text('REGLA_X · HTTP 400'), findsOneWidget);
    expect(find.text('BORRADOR'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // The button and the menu work again.
    await tester.tap(find.text('Activar plan'));
    await pumpStable(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancelar'),
      ),
    );
    await pumpStable(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await pumpStable(tester);
    expect(find.text('Eliminar borrador'), findsOneWidget);
  });

  testWidgets('the activate button spins while the request runs', (
    tester,
  ) async {
    final respuesta = Completer<ResponseBody>();
    final adapter = FakeHttpAdapter((_) => respuesta.future);
    var volvio = false;
    await _pump(
      tester,
      cargar: () async => _plan(),
      adapter: adapter,
      onVolverALista: () => volvio = true,
    );
    await pumpStable(tester);

    await tester.tap(find.text('Activar plan'));
    await pumpStable(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Activar plan'),
      ),
    );
    await pumpStable(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Activar plan'), findsNothing);
    expect(volvio, isFalse);

    respuesta.complete(
      jsonBody({'ok': true, 'data': _planJson(estado: 'ACTIVO')}),
    );
    await pumpStable(tester);

    expect(find.text('ACTIVO'), findsOneWidget);
  });

  testWidgets('Cancelar on the delete dialog sends nothing', (tester) async {
    final adapter = FakeHttpAdapter((_) async => jsonBody({'ok': true}));
    var volvio = false;
    await _pump(
      tester,
      cargar: () async => _plan(),
      adapter: adapter,
      onVolverALista: () => volvio = true,
    );
    await pumpStable(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await pumpStable(tester);
    await tester.tap(find.text('Eliminar borrador'));
    await pumpStable(tester);

    final dialogo = find.byType(AlertDialog);
    expect(
      find.descendant(
        of: dialogo,
        matching: find.text('¿Eliminar este borrador?'),
      ),
      findsOneWidget,
    );
    expect(adapter.requests, isEmpty);

    await tester.tap(
      find.descendant(of: dialogo, matching: find.text('Cancelar')),
    );
    await pumpStable(tester);

    expect(adapter.requests, isEmpty);
    expect(volvio, isFalse);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('confirming a delete goes back and invalidates the list', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter((_) async => jsonBody({'ok': true}));
    var volvio = false;
    var cargasDeLista = 0;
    await _pump(
      tester,
      cargar: () async => _plan(),
      adapter: adapter,
      onVolverALista: () => volvio = true,
      alCargarLista: () => cargasDeLista++,
    );
    await pumpStable(tester);
    // Keep the list alive, as the list screen would behind the detail.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlanDetalleScreen)),
    );
    final suscripcion = container.listen(
      planesDePacienteProvider('pac1'),
      (_, _) {},
    );
    addTearDown(suscripcion.close);
    expect(cargasDeLista, 1);

    await tester.tap(find.byIcon(Icons.more_vert));
    await pumpStable(tester);
    await tester.tap(find.text('Eliminar borrador'));
    await pumpStable(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar borrador'),
      ),
    );
    await pumpStable(tester);

    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.path, '/planes/p1');
    expect(volvio, isTrue);
    expect(cargasDeLista, 2);
  });

  testWidgets('a failed delete shows the API message and stays', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({
        'ok': false,
        'error': {'codigo': 'PLAN_NO_BORRADOR', 'mensaje': 'No es borrador.'},
      }, status: 409),
    );
    var volvio = false;
    await _pump(
      tester,
      cargar: () async => _plan(),
      adapter: adapter,
      onVolverALista: () => volvio = true,
    );
    await pumpStable(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await pumpStable(tester);
    await tester.tap(find.text('Eliminar borrador'));
    await pumpStable(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar borrador'),
      ),
    );
    await pumpStable(tester);

    expect(find.text('No es borrador.'), findsOneWidget);
    expect(find.text('PLAN_NO_BORRADOR · HTTP 409'), findsOneWidget);
    expect(volvio, isFalse);
    expect(find.text('Activar plan'), findsOneWidget);
  });

  testWidgets('ACTIVO and ARCHIVADO never draw Activar plan nor the menu', (
    tester,
  ) async {
    for (final estado in ['ACTIVO', 'ARCHIVADO']) {
      // A fresh tree: the provider of the previous pump must not be reused.
      await tester.pumpWidget(const SizedBox());
      await _pump(
        tester,
        cargar: () async => _plan(estado: estado),
        onEditarTiempo: (dia, tipo) {},
      );
      await pumpStable(tester);

      expect(find.text(estado), findsOneWidget, reason: estado);
      expect(find.text('Activar plan'), findsNothing, reason: estado);
      expect(find.byIcon(Icons.more_vert), findsNothing, reason: estado);
      expect(find.byTooltip('Eliminar borrador'), findsNothing, reason: estado);
      expect(find.byIcon(Icons.chevron_right), findsNothing, reason: estado);
    }
  });

  testWidgets('the state badge is the tinted one, from the colorScheme', (
    tester,
  ) async {
    final esperado = {
      'BORRADOR': (
        (ColorScheme c) => c.surfaceContainer,
        (ColorScheme c) => c.onSurfaceVariant,
      ),
      'ACTIVO': (
        (ColorScheme c) => c.secondaryContainer,
        (ColorScheme c) => c.onSecondaryContainer,
      ),
      'ARCHIVADO': (
        (ColorScheme c) => c.surfaceContainer,
        (ColorScheme c) => c.onSurfaceVariant,
      ),
    };
    for (final MapEntry(key: estado, value: (fondo, frente))
        in esperado.entries) {
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, cargar: () async => _plan(estado: estado));
      await pumpStable(tester);
      final colors = Theme.of(tester.element(find.byType(PlanDetalleScreen)))
          .colorScheme;

      final insignia = tester.widget<Container>(
        find.byKey(const Key('insignia-estado')),
      );
      expect(
        (insignia.decoration! as BoxDecoration).color,
        fondo(colors),
        reason: estado,
      );
      expect(
        tester.widget<Text>(find.text(estado)).style?.color,
        frente(colors),
        reason: estado,
      );
    }
  });
}
