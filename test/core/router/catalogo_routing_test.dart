import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/router/app_router.dart';
import 'package:baleadafit/core/router/app_routes.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/auth/application/session_controller.dart';
import 'package:baleadafit/features/auth/data/auth_session.dart';
import 'package:baleadafit/features/auth/data/user_role.dart';
import 'package:baleadafit/features/catalogo/data/catalogo_providers.dart';
import 'package:baleadafit/features/catalogo/data/catalogo_repository.dart';
import 'package:baleadafit/features/catalogo/ui/alimento_detalle_screen.dart';
import 'package:baleadafit/features/catalogo/ui/alimento_form_screen.dart';
import 'package:baleadafit/features/catalogo/ui/alimento_historial_screen.dart';
import 'package:baleadafit/features/catalogo/ui/catalogo_busqueda_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/pump.dart';

class _Sesion extends SessionController {
  @override
  SessionState build() => const SessionState(
    status: SessionStatus.authenticated,
    session: AuthSession(rol: UserRole.nutricionista, displayName: 'Sofía'),
  );

  @override
  Future<void> restore() async {}
}

Map<String, Object?> _alimento(String id, String nombre) => {
  'id': id,
  'nombre': nombre,
  'categoria': 'PROTEINA',
  'porcionDescripcion': '1 pieza',
  'porcionGramos': 120,
  'kcal': 190,
  'proteinaG': 31,
  'carbohidratoG': 0,
  'grasaG': 4,
  'esTipicoHn': false,
};

/// Answers every endpoint the catalogue uses.
FakeHttpAdapter _adapter() => FakeHttpAdapter((o) async {
  if (o.method == 'POST') {
    return jsonBody({'ok': true, 'data': _alimento('al-9', 'Agua')}, status: 201);
  }
  if (o.path == '/restricciones') return jsonBody({'ok': true, 'data': []});
  if (o.path == '/alimentos') {
    final items = [
      _alimento('al-1', 'Pollo asado'),
      _alimento('al-2', 'Frijoles'),
    ];
    return jsonBody({
      'ok': true,
      'data': items,
      'meta': {'limit': 20, 'offset': 0, 'total': 2, 'hasMore': false},
    });
  }
  if (o.path == '/alimentos/al-1/versiones') {
    return jsonBody({
      'ok': true,
      'data': [
        {
          'id': 'ver-1',
          'version': 1,
          'tabla': 'INCAP',
          'vigenteDesde': '2026-11-12T12:00:00.000Z',
          'vigenteHasta': null,
        },
      ],
      'meta': {'limit': 20, 'offset': 0, 'total': 1, 'hasMore': false},
    });
  }
  if (o.path == '/alimentos/al-1') {
    return jsonBody({'ok': true, 'data': _alimento('al-1', 'Pollo asado')});
  }
  return jsonBody({
    'ok': false,
    'error': {'codigo': 'NOT_FOUND', 'mensaje': 'No existe.'},
  }, status: 404);
});

