import 'package:baleadafit/shared/widgets/app_sections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sectionLabelFor', () {
    test('names the section of its own route', () {
      expect(sectionLabelFor('/pacientes'), 'Pacientes');
      expect(sectionLabelFor('/home'), 'Inicio');
    });

    test('keeps naming the section on a child route', () {
      // `/pacientes/:id` is the patient file: still the Pacientes section, so
      // the top bar must not fall back to the product name.
      expect(sectionLabelFor('/pacientes/0d1f3c2a'), 'Pacientes');
      expect(sectionLabelFor('/dietas/plan-9'), 'Diseñador de dietas');
    });

    test('does not match a route that only shares a prefix', () {
      expect(sectionLabelFor('/pacientes-archivados'), 'BaleadaFit');
    });

    test('falls back to the product name outside the navigation', () {
      expect(sectionLabelFor('/login'), 'BaleadaFit');
    });
  });
}
