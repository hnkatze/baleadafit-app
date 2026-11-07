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

      final data = await ApiClient(dioWith(adapter)).get('/auth/me', fromJson: (json) => json);

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

    final result = await ApiClient(dioWith(adapter)).get(
      '/saludo',
      fromJson: (json) => '${json['saludo']}:${json['total']}',
    );

    expect(result, 'hola:2');
  });
}
