import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/network/api_failure.dart';
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

  test('reads one patient file from its own endpoint', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({
        'ok': true,
        'data': {
          'paciente': {
            'id': 'pac-1',
            'nombre': 'Paciente',
            'apellido': 'De Prueba',
          },
          'cabecera': {'edad': 31, 'imc': 23.9},
        },
      }),
    );

    final ficha = await PatientsRepository(ApiClient(dioWith(adapter)))
        .ficha('pac-1');

    expect(adapter.requests.single.path, '/pacientes/pac-1/ficha');
    expect(ficha.paciente.nombreCompleto, 'Paciente De Prueba');
    expect(ficha.cabecera.imc, 23.9);
  });

  test('a patient of another nutritionist surfaces as an ApiFailure', () async {
    final repository = PatientsRepository(
      ApiClient(
        dioWith(
          FakeHttpAdapter(
            (_) async => jsonBody({
              'ok': false,
              'error': {
                'codigo': 'NO_ENCONTRADO',
                'mensaje': 'No existe o no pertenece al usuario.',
              },
            }, status: 404),
          ),
        ),
      ),
    );

    expect(
      repository.ficha('pac-9'),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.statusCode, 'statusCode', 404)
            .having((f) => f.codigo, 'codigo', 'NO_ENCONTRADO'),
      ),
    );
  });

  test(
    'posts the measurement body to the patient and accepts the 201',
    () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': {'id': 'med-2', 'imc': 23.7},
        }, status: 201),
      );

      await PatientsRepository(ApiClient(dioWith(adapter))).registrarMedicion(
        'pac-1',
        body: {'pesoKg': 71.8, 'tallaCm': 174, 'fuente': 'MANUAL'},
      );

      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/pacientes/pac-1/mediciones');
      expect(adapter.requests.single.data, {
        'pesoKg': 71.8,
        'tallaCm': 174,
        'fuente': 'MANUAL',
      });
    },
  );

  test('surfaces the API message when the measurement is refused', () {
    final repository = PatientsRepository(
      ApiClient(
        dioWith(
          FakeHttpAdapter(
            (_) async => jsonBody({
              'ok': false,
              'error': {'codigo': 'VALIDACION', 'mensaje': 'Datos inválidos.'},
            }, status: 400),
          ),
        ),
      ),
    );

    expect(
      repository.registrarMedicion('pac-1', body: {'pesoKg': 1}),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.statusCode, 'statusCode', 400)
            .having((f) => f.mensaje, 'mensaje', 'Datos inválidos.'),
      ),
    );
  });

  test('deactivates a patient through DELETE /pacientes/{id}', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({
        'ok': true,
        'data': {'id': 'pac-1', 'activo': false},
      }),
    );

    await PatientsRepository(ApiClient(dioWith(adapter))).darDeBaja('pac-1');

    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.path, '/pacientes/pac-1');
  });

  test('surfaces the API message when the deactivation is refused', () {
    final repository = PatientsRepository(
      ApiClient(
        dioWith(
          FakeHttpAdapter(
            (_) async => jsonBody({
              'ok': false,
              'error': {
                'codigo': 'NO_ENCONTRADO',
                'mensaje': 'No existe o no pertenece al usuario.',
              },
            }, status: 404),
          ),
        ),
      ),
    );

    expect(
      repository.darDeBaja('pac-1'),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.statusCode, 'statusCode', 404)
            .having((f) => f.codigo, 'codigo', 'NO_ENCONTRADO')
            .having(
              (f) => f.mensaje,
              'mensaje',
              'No existe o no pertenece al usuario.',
            ),
      ),
    );
  });

  test(
    'creates a patient through POST /pacientes and returns its id',
    () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': {'id': 'pac-new', 'nombre': 'Ana', 'activo': true},
        }, status: 201),
      );
      const body = <String, Object?>{
        'nombre': 'Ana',
        'apellido': 'Paz',
        'correo': 'ana@correo.com',
        'pesoObjetivoKg': 62.5,
        'comidasAlDia': 4,
        'condiciones': ['DIABETES_2'],
      };

      final id = await PatientsRepository(ApiClient(dioWith(adapter)))
          .crearPaciente(body);

      expect(id, 'pac-new');
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/pacientes');
      // Numbers stay numbers on the wire: the API types them as such.
      expect(adapter.requests.single.data, body);
    },
  );

  test('surfaces the API message when the creation is refused', () {
    final repository = PatientsRepository(
      ApiClient(
        dioWith(
          FakeHttpAdapter(
            (_) async => jsonBody({
              'ok': false,
              'error': {
                'codigo': 'CONFLICTO',
                'mensaje': 'Ya existe un paciente con ese correo.',
              },
            }, status: 409),
          ),
        ),
      ),
    );

    expect(
      repository.crearPaciente({'nombre': 'Ana'}),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.statusCode, 'statusCode', 409)
            .having(
              (f) => f.mensaje,
              'mensaje',
              'Ya existe un paciente con ese correo.',
            ),
      ),
    );
  });

  test('reads the conditions and the restrictions catalogues', () async {
    final adapter = FakeHttpAdapter((options) async {
      final esCondiciones = options.path == '/condiciones';
      return jsonBody({
        'ok': true,
        'data': [
          if (esCondiciones)
            {
              'codigo': 'DIABETES_2',
              'nombre': 'Diabetes tipo 2',
              'descripcion': 'Control de carbohidratos',
            }
          else
            {'codigo': 'SIN_GLUTEN', 'nombre': 'Sin gluten'},
        ],
        'meta': {'limit': 20, 'offset': 0, 'total': 1, 'hasMore': false},
      });
    });
    final repository = PatientsRepository(ApiClient(dioWith(adapter)));

    final condiciones = await repository.condiciones();
    final restricciones = await repository.restricciones();

    expect(condiciones.single.codigo, 'DIABETES_2');
    expect(condiciones.single.nombre, 'Diabetes tipo 2');
    expect(condiciones.single.descripcion, 'Control de carbohidratos');
    expect(restricciones.single.codigo, 'SIN_GLUTEN');
    expect(restricciones.single.descripcion, isNull);
    expect(adapter.requests.map((r) => r.path), [
      '/condiciones',
      '/restricciones',
    ]);
  });

  test('reads a catalogue that answers no pagination meta', () async {
    // `GET /condiciones` and `GET /restricciones` answer `{ok, data: []}` with
    // no `meta` block, unlike the patient lists.
    final repository = PatientsRepository(
      ApiClient(
        dioWith(
          FakeHttpAdapter(
            (_) async => jsonBody({
              'ok': true,
              'data': [
                {'codigo': 'DM2', 'nombre': 'Diabetes tipo 2'},
                {'codigo': 'HTA', 'nombre': 'Hipertensión'},
              ],
            }),
          ),
        ),
      ),
    );

    final condiciones = await repository.condiciones();

    expect(condiciones, hasLength(2));
    expect(condiciones.first.codigo, 'DM2');
    expect(condiciones.first.nombre, 'Diabetes tipo 2');
  });
}
