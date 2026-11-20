import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/catalogo/data/alimento.dart';
import 'package:baleadafit/features/catalogo/data/catalogo_providers.dart';
import 'package:baleadafit/features/catalogo/data/catalogo_repository.dart';
import 'package:baleadafit/features/catalogo/ui/alimento_form_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/pump.dart';

const _aviso =
    'Todos los valores son por porción. Si vaciás un campo, se conserva el '
    'valor guardado. Cambiar un nutriente crea una versión nueva.';
const _ayudaSodio = 'Se guarda como aproximado. Verificar con INCAP.';
const _ayudaIg =
    'Dejalo vacío si el alimento no tiene carbohidratos: queda “sin dato”, '
    'no 0.';
const _notaContiene =
    'Ninguna marcada: aparece aunque se excluyan restricciones en la búsqueda.';

Map<String, Object?> _entidad() => {
  'ok': true,
  'data': {'id': 'al-1', 'nombre': 'Pollo asado', 'categoria': 'PROTEINA'},
};

Map<String, Object?> _error(
  String codigo,
  String mensaje, {
  List<Object?>? detalles,
}) => {
  'ok': false,
  'error': {'codigo': codigo, 'mensaje': mensaje, 'detalles': ?detalles},
};

final _restricciones = {
  'ok': true,
  'data': [
    {'id': 'r-1', 'codigo': 'lactosa', 'nombre': 'Lactosa'},
    {'id': 'r-2', 'codigo': 'gluten', 'nombre': 'Gluten'},
  ],
};

/// Answers `GET /restricciones` with the vocabulary and every write with
/// [escritura].
FakeHttpAdapter _adapter(
  Future<ResponseBody> Function(RequestOptions) escritura,
) => FakeHttpAdapter(
  (o) async => o.method == 'GET' ? jsonBody(_restricciones) : escritura(o),
);

List<RequestOptions> _escrituras(FakeHttpAdapter a) =>
    a.requests.where((r) => r.method != 'GET').toList();

const _existente = Alimento(
  id: 'al-1',
  nombre: 'Pollo asado',
  categoria: 'PROTEINA',
  porcionDescripcion: '1 pieza',
  porcionGramos: 120,
  kcal: 190.5,
  proteinaG: 31,
  carbohidratoG: 0,
  grasaG: 4,
  fibraG: 0,
  sodioMg: 74,
  esTipicoHn: true,
  tiposComida: ['ALMUERZO', 'CENA'],
  contiene: ['gluten'],
  fuente: 'INCAP',
);

Future<void> _pump(
  WidgetTester tester,
  FakeHttpAdapter adapter, {
  Alimento? alimento,
  VoidCallback? onCerrar,
  void Function(Alimento)? onGuardado,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
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
        home: AlimentoFormScreen(
          alimento: alimento,
          onCerrar: onCerrar ?? () {},
          onGuardado: onGuardado ?? (_) {},
        ),
      ),
    ),
  );
  await pumpStable(tester);
}

Finder _campo(String clave) => find.byKey(ValueKey(clave));

Future<void> _escribir(WidgetTester tester, String clave, String texto) async {
  await tester.ensureVisible(_campo(clave));
  await tester.enterText(_campo(clave), texto);
}

Future<void> _tocar(WidgetTester tester, Finder f) async {
  await pumpStable(tester); // let a focused field finish scrolling itself
  await tester.ensureVisible(f);
  await pumpStable(tester);
  await tester.tap(f);
  await tester.pump();
}

Future<void> _guardar(WidgetTester tester, String etiqueta) async {
  final boton = find.widgetWithText(FilledButton, etiqueta);
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await pumpStable(tester);
}

bool _habilitado(WidgetTester tester, String etiqueta) => tester
    .widget<FilledButton>(find.widgetWithText(FilledButton, etiqueta))
    .enabled;

String _texto(WidgetTester tester, String clave) =>
    tester.widget<TextField>(_campo(clave)).controller!.text;

