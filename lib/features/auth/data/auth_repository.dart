import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import 'auth_failure.dart';
import 'auth_gateway.dart';
import 'auth_session.dart';

/// Turns an auth provider into an app session.
///
/// Sign-in is provider first, then `GET /auth/me` with a freshly issued token:
/// the API decides the role, the app never guesses it.
class AuthRepository {
  const AuthRepository(this._gateway, this._api);

  final AuthGateway _gateway;
  final ApiClient _api;

  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _signIn(
      () => _gateway.signInWithEmail(email: email, password: password),
    );
  }

  Future<AuthSession> signInWithGoogle() {
    return _signIn(() => _gateway.signInWithGoogle());
  }

  /// Session for whoever is already signed in with Firebase.
  ///
  /// [forceRefresh] should stay true right after a sign-in.
  Future<AuthSession> currentSession({bool forceRefresh = true}) async {
    final String? token;
    try {
      token = await _gateway.idToken(forceRefresh: forceRefresh);
    } on Object catch (error) {
      throw _mapError(error);
    }
    if (token == null) throw const UnauthenticatedFailure();

    try {
      final data = await _api.get('/auth/me');
      return AuthSession.fromMeData(data);
    } on ApiFailure catch (failure) {
      throw _mapApiFailure(failure);
    } on FormatException catch (error) {
      throw UnknownAuthFailure(error.message);
    }
  }

  Future<void> signOut() async {
    try {
      await _gateway.signOut();
    } on Object catch (error) {
      throw _mapError(error);
    }
  }

  Future<AuthSession> _signIn(Future<void> Function() signIn) async {
    try {
      await signIn();
    } on Object catch (error) {
      throw _mapError(error);
    }
    return currentSession();
  }

  AuthFailure _mapApiFailure(ApiFailure failure) {
    if (failure.isUnauthenticated) return const UnauthenticatedFailure();
    if (failure.isForbidden) return const ForbiddenFailure();
    if (failure.statusCode == null) return const NetworkFailure();
    return UnknownAuthFailure(failure.mensaje);
  }

  AuthFailure _mapError(Object error) {
    if (error is AuthFailure) return error;

    if (error is ApiFailure) return _mapApiFailure(error);

    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'invalid-email' ||
        'user-disabled' => const InvalidCredentialsFailure(),
        'network-request-failed' => const NetworkFailure(),
        // The account exists in Google but has no Firebase user yet.
        'account-exists-with-different-credential' => const UnknownAuthFailure(
          'Ese correo ya está registrado con contraseña. Entrá con tu contraseña.',
        ),
        _ => UnknownAuthFailure(error.message ?? 'Algo salió mal. Intentá de nuevo.'),
      };
    }

    if (error is GoogleSignInException) {
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled => const SignInCancelledFailure(),
        GoogleSignInExceptionCode.interrupted ||
        GoogleSignInExceptionCode.uiUnavailable => const UnknownAuthFailure(
          'No pudimos abrir Google. Intentá de nuevo.',
        ),
        _ => const UnknownAuthFailure(),
      };
    }

    return const UnknownAuthFailure();
  }
}
