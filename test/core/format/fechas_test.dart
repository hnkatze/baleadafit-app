import 'package:baleadafit/core/format/fechas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatearFecha', () {
    test('pads the day and the month', () {
      expect(formatearFecha(DateTime(2026, 1, 5)), '05/01/2026');
      expect(formatearFecha(DateTime(2026, 11, 30)), '30/11/2026');
    });
  });

  group('leerFecha', () {
    test('reads a complete dd/mm/aaaa', () {
      expect(leerFecha('07/11/2026'), DateTime(2026, 11, 7));
    });

    test('rejects an incomplete date', () {
      expect(leerFecha('7/11/2026'), isNull);
      expect(leerFecha('07/11'), isNull);
      expect(leerFecha(''), isNull);
    });

    test('rejects a day that does not exist instead of rolling over', () {
      expect(leerFecha('31/02/2020'), isNull);
    });
  });

  group('fechaIso', () {
    test('formats a calendar date from its own fields', () {
      expect(fechaIso(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('does not shift a midnight UTC date to the previous day', () {
      expect(fechaIso(DateTime.utc(2026, 11, 7)), '2026-11-07');
    });

    test('round-trips with leerFecha', () {
      final fecha = DateTime(2026, 3, 9);
      expect(leerFecha(formatearFecha(fecha)), fecha);
    });
  });

  group('fechaLarga', () {
    test('names the weekday and the month in Spanish', () {
      expect(fechaLarga(DateTime(2026, 11, 7)), 'Sábado, 7 de noviembre');
      expect(fechaLarga(DateTime(2026, 1, 5)), 'Lunes, 5 de enero');
    });
  });

  group('mesLargo / mesYAnio', () {
    test('capitalises the month in Spanish', () {
      expect(mesLargo(DateTime(2026, 11, 7)), 'Noviembre');
      expect(mesLargo(DateTime(2026, 1, 31)), 'Enero');
    });

    test('adds the year', () {
      expect(mesYAnio(DateTime(2026, 11, 7)), 'Noviembre 2026');
      expect(mesYAnio(DateTime(2027, 2, 1)), 'Febrero 2027');
    });
  });
}