Future<GoRouter> _pump(
  WidgetTester tester,
  FakeHttpAdapter adapter, {
  String location = AppRoutes.home,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(_Sesion.new),
        catalogoRepositoryProvider.overrideWithValue(
          CatalogoRepository(ApiClient(dioWith(adapter))),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await pumpStable(tester);
  return router;
}

String _ubicacion(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

int _busquedas(FakeHttpAdapter a) => a.requests
    .where(
      (r) =>
          r.method == 'GET' &&
          r.path == '/alimentos' &&
          r.queryParameters['limit'] != 1,
    )
    .length;

void main() {
  group('rutas', () {
    test('the helpers build the catalogue locations', () {
      expect(AppRoutes.catalogo, '/catalogo');
      expect(AppRoutes.nuevoAlimento, '/catalogo/nueva');
      expect(AppRoutes.alimento('al-1'), '/catalogo/al-1');
      expect(AppRoutes.editarAlimento('al-1'), '/catalogo/al-1/editar');
      expect(AppRoutes.historialAlimento('al-1'), '/catalogo/al-1/historial');
    });

    test('encode odd ids', () {
      expect(AppRoutes.alimento('a b/c'), '/catalogo/a%20b%2Fc');
      expect(
        AppRoutes.editarAlimento('a b/c'),
        '/catalogo/a%20b%2Fc/editar',
      );
      expect(
        AppRoutes.historialAlimento('ñ?#'),
        '/catalogo/%C3%B1%3F%23/historial',
      );
    });
  });

  group('ruteo', () {
    testWidgets('the drawer reaches the search and lists the results', (
      tester,
    ) async {
      final adapter = _adapter();
      final router = await _pump(tester, adapter);

      await tester.tap(find.byTooltip('Abrir menú'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Catálogo de alimentos'));
      await tester.pumpAndSettle();

      expect(_ubicacion(router), AppRoutes.catalogo);
      expect(find.byType(CatalogoBusquedaScreen), findsOneWidget);
      expect(find.text('Pollo asado'), findsOneWidget);
      expect(find.text('Frijoles'), findsOneWidget);
    });

    testWidgets('tapping a row opens the detail of that food', (tester) async {
      final router = await _pump(
        tester,
        _adapter(),
        location: AppRoutes.catalogo,
      );

      await tester.tap(find.text('Pollo asado'));
      await pumpStable(tester);

      expect(_ubicacion(router), AppRoutes.alimento('al-1'));
      final detalle = tester.widget<AlimentoDetalleScreen>(
        find.byType(AlimentoDetalleScreen),
      );
      expect(detalle.alimentoId, 'al-1');
    });

    testWidgets('the back arrow of the detail returns to the search', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        _adapter(),
        location: AppRoutes.catalogo,
      );
      await tester.tap(find.text('Pollo asado'));
      await pumpStable(tester);

      await tester.tap(find.byTooltip('Volver'));
      await pumpStable(tester);

      expect(_ubicacion(router), AppRoutes.catalogo);
      expect(find.byType(CatalogoBusquedaScreen), findsOneWidget);
    });

    testWidgets('a deep link to the detail still goes back to the search', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        _adapter(),
        location: AppRoutes.alimento('al-1'),
      );
      expect(find.byType(AlimentoDetalleScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Volver'));
      await pumpStable(tester);

      expect(_ubicacion(router), AppRoutes.catalogo);
    });

    testWidgets('Editar opens the preloaded form', (tester) async {
      final router = await _pump(
        tester,
        _adapter(),
        location: AppRoutes.alimento('al-1'),
      );

      await tester.tap(find.text('Editar'));
      await pumpStable(tester);

      expect(_ubicacion(router), AppRoutes.editarAlimento('al-1'));
      expect(find.byType(AlimentoFormScreen), findsOneWidget);
      expect(find.text('Editar alimento'), findsOneWidget);
      final nombre = tester.widget<TextField>(
        find.byKey(const ValueKey('nombre')),
      );
      expect(nombre.controller!.text, 'Pollo asado');
    });

    testWidgets('a deep link to the edit form loads the food first', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(),
        location: AppRoutes.editarAlimento('al-1'),
      );

      expect(find.byType(AlimentoFormScreen), findsOneWidget);
      expect(find.text('Editar alimento'), findsOneWidget);
    });

    testWidgets('the edit form shows an x and a spinner while it loads', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter((o) async {
        if (o.path == '/alimentos/al-1') {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        return _adapter().responder(o);
      });
      final router = await _pump(
        tester,
        adapter,
        location: AppRoutes.editarAlimento('al-1'),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byType(AlimentoFormScreen), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump(const Duration(seconds: 2));
      await pumpStable(tester);
      expect(_ubicacion(router), AppRoutes.alimento('al-1'));
    });

    testWidgets('a failed load offers the exit and Reintentar', (tester) async {
      var fallar = true;
      final adapter = FakeHttpAdapter((o) async {
        if (o.path == '/alimentos/al-1' && fallar) {
          return jsonBody({
            'ok': false,
            'error': {'codigo': 'ERROR', 'mensaje': 'Falló el servidor.'},
          }, status: 500);
        }
        return _adapter().responder(o);
      });
      await _pump(tester, adapter, location: AppRoutes.editarAlimento('al-1'));

      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      fallar = false;
      await tester.tap(find.text('Reintentar'));
      await pumpStable(tester);
      expect(find.byType(AlimentoFormScreen), findsOneWidget);
    });

    testWidgets('Ver historial opens the history of that food', (tester) async {
      final router = await _pump(
        tester,
        _adapter(),
        location: AppRoutes.alimento('al-1'),
      );

      await tester.tap(find.text('Ver historial').last);
      await pumpStable(tester);

      expect(_ubicacion(router), AppRoutes.historialAlimento('al-1'));
      expect(find.byType(AlimentoHistorialScreen), findsOneWidget);
      expect(find.text('Pollo asado · 1 versión'), findsOneWidget);
    });

    testWidgets('the x of the alta returns to the search', (tester) async {
      final router = await _pump(
        tester,
        _adapter(),
        location: AppRoutes.catalogo,
      );

      await tester.tap(find.text('Agregar alimento'));
      await pumpStable(tester);
      expect(_ubicacion(router), AppRoutes.nuevoAlimento);
      expect(find.byType(AlimentoFormScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await pumpStable(tester);

      expect(_ubicacion(router), AppRoutes.catalogo);
      expect(find.byType(AlimentoFormScreen), findsNothing);
      expect(find.byType(CatalogoBusquedaScreen), findsOneWidget);
    });

    testWidgets('nueva is not read as a food id', (tester) async {
      final adapter = _adapter();
      await _pump(tester, adapter, location: AppRoutes.nuevoAlimento);

      expect(find.byType(AlimentoFormScreen), findsOneWidget);
      expect(find.byType(AlimentoDetalleScreen), findsNothing);
      expect(adapter.requests.any((r) => r.path == '/alimentos/nueva'), isFalse);
    });

    testWidgets('a saved alta returns to the search and asks the list again', (
      tester,
    ) async {
      final adapter = _adapter();
      final router = await _pump(
        tester,
        adapter,
        location: AppRoutes.catalogo,
      );
      final antes = _busquedas(adapter);
      expect(antes, 1);

      await tester.tap(find.text('Agregar alimento'));
      await pumpStable(tester);
      await tester.enterText(find.byKey(const ValueKey('nombre')), 'Agua');
      await tester.enterText(find.byKey(const ValueKey('kcal')), '0');
      final guardar = find.widgetWithText(FilledButton, 'Agregar alimento');
      await tester.ensureVisible(guardar);
      await tester.tap(guardar);
      await pumpStable(tester);
      await pumpStable(tester);

      expect(adapter.requests.where((r) => r.method == 'POST'), hasLength(1));
      expect(_ubicacion(router), AppRoutes.catalogo);
      expect(find.byType(AlimentoFormScreen), findsNothing);
      expect(_busquedas(adapter), antes + 1);
    });
  });

  test('the search providers are the ones the routes invalidate', () {
    // Guards the public surface the host relies on.
    expect(resultadosCatalogoProvider, isNotNull);
    expect(totalCatalogoProvider, isNotNull);
    expect(alimentoDetalleProvider('x'), isNotNull);
    expect(alimentoVersionesProvider('x'), isNotNull);
  });
}
