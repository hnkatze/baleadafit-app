import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/core/theme/app_typography.dart';
import 'package:baleadafit/features/planes/data/alimentos_repository.dart';
import 'package:baleadafit/features/planes/data/plan.dart';
import 'package:baleadafit/features/planes/data/planes_providers.dart';
import 'package:baleadafit/features/planes/data/planes_repository.dart';
import 'package:baleadafit/features/planes/ui/editar_tiempo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/pump.dart';

Map<String, Object?> _itemJson({
  required String alimentoId,
  required String nombre,
  double porciones = 1,
  double kcal = 205,
}) => {
  'id': 'i-$alimentoId',
  'alimentoId': alimentoId,
  'porciones': porciones,
  'alimentoVersionId': null,
  'alimento': {'nombre': nombre, 'porcionDescripcion': '1 taza', 'kcal': kcal},
};

/// One plan with a single day and a single meal time: what the editor opens on.
Map<String, Object?> _planJson({
  List<Map<String, Object?>> items = const [],
  double pctKcal = 0.35,
  double kcalMeta = 525,
}) => {
  'id': 'p1',
  'nombre': 'Plan 2026-11-07',
  'estado': 'BORRADOR',
  'origen': 'REGLAS',
  'kcalObjetivo': 1500,
  'proteinaG': 93.8,
  'carbohidratoG': 187.5,
  'grasaG': 41.7,
  'dias': [
    {
      'dia': 'LUNES',
      'tiempos': [
        {
          'id': 't-ALMUERZO',
          'planId': 'p1',
          'dia': 'LUNES',
          'tipo': 'ALMUERZO',
          'orden': 1,
          'kcalMeta': kcalMeta,
          'pctKcal': pctKcal,
          'items': items,
        },
      ],
      'totales': {'kcal': 1506},
      'desviacion': 0.004,
    },
  ],
};

/// The API the screen talks to: `GET /alimentos` for the picker and the `PUT`
/// that saves the meal time. [alTiempo] holds the copy of the list the screen
/// shows for the screen's assertions.
class _Api {
  _Api({List<Map<String, Object?>>? alimentos, this.falla})
    : alimentos = alimentos ?? const [];

  final List<Map<String, Object?>> alimentos;

  /// When it is set, the `PUT` answers with it instead of the plan.
  final Map<String, Object?>? falla;
  int guardados = 0;
}

FakeHttpAdapter _adapter(_Api api) => FakeHttpAdapter((options) async {
  if (options.method == 'PUT') {
    api.guardados++;
    final falla = api.falla;
    if (falla != null) {
      return jsonBody({'ok': false, 'error': falla}, status: 400);
    }
    return jsonBody({'ok': true, 'data': _planJson()});
  }
  return jsonBody({
    'ok': true,
    'data': api.alimentos,
    'meta': {
      'limit': 20,
      'offset': 0,
      'total': api.alimentos.length,
      'hasMore': false,
    },
  });
});

Future<void> _pump(
  WidgetTester tester, {
  required Map<String, Object?> plan,
  required FakeHttpAdapter adapter,
  VoidCallback? onGuardado,
  VoidCallback? onCerrar,
}) async {
  final api = ApiClient(dioWith(adapter));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        planDetalleProvider.overrideWith(
          (ref, id) => Future.value(PlanDetalle.fromJson(plan)),
        ),
        planesRepositoryProvider.overrideWith((ref) => PlanesRepository(api)),
        alimentosRepositoryProvider.overrideWith(
          (ref) => AlimentosRepository(api),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: EditarTiempoScreen(
          planId: 'p1',
          dia: DiaSemana.lunes,
          tipo: TipoComida.almuerzo,
          onCerrar: onCerrar ?? () {},
          onGuardado: onGuardado ?? () {},
        ),
      ),
    ),
  );
}

/// The border the portion button draws in its current state.
/// The bordered box a portion button draws: the 28 px square inside its tap
/// target.
BorderSide _borde(WidgetTester tester, String clave) {
  final caja = tester.widget<Container>(_cajaDe(clave));
  final decoracion = caja.decoration! as BoxDecoration;
  return decoracion.border!.top;
}

