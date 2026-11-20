import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/catalogo/data/catalogo_providers.dart';
import 'package:baleadafit/features/catalogo/data/catalogo_repository.dart';
import 'package:baleadafit/features/catalogo/ui/alimento_historial_screen.dart';
import 'package:dio/dio.dart' show ResponseBody;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/pump.dart';

const _aviso =
    'Cada cambio de nutrientes guarda una versión. Es la prueba de qué '
    'valores tenía el alimento cuando se armó un plan. Valores por porción.';
const _unaSola =
    'Un alimento recién agregado muestra sólo la Versión 1, vigente, con '
    '“→ hoy”. Sin línea de tiempo ni comparación.';

// Midday UTC: the same calendar day in every time zone.
Map<String, Object?> _version(
  int n, {
  required String desde,
  String? hasta,
  String tabla = 'INCAP',
  Map<String, Object?> extra = const {},
}) => {
  'id': 'ver-$n',
  'version': n,
  'tabla': tabla,
  'vigenteDesde': desde,
  'vigenteHasta': hasta,
  ...extra,
};

Map<String, Object?> _pagina(
  List<Map<String, Object?>> items, {
  bool hasMore = false,
  int? total,
  int offset = 0,
}) => {
  'ok': true,
  'data': items,
  'meta': {
    'limit': 20,
    'offset': offset,
    'total': total ?? items.length,
    'hasMore': hasMore,
  },
};

final _dos = [
  _version(
    2,
    desde: '2026-11-12T12:00:00.000Z',
    tabla: 'USDA',
    extra: {
      'kcal': 165,
      'proteinaG': 31,
      'carbohidratoG': 0,
      'grasaG': 4,
      'sodioMg': 74,
      'fibraG': 0,
      'grasasSatG': 1,
    },
  ),
  _version(
    1,
    desde: '2025-03-01T12:00:00.000Z',
    hasta: '2026-11-12T12:00:00.000Z',
    extra: {'kcal': 172, 'sodioMg': 80},
  ),
];

int _volver = 0;

Future<FakeHttpAdapter> _pump(
  WidgetTester tester,
  Future<ResponseBody> Function(int llamada) responder,
) async {
  _volver = 0;
  var llamadas = 0;
  final adapter = FakeHttpAdapter((_) => responder(llamadas++));

  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogoRepositoryProvider.overrideWithValue(
          CatalogoRepository(ApiClient(dioWith(adapter))),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AlimentoHistorialScreen(
            alimentoId: 'ali-1',
            alimentoNombre: 'Pollo a la plancha',
            onVolver: () => _volver++,
          ),
        ),
      ),
    ),
  );
  await pumpStable(tester);
  return adapter;
}

