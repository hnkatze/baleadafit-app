import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/network/api_failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  group('ApiClient.get', () {
    test('unwraps the data object of a successful envelope', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': {'rol': 'paciente'},
        }),
      );

      final data = await ApiClient(dioWith(adapter))
          .get('/auth/me', fromJson: (json) => json);

      expect(data, {'rol': 'paciente'});
      expect(adapter.requests.single.path, '/auth/me');
    });

    test('turns an ok:false envelope into an ApiFailure', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': false,
          'error': {
            'codigo': 'VALIDACION',
            'mensaje': 'El correo no es válido.',
          },
        }, status: 400),
      );

      await expectLater(
        ApiClient(dioWith(adapter)).get('/auth/me', fromJson: (json) => json),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.codigo, 'codigo', 'VALIDACION')
              .having((f) => f.mensaje, 'mensaje', 'El correo no es válido.')
              .having((f) => f.statusCode, 'statusCode', 400),
        ),
      );
    });

    test('marks a 401 response as unauthenticated', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': false,
          'error': {
            'codigo': 'NO_AUTENTICADO',
            'mensaje': 'Token inválido o expirado.',
          },
        }, status: 401),
      );

      await expectLater(
        ApiClient(dioWith(adapter)).get('/auth/me', fromJson: (json) => json),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.isUnauthenticated, 'isUnauthenticated', isTrue)
              .having((f) => f.codigo, 'codigo', 'NO_AUTENTICADO'),
        ),
      );
    });

    test('rejects a body that is not the documented envelope', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody(<Object?>[1, 2, 3]),
      );

      await expectLater(
        ApiClient(dioWith(adapter)).get('/auth/me', fromJson: (json) => json),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.mensaje,
            'mensaje',
            'Algo salió mal. Intentá de nuevo.',
          ),
        ),
      );
    });

    test('reports a connection error as a network failure', () async {
      final adapter = FakeHttpAdapter(
        (options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        ),
      );

      await expectLater(
        ApiClient(dioWith(adapter)).get('/auth/me', fromJson: (json) => json),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.mensaje,
            'mensaje',
            contains('No pudimos conectar con el servidor'),
          ),
        ),
      );
    });
  });

  test('decodes the payload with the caller fromJson', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({
        'ok': true,
        'data': {'saludo': 'hola', 'total': 2},
      }),
    );

    final result = await ApiClient(
      dioWith(adapter),
    ).get('/saludo', fromJson: (json) => '${json['saludo']}:${json['total']}');

    expect(result, 'hola:2');
  });

  test('decodes a list payload with its meta', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({
        'ok': true,
        'data': [
          {'nombre': 'Carlos'},
          {'nombre': 'Mariana'},
        ],
        'meta': {'limit': 2, 'offset': 0, 'total': 7, 'hasMore': true},
      }),
    );

    final page = await ApiClient(
      dioWith(adapter),
    ).getPaged('/pacientes', itemFromJson: (json) => json['nombre'] as String);

    expect(page.items, ['Carlos', 'Mariana']);
    expect(page.meta.total, 7);
    expect(page.meta.hasMore, isTrue);
  });

  test('a list payload wrapped in an error is an ApiFailure', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({
        'ok': false,
        'error': {'codigo': 'SIN_PERMISO', 'mensaje': 'Sin acceso.'},
      }, status: 403),
    );

    await expectLater(
      ApiClient(dioWith(adapter))
          .getPaged('/pacientes', itemFromJson: (json) => json),
      throwsA(isA<ApiFailure>()),
    );
  });

  group('ApiClient writes', () {
    Map<String, Object?> errorEnvelope() => {
      'ok': false,
      'error': {
        'codigo': 'VALIDACION',
        'mensaje': 'Datos inválidos.',
        'detalles': ['pesoKg'],
      },
    };

    test('post sends the body and decodes the data object', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': {'id': 'med-2'},
        }, status: 201),
      );

      final id = await ApiClient(dioWith(adapter)).post(
        '/pacientes/pac-1/mediciones',
        body: {'pesoKg': 71.8},
        fromJson: (json) => json['id'] as String,
      );

      expect(id, 'med-2');
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/pacientes/pac-1/mediciones');
      expect(adapter.requests.single.data, {'pesoKg': 71.8});
    });

    test('delete decodes the data object', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': {'activo': false},
        }),
      );

      final activo = await ApiClient(dioWith(adapter))
          .delete('/pacientes/pac-1', fromJson: (json) => json['activo']);

      expect(activo, false);
      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.path, '/pacientes/pac-1');
    });

    test('post and delete raise the ApiFailure of an error envelope', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody(errorEnvelope(), status: 400),
      );
      final api = ApiClient(dioWith(adapter));
      final failure = isA<ApiFailure>()
          .having((f) => f.codigo, 'codigo', 'VALIDACION')
          .having((f) => f.mensaje, 'mensaje', 'Datos inválidos.')
          .having((f) => f.statusCode, 'statusCode', 400)
          .having((f) => f.detalles, 'detalles', ['pesoKg']);

      await expectLater(
        api.post('/x', fromJson: (json) => json),
        throwsA(failure),
      );
      await expectLater(
        api.delete('/x', fromJson: (json) => json),
        throwsA(failure),
      );
      await expectLater(api.postAck('/x', body: {}), throwsA(failure));
      await expectLater(api.deleteAck('/x'), throwsA(failure));
    });

    test('post and delete report an unexpected body', () async {
      final adapter = FakeHttpAdapter((_) async => jsonBody(<Object?>[1, 2]));
      final api = ApiClient(dioWith(adapter));
      final unexpected = isA<ApiFailure>().having(
        (f) => f.mensaje,
        'mensaje',
        'Algo salió mal. Intentá de nuevo.',
      );

      await expectLater(
        api.post('/x', fromJson: (json) => json),
        throwsA(unexpected),
      );
      await expectLater(
        api.delete('/x', fromJson: (json) => json),
        throwsA(unexpected),
      );
      await expectLater(api.postAck('/x'), throwsA(unexpected));
      await expectLater(api.deleteAck('/x'), throwsA(unexpected));
    });

    test('a payload of the wrong shape is an unexpected body', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({'ok': true, 'data': 'not an object'}),
      );

      await expectLater(
        ApiClient(dioWith(adapter)).post('/x', fromJson: (json) => json),
        throwsA(isA<ApiFailure>()),
      );
    });

    test('the acknowledged variants accept any ok:true answer', () async {
      final adapter = FakeHttpAdapter((_) async => jsonBody({'ok': true}));
      final api = ApiClient(dioWith(adapter));

      await api.postAck('/x', body: {'a': 1});
      await api.deleteAck('/y');

      expect(adapter.requests.map((r) => r.method), ['POST', 'DELETE']);
    });

    test('a transport error is mapped through ApiFailure.fromDio', () async {
      final adapter = FakeHttpAdapter(
        (options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        ),
      );

      await expectLater(
        ApiClient(dioWith(adapter)).postAck('/x'),
        throwsA(isA<ApiFailure>()),
      );
    });
  });

  group('ApiClient.getList', () {
    test('reads a list envelope that carries no meta', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': [
            {'codigo': 'DM2', 'nombre': 'Diabetes tipo 2'},
          ],
        }),
      );

      final items = await ApiClient(
        dioWith(adapter),
      ).getList('/condiciones', itemFromJson: (json) => json['codigo']);

      expect(items, ['DM2']);
      expect(adapter.requests.single.path, '/condiciones');
    });

    test('rejects a body whose data is not a list', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': {'codigo': 'DM2'},
        }),
      );

      expect(
        ApiClient(
          dioWith(adapter),
        ).getList('/condiciones', itemFromJson: (json) => json),
        throwsA(isA<ApiFailure>()),
      );
    });
  });
}
