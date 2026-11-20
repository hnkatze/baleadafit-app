import 'dart:async';

import 'package:baleadafit/features/catalogo/data/alimento.dart';
import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/catalogo/data/catalogo_providers.dart';
import 'package:baleadafit/features/catalogo/data/catalogo_repository.dart';
import 'package:baleadafit/features/catalogo/ui/alimento_detalle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, Object?> _pollo({
  List<String> contiene = const [],
  Object? indiceGlucemico,
  bool activo = true,
}) => {
  'id': 'ali-1',
  'nombre': 'Pollo a la plancha',
  'categoria': 'PROTEINA',
  'porcionDescripcion': '1 pieza mediana',
  'porcionGramos': 100,
  'kcal': 165,
  'proteinaG': 31,
  'carbohidratoG': 0,
  'grasaG': 4,
  'fibraG': 0,
  'sodioMg': 74,
  'potasioMg': 256,
  'fosforoMg': 228,
  'azucaresG': 0,
  'grasasSatG': 1,
  'indiceGlucemico': indiceGlucemico,
  'esTipicoHn': false,
  'tiposComida': ['ALMUERZO', 'CENA'],
  'contiene': contiene,
  'fuente': 'USDA',
  'activo': activo,
};

final _restricciones = [
  {'id': 'r1', 'codigo': 'lactosa', 'nombre': 'Lactosa'},
  {'id': 'r2', 'codigo': 'gluten', 'nombre': 'Gluten'},
];

FakeHttpAdapter _adapter({
  Map<String, Object?>? alimento,
  int detalleStatus = 200,
}) => FakeHttpAdapter((o) async {
  if (o.path == '/restricciones') {
    return jsonBody({'ok': true, 'data': _restricciones});
  }
  if (o.method == 'PATCH') {
    return jsonBody({
      'ok': true,
      'data': {...(alimento ?? _pollo()), 'activo': false},
    });
  }
  if (detalleStatus != 200) {
    return jsonBody({
      'ok': false,
      'error': {
        'codigo': 'ERROR',
        'mensaje': 'No hay conexión con el catálogo',
      },
    }, status: detalleStatus);
  }
  return jsonBody({'ok': true, 'data': alimento ?? _pollo()});
});

class _Llamadas {
  int volver = 0, editar = 0, historial = 0, baja = 0;
}

