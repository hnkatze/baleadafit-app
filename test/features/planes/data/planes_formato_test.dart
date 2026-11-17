import 'package:baleadafit/features/planes/data/planes_formato.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fractions are multiplied by 100', () {
    test('pctKcal 0.35 is 35%, not 0%', () {
      expect(formatearFraccion(0.35), '35%');
      expect(formatearFraccion(0.25), '25%');
      expect(formatearFraccion(0.1), '10%');
      expect(formatearFraccion(0.195), '19.5%');
    });

    test('floating point noise does not leak into the text', () {
      expect(formatearFraccion(0.29), '29%');
      expect(formatearFraccion(0.57), '57%');
    });

    test('desviacion 0.004 is +0.4%, not 0.004%', () {
      expect(formatearDesviacion(0.004), '+0.4%');
      expect(formatearDesviacion(-0.008), '−0.8%');
      expect(formatearDesviacion(0.05), '+5.0%');
    });

    test('a change that rounds to zero has no sign', () {
      expect(formatearDesviacion(0), '0.0%');
      expect(formatearDesviacion(0.0004), '0.0%');
      expect(formatearDesviacion(-0.0004), '0.0%');
    });
  });

  group('a percentage is not multiplied', () {
    test('pctGrasa 19.5 stays 19.5%', () {
      expect(formatearPorcentaje(19.5), '19.5%');
      expect(formatearPorcentaje(34), '34%');
      expect(formatearPorcentaje(0.5), '0.5%');
    });
  });

  group('numbers', () {
    test('whole numbers have no decimals, otherwise one', () {
      expect(formatearNumero(100), '100');
      expect(formatearNumero(93.75), '93.8');
      expect(formatearNumero(187.5), '187.5');
      expect(formatearNumero(41.67), '41.7');
      expect(formatearNumero(-0.5), '−0.5');
    });

    test('grams carry the unit with no space', () {
      expect(formatearGramos(100), '100g');
      expect(formatearGramos(93.75), '93.8g');
    });

    test('kcal use a dot for thousands', () {
      expect(formatearKcal(375), '375');
      expect(formatearKcal(1500), '1.500');
      expect(formatearKcal(10542), '10.542');
      expect(formatearKcal(1000000), '1.000.000');
      expect(formatearKcal(1505.6), '1.506');
      expect(formatearKcal(-1500), '−1.500');
    });

    test('signed kcal', () {
      expect(formatearKcalFirmada(300), '+300');
      expect(formatearKcalFirmada(-500), '−500');
      expect(formatearKcalFirmada(0), '0');
    });

    test('portions keep the quarter', () {
      expect(formatearPorciones(1), '1');
      expect(formatearPorciones(1.5), '1.5');
      expect(formatearPorciones(0.25), '0.25');
      expect(formatearPorciones(0.75), '0.75');
      expect(formatearPorciones(6), '6');
      expect(formatearPorciones(10), '10');
    });
  });
}
