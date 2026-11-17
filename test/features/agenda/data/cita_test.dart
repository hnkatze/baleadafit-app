import 'package:baleadafit/features/agenda/data/cita.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cita.fromJson', () {
    test('reads every field the agenda draws', () {
      final cita = Cita.fromJson({
        'id': 'c1',
        'pacienteId': 'p1',
        'nutricionistaId': 'n1',
        'fechaHora': '2026-11-07T15:00:00.000Z',
        'duracionMin': 45,
        'estado': 'PROGRAMADA',
        'motivo': 'Revisión de mediciones',
        'notas': '',
        'paciente': {
          'id': 'p1',
          'nombre': 'Paciente',
          'apellido': 'De Prueba',
          'telefono': '9999-9999',
        },
        'subjetivo': 'Refiere cansancio',
        'objetivo': 'Peso 72.4',
        'analisis': 'Déficit leve',
        'plan': 'Mantener',
        'proximaCitaSugerida': '2026-11-14T00:00:00.000Z',
      });

      expect(cita.id, 'c1');
      expect(cita.estado, EstadoCita.programada);
      expect(cita.duracionMin, 45);
      expect(cita.motivo, 'Revisión de mediciones');
      expect(cita.pacienteNombre, 'Paciente De Prueba');
      expect(cita.paciente?.telefono, '9999-9999');
      expect(cita.subjetivo, 'Refiere cansancio');
      expect(cita.plan, 'Mantener');
      expect(cita.fechaHora, DateTime.utc(2026, 11, 7, 15));
    });

    test('keeps fechaHora as the instant it received', () {
      final cita = Cita.fromJson({
        'id': 'c1',
        'fechaHora': '2026-11-07T15:00:00.000Z',
      });

      expect(cita.fechaHora.isUtc, isTrue);
      expect(cita.fechaHora, DateTime.utc(2026, 11, 7, 15));
    });

    test('reads proximaCitaSugerida from its own fields, never shifted', () {
      final cita = Cita.fromJson({
        'id': 'c1',
        'fechaHora': '2026-11-07T15:00:00.000Z',
        'proximaCitaSugerida': '2026-11-14T00:00:00.000Z',
      });

      expect(cita.proximaCitaSugerida, DateTime.utc(2026, 11, 14));
      expect(cita.proximaCitaIso, '2026-11-14');
    });

    test('defaults duracionMin to 45 when the API omits it', () {
      final cita = Cita.fromJson({
        'id': 'c1',
        'fechaHora': '2026-11-07T15:00:00.000Z',
      });

      expect(cita.duracionMin, 45);
    });

    test('reads an unknown estado as programada instead of failing', () {
      final cita = Cita.fromJson({
        'id': 'c1',
        'fechaHora': '2026-11-07T15:00:00.000Z',
        'estado': 'EN_CURSO',
      });

      expect(cita.estado, EstadoCita.programada);
    });

    test('leaves the nested paciente empty when the API does not send it', () {
      final cita = Cita.fromJson({
        'id': 'c1',
        'fechaHora': '2026-11-07T15:00:00.000Z',
      });

      expect(cita.paciente, isNull);
      expect(cita.pacienteNombre, 'Paciente sin nombre');
    });
  });

  group('Cita display helpers', () {
    final cita = Cita(
      id: 'c1',
      pacienteId: 'p1',
      fechaHora: DateTime(2026, 11, 7, 9, 5),
      duracionMin: 45,
    );

    test('hora reads the instant in local time', () {
      expect(cita.hora, '09:05');
    });

    test('fin is the start plus the duration', () {
      expect(cita.fin, DateTime(2026, 11, 7, 9, 50));
    });
  });
}