void main() {
  group('S8 · el formulario', () {
    testWidgets('draws the alta board with the exact copy and no cancel', (
      tester,
    ) async {
      await _pump(tester, _adapter((_) async => jsonBody(_entidad())));

      // Title and action both read "Agregar alimento" (open in the spec).
      expect(find.text('Agregar alimento'), findsNWidgets(2));
      expect(find.text('Editar alimento'), findsNothing);
      expect(find.text('Guardar cambios'), findsNothing);
      expect(find.text(_aviso), findsOneWidget);
      for (final t in [
        '1 · Identidad',
        'Nombre',
        'Categoría',
        'Típico hondureño',
        'Fuente',
        '2 · Porción',
        'Descripción',
        'Gramos',
        '3 · Composición por porción',
        'ENERGÍA Y MACROS',
        'Energía · kcal',
        'Proteína · g',
        'Carbohidrato · g',
        'Grasa · g',
        'Fibra · g',
        'MICRONUTRIENTES',
        'Sodio · mg',
        'Estimado',
        _ayudaSodio,
        'Potasio · mg',
        'Fósforo · mg',
        'Azúcares · g',
        'Grasas sat. · g',
        'Índice glucémico',
        _ayudaIg,
        '4 · Uso',
        'Tiempos de comida',
        'Contiene',
        _notaContiene,
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.text('INCAP, USDA, etiqueta del producto…'), findsOneWidget);
      expect(find.text('Sin dato'), findsOneWidget); // IG placeholder
      expect(find.text('Cancelar'), findsNothing);
      for (final t in [
        'Plato típico',
        'Proteína',
        'Cereal y tubérculo',
        'Leguminosa',
        'Lácteo',
        'Fruta',
        'Verdura',
        'Grasa',
        'Bebida',
        'Desayuno',
        'Merienda AM',
        'Almuerzo',
        'Merienda PM',
        'Cena',
        'Lactosa', // from GET /restricciones, by nombre
        'Gluten',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });

    testWidgets('the close x calls onCerrar', (tester) async {
      var cerrado = 0;
      await _pump(
        tester,
        _adapter((_) async => jsonBody(_entidad())),
        onCerrar: () => cerrado++,
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(cerrado, 1);
    });

    testWidgets('edit preloads, titles Editar alimento / Guardar cambios', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter((_) async => jsonBody(_entidad())),
        alimento: _existente,
      );

      expect(find.text('Editar alimento'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
      expect(find.text('Agregar alimento'), findsNothing);
      expect(_texto(tester, 'nombre'), 'Pollo asado');
      expect(_texto(tester, 'porcionGramos'), '120'); // no "120.0"
      expect(_texto(tester, 'kcal'), '190.5');
      expect(_texto(tester, 'sodioMg'), '74');
      expect(_texto(tester, 'indiceGlucemico'), ''); // Sin dato, never 0
      expect(_texto(tester, 'fuente'), 'INCAP');
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('offers no way to clear a stored value', (tester) async {
      await _pump(
        tester,
        _adapter((_) async => jsonBody(_entidad())),
        alimento: _existente,
      );

      expect(find.byIcon(Icons.clear), findsNothing);
      expect(find.byIcon(Icons.cancel), findsNothing);
      expect(find.textContaining('Quitar'), findsNothing);
      expect(find.textContaining('Borrar'), findsNothing);
    });
  });

  group('S8 · alta', () {
    testWidgets('POSTs the 19 writable fields, numbers and lists typed', (
      tester,
    ) async {
      final adapter = _adapter((_) async => jsonBody(_entidad(), status: 201));
      Alimento? guardado;
      await _pump(tester, adapter, onGuardado: (a) => guardado = a);

      await _escribir(tester, 'nombre', '  Pollo asado ');
      await _tocar(tester, find.byKey(const ValueKey('categoria-PROTEINA')));
      await _tocar(tester, find.byType(Switch));
      await _escribir(tester, 'fuente', 'INCAP');
      await _escribir(tester, 'porcionDescripcion', '1 pieza');
      await _escribir(tester, 'porcionGramos', '120');
      await _escribir(tester, 'kcal', '190,5'); // decimal comma
      await _escribir(tester, 'proteinaG', '31');
      await _escribir(tester, 'carbohidratoG', '0');
      await _escribir(tester, 'grasaG', '4');
      await _escribir(tester, 'fibraG', '0');
      await _escribir(tester, 'sodioMg', '74');
      await _escribir(tester, 'potasioMg', '250');
      await _escribir(tester, 'fosforoMg', '180');
      await _escribir(tester, 'azucaresG', '0');
      await _escribir(tester, 'grasasSatG', '1.2');
      await _escribir(tester, 'indiceGlucemico', '55');
      await _tocar(tester, find.byKey(const ValueKey('tipo-ALMUERZO')));
      await _tocar(tester, find.byKey(const ValueKey('tipo-CENA')));
      await _tocar(tester, find.byKey(const ValueKey('contiene-gluten')));
      await _guardar(tester, 'Agregar alimento');

      final pedido = _escrituras(adapter).single;
      expect(pedido.method, 'POST');
      expect(pedido.path, '/alimentos');
      expect(pedido.data, {
        'nombre': 'Pollo asado',
        'categoria': 'PROTEINA',
        'esTipicoHn': true,
        'fuente': 'INCAP',
        'porcionDescripcion': '1 pieza',
        'porcionGramos': 120,
        'kcal': 190.5,
        'proteinaG': 31,
        'carbohidratoG': 0,
        'grasaG': 4,
        'fibraG': 0,
        'sodioMg': 74,
        'potasioMg': 250,
        'fosforoMg': 180,
        'azucaresG': 0,
        'grasasSatG': 1.2,
        'indiceGlucemico': 55,
        'tiposComida': ['ALMUERZO', 'CENA'],
        'contiene': ['gluten'],
      });
      expect(pedido.data['porcionGramos'], isA<int>());
      expect(pedido.data['kcal'], isA<double>());
      expect(guardado?.id, 'al-1');
    });

    testWidgets('empty fields never travel and an empty IG does not break', (
      tester,
    ) async {
      final adapter = _adapter((_) async => jsonBody(_entidad(), status: 201));
      Alimento? guardado;
      await _pump(tester, adapter, onGuardado: (a) => guardado = a);

      await _escribir(tester, 'nombre', 'Agua');
      await _escribir(tester, 'kcal', '0');
      await _escribir(tester, 'indiceGlucemico', '   ');
      await _guardar(tester, 'Agregar alimento');

      final cuerpo = _escrituras(adapter).single.data as Map;
      expect(cuerpo, {
        'nombre': 'Agua',
        'esTipicoHn': false,
        'kcal': 0,
        // Lists are the whole selection, so empty ones still travel: S8 leaves
        // no way to un-choose the last tag otherwise.
        'tiposComida': <String>[],
        'contiene': <String>[],
      });
      expect(cuerpo.containsKey('indiceGlucemico'), isFalse);
      expect(guardado, isNotNull);
    });

    testWidgets('a name left empty never reaches the API', (tester) async {
      final adapter = _adapter((_) async => jsonBody(_entidad()));
      await _pump(tester, adapter);

      await _guardar(tester, 'Agregar alimento');

      expect(_escrituras(adapter), isEmpty);
      expect(find.text('Ingresá el nombre del alimento'), findsOneWidget);
      expect(_habilitado(tester, 'Agregar alimento'), isTrue);
    });

    testWidgets('text that is not a number stays on the field', (tester) async {
      final adapter = _adapter((_) async => jsonBody(_entidad()));
      await _pump(tester, adapter);

      await _escribir(tester, 'nombre', 'Agua');
      await _escribir(tester, 'kcal', 'mucho');
      await _guardar(tester, 'Agregar alimento');

      expect(_escrituras(adapter), isEmpty);
      expect(find.text('Ingresá un número'), findsOneWidget);
      expect(_habilitado(tester, 'Agregar alimento'), isTrue);
    });

    testWidgets('choosing and unchoosing category, times and labels', (
      tester,
    ) async {
      final adapter = _adapter((_) async => jsonBody(_entidad(), status: 201));
      await _pump(tester, adapter);

      await _escribir(tester, 'nombre', 'Queso');
      await _tocar(tester, find.byKey(const ValueKey('categoria-FRUTA')));
      await _tocar(tester, find.byKey(const ValueKey('categoria-LACTEO')));
      await _tocar(tester, find.byKey(const ValueKey('tipo-DESAYUNO')));
      await _tocar(tester, find.byKey(const ValueKey('tipo-MERIENDA_PM')));
      await _tocar(tester, find.byKey(const ValueKey('tipo-DESAYUNO')));
      await _tocar(tester, find.byKey(const ValueKey('contiene-lactosa')));
      await _guardar(tester, 'Agregar alimento');

      final cuerpo = _escrituras(adapter).single.data as Map;
      expect(cuerpo['categoria'], 'LACTEO');
      expect(cuerpo['tiposComida'], ['MERIENDA_PM']);
      expect(cuerpo['contiene'], ['lactosa']);
    });
  });

  group('S8 · edición', () {
    testWidgets('PATCHes only the fields with a value', (tester) async {
      final adapter = _adapter((_) async => jsonBody(_entidad()));
      await _pump(
        tester,
        adapter,
        alimento: const Alimento(id: 'al-1', nombre: 'Pollo asado'),
      );

      await _escribir(tester, 'nombre', 'Pollo frito');
      await _escribir(tester, 'kcal', '210');
      await _guardar(tester, 'Guardar cambios');

      final pedido = _escrituras(adapter).single;
      expect(pedido.method, 'PATCH');
      expect(pedido.path, '/alimentos/al-1');
      expect(pedido.data, {
        'nombre': 'Pollo frito',
        'esTipicoHn': false,
        'kcal': 210,
        'tiposComida': <String>[],
        'contiene': <String>[],
      });
    });

    testWidgets('a field emptied by the user resends the stored value', (
      tester,
    ) async {
      final adapter = _adapter((_) async => jsonBody(_entidad()));
      await _pump(tester, adapter, alimento: _existente);

      await _escribir(tester, 'kcal', '');
      await _escribir(tester, 'fuente', '');
      await _escribir(tester, 'sodioMg', '80');
      await _guardar(tester, 'Guardar cambios');

      expect(_escrituras(adapter).single.data, {
        'nombre': 'Pollo asado',
        'categoria': 'PROTEINA',
        'esTipicoHn': true,
        'fuente': 'INCAP',
        'porcionDescripcion': '1 pieza',
        'porcionGramos': 120,
        'kcal': 190.5,
        'proteinaG': 31,
        'carbohidratoG': 0,
        'grasaG': 4,
        'fibraG': 0,
        'sodioMg': 80,
        'tiposComida': ['ALMUERZO', 'CENA'],
        // The lists travel as the whole selection, so an untouched one comes
        // back exactly as it was stored.
        'contiene': ['gluten'],
      });
    });

    testWidgets('the last label can be unticked and travels as an empty list', (
      tester,
    ) async {
      final adapter = _adapter((_) async => jsonBody(_entidad()));
      await _pump(tester, adapter, alimento: _existente);

      await _tocar(tester, find.byKey(const ValueKey('contiene-gluten')));
      await _guardar(tester, 'Guardar cambios');

      final cuerpo = _escrituras(adapter).single.data as Map;
      // `[]` is a value: it is how the food stops having restrictions. Omitting
      // it would keep the stored label forever.
      expect(cuerpo['contiene'], isEmpty);
    });
  });

  group('S8 · fallos', () {
    testWidgets(
      'a 400 with a field detail shows it on the field and re-enables',
      (tester) async {
        final adapter = _adapter(
          (_) async => jsonBody(
            _error(
              'VALIDACION',
              'Datos inválidos',
              detalles: [
                {'campo': 'kcal', 'mensaje': 'Energía fuera de rango'},
              ],
            ),
            status: 400,
          ),
        );
        Alimento? guardado;
        await _pump(tester, adapter, onGuardado: (a) => guardado = a);

        await _escribir(tester, 'nombre', 'Pollo');
        await _guardar(tester, 'Agregar alimento');

        expect(_escrituras(adapter), hasLength(1));
        expect(find.text('Energía fuera de rango'), findsOneWidget);
        expect(find.byKey(const Key('fallo-codigo')), findsNothing);
        expect(guardado, isNull);
        expect(_habilitado(tester, 'Agregar alimento'), isTrue);
      },
    );

    testWidgets('a 400 that names no field goes to the failure block', (
      tester,
    ) async {
      final adapter = _adapter(
        (_) async => jsonBody(
          _error('VALIDACION', 'Datos inválidos', detalles: ['algo raro']),
          status: 400,
        ),
      );
      await _pump(tester, adapter);

      await _escribir(tester, 'nombre', 'Pollo');
      await _guardar(tester, 'Agregar alimento');

      expect(find.text('Datos inválidos'), findsOneWidget);
      expect(find.text('VALIDACION · HTTP 400'), findsOneWidget);
      expect(_habilitado(tester, 'Agregar alimento'), isTrue);
    });

    testWidgets('a 404 shows as a failure and nothing stays locked', (
      tester,
    ) async {
      var intentos = 0;
      final adapter = _adapter((_) async {
        intentos++;
        return intentos == 1
            ? jsonBody(
                _error('NO_ENCONTRADO', 'El alimento no existe'),
                status: 404,
              )
            : jsonBody(_entidad());
      });
      Alimento? guardado;
      await _pump(
        tester,
        adapter,
        alimento: _existente,
        onGuardado: (a) => guardado = a,
      );

      await _guardar(tester, 'Guardar cambios');

      expect(find.text('El alimento no existe'), findsOneWidget);
      expect(find.text('NO_ENCONTRADO · HTTP 404'), findsOneWidget);
      expect(_habilitado(tester, 'Guardar cambios'), isTrue);

      await _guardar(tester, 'Guardar cambios');
      expect(_escrituras(adapter), hasLength(2));
      expect(guardado?.id, 'al-1');
      expect(find.text('El alimento no existe'), findsNothing);
    });
  });
}
