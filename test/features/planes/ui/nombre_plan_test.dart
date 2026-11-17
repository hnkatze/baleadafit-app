import 'package:baleadafit/features/planes/ui/generar_plan_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the suggested name of a plan', () {
    test('carries the patient and the moment it was asked for', () {
      expect(
        nombrePorDefecto(
          'María Isabel Hernández Paz',
          DateTime(2026, 11, 16, 14, 35),
        ),
        'María Isabel Hernández Paz_2026-11-16_14:35',
      );
    });

    test('pads the hour and the minute so the name sorts', () {
      expect(
        nombrePorDefecto('Ana', DateTime(2026, 1, 5, 9, 7)),
        'Ana_2026-01-05_09:07',
      );
    });

    test('falls back to the moment when the patient has no name yet', () {
      expect(
        nombrePorDefecto(null, DateTime(2026, 11, 16, 14, 35)),
        'Plan 2026-11-16_14:35',
      );
      expect(
        nombrePorDefecto('   ', DateTime(2026, 11, 16, 14, 35)),
        'Plan 2026-11-16_14:35',
      );
    });

    test('never exceeds the 120 characters the contract allows', () {
      final largo = 'María ' * 40;

      final nombre = nombrePorDefecto(largo, DateTime(2026, 11, 16, 14, 35));

      expect(nombre.length, lessThanOrEqualTo(120));
      // The patient gives up the room, never the timestamp: that is what keeps
      // two plans of the same patient apart.
      expect(nombre, endsWith('_2026-11-16_14:35'));
      expect(nombre.trim(), nombre);
    });
  });
}
