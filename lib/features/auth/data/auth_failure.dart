/// Failure the login screen can show without inspecting any other type.
///
/// Each variant carries a Spanish [mensaje] ready to render, so the screen has
/// no message table of its own and the wording stays in one place.
sealed class AuthFailure implements Exception {
  const AuthFailure(this.mensaje);

  final String mensaje;
}

/// Wrong email or password.
class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure()
    : super('El correo o la contraseña no son correctos.');
}

/// The device could not reach the API.
class NetworkFailure extends AuthFailure {
  const NetworkFailure()
    : super('No pudimos conectar con el servidor. Revisá tu conexión.');
}

/// No valid session: the API answered 401.
class UnauthenticatedFailure extends AuthFailure {
  const UnauthenticatedFailure()
    : super('Tu sesión venció. Iniciá sesión otra vez.');
}

/// Signed in, but not allowed to read the profile.
class ForbiddenFailure extends AuthFailure {
  const ForbiddenFailure() : super('Tu cuenta no tiene acceso a esta app.');
}

/// The user closed the Google sheet; not an error to show.
class SignInCancelledFailure extends AuthFailure {
  const SignInCancelledFailure() : super('Inicio de sesión cancelado.');
}

/// Anything else, keeping the API message when there is one.
class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure([super.mensaje = 'Algo salió mal. Intentá de nuevo.']);
}
