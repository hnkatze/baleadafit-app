import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/features/auth/data/auth_failure.dart';
import 'package:baleadafit/features/auth/data/auth_gateway.dart';
import 'package:baleadafit/features/auth/data/auth_repository.dart';
import 'package:baleadafit/features/auth/data/user_role.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

class _FakeGateway implements AuthGateway {
  _FakeGateway({this.token = 'token-1', this.signInError});

  String? token;
  Object? signInError;
  int signedOut = 0;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (signInError != null) throw signInError!;
  }

  @override
  Future<void> signInWithGoogle() async {
    if (signInError != null) throw signInError!;
  }

  @override
  Future<void> signOut() async => signedOut++;

  @override
  Future<String?> idToken({bool forceRefresh = false}) async => token;
}

AuthRepository _repository({
  required _FakeGateway gateway,
  required FakeHttpAdapter adapter,
}) {
  return AuthRepository(gateway, ApiClient(dioWith(adapter)));
}

Map<String, Object?> meEnvelope({
  required String rol,
  Map<String, Object?>? perfil,
}) {
  return {
    'ok': true,
    'data': {'rol': rol, 'perfil': perfil},
  };
}

void main() {
  group('signInWithEmail', () {
    test('returns the session the API reports', () async {
      final gateway = _FakeGateway();
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody(
          meEnvelope(
            rol: 'nutricionista',
            perfil: {'nombre': 'Sofía Herrera', 'correo': 'sofia@demo.hn'},
          ),
        ),
      );

      final session = await _repository(
        gateway: gateway,
        adapter: adapter,
      ).signInWithEmail(email: ' sofia@demo.hn ', password: 'secreta');

      expect(session.rol, UserRole.nutricionista);
      expect(session.displayName, 'Sofía Herrera');
      expect(session.perfil?['correo'], 'sofia@demo.hn');
    });

    test('maps a 401 from the API to an unauthenticated failure', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody({
          'ok': false,
          'error': {
            'codigo': 'NO_AUTENTICADO',
            'mensaje': 'Token inválido o expirado.',
          },
        }, status: 401),
      );

      await expectLater(
        _repository(gateway: _FakeGateway(), adapter: adapter).signInWithEmail(
          email: 'a@b.hn',
          password: 'x',
        ),
        throwsA(
          isA<UnauthenticatedFailure>().having(
            (f) => f.mensaje,
            'mensaje',
            'Tu sesión venció. Iniciá sesión otra vez.',
          ),
        ),
      );
    });

    test('maps a wrong password to invalid credentials', () async {
      final adapter = FakeHttpAdapter((_) async => jsonBody(meEnvelope(rol: 'paciente')));
      final gateway = _FakeGateway(
        signInError: FirebaseAuthException(code: 'wrong-password'),
      );

      await expectLater(
        _repository(gateway: gateway, adapter: adapter).signInWithEmail(
          email: 'a@b.hn',
          password: 'mala',
        ),
        throwsA(
          isA<InvalidCredentialsFailure>().having(
            (f) => f.mensaje,
            'mensaje',
            'El correo o la contraseña no son correctos.',
          ),
        ),
      );
    });

    test('accepts sin_perfil as a valid role', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody(meEnvelope(rol: 'sin_perfil')),
      );

      final session = await _repository(
        gateway: _FakeGateway(),
        adapter: adapter,
      ).signInWithEmail(email: 'a@b.hn', password: 'x');

      expect(session.rol, UserRole.sinPerfil);
      expect(session.displayName, isNull);
    });

    test('does not call the API when the provider fails', () async {
      final adapter = FakeHttpAdapter((_) async => jsonBody(meEnvelope(rol: 'paciente')));
      final gateway = _FakeGateway(signInError: StateError('boom'));

      await expectLater(
        _repository(gateway: gateway, adapter: adapter).signInWithEmail(
          email: 'a@b.hn',
          password: 'x',
        ),
        throwsA(isA<UnknownAuthFailure>()),
      );
      expect(adapter.requests, isEmpty);
    });
  });

  group('signInWithGoogle', () {
    test('treats a closed sheet as a cancellation, not an error message', () async {
      final adapter = FakeHttpAdapter((_) async => jsonBody(meEnvelope(rol: 'paciente')));
      final gateway = _FakeGateway(
        signInError: GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        ),
      );

      await expectLater(
        _repository(gateway: gateway, adapter: adapter).signInWithGoogle(),
        throwsA(isA<SignInCancelledFailure>()),
      );
    });
  });

  group('currentSession', () {
    test('fails as unauthenticated without a token', () async {
      final adapter = FakeHttpAdapter((_) async => jsonBody(meEnvelope(rol: 'paciente')));

      await expectLater(
        _repository(
          gateway: _FakeGateway(token: null),
          adapter: adapter,
        ).currentSession(),
        throwsA(isA<UnauthenticatedFailure>()),
      );
      expect(adapter.requests, isEmpty);
    });

    test('reads /auth/me with the current token', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody(meEnvelope(rol: 'paciente', perfil: {'nombre': 'Ana'})),
      );

      final session = await _repository(
        gateway: _FakeGateway(),
        adapter: adapter,
      ).currentSession();

      expect(session.rol, UserRole.paciente);
      expect(session.displayName, 'Ana');
      expect(adapter.requests.single.path, '/auth/me');
    });
  });

  test('signOut delegates to the gateway', () async {
    final gateway = _FakeGateway();
    final adapter = FakeHttpAdapter((_) async => jsonBody(meEnvelope(rol: 'paciente')));

    await _repository(gateway: gateway, adapter: adapter).signOut();

    expect(gateway.signedOut, 1);
  });
}