void main() {
  testWidgets('S9: asks GET /alimentos/{id}/versiones and shows the loading', (
    tester,
  ) async {
    final adapter = await _pump(tester, (_) async => jsonBody(_pagina(_dos)));

    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/alimentos/ali-1/versiones');
  });

  testWidgets('S9: header, notice and the two versions', (tester) async {
    await _pump(tester, (_) async => jsonBody(_pagina(_dos)));

    expect(find.text('Pollo a la plancha · 2 versiones'), findsOneWidget);
    expect(find.text(_aviso), findsOneWidget);
    expect(find.text('Versión 2'), findsOneWidget);
    expect(find.text('Versión 1'), findsOneWidget);
    expect(find.text('VIGENTE'), findsOneWidget);
    expect(find.text('Tabla: USDA'), findsOneWidget);
    expect(find.text('Tabla: INCAP'), findsOneWidget);
    expect(find.text('12 nov 2026 → hoy'), findsOneWidget);
    expect(find.text('1 mar 2025 → 12 nov 2026'), findsOneWidget);
  });

  testWidgets('S9: the grid shows the values and sodium as an estimate', (
    tester,
  ) async {
    await _pump(tester, (_) async => jsonBody(_pagina(_dos)));

    for (final etiqueta in [
      'KCAL',
      'PROT',
      'CARB',
      'GRASA',
      'SODIO',
      'FIBRA',
      'SAT',
      'IG',
    ]) {
      expect(find.text(etiqueta), findsNWidgets(2), reason: etiqueta);
    }
    expect(find.text('165'), findsOneWidget);
    expect(find.text('31 g'), findsOneWidget);
    expect(find.text('~74 mg'), findsOneWidget);
    expect(find.text('~80 mg'), findsOneWidget);
  });

  testWidgets('S9: a missing value reads "sin dato", never 0', (tester) async {
    await _pump(tester, (_) async => jsonBody(_pagina(_dos)));

    // v2: only IG missing. v1: everything but KCAL and SODIO (6 of 8).
    expect(find.text('sin dato'), findsNWidgets(1 + 6));
    expect(find.text('0 g'), findsNWidgets(2)); // CARB and FIBRA of v2: real 0
  });

  testWidgets('S9: a single version explains the state, two do not', (
    tester,
  ) async {
    await _pump(
      tester,
      (_) async =>
          jsonBody(_pagina([_version(1, desde: '2026-11-12T12:00:00.000Z')])),
    );

    expect(find.text('Pollo a la plancha · 1 versión'), findsOneWidget);
    expect(find.text('Estado: una sola versión'), findsOneWidget);
    expect(find.text(_unaSola), findsOneWidget);
    expect(find.text('VIGENTE'), findsOneWidget);
    expect(find.text('12 nov 2026 → hoy'), findsOneWidget);
  });

  testWidgets('S9: with two versions the single-version block is absent', (
    tester,
  ) async {
    await _pump(tester, (_) async => jsonBody(_pagina(_dos)));

    expect(find.text('Estado: una sola versión'), findsNothing);
    expect(find.text(_unaSola), findsNothing);
  });

  testWidgets('S9: the back arrow calls onVolver', (tester) async {
    await _pump(tester, (_) async => jsonBody(_pagina(_dos)));

    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(_volver, 1);
  });

  testWidgets('S9: pagination appears only with hasMore and appends', (
    tester,
  ) async {
    final adapter = await _pump(
      tester,
      (n) async => n == 0
          ? jsonBody(_pagina([_dos[0]], hasMore: true, total: 2))
          : jsonBody(_pagina([_dos[1]], total: 2, offset: 1)),
    );

    expect(find.text('Versión 1'), findsNothing);
    expect(find.text('Pollo a la plancha · 2 versiones'), findsOneWidget);
    await tester.tap(find.text('Cargar más versiones'));
    await pumpStable(tester);

    expect(adapter.requests.last.queryParameters['offset'], 1);
    expect(find.text('Versión 1'), findsOneWidget);
    expect(find.text('Versión 2'), findsOneWidget);
    expect(find.text('Cargar más versiones'), findsNothing);
  });

  testWidgets('S9: without more pages there is no load-more action', (
    tester,
  ) async {
    await _pump(tester, (_) async => jsonBody(_pagina(_dos)));

    expect(find.text('Cargar más versiones'), findsNothing);
  });

  testWidgets('S9: a 401 shows the failure and Reintentar asks again', (
    tester,
  ) async {
    final adapter = await _pump(
      tester,
      (n) async => n == 0
          ? jsonBody({
              'ok': false,
              'error': {
                'codigo': 'NO_AUTENTICADO',
                'mensaje': 'Token inválido o expirado.',
              },
            }, status: 401)
          : jsonBody(_pagina(_dos)),
    );

    expect(find.text('No pudimos cargar el historial.'), findsOneWidget);
    expect(find.text('Token inválido o expirado.'), findsOneWidget);
    expect(find.text('Versión 2'), findsNothing);

    await tester.tap(find.text('Reintentar'));
    await pumpStable(tester);

    expect(adapter.requests, hasLength(2));
    expect(find.text('Versión 2'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('S9: an empty list says there is no history', (tester) async {
    await _pump(tester, (_) async => jsonBody(_pagina(const [])));

    expect(find.text('Sin versiones registradas.'), findsOneWidget);
    expect(find.text('Estado: una sola versión'), findsNothing);
  });
}
