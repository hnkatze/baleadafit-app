import 'package:baleadafit/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Env', () {
    tearDown(() => Env.loadFromJson('{}'));

    test('reads the configured environment name', () {
      Env.loadFromJson('{"APP_ENV": "prod"}');

      expect(Env.environment, 'prod');
    });

    test('falls back to dev when the environment is not set', () {
      Env.loadFromJson('{}');

      expect(Env.environment, 'dev');
    });

    test('exposes the API base URL when it is configured', () {
      Env.loadFromJson('{"API_BASE_URL": "https://api.example.test"}');

      expect(Env.hasApiBaseUrl, isTrue);
      expect(Env.apiBaseUrl, 'https://api.example.test');
    });

    test('reports an empty API base URL instead of returning a blank string', () {
      Env.loadFromJson('{"API_BASE_URL": ""}');

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

    test('rejects a configuration that is not a flat JSON object', () {
      expect(
        () => Env.loadFromJson('[1, 2, 3]'),
        throwsA(isA<EnvException>()),
      );
    });

    testWidgets('loads the config/env.json asset shipped with the app', (
      tester,
    ) async {
      await Env.load();

      expect(Env.environment, isNotEmpty);
    });
  });
}
