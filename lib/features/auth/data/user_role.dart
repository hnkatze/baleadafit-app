/// Role the API assigns to the signed-in user, as returned by `GET /auth/me`.
///
/// The wire strings are part of the API contract; an unknown value is a bug or
/// an API change, so parsing throws instead of silently defaulting.
enum UserRole {
  nutricionista('nutricionista'),
  paciente('paciente'),
  sinPerfil('sin_perfil');

  const UserRole(this.wireValue);

  final String wireValue;

  static UserRole parse(String wireValue) {
    for (final role in UserRole.values) {
      if (role.wireValue == wireValue) return role;
    }
    throw ArgumentError.value(wireValue, 'wireValue', 'Unknown user role');
  }

  /// True when the account has a profile the app can show.
  bool get hasProfile => this != UserRole.sinPerfil;
}
