import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/features/patients/data/patients_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, Object?> _medicamento({
  bool activo = true,
  Object? duplicadoDe,
  bool conDuplicadoDe = false,
}) => {
  'ok': true,
  'data': {
    'id': 'med-1',
    'pacienteId': 'pac-1',
    'nombre': 'Metformina',
    'dosis': '500 mg',
    'frecuencia': 'Cada 12 horas con comida',
    'activo': activo,
    'creadoEn': '2026-11-09T15:00:00Z',
    'actualizadoEn': '2026-11-10T08:30:00Z',
    if (conDuplicadoDe) 'duplicadoDe': duplicadoDe,
  },
};

PatientsRepository _repository(FakeHttpAdapter adapter) =>
    PatientsRepository(ApiClient(dioWith(adapter)));

void main() {
  test('registers a medication with only the fields that carry text', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody(_medicamento(), status: 201),
    );

    final creado = await _repository(adapter).registrarMedicamento(
      'pac-1',
      nombre: '  Metformina ',
      dosis: '500 mg',
      frecuencia: '   ',
    );

    final pedido = adapter.requests.single;
    expect(pedido.method, 'POST');
    expect(pedido.path, '/pacientes/pac-1/medicamentos');
    // A blank is not null: sending it as "" is undefined by the contract.
    expect(pedido.data, {'nombre': 'Metformina', 'dosis': '500 mg'});
    expect(creado.medicamento.id, 'med-1');
    expect(creado.medicamento.activo, isTrue);
    expect(creado.medicamento.composicion, '500 mg · Cada 12 horas con comida');
  });

  test('editing sends only the fields it was given', () async {
    final adapter = FakeHttpAdapter((_) async => jsonBody(_medicamento()));

    await _repository(adapter).actualizarMedicamento(
      'med-1',
      nombre: 'Metformina',
      dosis: null,
      frecuencia: '',
    );

    final pedido = adapter.requests.single;
    expect(pedido.method, 'PATCH');
    expect(pedido.path, '/medicamentos/med-1');
    // Omitting keeps the stored value: the empty dosis and frecuencia stay out.
    expect(pedido.data, {'nombre': 'Metformina'});
  });

  test('the logical delete answers the medication already inactive', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody(_medicamento(activo: false)),
    );

    final baja = await _repository(adapter).darDeBajaMedicamento('med-1');

    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.path, '/medicamentos/med-1');
    expect(baja.activo, isFalse);
    expect(baja.nombre, 'Metformina');
  });

  test('registration decodes duplicadoDe when it comes (S17)', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody(
        _medicamento(
          conDuplicadoDe: true,
          duplicadoDe: {'id': 'med-0', 'nombre': 'Metformina'},
        ),
        status: 201,
      ),
    );

    final creado = await _repository(adapter)
        .registrarMedicamento('pac-1', nombre: 'Metformina');

    expect(creado.duplicadoDe?.id, 'med-0');
    expect(creado.duplicadoDe?.nombre, 'Metformina');
    expect(creado.medicamento.id, 'med-1');
  });

  test('registration has no duplicadoDe when null or absent (S17)', () async {
    for (final cuerpo in [
      _medicamento(conDuplicadoDe: true, duplicadoDe: null),
      _medicamento(),
    ]) {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody(cuerpo, status: 201),
      );
      final creado = await _repository(adapter)
          .registrarMedicamento('pac-1', nombre: 'Metformina');
      expect(creado.duplicadoDe, isNull);
    }
  });

  test('actualizadoEn is read next to creadoEn', () async {
    final adapter = FakeHttpAdapter((_) async => jsonBody(_medicamento()));

    final m = await _repository(adapter).actualizarMedicamento('med-1');

    expect(m.creadoEn, DateTime.utc(2026, 11, 9, 15));
    expect(m.actualizadoEn, DateTime.utc(2026, 11, 10, 8, 30));
  });

  test(
    'limpiarDosis sends dosis: null and keeps the rest omitted (S16)',
    () async {
      final adapter = FakeHttpAdapter((_) async => jsonBody(_medicamento()));

      await _repository(adapter)
          .actualizarMedicamento('med-1', dosis: '500 mg', limpiarDosis: true);

      expect(adapter.requests.single.data, {'dosis': null});
    },
  );

  test('limpiarFrecuencia sends frecuencia: null (S16)', () async {
    final adapter = FakeHttpAdapter((_) async => jsonBody(_medicamento()));

    await _repository(adapter)
        .actualizarMedicamento('med-1', limpiarFrecuencia: true);

    expect(adapter.requests.single.data, {'frecuencia': null});
  });

  test('editing never sends an empty string, only omits or null', () async {
    final adapter = FakeHttpAdapter((_) async => jsonBody(_medicamento()));

    await _repository(adapter).actualizarMedicamento(
      'med-1',
      nombre: '  ',
      dosis: '',
      frecuencia: '   ',
    );
    await _repository(adapter).actualizarMedicamento(
      'med-1',
      dosis: '',
      limpiarDosis: true,
      frecuencia: '  ',
    );

    expect(adapter.requests[0].data, <String, Object?>{});
    expect(adapter.requests[1].data, {'dosis': null});
    for (final pedido in adapter.requests) {
      expect((pedido.data as Map).values, isNot(contains('')));
    }
  });
}
