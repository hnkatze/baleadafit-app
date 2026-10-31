import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Per-environment configuration loaded from `config/env.json`.
///
/// The file is a versioned asset with no secrets in it: it only holds the
/// public API base URL and the environment name. Call [load] once, before
/// `runApp`; values are read lazily so a missing key fails where it is used.
abstract final class Env {
  static const String assetPath = 'config/env.json';
  static const String apiBaseUrlKey = 'API_BASE_URL';
  static const String environmentKey = 'APP_ENV';

  static Map<String, String> _values = const {};

  /// Reads [asset] and makes its values available to the getters below.
  ///
  /// A missing asset is surfaced as an [EnvException] instead of a bare
  /// asset-bundle error, so startup failures name the real problem.
  static Future<void> load({AssetBundle? bundle, String asset = assetPath}) async {
    try {
      final source = await (bundle ?? rootBundle).loadString(asset);
      loadFromJson(source);
    } on Object catch (error) {
      throw EnvException('Could not read $asset: $error');
    }
  }

  /// Parses a flat JSON object of string values. Exposed for tests and for
  /// callers that already hold the configuration in memory.
  @visibleForTesting
  static void loadFromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const EnvException('Configuration must be a flat JSON object.');
    }

    _values = {
      for (final entry in decoded.entries) entry.key: '${entry.value}',
    };
  }

  /// Current environment name, `dev` unless the file says otherwise.
  static String get environment =>
      _value(environmentKey) ?? 'dev';

  /// True when a base URL was configured, so callers can decide to stay offline.
  static bool get hasApiBaseUrl => (_value(apiBaseUrlKey) ?? '').isNotEmpty;

  /// Base URL of the BaleadaFit API, without a trailing slash.
  static String get apiBaseUrl {
    final value = _value(apiBaseUrlKey);
    if (value == null || value.isEmpty) {
      throw const EnvException(
        '$apiBaseUrlKey is empty. Fill it in $assetPath.',
      );
    }
    return value;
  }

  static String? _value(String key) => _values[key];
}

/// Thrown when the configuration is missing, unreadable or incomplete.
class EnvException implements Exception {
  const EnvException(this.message);

  final String message;

  @override
  String toString() => 'EnvException: $message';
}
