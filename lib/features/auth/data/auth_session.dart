import 'user_role.dart';

/// Authenticated session read from `GET /auth/me`.
///
/// Only the fields the app uses today are modeled; [perfil] keeps the raw
/// payload so feature screens can read their own fields without a second call.
class AuthSession {
  const AuthSession({required this.rol, this.displayName, this.perfil});

  final UserRole rol;

  /// Name to greet the user with, when the profile has one.
  final String? displayName;

  /// Raw `perfil` object: nutritionist or patient record, null without profile.
  final Map<String, dynamic>? perfil;

  /// Parses the `data` object of `GET /auth/me`.
  factory AuthSession.fromMeData(Map<String, dynamic> data) {
    final rol = data['rol'];
    if (rol is! String) {
      throw const FormatException('GET /auth/me returned no rol');
    }

    final perfil = data['perfil'];
    final perfilMap = perfil is Map ? Map<String, dynamic>.from(perfil) : null;
    final nombre = perfilMap?['nombre'];

    return AuthSession(
      rol: UserRole.parse(rol),
      displayName: nombre is String ? nombre : null,
      perfil: perfilMap,
    );
  }
}
