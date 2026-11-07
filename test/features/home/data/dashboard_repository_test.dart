import 'package:baleadafit/features/home/data/dashboard_repository.dart';
import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/network/api_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, Object?> _dashboardBody() => {
  'ok': true,
  'data': {
    'pacientesActivos': 12,
    'planesEnBorrador': 3,
    'citasHoy': [
      {
        'id': 'cita-1',
        'fechaHora': '2026-11-06T09:30:00.000Z',
        'duracionMin': 45,
        'motivo': 'Control mensual',
        'estado': 'pendiente',
        'paciente': {
          'id': 'pac-1',
          'nombre': 'Carlos',
          'apellido': 'Mendoza',
          'telefono': '9999-0000',
        },
      },
    ],
  },
};

DashboardRepository _repository(FakeHttpAdapter adapter) =>
    DashboardRepository(ApiClient(dioWith(adapter)));

void main() {
  test('reads the summary the API returns', () async {
    final resumen = await _repository(
      FakeHttpAdapter((_) async => jsonBody(_dashboardBody())),
    ).resumen();

    expect(resumen.pacientesActivos, 12);
    expect(resumen.planesEnBorrador, 3);
    expect(resumen.citasHoy, hasLength(1));
    expect(resumen.citasHoy.single.pacienteNombre, 'Carlos Mendoza');
    expect(resumen.citasHoy.single.duracionMin, 45);
    expect(resumen.citasHoy.single.fechaHora.toUtc().hour, 9);
  });

  test('asks the dashboard endpoint', () async {
    final adapter = FakeHttpAdapter((_) async => jsonBody(_dashboardBody()));

    await _repository(adapter).resumen();

    expect(adapter.requests.single.path, '/dashboard');
  });

  test('keeps an empty day as an empty list', () async {
    final resumen = await _repository(
      FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': {
            'pacientesActivos': 0,
            'planesEnBorrador': 0,
            'citasHoy': <Object?>[],
          },
        }),
      ),
    ).resumen();

    expect(resumen.citasHoy, isEmpty);
  });

  test('reports a rejected token as an ApiFailure', () async {
    final repository = _repository(
      FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': false,
          'error': {'codigo': 'NO_AUTENTICADO', 'mensaje': 'Token inválido.'},
        }, status: 401),
      ),
    );

    await expectLater(
      repository.resumen(),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.isUnauthenticated,
          'isUnauthenticated',
          isTrue,
        ),
      ),
    );
  });

  test('a summary without counts is a typed failure, not a crash', () async {
    final repository = _repository(
      FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': {'citasHoy': <Object?>[]},
        }),
      ),
    );

    await expectLater(repository.resumen(), throwsA(isA<ApiFailure>()));
  });
}