Future<_Llamadas> _pump(WidgetTester tester, FakeHttpAdapter adapter) async {
  final llamadas = _Llamadas();
  tester.view.physicalSize = const Size(390, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
          body: AlimentoDetalleScreen(
            alimentoId: 'ali-1',
            onVolver: () => llamadas.volver++,
            onEditar: () => llamadas.editar++,
            onVerHistorial: () => llamadas.historial++,
            onDadoDeBaja: () => llamadas.baja++,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return llamadas;
}

void main() {
  testWidgets('S6: draws identity, energy, macros and the source', (
    tester,
  ) async {
    await _pump(tester, _adapter());

    expect(find.text('Alimento'), findsOneWidget);
    expect(find.text('Pollo a la plancha'), findsOneWidget);
    expect(find.text('Proteína'), findsWidgets);
    expect(find.text('1 pieza mediana · 100 g'), findsOneWidget);
    expect(find.text('Por porción'), findsOneWidget);
    expect(find.text('165 kcal'), findsOneWidget);
    expect(find.text('31 g'), findsOneWidget);
    expect(find.text('Carbos'), findsOneWidget);
    expect(find.text('Grasa'), findsOneWidget);
    expect(find.text('Fibra'), findsOneWidget);
    expect(find.text('Fuente: USDA'), findsOneWidget);
  });

  testWidgets(
    'S6: sodium is Estimado with ~, null glycemic index is Sin dato',
    (tester) async {
      await _pump(tester, _adapter());

      expect(find.text('Micronutrientes'), findsOneWidget);
      expect(find.text('Sodio'), findsOneWidget);
      expect(find.text('Estimado'), findsOneWidget);
      expect(find.text('~74 mg'), findsOneWidget);
      expect(find.text('256 mg'), findsOneWidget);
      expect(find.text('Índice glucémico'), findsOneWidget);
      expect(find.text('Sin dato'), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(
        find.text(
          'El sodio es aproximado: verificar con INCAP. El índice glucémico no '
          'aplica a alimentos sin carbohidratos.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('S6: a real glycemic index shows its number, not Sin dato', (
    tester,
  ) async {
    await _pump(tester, _adapter(alimento: _pollo(indiceGlucemico: 55)));

    expect(find.text('55'), findsOneWidget);
    expect(find.text('Sin dato'), findsNothing);
  });

  testWidgets('S6: Contiene draws the nombre of each restriction', (
    tester,
  ) async {
    await _pump(
      tester,
      _adapter(alimento: _pollo(contiene: ['lactosa', 'gluten'])),
    );

    expect(find.text('Lactosa'), findsOneWidget);
    expect(find.text('Gluten'), findsOneWidget);
    expect(find.text('lactosa'), findsNothing);
    expect(find.textContaining('Sin etiquetas de restricción'), findsNothing);
  });

  testWidgets('S6: an unknown restriction does not break the screen', (
    tester,
  ) async {
    await _pump(
      tester,
      _adapter(alimento: _pollo(contiene: ['lactosa', 'maní'])),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Lactosa'), findsOneWidget);
    expect(find.text('maní'), findsOneWidget);
  });

  testWidgets('S6: no labels shows the empty text', (tester) async {
    await _pump(tester, _adapter());

    expect(
      find.text(
        'Sin etiquetas de restricción. Aparece aunque se excluya lactosa o '
        'gluten.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('S6: meal times are the ones of the food, not the five', (
    tester,
  ) async {
    await _pump(tester, _adapter());

    expect(find.text('Tiempos de comida'), findsOneWidget);
    expect(find.text('Almuerzo'), findsOneWidget);
    expect(find.text('Cena'), findsOneWidget);
    expect(find.text('Desayuno'), findsNothing);
    expect(find.text('Merienda AM'), findsNothing);
    expect(find.text('Merienda PM'), findsNothing);
  });

  testWidgets('S6: closing section and the three actions', (tester) async {
    final llamadas = await _pump(tester, _adapter());

    expect(find.text('DAR DE BAJA'), findsOneWidget);
    expect(
      find.text(
        'Sale del catálogo y de las búsquedas. No se borra: su historial de '
        'versiones se conserva.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Ver historial'));
    await tester.tap(find.text('Editar'));
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    expect(llamadas.historial, 1);
    expect(llamadas.editar, 1);
    expect(llamadas.volver, 1);
    expect(llamadas.baja, 0);
  });

  testWidgets('S6: the history icon of the header opens the history', (
    tester,
  ) async {
    final llamadas = await _pump(tester, _adapter());

    await tester.tap(find.byTooltip('Ver historial'));
    await tester.pump();

    expect(llamadas.historial, 1);
  });

  testWidgets('S7: Dar de baja asks, one PATCH, then onDadoDeBaja', (
    tester,
  ) async {
    final adapter = _adapter();
    final llamadas = await _pump(tester, adapter);

    await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
    await tester.pumpAndSettle();
    expect(find.text('¿Dar de baja “Pollo a la plancha”?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Dar de baja'),
      ),
    );
    await tester.pumpAndSettle();

    final patches = adapter.requests.where((r) => r.method == 'PATCH');
    expect(patches, hasLength(1));
    expect(patches.single.data, {'activo': false});
    expect(llamadas.baja, 1);
  });

  testWidgets('S7: the cross leaves the screen untouched', (tester) async {
    final adapter = _adapter();
    final llamadas = await _pump(tester, adapter);

    await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cerrar-dialogo')));
    await tester.pumpAndSettle();

    expect(adapter.requests.where((r) => r.method == 'PATCH'), isEmpty);
    expect(llamadas.baja, 0);
  });

  testWidgets('S7: a failed baja shows the message and does not notify', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter((o) async {
      if (o.path == '/restricciones') return jsonBody({'ok': true, 'data': []});
      if (o.method == 'PATCH') {
        return jsonBody({
          'ok': false,
          'error': {
            'codigo': 'NO_ENCONTRADO',
            'mensaje': 'El alimento no existe',
          },
        }, status: 404);
      }
      return jsonBody({'ok': true, 'data': _pollo()});
    });
    final llamadas = await _pump(tester, adapter);

    await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Dar de baja'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('El alimento no existe'), findsOneWidget);
    expect(llamadas.baja, 0);
  });

  testWidgets('load failure shows the message and Reintentar recovers', (
    tester,
  ) async {
    var falla = true;
    final adapter = FakeHttpAdapter((o) async {
      if (o.path == '/restricciones') return jsonBody({'ok': true, 'data': []});
      if (falla) {
        return jsonBody({
          'ok': false,
          'error': {
            'codigo': 'ERROR',
            'mensaje': 'Sin conexión con el catálogo',
          },
        }, status: 500);
      }
      return jsonBody({'ok': true, 'data': _pollo()});
    });
    await _pump(tester, adapter);

    expect(find.text('Sin conexión con el catálogo'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    falla = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Pollo a la plancha'), findsOneWidget);
  });

  testWidgets('the back arrow works while the food is still loading', (
    tester,
  ) async {
    final llamadas = _Llamadas();
    final carga = Completer<Alimento>();
    addTearDown(() => carga.complete(const Alimento(id: 'ali-1', nombre: 'x')));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alimentoDetalleProvider.overrideWith((ref, id) => carga.future),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AlimentoDetalleScreen(
              alimentoId: 'ali-1',
              onVolver: () => llamadas.volver++,
              onEditar: () {},
              onVerHistorial: () {},
              onDadoDeBaja: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(llamadas.volver, 1);
  });
}
