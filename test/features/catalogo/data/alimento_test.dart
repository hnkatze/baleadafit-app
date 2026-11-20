import 'package:baleadafit/features/catalogo/data/alimento.dart';
import 'package:baleadafit/features/catalogo/data/alimento_version.dart';
import 'package:baleadafit/features/catalogo/data/restriccion.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _pollo() => {
  'id': 'ali-1',
  'nombre': 'Pechuga de pollo a la plancha',
  'categoria': 'PROTEINA',
  'porcionDescripcion': '1 pieza mediana',
  'porcionGramos': 100,
  'kcal': 165,
  'proteinaG': 31.0,
  'carbohidratoG': 0,
  'grasaG': 3.6,
  'fibraG': 0,
  'sodioMg': 74,
  'potasioMg': 256,
  'fosforoMg': 228,
  'azucaresG': 0,
  'grasasSatG': 1.0,
  'indiceGlucemico': 0,
  'esTipicoHn': true,
  'tiposComida': ['ALMUERZO', 'CENA'],
  'contiene': ['lactosa'],
  'fuente': 'INCAP',
  'activo': true,
};

void main() {
  group('Alimento', () {
    test('reads the 21 fields of the contract', () {
      final a = Alimento.fromJson(_pollo());

      expect(a.id, 'ali-1');
      expect(a.nombre, 'Pechuga de pollo a la plancha');
      expect(a.categoria, 'PROTEINA');
      expect(a.porcionDescripcion, '1 pieza mediana');
      expect(a.porcionGramos, 100);
      expect(a.kcal, 165);
      expect(a.proteinaG, 31.0);
      expect(a.carbohidratoG, 0);
      expect(a.grasaG, 3.6);
      expect(a.fibraG, 0);
      expect(a.sodioMg, 74);
      expect(a.potasioMg, 256);
      expect(a.fosforoMg, 228);
      expect(a.azucaresG, 0);
      expect(a.grasasSatG, 1.0);
      expect(a.indiceGlucemico, 0);
      expect(a.esTipicoHn, isTrue);
      expect(a.tiposComida, ['ALMUERZO', 'CENA']);
      expect(a.contiene, ['lactosa']);
      expect(a.fuente, 'INCAP');
      expect(a.activo, isTrue);
    });

    test('an absent glycemic index is null, never 0', () {
      final json = _pollo()..remove('indiceGlucemico');
      expect(Alimento.fromJson(json).indiceGlucemico, isNull);

      final nulo = _pollo()..['indiceGlucemico'] = null;
      expect(Alimento.fromJson(nulo).indiceGlucemico, isNull);
    });

    test('absent or mistyped nutrients are null, never 0', () {
      final json = _pollo()
        ..remove('sodioMg')
        ..remove('potasioMg')
        ..['fosforoMg'] = 'mucho'
        ..['azucaresG'] = null
        ..remove('grasasSatG')
        ..remove('kcal');
      final a = Alimento.fromJson(json);

      expect(a.sodioMg, isNull);
      expect(a.potasioMg, isNull);
      expect(a.fosforoMg, isNull);
      expect(a.azucaresG, isNull);
      expect(a.grasasSatG, isNull);
      expect(a.kcal, isNull);
      // A real zero stays a zero.
      expect(a.carbohidratoG, 0);
    });

    test('tiposComida and contiene tolerate empty, null and garbage', () {
      final vacio = Alimento.fromJson(
        _pollo()
          ..['tiposComida'] = <Object?>[]
          ..['contiene'] = <Object?>[],
      );
      expect(vacio.tiposComida, isEmpty);
      expect(vacio.contiene, isEmpty);

      final basura = Alimento.fromJson(
        _pollo()
          ..['tiposComida'] = 'ALMUERZO'
          ..['contiene'] = ['gluten', 3, null, 'lactosa'],
      );
      expect(basura.tiposComida, isEmpty);
      expect(basura.contiene, ['gluten', 'lactosa']);

      final ausentes = Alimento.fromJson(
        _pollo()
          ..remove('tiposComida')
          ..remove('contiene'),
      );
      expect(ausentes.tiposComida, isEmpty);
      expect(ausentes.contiene, isEmpty);
    });

    test('flags default when absent: active, not typical', () {
      final a = Alimento.fromJson({'id': 'ali-2', 'nombre': 'Agua'});

      expect(a.activo, isTrue);
      expect(a.esTipicoHn, isFalse);
      expect(a.categoria, isNull);
      expect(a.fuente, isNull);
      expect(a.kcal, isNull);
    });

    test('an inactive food reads as inactive', () {
      expect(Alimento.fromJson(_pollo()..['activo'] = false).activo, isFalse);
    });

    test('tryFromJson returns null without id or nombre', () {
      expect(Alimento.tryFromJson(_pollo()..remove('id')), isNull);
      expect(Alimento.tryFromJson(_pollo()..['nombre'] = 4), isNull);
      expect(Alimento.tryFromJson(_pollo())?.id, 'ali-1');
    });
  });

  group('AlimentoVersion', () {
    Map<String, dynamic> version({Object? hasta}) => {
      'id': 'ver-2',
      'version': 2,
      'tabla': 'INCAP 2012',
      'fuente': 'INCAP',
      'porcionDescripcion': '1 pieza mediana',
      'porcionGramos': 100,
      'vigenteDesde': '2026-11-12T00:00:00.000Z',
      'vigenteHasta': hasta,
      'kcal': 170,
      'proteinaG': 32,
      'carbohidratoG': 0,
      'grasaG': 3.9,
      'fibraG': 0,
      'sodioMg': 80,
      'potasioMg': 260,
      'fosforoMg': 230,
      'azucaresG': 0,
      'grasasSatG': 1.1,
    };

    test('a null vigenteHasta means current', () {
      final v = AlimentoVersion.fromJson(version());

      expect(v.vigenteHasta, isNull);
      expect(v.vigente, isTrue);
      expect(v.version, 2);
      expect(v.tabla, 'INCAP 2012');
      // The entity has no `alimentoId`: the route names the food, and the
      // portion belongs to the version because it can change over time.
      expect(v.fuente, 'INCAP');
      expect(v.porcionDescripcion, '1 pieza mediana');
      expect(v.porcionGramos, 100);
    });

    test('a closed version is not current and keeps its readable range', () {
      final v = AlimentoVersion.fromJson(
        version(hasta: '2026-12-01T00:00:00.000Z'),
      );

      expect(v.vigente, isFalse);
      expect(v.vigenteDesde, DateTime.utc(2026, 11, 12));
      expect(v.vigenteHasta, DateTime.utc(2026, 12));
      expect(v.vigenteDesde!.isBefore(v.vigenteHasta!), isTrue);
    });

    test('nutrients are nullable and a missing glycemic index is not 0', () {
      final v = AlimentoVersion.fromJson(
        version()
          ..remove('sodioMg')
          ..remove('indiceGlucemico'),
      );

      expect(v.kcal, 170);
      expect(v.sodioMg, isNull);
      expect(v.indiceGlucemico, isNull);
      expect(v.carbohidratoG, 0);
    });
  });

  group('Restriccion', () {
    test('reads id, codigo, nombre and descripcion', () {
      final r = Restriccion.fromJson({
        'id': 'r-1',
        'codigo': 'lactosa',
        'nombre': 'Lactosa',
        'descripcion': 'Productos lácteos',
      });

      expect(r.id, 'r-1');
      expect(r.codigo, 'lactosa');
      expect(r.nombre, 'Lactosa');
      expect(r.descripcion, 'Productos lácteos');
    });

    test('descripcion is optional', () {
      final r = Restriccion.fromJson({
        'id': 'r-2',
        'codigo': 'gluten',
        'nombre': 'Gluten',
      });
      expect(r.descripcion, isNull);
    });
  });
}
