import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/features/planes/data/plan.dart';
import 'package:baleadafit/features/planes/data/planes_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, Object?> _totales({double kcal = 375, bool completo = true}) => {
  'kcal': kcal,
  'proteinaG': 23.4,
  'carbohidratoG': 46.9,
  'grasaG': 10.4,
  if (completo) ...{
    'fibraG': 5,
    'sodioMg': 300,
    'potasioMg': 600,
    'fosforoMg': 250,
    'azucaresG': 8,
    'grasasSatG': 3,
    'cargaGlucemica': 20,
  },
};

Map<String, Object?> _item({String id = 'i1', bool versionado = true}) => {
  'id': id,
  'tiempoComidaId': 't1',
  'alimentoId': 'a1',
  'porciones': 1.5,
  'alimento': {
    'id': 'a1',
    'nombre': 'Arroz blanco',
    'porcionDescripcion': '1 taza',
    'porcionGramos': 158,
    'kcal': 205,
    'categoria': 'CEREALES',
    'contiene': ['gluten'],
  },
  'alimentoVersionId': versionado ? 'v1' : null,
  'alimentoVersion': versionado ? {'version': 1, 'kcal': 205} : null,
};

Map<String, Object?> _tiempo({
  String id = 't1',
  String dia = 'LUNES',
  String tipo = 'DESAYUNO',
  List<Map<String, Object?>>? items,
}) => {
  'id': id,
  'planId': 'pl1',
  'dia': dia,
  'tipo': tipo,
  'orden': 1,
  'items': items ?? [_item()],
  'kcalMeta': 375,
  'pctKcal': 0.25,
  'desviacion': -0.008,
  'totales': _totales(),
};

Map<String, Object?> _plan({
  String id = 'pl1',
  String estado = 'BORRADOR',
  String origen = 'REGLAS',
  String? justificacion = 'Generado por reglas.',
  String? aprobadoEn,
}) => {
  'id': id,
  'pacienteId': 'p1',
  'nutricionistaId': 'n1',
  'nombre': 'Plan 2026-11-07',
  'estado': estado,
  'origen': origen,
  'kcalObjetivo': 1500,
  'proteinaG': 93.75,
  'carbohidratoG': 187.5,
  'grasaG': 41.67,
  'justificacion': justificacion,
  'creadoEn': '2026-11-07T15:30:00.000Z',
  'aprobadoEn': aprobadoEn,
};

Map<String, Object?> _detalle({
  String estado = 'BORRADOR',
  List<Map<String, Object?>>? tiempos,
}) {
  final lista = tiempos ?? [_tiempo(), _tiempo(id: 't2', tipo: 'ALMUERZO')];
  return {
    ..._plan(estado: estado),
    'tiempos': lista,
    'dias': [
      {
        'dia': 'LUNES',
        'tiempos': lista,
        'totales': _totales(kcal: 1506),
        'desviacion': 0.004,
      },
    ],
    'totales': _totales(kcal: 10542),
    'desviacion': 0.004,
  };
}

PlanesRepository _repo(FakeHttpAdapter adapter) =>
    PlanesRepository(ApiClient(dioWith(adapter)));

FakeHttpAdapter _responde(Object? data, {int status = 200}) => FakeHttpAdapter(
  (_) async => jsonBody({'ok': true, 'data': data}, status: status),
);

