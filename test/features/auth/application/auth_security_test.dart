import 'package:baleadafit/core/network/auth_interceptor.dart';
import 'package:baleadafit/features/auth/application/session_controller.dart';
import 'package:baleadafit/features/auth/data/auth_failure.dart';
import 'package:baleadafit/features/auth/data/auth_gateway.dart';
import 'package:baleadafit/features/auth/data/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

class _Tokens implements TokenSource {
  _Tokens(this.token);

  String? token;

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    if (token == null) return null;
    return forceRefresh ? 'FRESH' : 'CACHED';
  }
}

class _Gateway implements AuthGateway {
  _Gateway(this.tokens);

  final _Tokens tokens;
  int signOuts = 0;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {
    signOuts++;
    tokens.token = null;
  }

  @override
  Future<String?> idToken({bool forceRefresh = false}) =>
      tokens.idToken(forceRefresh: forceRefresh);
}

ProviderContainer _container(_Gateway gateway, _Tokens tokens, FakeHttpAdapter adapter) {
  final dio = dioWith(adapter)
    ..interceptors.add(AuthInterceptor(tokens, baseUrl: 'https://api.test'));
  final container = ProviderContainer(
    overrides: [
      authGatewayProvider.overrideWithValue(gateway),
      tokenSourceProvider.overrideWithValue(tokens),
      dioProvider.overrideWithValue(dio),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

FakeHttpAdapter _ok(String rol) =>
    FakeHttpAdapter((_) async => jsonBody({
      'ok': true,
      'data': {'rol': rol},
    }));

void main() {
  test('sign-in sends /auth/me with the freshly issued token', () async {
    final tokens = _Tokens('old');
    final adapter = _ok('nutricionista');

    await _container(_Gateway(tokens), tokens, adapter)
        .read(sessionControllerProvider.notifier)
        .signInWithEmail(email: 'a@b.hn', password: 'secreta');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer FRESH');
  });

  test('a failed /auth/me signs the provider out again', () async {
    final tokens = _Tokens('t');
    final gateway = _Gateway(tokens);
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({
        'ok': false,
        'error': {'codigo': 'ERROR', 'mensaje': 'boom'},
      }, status: 500),
    );

    await expectLater(
      _container(gateway, tokens, adapter)
          .read(sessionControllerProvider.notifier)
          .signInWithEmail(email: 'a@b.hn', password: 'secreta'),
      throwsA(isA<AuthFailure>()),
    );
    expect(gateway.signOuts, 1);
  });

  test('an unknown role is a typed failure, not a raw ArgumentError', () async {
    final tokens = _Tokens('t');

    await expectLater(
      _container(_Gateway(tokens), tokens, _ok('admin_super'))
          .read(sessionControllerProvider.notifier)
          .signInWithEmail(email: 'a@b.hn', password: 'secreta'),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('the bearer header never leaves the API origin', () async {
    final tokens = _Tokens('secret');
    final adapter = _ok('paciente');
    final dio = dioWith(adapter)
      ..interceptors.add(AuthInterceptor(tokens, baseUrl: 'https://api.test'));

    await dio.get<Object?>('https://attacker.example/collect');

    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('no header once the token source is empty', () async {
    final tokens = _Tokens('secret');
    final adapter = _ok('paciente');
    final dio = dioWith(adapter)
      ..interceptors.add(AuthInterceptor(tokens, baseUrl: 'https://api.test'));

    await dio.get<Object?>('/auth/me');
    tokens.token = null;
    await dio.get<Object?>('/auth/me');

    expect(adapter.requests.last.headers.containsKey('Authorization'), isFalse);
  });
}