Finder _cajaDe(String clave) => find.descendant(
  of: find.byKey(Key(clave)),
  matching: find.byType(Container),
);

void main() {
  testWidgets('starts from the meal time and labels kcal per portion', (
    tester,
  ) async {
    final adapter = _adapter(_Api());
    await _pump(
      tester,
      plan: _planJson(
        items: [
          _itemJson(alimentoId: 'a-arroz', nombre: 'Arroz blanco'),
          _itemJson(
            alimentoId: 'a-pollo',
            nombre: 'Pollo a la plancha',
            porciones: 1.5,
            kcal: 231,
          ),
        ],
      ),
      adapter: adapter,
    );
    await pumpStable(tester);

    expect(find.text('Almuerzo · Lunes'), findsOneWidget);
    // `pctKcal` is a fraction: 0.35 is 35%, and the kcal is `kcalMeta`.
    expect(find.text('35% del día · meta 525 kcal'), findsOneWidget);
    expect(find.text('2 de 12 alimentos'), findsOneWidget);
    expect(find.text('Arroz blanco'), findsOneWidget);
    // The kcal is per portion and says so; 231 × 1.5 would be 347.
    expect(find.text('1 taza · 205 kcal por porción'), findsOneWidget);
    expect(find.text('1 taza · 231 kcal por porción'), findsOneWidget);
    expect(find.textContaining('347'), findsNothing);
    expect(find.text('1.5'), findsOneWidget);
    // Nothing was written to reach this state.
    expect(adapter.requests, isEmpty);
  });

  testWidgets('an empty meal time reads Sin alimentos, not a blocked save', (
    tester,
  ) async {
    await _pump(tester, plan: _planJson(), adapter: _adapter(_Api()));
    await pumpStable(tester);

    expect(find.text('Sin alimentos'), findsOneWidget);
    expect(find.text('0 de 12 alimentos'), findsOneWidget);
    expect(find.text('Guardar tiempo'), findsOneWidget);
  });

  testWidgets('saves the whole list to the path of the day and the time', (
    tester,
  ) async {
    final adapter = _adapter(_Api());
    var guardados = 0;
    await _pump(
      tester,
      plan: _planJson(
        items: [
          _itemJson(alimentoId: 'a-arroz', nombre: 'Arroz blanco'),
          _itemJson(
            alimentoId: 'a-pollo',
            nombre: 'Pollo a la plancha',
            porciones: 1.5,
            kcal: 231,
          ),
        ],
      ),
      adapter: adapter,
      onGuardado: () => guardados++,
    );
    await pumpStable(tester);

    // Taking one off is how the list shrinks: the PUT carries what is left.
    await tester.tap(find.byKey(const Key('quitar-a-pollo')));
    await pumpStable(tester);
    expect(find.text('Pollo a la plancha'), findsNothing);
    expect(find.text('1 de 12 alimentos'), findsOneWidget);

    await tester.tap(find.text('Guardar tiempo'));
    await pumpStable(tester);

    final pedido = adapter.requests.single;
    expect(pedido.method, 'PUT');
    expect(pedido.path, '/planes/p1/tiempos/LUNES/ALMUERZO/items');
    expect(pedido.data, {
      'items': [
        {'alimentoId': 'a-arroz', 'porciones': 1.0},
      ],
    });
    expect(guardados, 1);
  });

  testWidgets('an emptied meal time is saved with an empty list', (
    tester,
  ) async {
    final adapter = _adapter(_Api());
    var guardados = 0;
    await _pump(
      tester,
      plan: _planJson(
        items: [_itemJson(alimentoId: 'a-arroz', nombre: 'Arroz blanco')],
      ),
      adapter: adapter,
      onGuardado: () => guardados++,
    );
    await pumpStable(tester);

    await tester.tap(find.byKey(const Key('quitar-a-arroz')));
    await pumpStable(tester);
    await tester.tap(find.text('Guardar tiempo'));
    await pumpStable(tester);

    // The contract declares a maximum of 12 and no minimum: `[]` is valid.
    expect(adapter.requests.single.data, {'items': <Object?>[]});
    expect(guardados, 1);
  });

  testWidgets('the portion control moves in quarters and stops at its limits', (
    tester,
  ) async {
    await _pump(
      tester,
      plan: _planJson(
        items: [_itemJson(alimentoId: 'a-arroz', nombre: 'Arroz blanco')],
      ),
      adapter: _adapter(_Api()),
    );
    await pumpStable(tester);

    final valor = find.byKey(const Key('porciones-a-arroz'));
    expect(tester.widget<Text>(valor).data, '1');

    await tester.tap(find.byKey(const Key('mas-a-arroz')));
    await pumpStable(tester);
    expect(tester.widget<Text>(valor).data, '1.25');

    // Down to the floor, one quarter at a time: 0.25 is where it stops.
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const Key('menos-a-arroz')));
      await pumpStable(tester);
    }
    expect(tester.widget<Text>(valor).data, '0.25');

    final menos = tester.widget<IconButton>(
      find.byKey(const Key('menos-a-arroz')),
    );
    expect(menos.onPressed, isNull);
    // A disabled control still draws its bordered square, but softer.
    final c = Theme.of(tester.element(find.byType(EditarTiempoScreen)))
        .colorScheme;
    expect(
      _borde(tester, 'menos-a-arroz').color,
      c.outlineVariant.withValues(alpha: 0.5),
    );
    expect(_borde(tester, 'mas-a-arroz').color, c.outlineVariant);

    // Up to the ceiling: 6 is where it stops.
    for (var i = 0; i < 30; i++) {
      await tester.tap(find.byKey(const Key('mas-a-arroz')));
      await pumpStable(tester);
    }
    expect(tester.widget<Text>(valor).data, '6');
    final mas = tester.widget<IconButton>(find.byKey(const Key('mas-a-arroz')));
    expect(mas.onPressed, isNull);
    expect(
      _borde(tester, 'mas-a-arroz').color,
      c.outlineVariant.withValues(alpha: 0.5),
    );
  });

  testWidgets('the portion buttons are 28 px bordered squares, value in mono', (
    tester,
  ) async {
    await _pump(
      tester,
      plan: _planJson(
        items: [_itemJson(alimentoId: 'a-arroz', nombre: 'Arroz blanco')],
      ),
      adapter: _adapter(_Api()),
    );
    await pumpStable(tester);
    final c = Theme.of(tester.element(find.byType(EditarTiempoScreen)))
        .colorScheme;

    for (final clave in ['menos-a-arroz', 'mas-a-arroz']) {
      // The border keeps the 28 px the artboard draws; the tap target around it
      // is 40, because 28 is below what a finger hits reliably.
      expect(_cajaDe(clave), findsOneWidget);
      expect(tester.getSize(_cajaDe(clave)), const Size(28, 28));
      expect(tester.getSize(find.byKey(Key(clave))), const Size(40, 40));
      expect(_borde(tester, clave).color, c.outlineVariant);
      expect(_borde(tester, clave).width, 1);
    }

    final valor = tester.widget<Text>(
      find.byKey(const Key('porciones-a-arroz')),
    );
    expect(valor.style?.fontFamily, AppTypography.monoFamily);
    expect(valor.style?.fontSize, 13);
    expect(valor.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('the replace notice is a block with the info icon', (
    tester,
  ) async {
    await _pump(
      tester,
      plan: _planJson(items: []),
      adapter: _adapter(_Api()),
    );
    await pumpStable(tester);
    final c = Theme.of(tester.element(find.byType(EditarTiempoScreen)))
        .colorScheme;

    final aviso = find.byKey(const Key('aviso-reemplazo'));
    expect(
      (tester.widget<Container>(aviso).decoration! as BoxDecoration).color,
      c.surfaceContainerLow,
    );
    expect(
      find.descendant(of: aviso, matching: find.byIcon(Icons.info_outline)),
      findsOneWidget,
    );
  });

  testWidgets('a food picked from the catalogue joins the list', (
    tester,
  ) async {
    final adapter = _adapter(
      _Api(
        alimentos: [
          {
            'id': 'a-aji',
            'nombre': 'Ají verde',
            'porcionDescripcion': '1 unidad',
            'kcal': 12,
          },
        ],
      ),
    );
    await _pump(tester, plan: _planJson(), adapter: adapter);
    await pumpStable(tester);

    await tester.tap(find.byKey(const Key('agregar-alimento')));
    await pumpStable(tester);
    expect(find.text('Buscar alimento'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ají');
    // The field waits 300 ms after the last keystroke before asking.
    await pumpStable(tester);

    expect(find.text('Ají verde'), findsOneWidget);
    await tester.tap(find.text('Ají verde'));
    await pumpStable(tester);

    expect(find.byKey(const Key('item-a-aji')), findsOneWidget);
    expect(find.text('1 unidad · 12 kcal por porción'), findsOneWidget);
    expect(find.text('1 de 12 alimentos'), findsOneWidget);
    // The picker asked the catalogue with what was typed.
    final busqueda = adapter.requests.single;
    expect(busqueda.path, '/alimentos');
    expect(busqueda.queryParameters['q'], 'ají');
  });

  testWidgets('with twelve foods there is no room for one more', (
    tester,
  ) async {
    await _pump(
      tester,
      plan: _planJson(
        items: [
          for (var i = 1; i <= 12; i++)
            _itemJson(alimentoId: 'a-$i', nombre: 'Alimento $i'),
        ],
      ),
      adapter: _adapter(
        _Api(
          alimentos: [
            {'id': 'a-aji', 'nombre': 'Ají verde', 'kcal': 12},
          ],
        ),
      ),
    );
    await pumpStable(tester);

    expect(find.text('12 de 12 alimentos'), findsOneWidget);

    // The list is lazy: the field is built only once it scrolls near.
    await tester.scrollUntilVisible(
      find.byKey(const Key('agregar-alimento')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('agregar-alimento')));
    await pumpStable(tester);
    // The field ignores pointers when full: the tap must land on nothing.
    await tester.tap(
      find.byKey(const Key('agregar-alimento')),
      warnIfMissed: false,
    );
    await pumpStable(tester);

    // The field is there but it does not answer: the list is full.
    expect(find.text('Agregar alimento'), findsOneWidget);
    expect(find.text('Buscar alimento'), findsNothing);
  });

  testWidgets('a failed save keeps the list and can be tried again', (
    tester,
  ) async {
    final api = _Api(
      falla: {'codigo': 'VALIDACION', 'mensaje': 'Máximo 12 alimentos.'},
    );
    final adapter = _adapter(api);
    await _pump(
      tester,
      plan: _planJson(
        items: [_itemJson(alimentoId: 'a-arroz', nombre: 'Arroz blanco')],
      ),
      adapter: adapter,
    );
    await pumpStable(tester);

    await tester.tap(find.text('Guardar tiempo'));
    await pumpStable(tester);

    expect(find.text('Máximo 12 alimentos.'), findsOneWidget);
    expect(find.text('VALIDACION · HTTP 400'), findsOneWidget);
    // Nothing typed is lost, and the button works again.
    expect(find.text('Arroz blanco'), findsOneWidget);
    expect(find.text('1 de 12 alimentos'), findsOneWidget);

    await tester.tap(find.text('Guardar tiempo'));
    await pumpStable(tester);

    expect(api.guardados, 2);
  });

  testWidgets('closing without saving writes nothing', (tester) async {
    final adapter = _adapter(_Api());
    var cerrado = false;
    await _pump(
      tester,
      plan: _planJson(
        items: [_itemJson(alimentoId: 'a-arroz', nombre: 'Arroz blanco')],
      ),
      adapter: adapter,
      onCerrar: () => cerrado = true,
    );
    await pumpStable(tester);

    await tester.tap(find.byKey(const Key('quitar-a-arroz')));
    await pumpStable(tester);
    await tester.tap(find.byTooltip('Cerrar sin guardar'));
    await pumpStable(tester);

    expect(cerrado, isTrue);
    expect(adapter.requests, isEmpty);
  });
}
