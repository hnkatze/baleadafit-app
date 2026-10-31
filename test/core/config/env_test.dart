import 'package:baleadafit/core/config/env.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Env', () {
    tearDown(Env.resetOverride);

    test('falls back to dev when no environment name is defined', () {
      Env.override(environment: '');

      expect(Env.environment, 'dev');
    });

    test('reads the environment name injected at build time', () {
      Env.override(environment: 'pro');

      expect(Env.environment, 'pro');
    });

    test('exposes the API base URL when it is defined', () {
      Env.override(apiBaseUrl: 'https://api.example.test');

      expect(Env.hasApiBaseUrl, isTrue);
      expect(Env.apiBaseUrl, 'https://api.example.test');
    });

    test('reports an empty API base URL instead of returning a blank string', () {
      Env.override(apiBaseUrl: '');

      expect(Env.hasApiBaseUrl, isFalse);
      expect(
        () => Env.apiBaseUrl,
        throwsA(
          isA<EnvException>().having(
            (error) => error.message,
            'message',
            contains('API_BASE_URL'),
          ),
        ),
      );
    });

    test('does not ship the configuration as a bundled asset', () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

      expect(manifest.listAssets(), isNot(contains('config/env.json')));
    });
  });

  group('Env with --dart-define values', () {
    const hasDefine = bool.hasEnvironment('API_BASE_URL');

    test('reads the value passed with --dart-define', () {
      expect(Env.apiBaseUrl, const String.fromEnvironment('API_BASE_URL'));
    }, skip: hasDefine ? false : 'run through `make test-defines`');
  });
}
