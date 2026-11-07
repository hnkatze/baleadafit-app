import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_failure.dart';
import '../data/auth_providers.dart';
import '../data/auth_session.dart';

/// Where the app stands regarding the signed-in user.
enum SessionStatus {
  /// A restore is in flight; the router does not move yet.
  unknown,
  unauthenticated,
  authenticated,
}

/// Session as the UI needs it: a status plus the API session when there is one.
@immutable
class SessionState {
  const SessionState({this.status = SessionStatus.unknown, this.session});

  final SessionStatus status;
  final AuthSession? session;

  bool get isAuthenticated => status == SessionStatus.authenticated;

  @override
  bool operator ==(Object other) =>
      other is SessionState &&
      other.status == status &&
      other.session?.rol == session?.rol &&
      other.session?.displayName == session?.displayName;

  @override
  int get hashCode => Object.hash(status, session?.rol, session?.displayName);
}

/// Owns the session: sign-in, restore and sign-out.
///
/// Sign-in failures are rethrown as [AuthFailure] so the screen can show the
/// message, and they never change the state: a failed attempt leaves the app
/// where it was.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState();

  /// Reads the session of a user who is already signed in with Firebase.
  ///
  /// Any failure leaves the app signed out: a broken build (missing API base
  /// URL, Firebase not initialized) must still reach the login form.
  Future<void> restore() async {
    try {
      final session = await ref.read(authRepositoryProvider).currentSession();
      state = SessionState(
        status: SessionStatus.authenticated,
        session: session,
      );
    } on Object {
      state = const SessionState(status: SessionStatus.unauthenticated);
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final session = await ref
        .read(authRepositoryProvider)
        .signInWithEmail(email: email, password: password);
    state = SessionState(status: SessionStatus.authenticated, session: session);
  }

  /// Cancelling the Google sheet leaves the state untouched.
  Future<void> signInWithGoogle() async {
    try {
      final session = await ref.read(authRepositoryProvider).signInWithGoogle();
      state = SessionState(
        status: SessionStatus.authenticated,
        session: session,
      );
    } on SignInCancelledFailure {
      return;
    }
  }

  Future<void> signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on Object {
      // The session is dropped locally even when the provider call fails:
      // leaving the app in an authenticated state would be worse.
    }
    state = const SessionState(status: SessionStatus.unauthenticated);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
