import 'package:baleadafit/features/auth/application/session_controller.dart';
import 'package:baleadafit/features/auth/data/auth_failure.dart';
import 'package:baleadafit/features/auth/data/auth_gateway.dart';
import 'package:baleadafit/features/auth/data/auth_providers.dart';
import 'package:baleadafit/features/auth/data/user_role.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

class _FakeGateway implements AuthGateway {
  _FakeGateway({this.token = 'token-1', this.signInError});

  String? token;
  Object? signInError;

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
  Future<void> signOut() async {}

  @override
  Future<String?> idToken({bool forceRefresh = false}) async => token;
}

Map<String, Object?> _me(String rol, {Map<String, Object?>? perfil}) => {
  'ok': true,
  'data': {'rol': rol, 'perfil': perfil},
};

ProviderContainer _container({
  required _FakeGateway gateway,
  required FakeHttpAdapter adapter,
}) {
  final container = ProviderContainer(
    overrides: [
      authGatewayProvider.overrideWithValue(gateway),
      dioProvider.overrideWithValue(dioWith(adapter)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('restore reads the session of a user already signed in', () async {
    final container = _container(
      gateway: _FakeGateway(),
      adapter: FakeHttpAdapter(
        (_) async => jsonBody(_me('paciente', perfil: {'nombre': 'Ana'})),
      ),
    );

    await container.read(sessionControllerProvider.notifier).restore();

    final state = container.read(sessionControllerProvider);
    expect(state.status, SessionStatus.authenticated);
    expect(state.session?.rol, UserRole.paciente);
    expect(state.session?.displayName, 'Ana');
  });

  test('restore leaves the app signed out when there is no session', () async {
    final container = _container(
      gateway: _FakeGateway(token: null),
      adapter: FakeHttpAdapter((_) async => jsonBody(_me('paciente'))),
    );

    await container.read(sessionControllerProvider.notifier).restore();

    expect(container.read(sessionControllerProvider).status,
        SessionStatus.unauthenticated);
    expect(container.read(sessionControllerProvider).session, isNull);
  });

  test('restore survives a misconfigured build instead of crashing', () async {
    final container = ProviderContainer(
      overrides: [
        authGatewayProvider.overrideWith(
          (ref) => throw StateError('Firebase is not initialized'),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionControllerProvider.notifier).restore();

    expect(container.read(sessionControllerProvider).status,
        SessionStatus.unauthenticated);
  });

  test('a successful sign-in stores the session', () async {
    final container = _container(
      gateway: _FakeGateway(),
      adapter: FakeHttpAdapter(
        (_) async => jsonBody(_me('nutricionista', perfil: {'nombre': 'Sofía'})),
      ),
    );

    await container
        .read(sessionControllerProvider.notifier)
        .signInWithEmail(email: 'sofia@demo.hn', password: 'secreta');

    final state = container.read(sessionControllerProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.session?.rol, UserRole.nutricionista);
  });

  test('a failed sign-in rethrows and leaves the state untouched', () async {
    final container = _container(
      gateway: _FakeGateway(
        signInError: FirebaseAuthException(code: 'wrong-password'),
      ),
      adapter: FakeHttpAdapter((_) async => jsonBody(_me('nutricionista'))),
    );

    await expectLater(
      container
          .read(sessionControllerProvider.notifier)
          .signInWithEmail(email: 'sofia@demo.hn', password: 'mala'),
      throwsA(isA<InvalidCredentialsFailure>()),
    );
    expect(container.read(sessionControllerProvider).status,
        SessionStatus.unknown);
  });

  test('sign-out drops the session', () async {
    final container = _container(
      gateway: _FakeGateway(),
      adapter: FakeHttpAdapter((_) async => jsonBody(_me('paciente'))),
    );
    await container.read(sessionControllerProvider.notifier).restore();

    await container.read(sessionControllerProvider.notifier).signOut();

    expect(container.read(sessionControllerProvider).status,
        SessionStatus.unauthenticated);
  });
}
