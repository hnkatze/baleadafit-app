import 'package:baleadafit/features/auth/data/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses every wire value the API documents', () {
    expect(UserRole.parse('nutricionista'), UserRole.nutricionista);
    expect(UserRole.parse('paciente'), UserRole.paciente);
    expect(UserRole.parse('sin_perfil'), UserRole.sinPerfil);
  });

  test('throws on an unknown wire value instead of guessing', () {
    expect(() => UserRole.parse('admin'), throwsArgumentError);
  });

  test('knows which roles have a profile', () {
    expect(UserRole.nutricionista.hasProfile, isTrue);
    expect(UserRole.paciente.hasProfile, isTrue);
    expect(UserRole.sinPerfil.hasProfile, isFalse);
  });
}
