import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/network/auth_interceptor.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The identity operations the app needs, behind an interface.
///
/// The Firebase/Google plugins are plugin calls that cannot run in a widget
/// test, so [AuthRepository] depends on this interface and the production
/// implementation stays a thin, untested adapter.
abstract interface class AuthGateway implements TokenSource {
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  /// Opens the Google sheet and signs the account into Firebase.
  ///
  /// Throws [GoogleSignInException] with a cancellation code when the user
  /// closes the sheet.
  Future<void> signInWithGoogle();

  Future<void> signOut();

  @override
  Future<String?> idToken({bool forceRefresh = false});
}

/// [AuthGateway] backed by Firebase Auth and Google Sign-In.
class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway(this._auth, {this.googleServerClientId});

  final FirebaseAuth _auth;

  /// Web client id of the Firebase project: Android needs it to receive an
  /// idToken from Google. Null on platforms that read it from their config file.
  final String? googleServerClientId;

  bool _googleReady = false;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      final serverClientId = googleServerClientId;
      await google.initialize(
        serverClientId: serverClientId == null || serverClientId.isEmpty
            ? null
            : serverClientId,
      );
      _googleReady = true;
    }

    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google did not return an idToken for this account.',
      );
    }

    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } on Object {
      // Not signed in through Google, or the plugin is not initialized:
      // Firebase sign-out below is what ends the session.
    }
    await _auth.signOut();
  }

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }
}
