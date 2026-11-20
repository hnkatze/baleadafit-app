import 'package:baleadafit/core/format/numeros.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void tabla(
    String nombre,
    String Function(num) formato,
    Map<num, String> casos,
  ) {
    group(nombre, () {
      casos.forEach((entrada, esperado) {
        test('$entrada → $esperado', () => expect(formato(entrada), esperado));
      });
    });
  }

  tabla('formatearKcal: comma for thousands', formatearKcal, {
    375: '375',
    999: '999',
    1000: '1,000',
    1500: '1,500',
    10542: '10,542',
    1000000: '1,000,000',
    1505.6: '1,506',
    -1500: '−1,500',
  });

  tabla('formatearKcalFirmada', formatearKcalFirmada, {
    300: '+300',
    1500: '+1,500',
    -500: '−500',
    -1500: '−1,500',
    0: '0',
  });

  tabla('formatearNumero: dot decimal, at most one', formatearNumero, {
    100: '100',
    25: '25',
    93.75: '93.8',
    93.81: '93.8',
    187.5: '187.5',
    41.67: '41.7',
    -0.5: '−0.5',
    -0.04: '0',
    28.999999999999996: '29',
  });

  tabla('formatearGramos: no space', formatearGramos, {
    100: '100g',
    93.75: '93.8g',
    93.8: '93.8g',
  });

  tabla('formatearPorcentaje: already a percentage', formatearPorcentaje, {
    19.5: '19.5%',
    34: '34%',
    0.5: '0.5%',
  });

  tabla('formatearFraccion: multiplied by 100', formatearFraccion, {
    0.35: '35%',
    0.25: '25%',
    0.1: '10%',
    0.195: '19.5%',
    0.29: '29%',
    0.57: '57%',
  });

  tabla('formatearDesviacion: signed, one decimal', formatearDesviacion, {
    0.004: '+0.4%',
    -0.008: '−0.8%',
    0.05: '+5.0%',
    0: '0.0%',
    0.0004: '0.0%',
    -0.0004: '0.0%',
  });

  tabla('formatearPorciones: keep the quarter', formatearPorciones, {
    1: '1',
    1.5: '1.5',
    0.25: '0.25',
    0.75: '0.75',
    6: '6',
    10: '10',
  });
}
