import 'package:baleadafit/features/patients/data/paciente_ficha.dart';
import 'package:flutter_test/flutter_test.dart';

/// Payload with the shape and values the API returned for
/// `GET /pacientes/{id}/ficha` (see `odd/designs/pacientes-context.md` §3).
/// Most of its fields are untyped in the OpenAPI, so the test pins exactly the
/// ones the ficha draws.
Map<String, Object?> _fichaJson() => {
  'paciente': {
    'id': 'pac-1',
    'nombre': 'Paciente',
    'apellido': 'De Prueba',
    'sexo': 'M',
    'fechaNacimiento': '1994-06-12T00:00:00.000Z',
    'correo': 'prueba.qa@baleadafit.hn',
    'telefono': '+504 9999-0000',
    'meta': 'BAJAR',
    'nivelActividad': 'SEDENTARIO',
    'estadoFisiologico': 'NINGUNO',
    'activo': true,
    'firebaseUid': null,
  },
  'cabecera': {
    'edad': 31,
    'imc': 23.9,
    'clasificacionImc': 'NORMAL',
    'pctGrasa': 19.5,
    'masaMagraKg': 58.3,
    'masaGrasaKg': 14.1,
    'grasaVisceral': 4,
    'objetivo': 'BAJAR',
    'composicionFecha': '2026-11-06T00:00:00.000Z',
    'ultimaMedicion': {'id': 'med-1', 'tallaCm': 174},
  },
  'progreso': {
    'pesoInicial': 72.4,
    'pesoActual': 72.4,
    'deltaKg': 0,
    'ritmoKgSemana': null,
    'proyeccionKg': null,
  },
  'requerimiento': {
    'edad': 31,
    'tmb': 1662,
    'factorActividad': 1.2,
    'gastoTotal': 1994,
    'ajusteMeta': -500,
    'kcalObjetivo': 1500,
    'proteinaG': 93.8,
    'carbohidratoG': 187.5,
    'grasaG': 41.7,
  },
  'adherencia30d': {'porcentaje': null, 'cumplidos': 0, 'total': 0},
  'alertas': [
    {
      'tipo': 'SIN_PLAN_ACTIVO',
      'severidad': 'alta',
      'detalle': 'El paciente no tiene un plan activo.',
    },
  ],
  'evolucion': [
    {
      'id': 'med-1',
      'fecha': '2026-11-06T00:00:00.000Z',
      'pesoKg': 72.4,
      'tallaCm': 174,
      'pctGrasa': 19.5,
      'imc': 23.9,
    },
  ],
  'consultas': {
    'proximas': [
      {
        'id': 'cita-1',
        'fechaHora': '2026-11-07T15:00:00.000Z',
        'duracionMin': 45,
        'motivo': 'Revisión de mediciones',
      },
    ],
    'pasadas': [],
  },
  'planes': [
    {
      'id': 'plan-1',
      'nombre': 'Plan 2026-11-07',
      'estado': 'ACTIVO',
      'origen': 'REGLAS',
      'aprobadoEn': '2026-11-07T00:00:00.000Z',
      'kcalObjetivo': 1500,
    },
  ],
};

