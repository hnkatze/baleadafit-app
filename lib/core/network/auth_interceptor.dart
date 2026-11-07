import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Where the app gets the bearer token for API calls.
///
/// Abstracted so the API layer can be tested without the Firebase plugin.
abstract interface class TokenSource {
  /// Current token, or null when nobody is signed in.
  ///
  /// [forceRefresh] asks the identity provider for a new token; use it right
  /// after sign-in so the API never receives a token issued before the session.
  Future<String?> idToken({bool forceRefresh = false});
}

/// [TokenSource] backed by the signed-in Firebase user.
class FirebaseTokenSource implements TokenSource {
  const FirebaseTokenSource(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }
}

/// Adds `Authorization: Bearer <token>` to requests aimed at [baseUrl].
///
/// Requests whose origin is not the API origin get no header, so a stray
/// absolute URL can never carry the session token. An already present header
/// wins, which is how a caller sends a freshly issued token.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens, {required String baseUrl})
    : _origin = Uri.parse(baseUrl).origin;

  final TokenSource _tokens;
  final String _origin;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final hasHeader = options.headers.containsKey('Authorization');
    if (hasHeader || options.uri.origin != _origin) {
      return handler.next(options);
    }

    final token = await _tokens.idToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
