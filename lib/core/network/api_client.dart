import 'package:dio/dio.dart';

import 'api_failure.dart';
import 'paged.dart';

/// Thin wrapper over [Dio] that speaks the BaleadaFit envelope.
///
/// The API wraps every success in `{ok: true, data: …}` and every failure in
/// `{ok: false, error: {…}}`. Callers ask for a path and the type they expect;
/// they get that value or an [ApiFailure], never a raw Dio error.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  /// Exposes the underlying client for callers that need something other than a
  /// JSON GET (uploads, streams).
  Dio get dio => _dio;

  /// GET [path] and decode its `data` with [fromJson].
  ///
  /// [bearerToken] is passed when the caller already holds a token issued in
  /// this same flow, instead of the one the interceptor caches.
  Future<T> get<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    String? bearerToken,
  }) async {
    final Response<Object?> response;
    try {
      response = await _dio.get<Object?>(
        path,
        options: bearerToken == null
            ? null
            : Options(headers: {'Authorization': 'Bearer $bearerToken'}),
      );
    } on DioException catch (exception) {
      throw ApiFailure.fromDio(exception);
    }
    return _decode(response, fromJson);
  }

  /// GET [path] for a list payload, keeping the pagination [PageMeta].
  ///
  /// List endpoints answer `{ok: true, data: [...], meta: {...}}`, so the
  /// envelope handling differs from [get] only in the shape of `data`.
  Future<Paged<T>> getPaged<T>(
    String path, {
    required T Function(Map<String, dynamic> json) itemFromJson,
    Map<String, Object?>? query,
    String? bearerToken,
  }) async {
    final Response<Object?> response;
    try {
      response = await _dio.get<Object?>(
        path,
        queryParameters: query,
        options: bearerToken == null
            ? null
            : Options(headers: {'Authorization': 'Bearer $bearerToken'}),
      );
    } on DioException catch (exception) {
      throw ApiFailure.fromDio(exception);
    }

    final envelope = _envelope(response.data, response.statusCode);
    final data = envelope['data'];
    if (data is! List) {
      throw ApiFailure.unexpectedBody(statusCode: response.statusCode);
    }

    try {
      return Paged(
        items: data
            .cast<Map<String, dynamic>>()
            .map(itemFromJson)
            .toList(growable: false),
        meta: PageMeta.fromJson(
          (envelope['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      );
    } on TypeError {
      throw ApiFailure.unexpectedBody(statusCode: response.statusCode);
    }
  }

  T _decode<T>(
    Response<Object?> response,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final data = _unwrap(response.data, response.statusCode);
    try {
      return fromJson(data);
    } on TypeError {
      // The payload does not have the shape the caller expects: report it as a
      // typed API failure instead of letting a cast error reach the UI.
      throw ApiFailure.unexpectedBody(statusCode: response.statusCode);
    }
  }

  Map<String, dynamic> _unwrap(Object? body, int? statusCode) {
    final envelope = _envelope(body, statusCode);
    final data = envelope['data'];
    if (data is! Map) throw ApiFailure.unexpectedBody(statusCode: statusCode);
    return Map<String, dynamic>.from(data);
  }

  /// The `{ok, data|error}` wrapper, verified and mapped to a map.
  Map<String, dynamic> _envelope(Object? body, int? statusCode) {
    if (body is! Map) throw ApiFailure.unexpectedBody(statusCode: statusCode);

    final envelope = Map<String, dynamic>.from(body);
    if (envelope['ok'] != true) {
      throw ApiFailure.fromEnvelope(envelope, statusCode: statusCode);
    }
    return envelope;
  }
}