void main() {
  group('PacienteFicha', () {
    test('reads the header, the requirement and the plan the ficha draws', () {
      final ficha = PacienteFicha.fromJson(_fichaJson());

      expect(ficha.paciente.nombreCompleto, 'Paciente De Prueba');
      expect(ficha.cabecera.edad, 31);
      expect(ficha.cabecera.imc, 23.9);
      expect(ficha.cabecera.clasificacionImc, 'NORMAL');
      expect(ficha.cabecera.pctGrasa, 19.5);
      expect(ficha.cabecera.masaMagraKg, 58.3);
      expect(ficha.cabecera.tallaCm, 174);
      expect(ficha.progreso.pesoInicial, 72.4);
      expect(ficha.progreso.deltaKg, 0);
      expect(ficha.requerimiento?.kcalObjetivo, 1500);
      expect(ficha.requerimiento?.tmb, 1662);
      expect(ficha.requerimiento?.proteinaG, 93.8);
      expect(ficha.planActivo?.nombre, 'Plan 2026-11-07');
      expect(ficha.planActivo?.estado, 'ACTIVO');
      expect(ficha.planActivo?.origen, 'REGLAS');
      expect(ficha.consultas.proximas.single.motivo, 'Revisión de mediciones');
      expect(ficha.evolucion, hasLength(1));
      expect(ficha.alertas.single.tipo, 'SIN_PLAN_ACTIVO');
    });

    test(
      'a patient who never signed in reads as not entered, with no trend',
      () {
        final ficha = PacienteFicha.fromJson(_fichaJson());

        expect(ficha.paciente.entroALaApp, isFalse);
        expect(ficha.progreso.ritmoKgSemana, isNull);
        expect(ficha.progreso.proyeccionKg, isNull);
        expect(ficha.progreso.hayTendencia, isFalse);
      },
    );

    test('a patient with a firebase uid reads as entered the app', () {
      final json = _fichaJson();
      json['paciente'] = {
        ...json['paciente']! as Map<String, Object?>,
        'firebaseUid': 'uid-123',
      };

      expect(PacienteFicha.fromJson(json).paciente.entroALaApp, isTrue);
    });

    test('zero registros reads as no adherence data, not as 0%', () {
      final ficha = PacienteFicha.fromJson(_fichaJson());

      expect(ficha.adherencia.sinDatos, isTrue);
      expect(ficha.adherencia.porcentaje, isNull);
    });

    test('a file with no measurement and no plan is not invented', () {
      final ficha = PacienteFicha.fromJson({
        'paciente': {
          'id': 'pac-2',
          'nombre': 'Ana',
          'apellido': 'Martínez',
          'sexo': 'F',
          'meta': 'MANTENER',
          'activo': true,
          'firebaseUid': null,
        },
        'cabecera': {'edad': 28, 'imc': null, 'pctGrasa': null},
        'progreso': {
          'pesoInicial': null,
          'pesoActual': null,
          'deltaKg': null,
          'ritmoKgSemana': null,
          'proyeccionKg': null,
        },
        'requerimiento': null,
        'adherencia30d': {'porcentaje': null, 'cumplidos': 0, 'total': 0},
        'alertas': [
          {
            'tipo': 'SIN_PLAN_ACTIVO',
            'severidad': 'alta',
            'detalle': 'El paciente no tiene un plan activo.',
          },
        ],
        'evolucion': [],
        'consultas': {'proximas': [], 'pasadas': []},
        'planes': [],
      });

      expect(ficha.tieneMediciones, isFalse);
      expect(ficha.requerimiento, isNull);
      expect(ficha.planActivo, isNull);
      expect(ficha.cabecera.imc, isNull);
      expect(ficha.alertas, hasLength(1));
    });

    test('a missing block is null instead of a cast error', () {
      final ficha = PacienteFicha.fromJson({
        'paciente': {'id': 'pac-3', 'nombre': 'Sin', 'apellido': 'Bloques'},
      });

      expect(ficha.requerimiento, isNull);
      expect(ficha.planActivo, isNull);
      expect(ficha.evolucion, isEmpty);
      expect(ficha.alertas, isEmpty);
      expect(ficha.consultas.proximas, isEmpty);
    });
  });

  group('situacion and habitos', () {
    test('reads the catalogue codes through the nested relation objects', () {
      final ficha = PacienteFicha.fromJson({
        'paciente': {'id': 'pac-1', 'notas': 'Cena temprano'},
        'situacion': {
          'condiciones': [
            {
              'pacienteId': 'pac-1',
              'condicionId': 'c-1',
              'condicion': {'id': 'c-1', 'codigo': 'DIABETES_2'},
            },
          ],
          'restricciones': [
            {
              'restriccionId': 'r-1',
              'restriccion': {'id': 'r-1', 'codigo': 'SIN_GLUTEN'},
            },
          ],
          'alergias': 'Maní',
          'cirugias': 'Cesárea',
          'suplementos': 'Omega 3',
          'motivoConsulta': 'Bajar de peso',
        },
        'habitos': {
          'comidasAlDia': 4,
          'aguaLitros': '2.5',
          'horasSueno': 7,
          'alcohol': 'Ocasional',
          'tabaco': 'No',
          'quienCocina': 'Ella',
          'presupuesto': 'Medio',
        },
      });

      expect(ficha.situacion.condiciones, ['DIABETES_2']);
      expect(ficha.situacion.restricciones, ['SIN_GLUTEN']);
      expect(ficha.situacion.alergias, 'Maní');
      expect(ficha.situacion.cirugias, 'Cesárea');
      expect(ficha.situacion.suplementos, 'Omega 3');
      expect(ficha.situacion.motivoConsulta, 'Bajar de peso');
      expect(ficha.habitos.comidasAlDia, 4);
      expect(ficha.habitos.aguaLitros, 2.5);
      expect(ficha.habitos.horasSueno, 7);
      expect(ficha.habitos.alcohol, 'Ocasional');
      expect(ficha.habitos.tabaco, 'No');
      expect(ficha.habitos.quienCocina, 'Ella');
      expect(ficha.habitos.presupuesto, 'Medio');
      expect(ficha.paciente.notas, 'Cena temprano');
    });

    test('tolerates bare strings and skips what carries no code', () {
      final ficha = PacienteFicha.fromJson({
        'paciente': {'id': 'pac-1'},
        'situacion': {
          'condiciones': ['DIABETES_2', 7, <String, Object?>{}],
          'restricciones': [
            'VEGETARIANO',
            {
              'restriccion': {'codigo': 'SIN_GLUTEN'},
            },
          ],
        },
      });

      expect(ficha.situacion.condiciones, ['DIABETES_2']);
      expect(ficha.situacion.restricciones, ['VEGETARIANO', 'SIN_GLUTEN']);
    });

    test('missing blocks read as empty', () {
      final ficha = PacienteFicha.fromJson({
        'paciente': {'id': 'pac-1'},
      });

      expect(ficha.situacion.condiciones, isEmpty);
      expect(ficha.situacion.restricciones, isEmpty);
      expect(ficha.habitos.comidasAlDia, isNull);
    });
  });
}