void main() {
  group('PlanesRepository.listar', () {
    test('GETs the plans of the patient and keeps the API order', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': [
            _plan(id: 'archivado', estado: 'ARCHIVADO'),
            _plan(id: 'activo', estado: 'ACTIVO'),
          ],
          'meta': {'limit': 20, 'offset': 0, 'total': 2, 'hasMore': false},
        }),
      );

      final page = await _repo(adapter).listar('p 1');

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/pacientes/p%201/planes');
      expect(request.queryParameters, isEmpty);
      expect(page.items.map((p) => p.id), ['archivado', 'activo']);
      expect(page.items.map((p) => p.estado), [
        EstadoPlan.archivado,
        EstadoPlan.activo,
      ]);
      expect(page.meta.total, 2);
    });

    test('sends the page the caller asks for', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': true,
          'data': <Object?>[],
          'meta': {'limit': 5, 'offset': 10, 'total': 0, 'hasMore': false},
        }),
      );

      await _repo(adapter).listar('p1', limit: 5, offset: 10);

      expect(adapter.requests.single.queryParameters, {
        'limit': 5,
        'offset': 10,
      });
    });

    test('never sends an offset together with a cursor', () {
      final adapter = _responde(<Object?>[]);

      expect(
        () => _repo(adapter).listar('p1', offset: 0, cursor: 'abc'),
        throwsArgumentError,
      );
      expect(adapter.requests, isEmpty);
    });
  });

  group('PlanesRepository.generar', () {
    test('POSTs and sends usarIa true when nothing else is given', () async {
      final adapter = _responde(_detalle(), status: 201);

      final plan = await _repo(adapter).generar('p1');

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/pacientes/p1/planes/generar');
      expect(request.data, {'usarIa': true});
      expect(plan.estado, EstadoPlan.borrador);
    });

    test(
      'sends every field given, with the distributions as fractions',
      () async {
        final adapter = _responde(_detalle(), status: 201);

        await _repo(adapter).generar(
          'p1',
          nombre: 'Plan inicial',
          kcalObjetivo: 1600,
          usarIa: false,
          indicaciones: '  Prefiere desayunos rápidos  ',
          distribucionMacros: const DistribucionMacros(
            proteina: 0.3,
            carbohidrato: 0.45,
            grasa: 0.25,
          ),
          distribucionTiempos: {
            TipoComida.desayuno: 0.3,
            TipoComida.meriendaAm: 0,
            TipoComida.almuerzo: 0.4,
            TipoComida.meriendaPm: 0.1,
            TipoComida.cena: 0.2,
          },
        );

        expect(adapter.requests.single.data, {
          'nombre': 'Plan inicial',
          'kcalObjetivo': 1600,
          'usarIa': false,
          'indicaciones': 'Prefiere desayunos rápidos',
          'distribucionMacros': {
            'proteina': 0.3,
            'carbohidrato': 0.45,
            'grasa': 0.25,
          },
          'distribucionTiempos': {
            'DESAYUNO': 0.3,
            'MERIENDA_AM': 0,
            'ALMUERZO': 0.4,
            'MERIENDA_PM': 0.1,
            'CENA': 0.2,
          },
        });
      },
    );

    test('does not send blank indicaciones', () async {
      final adapter = _responde(_detalle(), status: 201);

      await _repo(adapter).generar('p1', indicaciones: '   ');

      expect(adapter.requests.single.data, {'usarIa': true});
    });

    test('surfaces the API message of a 400', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': false,
          'error': {'codigo': 'VALIDACION', 'mensaje': 'kcalObjetivo inválido'},
        }, status: 400),
      );

      await expectLater(
        _repo(adapter).generar('p1', kcalObjetivo: 10),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.statusCode, 'statusCode', 400)
              .having((f) => f.mensaje, 'mensaje', 'kcalObjetivo inválido'),
        ),
      );
    });
  });

  group('PlanesRepository.detalle', () {
    test('GETs the plan and decodes the whole week', () async {
      final adapter = _responde(_detalle());

      final plan = await _repo(adapter).detalle('pl1');

      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.path, '/planes/pl1');

      expect(plan.nombre, 'Plan 2026-11-07');
      expect(plan.estado, EstadoPlan.borrador);
      expect(plan.origen, OrigenPlan.reglas);
      expect(plan.kcalObjetivo, 1500);
      expect(plan.proteinaG, 93.75);
      expect(plan.justificacion, 'Generado por reglas.');
      expect(plan.aprobadoEn, isNull);
      expect(plan.creadoEn, DateTime.utc(2026, 11, 7, 15, 30));
      expect(plan.creadoEn!.isUtc, isTrue);
      expect(plan.desviacion, 0.004);
      expect(plan.totales!.kcal, 10542);
      expect(plan.totales!.cargaGlucemica, 20);

      expect(plan.dias, hasLength(1));
      final dia = plan.dias.single;
      expect(dia.dia, DiaSemana.lunes);
      expect(dia.totales!.kcal, 1506);
      expect(dia.desviacion, 0.004);
      expect(dia.tiempos.map((t) => t.tipo), [
        TipoComida.desayuno,
        TipoComida.almuerzo,
      ]);

      expect(plan.tiempos, hasLength(2));
      final tiempo = plan.tiempos.first;
      expect(tiempo.id, 't1');
      expect(tiempo.planId, 'pl1');
      expect(tiempo.kcalMeta, 375);
      expect(tiempo.pctKcal, 0.25);
      expect(tiempo.desviacion, -0.008);
      expect(tiempo.totales!.proteinaG, 23.4);

      final item = tiempo.items.single;
      expect(item.alimentoId, 'a1');
      expect(item.porciones, 1.5);
      expect(item.alimento!.nombre, 'Arroz blanco');
      expect(item.alimento!.porcionDescripcion, '1 taza');
      expect(item.alimento!.kcal, 205, reason: 'per portion, not multiplied');
      expect(item.alimento!.porcionGramos, 158);
      expect(item.alimento!.categoria, 'CEREALES');
      expect(item.alimento!.contiene, ['gluten']);
      expect(item.alimentoVersionId, 'v1');
      expect(item.tieneVersion, isTrue);
    });

    test('reads the activation instant of an active plan', () async {
      final adapter = _responde({
        ..._detalle(estado: 'ACTIVO'),
        'aprobadoEn': '2026-11-07T20:00:00.000Z',
      });

      final plan = await _repo(adapter).detalle('pl1');

      expect(plan.estado, EstadoPlan.activo);
      expect(plan.aprobadoEn, DateTime.utc(2026, 11, 7, 20));
    });

    test('keeps an item older than versioning with no version', () async {
      final adapter = _responde(
        _detalle(
          tiempos: [
            _tiempo(items: [_item(versionado: false)]),
          ],
        ),
      );

      final item = (await _repo(adapter).detalle('pl1'))
          .tiempos
          .single
          .items
          .single;

      expect(item.alimentoVersionId, isNull);
      expect(item.tieneVersion, isFalse);
    });

    test('keeps a null justificacion and a time with no items', () async {
      final adapter = _responde({
        ..._detalle(tiempos: [_tiempo(items: [])]),
        'justificacion': null,
      });

      final plan = await _repo(adapter).detalle('pl1');

      expect(plan.justificacion, isNull);
      expect(plan.tiempos.single.items, isEmpty);
    });

    test(
      'reads a missing micronutrient as 0 and a missing block as null',
      () async {
        final adapter = _responde({
          ..._detalle(),
          'totales': _totales(completo: false),
          'desviacion': null,
        });

        final plan = await _repo(adapter).detalle('pl1');

        expect(plan.totales!.kcal, 375);
        expect(plan.totales!.fibraG, 0);
        expect(plan.totales!.sodioMg, 0);
        expect(plan.desviacion, isNull);
      },
    );

    test('draws only the days the plan has', () async {
      final adapter = _responde({
        ..._detalle(),
        'dias': [
          {'dia': 'LUNES', 'tiempos': [], 'totales': _totales()},
          {'dia': 'MIERCOLES', 'tiempos': [], 'totales': _totales()},
        ],
      });

      final plan = await _repo(adapter).detalle('pl1');

      expect(plan.dias.map((d) => d.dia), [
        DiaSemana.lunes,
        DiaSemana.miercoles,
      ]);
    });

    test('reports a 404 as the ApiFailure with the API message', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': false,
          'error': {
            'codigo': 'NO_ENCONTRADO',
            'mensaje': 'Plan no encontrado.',
          },
        }, status: 404),
      );

      await expectLater(
        _repo(adapter).detalle('x'),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.mensaje,
            'mensaje',
            'Plan no encontrado.',
          ),
        ),
      );
    });
  });

  group('PlanesRepository.activar', () {
    test('POSTs with no body and decodes the active plan', () async {
      final adapter = _responde({
        ..._detalle(estado: 'ACTIVO'),
        'aprobadoEn': '2026-11-07T20:00:00.000Z',
      }, status: 201);

      final plan = await _repo(adapter).activar('pl1');

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/planes/pl1/activar');
      expect(request.data, isNull);
      expect(plan.estado, EstadoPlan.activo);
      expect(plan.aprobadoEn, isNotNull);
    });
  });

  group('PlanesRepository.reemplazarItems', () {
    test(
      'PUTs to the path with the day and the time, never without the day',
      () async {
        final adapter = _responde(_detalle());

        await _repo(adapter).reemplazarItems(
          'pl1',
          dia: DiaSemana.miercoles,
          tipo: TipoComida.meriendaAm,
          items: const [
            ItemReemplazo(alimentoId: 'a1', porciones: 1.5),
            ItemReemplazo(alimentoId: 'a2', porciones: 0.25),
          ],
        );

        final request = adapter.requests.single;
        expect(request.method, 'PUT');
        expect(request.path, '/planes/pl1/tiempos/MIERCOLES/MERIENDA_AM/items');
        expect(request.data, {
          'items': [
            {'alimentoId': 'a1', 'porciones': 1.5},
            {'alimentoId': 'a2', 'porciones': 0.25},
          ],
        });
      },
    );

    test('sends an empty list as is and returns the full plan', () async {
      final adapter = _responde(_detalle());

      final plan = await _repo(adapter).reemplazarItems(
        'pl1',
        dia: DiaSemana.lunes,
        tipo: TipoComida.almuerzo,
        items: const [],
      );

      expect(
        adapter.requests.single.path,
        '/planes/pl1/tiempos/LUNES/ALMUERZO/items',
      );
      expect(adapter.requests.single.data, {'items': <Object?>[]});
      expect(plan.dias, isNotEmpty);
    });

    test('surfaces the API message of a 400', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': false,
          'error': {'codigo': 'VALIDACION', 'mensaje': 'Máximo 12 alimentos.'},
        }, status: 400),
      );

      await expectLater(
        _repo(adapter).reemplazarItems(
          'pl1',
          dia: DiaSemana.lunes,
          tipo: TipoComida.cena,
          items: const [],
        ),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.mensaje,
            'mensaje',
            'Máximo 12 alimentos.',
          ),
        ),
      );
    });
  });

  group('PlanesRepository.eliminar', () {
    test('DELETEs the plan and accepts the envelope', () async {
      final adapter = FakeHttpAdapter((_) async => jsonBody({'ok': true}));

      await _repo(adapter).eliminar('pl1');

      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.path, '/planes/pl1');
    });

    test(
      'surfaces the code of a failure so the caller decides by it',
      () async {
        final adapter = FakeHttpAdapter(
          (_) async => jsonBody({
            'ok': false,
            'error': {
              'codigo': 'PLAN_NO_BORRADOR',
              'mensaje': 'No es borrador.',
            },
          }, status: 400),
        );

        await expectLater(
          _repo(adapter).eliminar('pl1'),
          throwsA(
            isA<ApiFailure>().having(
              (f) => f.codigo,
              'codigo',
              'PLAN_NO_BORRADOR',
            ),
          ),
        );
      },
    );
  });

  group('enum fallbacks', () {
    test('an unknown estado degrades to the read-only state', () async {
      final adapter = _responde({..._detalle(), 'estado': 'PAUSADO'});

      expect((await _repo(adapter).detalle('x')).estado, EstadoPlan.archivado);
    });

    test('an unknown origen degrades to manual, not to IA', () async {
      final adapter = _responde({..._detalle(), 'origen': 'HIBRIDO'});

      expect((await _repo(adapter).detalle('x')).origen, OrigenPlan.manual);
    });

    test('an unknown dia and tipo still draw the row', () async {
      final adapter = _responde(
        _detalle(
          tiempos: [_tiempo(dia: 'FERIADO', tipo: 'SNACK')],
        ),
      );

      final tiempo = (await _repo(adapter).detalle('x')).tiempos.single;

      expect(tiempo.dia, DiaSemana.lunes);
      expect(tiempo.tipo, TipoComida.desayuno);
    });

    test('a null value degrades the same way', () {
      expect(EstadoPlan.desdeApi(null), EstadoPlan.archivado);
      expect(OrigenPlan.desdeApi(null), OrigenPlan.manual);
      expect(DiaSemana.desdeApi(null), DiaSemana.lunes);
      expect(TipoComida.desdeApi(null), TipoComida.desayuno);
    });

    test('every code of the contract round-trips', () {
      for (final e in EstadoPlan.values) {
        expect(EstadoPlan.desdeApi(e.codigo), e);
      }
      for (final o in OrigenPlan.values) {
        expect(OrigenPlan.desdeApi(o.codigo), o);
      }
      for (final d in DiaSemana.values) {
        expect(DiaSemana.desdeApi(d.codigo), d);
      }
      for (final t in TipoComida.values) {
        expect(TipoComida.desdeApi(t.codigo), t);
      }
      expect(DiaSemana.miercoles.codigo, 'MIERCOLES');
      expect(DiaSemana.sabado.codigo, 'SABADO');
      expect(DiaSemana.miercoles.etiqueta, 'Miércoles');
    });
  });
}
