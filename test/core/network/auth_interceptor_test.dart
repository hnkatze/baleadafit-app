import 'package:baleadafit/core/network/auth_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_adapter.dart';

class _FakeTokenSource implements TokenSource {
  _FakeTokenSource(this.token);

  final String? token;
  int calls = 0;

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    calls++;
    return token;
  }
}

void main() {
  test('adds the bearer header when a token exists', () async {
    final adapter = FakeHttpAdapter((_) async => jsonBody({'ok': true}));
    final dio = dioWith(adapter);
    dio.interceptors.add(AuthInterceptor(_FakeTokenSource('token-123')));

    await dio.get<Object?>('/auth/me');

    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer token-123',
    );
  });

  test('omits the header when nobody is signed in', () async {
    final source = _FakeTokenSource(null);
    final adapter = FakeHttpAdapter((_) async => jsonBody({'ok': true}));
    final dio = dioWith(adapter);
    dio.interceptors.add(AuthInterceptor(source));

    await dio.get<Object?>('/auth/me');

    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    expect(source.calls, 1);
  });
}
