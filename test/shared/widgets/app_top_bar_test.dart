import 'package:baleadafit/shared/widgets/app_top_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTopBar.initialsOf', () {
    test('uses the first and last name', () {
      expect(AppTopBar.initialsOf('Camilo Henriquez'), 'CH');
    });

    test('skips honorifics', () {
      expect(AppTopBar.initialsOf('Lic. Camilo Henriquez'), 'CH');
      expect(AppTopBar.initialsOf('Dra. Ana Sofía Mejía'), 'AM');
    });

    test('falls back to one letter or a placeholder', () {
      expect(AppTopBar.initialsOf('Camilo'), 'C');
      expect(AppTopBar.initialsOf('   '), '?');
    });
  });
}
