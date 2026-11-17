import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/features/agenda/data/cita.dart';
import 'package:baleadafit/features/agenda/data/citas_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, Object?> _cita({
  String id = 'c1',
  String estado = 'PROGRAMADA',
  String fechaHora = '2026-11-07T15:00:00.000Z',
}) => {
  'id': id,
  'pacienteId': 'p1',
  'nutricionistaId': 'n1',
  'fechaHora': fechaHora,
  'duracionMin': 45,
  'estado': estado,
  'motivo': 'Revisión de mediciones',
  'notas': '',
  'paciente': {
    'id': 'p1',
    'nombre': 'Paciente',
    'apellido': 'De Prueba',
    'telefono': '9999-9999',
  },
  'subjetivo': null,
  'objetivo': null,
  'analisis': null,
  'plan': null,
  'proximaCitaSugerida': null,
  'creadoEn': '2026-11-06T12:00:00.000Z',
};

void main() {
  group('CitasRepository.listar', () {
    test('asks for the whole local day, not just its first instant', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': [_cita()],
          'meta': {'limit': 100, 'offset': 0, 'total': 1, 'hasMore': false},
        }),
      );

      final page = await CitasRepository(ApiClient(dioWith(adapter)))
          .listar(desde: DateTime(2026, 11, 7), hasta: DateTime(2026, 11, 7));

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/citas');

      // The API does `new Date(desde)` / `lte: new Date(hasta)`, and a date
      // with no time is midnight UTC. Sending `2026-11-07` as `hasta` left
      // every appointment of the day out of the range.
      final desdeEnviado = DateTime.parse(
        request.queryParameters['desde'] as String,
      );
      final hastaEnviado = DateTime.parse(
        request.queryParameters['hasta'] as String,
      );
      expect(desdeEnviado.isUtc, isTrue);
      expect(hastaEnviado.isUtc, isTrue);
      expect(
        desdeEnviado.isAtSameMomentAs(DateTime(2026, 11, 7)),
        isTrue,
        reason: 'the range starts at local midnight',
      );
      expect(
        hastaEnviado.isAtSameMomentAs(
          DateTime(2026, 11, 8).subtract(const Duration(milliseconds: 1)),
        ),
        isTrue,
        reason: 'the range reaches the last instant of the local day',
      );
      expect(request.queryParameters['limit'], 100);
      expect(page.items.single.id, 'c1');
      expect(page.meta.total, 1);
    });

    test('sends estado only when a filter is asked for', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': <Object?>[],
          'meta': {'limit': 100, 'offset': 0, 'total': 0, 'hasMore': false},
        }),
      );
      final repository = CitasRepository(ApiClient(dioWith(adapter)));

      await repository.listar(
        desde: DateTime(2026, 11, 7),
        hasta: DateTime(2026, 11, 7),
      );
      expect(
        adapter.requests.single.queryParameters.containsKey('estado'),
        isFalse,
      );

      await repository.listar(
        desde: DateTime(2026, 11, 7),
        hasta: DateTime(2026, 11, 7),
        estado: EstadoCita.cancelada,
      );
      expect(adapter.requests.last.queryParameters['estado'], 'CANCELADA');
    });
  });

  group('CitasRepository.crear', () {
    test('posts the appointment and decodes the answer', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({'ok': true, 'data': _cita()}, status: 201),
      );

      final cita = await CitasRepository(ApiClient(dioWith(adapter))).crear(
        pacienteId: 'p1',
        fechaHora: DateTime(2026, 11, 7, 15),
        motivo: 'Revisión de mediciones',
      );

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/citas');
      expect((request.data as Map)['pacienteId'], 'p1');
      expect((request.data as Map)['duracionMin'], 45);
      expect((request.data as Map)['motivo'], 'Revisión de mediciones');
      final enviado = DateTime.parse(
        (request.data as Map)['fechaHora'] as String,
      );
      expect(enviado.isUtc, isTrue);
      expect(enviado.isAtSameMomentAs(DateTime(2026, 11, 7, 15)), isTrue);
      expect(cita.id, 'c1');
    });

    test('maps the 409 of an overlap to the message the API sends', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': false,
          'error': {
            'codigo': 'CONFLICTO',
            'mensaje': 'Esa hora se traslapa con otra cita.',
          },
        }, status: 409),
      );

      await expectLater(
        CitasRepository(ApiClient(dioWith(adapter)))
            .crear(pacienteId: 'p1', fechaHora: DateTime(2026, 11, 7, 15)),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.statusCode, 'statusCode', 409)
              .having(
                (f) => f.mensaje,
                'mensaje',
                'Esa hora se traslapa con otra cita.',
              ),
        ),
      );
    });
  });

  group('CitasRepository.actualizar', () {
    test('patches only the fields it was given and decodes the cita', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({'ok': true, 'data': _cita(estado: 'CANCELADA')}),
      );

      final cita = await CitasRepository(ApiClient(dioWith(adapter)))
          .actualizar('c1', estado: EstadoCita.cancelada);

      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/citas/c1');
      expect(request.data, {'estado': 'CANCELADA'});
      expect(cita.estado, EstadoCita.cancelada);
    });

    test('sends the SOAP note and the suggested date as yyyy-MM-dd', () async {
      final adapter = FakeHttpAdapter(
        (_) async =>
            jsonBody({'ok': true, 'data': _cita(estado: 'COMPLETADA')}),
      );

      await CitasRepository(ApiClient(dioWith(adapter))).actualizar(
        'c1',
        estado: EstadoCita.completada,
        subjetivo: 'Refiere cansancio',
        proximaCitaSugerida: DateTime.utc(2026, 11, 14),
      );

      final body = adapter.requests.single.data as Map;
      expect(body['estado'], 'COMPLETADA');
      expect(body['subjetivo'], 'Refiere cansancio');
      expect(body['proximaCitaSugerida'], '2026-11-14');
    });
  });
}
