import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/catalogo/data/alimento.dart';
import 'package:baleadafit/features/catalogo/data/catalogo_providers.dart';
import 'package:baleadafit/features/catalogo/data/catalogo_repository.dart';
import 'package:baleadafit/features/catalogo/ui/catalogo_busqueda_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

const _restricciones = [
  {'id': 'r1', 'codigo': 'lactosa', 'nombre': 'Sin lactosa'},
  {'id': 'r2', 'codigo': 'gluten', 'nombre': 'Sin gluten'},
];

Map<String, Object?> _alimento(int n, {String? nombre, bool tipico = false}) =>
    {
      'id': 'ali-$n',
      'nombre': nombre ?? 'Alimento $n',
      'categoria': 'PROTEINA',
      'porcionDescripcion': '1 pieza mediana',
      'porcionGramos': 100,
      'kcal': 165,
      'proteinaG': 31,
      'carbohidratoG': 0,
      'grasaG': 4,
      'esTipicoHn': tipico,
    };

/// Answers `/restricciones` and `/alimentos`. [total] is the size of the
/// filtered result; an unfiltered `limit=1` probe always answers [catalogo].
class _Api {
  _Api({this.total = 38, this.fallar = false});

  int total;
  static const catalogo = 151;
  bool fallar;

  late final adapter = FakeHttpAdapter((options) async {
    if (options.path == '/restricciones') {
      return jsonBody({'ok': true, 'data': _restricciones});
    }
    if (fallar) {
      return jsonBody({
        'ok': false,
        'error': {'codigo': 'ERROR', 'mensaje': 'Falló el servidor.'},
      }, status: 500);
    }
    final q = options.queryParameters;
    final limit = (q['limit'] as int?) ?? 20;
    final offset = (q['offset'] as int?) ?? 0;
    final filtrado = q.keys.any(
      (k) => const {
        'q',
        'categoria',
        'tipoComida',
        'soloTipicos',
        'excluir',
      }.contains(k),
    );
    final size = filtrado ? total : catalogo;
    final fin = (offset + limit).clamp(0, size);
    final items = [
      for (var i = offset; i < fin; i++) _alimento(i, tipico: i == 1),
    ];
    return jsonBody({
      'ok': true,
      'data': items,
      'meta': {
        'limit': limit,
        'offset': offset,
        'total': size,
        'hasMore': fin < size,
      },
    });
  });

  /// `GET /alimentos` requests, in order.
  List<Map<String, dynamic>> get busquedas => [
    for (final r in adapter.requests)
      if (r.path == '/alimentos') r.queryParameters,
  ];
}

int _agregados = 0;
Alimento? _abierto;

