import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/features/catalogo/data/catalogo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, Object?> _alimento({bool activo = true}) => {
  'id': 'ali-1',
  'nombre': 'Quesillo',
  'categoria': 'LACTEO',
  'porcionDescripcion': '1 rebanada',
  'porcionGramos': 30,
  'kcal': 90,
  'proteinaG': 6,
  'carbohidratoG': 1,
  'grasaG': 7,
  'esTipicoHn': true,
  'tiposComida': ['DESAYUNO'],
  'contiene': ['lactosa'],
  'fuente': 'INCAP',
  'activo': activo,
};

Map<String, Object?> _version(int n, {String? hasta}) => {
  'id': 'ver-$n',
  'version': n,
  'tabla': 'INCAP',
  'vigenteDesde': '2026-11-12T00:00:00.000Z',
  'vigenteHasta': hasta,
  'kcal': 90,
};

CatalogoRepository _repository(FakeHttpAdapter adapter) =>
    CatalogoRepository(ApiClient(dioWith(adapter)));

void main() {
  group('buscar', () {
    test('builds the query with every filter and decodes the page', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': [_alimento()],
          'meta': {'limit': 20, 'offset': 0, 'total': 38, 'hasMore': true},
        }),
      );

      final page = await _repository(adapter).buscar(
        q: 'queso',
        categoria: 'LACTEO',
        tipoComida: 'DESAYUNO',
        soloTipicos: true,
        excluir: ['lactosa', 'gluten'],
        limit: 20,
      );

      final pedido = adapter.requests.single;
      expect(pedido.method, 'GET');
      expect(pedido.path, '/alimentos');
      expect(pedido.queryParameters, {
        'q': 'queso',
        'categoria': 'LACTEO',
        'tipoComida': 'DESAYUNO',
        'soloTipicos': true,
        'excluir': 'lactosa,gluten',
        'limit': 20,
      });
      expect(page.items.single.nombre, 'Quesillo');
      expect(page.meta.total, 38);
      expect(page.meta.hasMore, isTrue);
    });

    test('sends no null parameter and no empty excluir', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': <Object?>[],
          'meta': {'limit': 20, 'offset': 0, 'total': 0, 'hasMore': false},
        }),
      );

      await _repository(adapter).buscar(excluir: const []);

      expect(adapter.requests.single.queryParameters, isEmpty);
    });

    test('offset and cursor together are an ArgumentError', () {
      final adapter = FakeHttpAdapter((_) async => jsonBody({'ok': true}));

      expect(
        () => _repository(adapter).buscar(offset: 20, cursor: 'abc'),
        throwsArgumentError,
      );
      expect(adapter.requests, isEmpty);
    });

    test('a 401 reaches the caller as an ApiFailure with its message', () {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': false,
          'error': {'codigo': 'UNAUTHORIZED', 'mensaje': 'Sesión vencida'},
        }, status: 401),
      );

      expect(
        _repository(adapter).buscar(),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.mensaje,
            'mensaje',
            'Sesión vencida',
          ),
        ),
      );
    });
  });

  test('detalle reads GET /alimentos/{id}', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({'ok': true, 'data': _alimento()}),
    );

    final a = await _repository(adapter).detalle('ali-1');

    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/alimentos/ali-1');
    expect(a.nombre, 'Quesillo');
    expect(a.contiene, ['lactosa']);
  });

  test('crear posts the body to /alimentos', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({'ok': true, 'data': _alimento()}, status: 201),
    );

    final a = await _repository(adapter)
        .crear({'nombre': 'Quesillo', 'kcal': 90});

    final pedido = adapter.requests.single;
    expect(pedido.method, 'POST');
    expect(pedido.path, '/alimentos');
    expect(pedido.data, {'nombre': 'Quesillo', 'kcal': 90});
    expect(a.id, 'ali-1');
  });

  test('actualizar patches /alimentos/{id} with the body', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({'ok': true, 'data': _alimento()}),
    );

    final a = await _repository(adapter)
        .actualizar('ali-1', body: {'kcal': 95});

    final pedido = adapter.requests.single;
    expect(pedido.method, 'PATCH');
    expect(pedido.path, '/alimentos/ali-1');
    expect(pedido.data, {'kcal': 95});
    expect(a.nombre, 'Quesillo');
  });

  test('darDeBaja patches activo false and answers the food', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({'ok': true, 'data': _alimento(activo: false)}),
    );

    final a = await _repository(adapter).darDeBaja('ali-1');

    final pedido = adapter.requests.single;
    expect(pedido.method, 'PATCH');
    expect(pedido.path, '/alimentos/ali-1');
    expect(pedido.data, {'activo': false});
    expect(a.activo, isFalse);
  });

  group('versiones', () {
    test('reads GET /alimentos/{id}/versiones with its page', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': [_version(2), _version(1, hasta: '2026-11-12T00:00:00Z')],
          'meta': {'limit': 20, 'offset': 0, 'total': 2, 'hasMore': false},
        }),
      );

      final page = await _repository(adapter)
          .versiones('ali-1', limit: 10, offset: 0);

      final pedido = adapter.requests.single;
      expect(pedido.method, 'GET');
      expect(pedido.path, '/alimentos/ali-1/versiones');
      expect(pedido.queryParameters, {'limit': 10, 'offset': 0});
      expect(page.items.map((v) => v.version), [2, 1]);
      expect(page.items.first.vigente, isTrue);
      expect(page.items.last.vigente, isFalse);
      expect(page.meta.total, 2);
    });

    test('sends no parameter that was not given', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': <Object?>[],
          'meta': {'limit': 20, 'offset': 0, 'total': 0, 'hasMore': false},
        }),
      );

      await _repository(adapter).versiones('ali-1');

      expect(adapter.requests.single.queryParameters, isEmpty);
    });
  });

  test('restricciones decodes the unpaged list', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({
        'ok': true,
        'data': [
          {'id': 'r-1', 'codigo': 'lactosa', 'nombre': 'Lactosa'},
          {
            'id': 'r-2',
            'codigo': 'gluten',
            'nombre': 'Gluten',
            'descripcion': 'Trigo',
          },
        ],
      }),
    );

    final lista = await _repository(adapter).restricciones();

    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/restricciones');
    expect(lista.map((r) => r.codigo), ['lactosa', 'gluten']);
    expect(lista.last.descripcion, 'Trigo');
  });
}
