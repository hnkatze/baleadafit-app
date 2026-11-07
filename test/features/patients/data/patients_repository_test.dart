import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/features/patients/data/patients_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, Object?> _pacientesBody() => {
  'ok': true,
  'data': [
    {
      'id': 'pac-1',
      'nombre': 'Paciente',
      'apellido': 'De Prueba',
      'ultimaMedicion': {
        'id': 'med-1',
        'fecha': '2026-10-31T00:00:00.000Z',
        'pesoKg': 72,
        'pctGrasa': 19.5,
      },
      'planActivo': {'id': 'plan-1'},
    },
  ],
  'meta': {'limit': 4, 'offset': 0, 'total': 1, 'hasMore': false},
};

void main() {
  test('reads the patients of the page with their measurement', () async {
    final page = await PatientsRepository(
      ApiClient(
        dioWith(FakeHttpAdapter((_) async => jsonBody(_pacientesBody()))),
      ),
    ).recientes();

    expect(page.items, hasLength(1));
    expect(page.items.single.nombreCompleto, 'Paciente De Prueba');
    expect(page.items.single.tienePlanActivo, isTrue);
    expect(page.items.single.ultimaMedicion?.resumen, '72.0 kg · 19.5% grasa');
    expect(page.meta.total, 1);
  });

  test('asks for the limit it was given', () async {
    final adapter = FakeHttpAdapter((_) async => jsonBody(_pacientesBody()));

    await PatientsRepository(ApiClient(dioWith(adapter))).recientes(limit: 3);

    expect(adapter.requests.single.path, '/pacientes');
    expect(adapter.requests.single.queryParameters['limit'], 3);
  });

  test('a patient without plan is not reported as having one', () async {
    final page = await PatientsRepository(
      ApiClient(
        dioWith(
          FakeHttpAdapter(
            (_) async => jsonBody({
              'ok': true,
              'data': [
                {
                  'id': 'pac-2',
                  'nombre': 'Ana',
                  'apellido': 'López',
                  'planActivo': null,
                },
              ],
              'meta': {'limit': 4, 'offset': 0, 'total': 1, 'hasMore': false},
            }),
          ),
        ),
      ),
    ).recientes();

    expect(page.items.single.tienePlanActivo, isFalse);
    expect(page.items.single.ultimaMedicion, isNull);
  });
}