Future<void> _pump(WidgetTester tester, _Api api) async {
  _agregados = 0;
  _abierto = null;
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogoRepositoryProvider.overrideWithValue(
          CatalogoRepository(ApiClient(dioWith(api.adapter))),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CatalogoBusquedaScreen(
            onAgregar: () => _agregados++,
            onAbrir: (a) => _abierto = a,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Types in the search box and lets the debounce fire.
Future<void> _escribir(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField), texto);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('S1: header shows the unfiltered count from a limit=1 search', (
    tester,
  ) async {
    final api = _Api();
    await _pump(tester, api);

    expect(find.text('Catálogo de alimentos'), findsOneWidget);
    expect(find.text('151 alimentos activos'), findsOneWidget);
    expect(find.text('Buscar por nombre…'), findsOneWidget);
    expect(api.busquedas.any((q) => q.length == 1 && q['limit'] == 1), isTrue);
  });

  testWidgets('S1: category chips start with Todas and the nine labels', (
    tester,
  ) async {
    await _pump(tester, _Api());

    for (final etiqueta in [
      'Todas',
      'Plato típico',
      'Proteína',
      'Cereal y tubérculo',
      'Leguminosa',
      'Lácteo',
      'Fruta',
      'Verdura',
      'Grasa',
      'Bebida',
    ]) {
      expect(
        find.descendant(
          of: find.byKey(const Key('chips-categoria')),
          matching: find.text(etiqueta),
        ),
        findsOneWidget,
        reason: etiqueta,
      );
    }
  });

  testWidgets('S1: typing sends q once after the debounce, not per key', (
    tester,
  ) async {
    final api = _Api();
    await _pump(tester, api);
    final antes = api.busquedas.length;

    await tester.enterText(find.byType(TextField), 'q');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'queso');
    await tester.pump(const Duration(milliseconds: 100));
    expect(api.busquedas.length, antes);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(api.busquedas.length, antes + 1);
    expect(api.busquedas.last['q'], 'queso');
  });

  testWidgets('S1: picking a category sends categoria', (tester) async {
    final api = _Api();
    await _pump(tester, api);

    await tester.tap(find.text('Lácteo'));
    await tester.pumpAndSettle();

    expect(api.busquedas.last['categoria'], 'LACTEO');
    // Todas goes back to no filter.
    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    expect(api.busquedas.last.containsKey('categoria'), isFalse);
  });

  testWidgets('S2: meal time sends tipoComida', (tester) async {
    final api = _Api();
    await _pump(tester, api);

    await tester.tap(find.byKey(const Key('filtro-tiempo')));
    await tester.pumpAndSettle();
    for (final t in ['Desayuno', 'Merienda AM', 'Almuerzo', 'Merienda PM']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    await tester.tap(find.text('Merienda AM'));
    await tester.pumpAndSettle();

    expect(api.busquedas.last['tipoComida'], 'MERIENDA_AM');
  });

  testWidgets('S2: Sólo típicos HN sends soloTipicos and draws its chip', (
    tester,
  ) async {
    final api = _Api();
    await _pump(tester, api);
    expect(find.text('FILTROS'), findsNothing);

    await tester.tap(find.byKey(const Key('filtro-solo-tipicos')));
    await tester.pumpAndSettle();

    expect(api.busquedas.last['soloTipicos'], true);
    expect(find.text('FILTROS'), findsOneWidget);
    // Same label in the control and in the FILTROS chip.
    expect(find.text('Sólo típicos HN'), findsNWidgets(2));
    expect(find.text('Sólo típicos'), findsNothing);
  });

  testWidgets(
    'S2: excluding a restriction sends its codigo and draws the chip',
    (tester) async {
      final api = _Api();
      await _pump(tester, api);
      expect(find.text('Excluir'), findsOneWidget);

      await tester.tap(find.byKey(const Key('filtro-excluir')));
      await tester.pumpAndSettle();
      // The names come from GET /restricciones.
      expect(find.text('Sin gluten'), findsOneWidget);
      await tester.tap(find.byKey(const Key('excluir-lactosa')));
      await tester.pumpAndSettle();

      expect(api.busquedas.last['excluir'], 'lactosa');
      expect(find.text('Excluir · 1'), findsOneWidget);
      expect(find.text('FILTROS'), findsOneWidget);
      expect(find.byKey(const Key('quitar-excluir-lactosa')), findsOneWidget);

      await tester.tap(find.byKey(const Key('quitar-excluir-lactosa')));
      await tester.pumpAndSettle();
      expect(api.busquedas.last.containsKey('excluir'), isFalse);
      expect(find.text('FILTROS'), findsNothing);
    },
  );

  testWidgets('S2: Limpiar removes every filter chip', (tester) async {
    final api = _Api();
    await _pump(tester, api);
    await tester.tap(find.text('Lácteo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filtro-solo-tipicos')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('filtros-limpiar')));
    await tester.pumpAndSettle();

    expect(find.text('FILTROS'), findsNothing);
    final ultima = api.busquedas.last;
    expect(ultima.containsKey('categoria'), isFalse);
    expect(ultima.containsKey('soloTipicos'), isFalse);
  });

  testWidgets('S3: results show count and the row copy', (tester) async {
    await _pump(tester, _Api());
    await _escribir(tester, 'a');

    expect(find.text('38 resultados'), findsOneWidget);
    expect(find.text('Alimento 0'), findsOneWidget);
    expect(find.text('Proteína · 1 pieza mediana · 100 g'), findsNWidgets(20));
    expect(find.text('P 31 · C 0 · G 4 g'), findsNWidgets(20));
    expect(find.text('KCAL'), findsNWidgets(20));
    expect(find.text('165'), findsNWidgets(20));
    // Only the typical one wears the badge.
    expect(find.text('Típico'), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('S3: tapping a row opens that food', (tester) async {
    await _pump(tester, _Api());

    await tester.tap(find.text('Alimento 2'));

    expect(_abierto?.id, 'ali-2');
    expect(_abierto?.nombre, 'Alimento 2');
  });

  testWidgets('S4: Cargar K más asks the next page and accumulates', (
    tester,
  ) async {
    final api = _Api();
    await _pump(tester, api);
    await _escribir(tester, 'a');

    expect(find.text('Mostrando 20 de 38'), findsOneWidget);
    expect(find.text('Cargar 18 más'), findsOneWidget);

    await tester.tap(find.text('Cargar 18 más'));
    await tester.pumpAndSettle();

    expect(api.busquedas.last['offset'], 20);
    expect(api.busquedas.last['q'], 'a');
    expect(find.text('Alimento 0'), findsOneWidget);
    expect(find.text('Alimento 37'), findsOneWidget);
    expect(find.text('Mostrando 38 de 38'), findsOneWidget);
    expect(find.textContaining('Cargar'), findsNothing);
  });

  testWidgets('S4: Agregar alimento calls onAgregar', (tester) async {
    await _pump(tester, _Api());

    await tester.tap(find.text('Agregar alimento'));

    expect(_agregados, 1);
  });

  testWidgets('S5: no results names the text and the filters, Limpiar them', (
    tester,
  ) async {
    final api = _Api(total: 0);
    await _pump(tester, api);
    await tester.tap(find.text('Lácteo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filtro-solo-tipicos')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filtro-excluir')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('excluir-lactosa')));
    await tester.pumpAndSettle();
    await _escribir(tester, 'quesillo');

    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.text('Ningún alimento con estos filtros'), findsOneWidget);
    expect(
      find.textContaining(
        'de 151 alimentos coinciden con “quesillo” y los 3 filtros. '
        'Quitá uno para ampliar la búsqueda.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('¿No está en el catálogo? Nadie más lo carga: lo agregás vos.'),
      findsOneWidget,
    );

    api.total = 5;
    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();

    expect(find.text('Ningún alimento con estos filtros'), findsNothing);
    expect(find.text('FILTROS'), findsNothing);
    final ultima = api.busquedas.last;
    for (final k in ['categoria', 'soloTipicos', 'excluir', 'tipoComida']) {
      expect(ultima.containsKey(k), isFalse, reason: k);
    }
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('S5: the Agregar of the support block calls onAgregar', (
    tester,
  ) async {
    await _pump(tester, _Api(total: 0));
    await _escribir(tester, 'zzz');

    await tester.tap(find.byKey(const Key('sin-resultados-agregar')));

    expect(_agregados, 1);
  });

  testWidgets('a failing search shows Reintentar and recovers', (tester) async {
    final api = _Api(fallar: true);
    await _pump(tester, api);
    await _escribir(tester, 'a');

    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Agregar alimento'), findsOneWidget);

    api.fallar = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('38 resultados'), findsOneWidget);
  });
}
