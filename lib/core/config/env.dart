import 'package:flutter/foundation.dart';

/// Build-time configuration injected with `--dart-define-from-file`.
///
/// Values are compile-time constants (`String.fromEnvironment`), so they are
/// baked into the binary and there is nothing to load before `runApp`. A
/// missing define yields an empty string silently, which is why every command
/// in the `Makefile` passes the env file explicitly.
///
/// Local files (`config/env.dev.json`, ...) are git-ignored; the tracked
/// template is `config/env.example.json`.
abstract final class Env {
  static const String apiBaseUrlKey = 'API_BASE_URL';
  static const String environmentKey = 'APP_ENV';

  /// Web client id of the Firebase project, needed by Google Sign-In on Android.
  static const String googleServerClientIdKey = 'GOOGLE_SERVER_CLIENT_ID';

  static const String exampleFile = 'config/env.example.json';
  static const String devFile = 'config/env.dev.json';

  static const String _definedApiBaseUrl = String.fromEnvironment(apiBaseUrlKey);
  static const String _definedEnvironment = String.fromEnvironment(
    environmentKey,
  );
  static const String _definedGoogleServerClientId = String.fromEnvironment(
    googleServerClientIdKey,
  );

  static String? _apiBaseUrlOverride;
  static String? _environmentOverride;
  static String? _googleServerClientIdOverride;

  /// Current environment name, `dev` when [environmentKey] is not defined.
  static String get environment {
    final value = _environmentOverride ?? _definedEnvironment;
    return value.isEmpty ? 'dev' : value;
  }

  /// True when a base URL was configured, so callers can decide to stay offline.
  static bool get hasApiBaseUrl => _apiBaseUrl.isNotEmpty;

  /// Base URL of the BaleadaFit API, without a trailing slash.
  static String get apiBaseUrl {
    final value = _apiBaseUrl;
    if (value.isEmpty) {
      throw const EnvException(
        '$apiBaseUrlKey is empty. Run Flutter with '
        '--dart-define-from-file=$devFile (copy $exampleFile first).',
      );
    }
    return value;
  }

  static String get _apiBaseUrl => _apiBaseUrlOverride ?? _definedApiBaseUrl;

  /// Google OAuth client id, or null when the platform reads it from its own
  /// configuration file.
  static String? get googleServerClientId {
    final value = _googleServerClientIdOverride ?? _definedGoogleServerClientId;
    return value.isEmpty ? null : value;
  }

  /// Replaces the build-time values. Exposed so tests can cover both the
  /// configured and the missing case without rebuilding the binary.
  @visibleForTesting
  static void override({
    String? apiBaseUrl,
    String? environment,
    String? googleServerClientId,
  }) {
    _apiBaseUrlOverride = apiBaseUrl;
    _environmentOverride = environment;
    _googleServerClientIdOverride = googleServerClientId;
  }

  /// Drops every [override] and goes back to the values baked at build time.
  @visibleForTesting
  static void resetOverride() {
    _apiBaseUrlOverride = null;
    _environmentOverride = null;
    _googleServerClientIdOverride = null;
  }
}

/// Thrown when the configuration is missing or incomplete.
class EnvException implements Exception {
  const EnvException(this.message);

  final String message;

  @override
  String toString() => 'EnvException: $message';
}
