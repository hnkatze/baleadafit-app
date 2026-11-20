import 'package:baleadafit/features/patients/data/paciente_ficha.dart';
import 'package:flutter_test/flutter_test.dart';

/// `situacion.medicacion` is the only source of a patient's medication: the API
/// has no `GET` of medications, so what the ficha brings is what the module has.
void main() {
  group('situacion.medicacion', () {
    test('reads the medication the ficha brings', () {
      final ficha = PacienteFicha.fromJson({
        'paciente': {'id': 'pac-1'},
        'situacion': {
          'medicacion': [
            {
              'id': 'med-1',
              'pacienteId': 'pac-1',
              'nombre': 'Metformina',
              'dosis': '500 mg',
              'frecuencia': 'Cada 12 horas con comida',
              'activo': true,
              'creadoEn': '2026-11-09T15:00:00Z',
            },
            {
              'id': 'med-2',
              'pacienteId': 'pac-1',
              'nombre': 'Ácido fólico',
              'dosis': null,
              'frecuencia': null,
              'activo': true,
              'creadoEn': '2026-11-10T15:00:00Z',
            },
          ],
        },
      });

      expect(ficha.situacion.medicamentos, hasLength(2));

      final metformina = ficha.situacion.medicamentos.first;
      expect(metformina.id, 'med-1');
      expect(metformina.nombre, 'Metformina');
      expect(metformina.dosis, '500 mg');
      expect(metformina.frecuencia, 'Cada 12 horas con comida');
      expect(metformina.activo, isTrue);
      expect(metformina.creadoEn, DateTime.utc(2026, 11, 9, 15));

      // A null stays null: the screen omits it, the model never invents text.
      final folico = ficha.situacion.medicamentos.last;
      expect(folico.dosis, isNull);
      expect(folico.frecuencia, isNull);
    });

    test('accepts an empty list and an absent block', () {
      final vacia = PacienteFicha.fromJson({'situacion': <String, Object?>{}});
      expect(vacia.situacion.medicamentos, isEmpty);
      expect(PacienteFicha.fromJson(const {}).situacion.medicamentos, isEmpty);
    });

    test('skips entries without id or name, and trims what it keeps', () {
      final ficha = PacienteFicha.fromJson({
        'situacion': {
          'medicacion': [
            {'id': 'med-1', 'nombre': '  Losartán  ', 'activo': true},
            {'id': 'med-2', 'activo': true},
            {'nombre': 'Sin id', 'activo': true},
            'basura',
            7,
          ],
        },
      });

      expect(ficha.situacion.medicamentos.map((m) => m.nombre), ['Losartán']);
    });

    test('composicion joins what exists and is null when nothing does', () {
      final ficha = PacienteFicha.fromJson({
        'situacion': {
          'medicacion': [
            {
              'id': 'med-1',
              'nombre': 'Metformina',
              'dosis': '500 mg',
              'frecuencia': 'Cada 12 horas',
            },
            {'id': 'med-2', 'nombre': 'Losartán', 'dosis': '50 mg'},
            {'id': 'med-3', 'nombre': 'Ácido fólico', 'dosis': '   '},
          ],
        },
      });

      final medicamentos = ficha.situacion.medicamentos;
      expect(medicamentos[0].composicion, '500 mg · Cada 12 horas');
      expect(medicamentos[1].composicion, '50 mg');
      // Neither datum: the list draws no second line, never "—" nor "null".
      expect(medicamentos[2].composicion, isNull);
    });
  });
}
