import 'package:dio/dio.dart';

import 'api_failure.dart';

/// Thin wrapper over [Dio] that speaks the BaleadaFit envelope.
///
/// The API wraps every success in `{ok: true, data: …}` and every failure in
/// `{ok: false, error: {…}}`. Callers get the payload or an [ApiFailure]; they
/// never see raw Dio errors.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  /// Exposes the underlying client for tests and for callers that need
  /// something other than a JSON GET (uploads, streams).
  Dio get dio => _dio;

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _dio.get<Object?>(path);
      return _unwrap(response.data, response.statusCode);
    } on DioException catch (exception) {
      throw ApiFailure.fromDio(exception);
    }
  }

  Map<String, dynamic> _unwrap(Object? body, int? statusCode) {
    if (body is! Map) throw ApiFailure.unexpectedBody(statusCode: statusCode);

    final envelope = Map<String, dynamic>.from(body);
    if (envelope['ok'] != true) {
      throw ApiFailure.fromEnvelope(envelope, statusCode: statusCode);
    }

    final data = envelope['data'];
    if (data is! Map) throw ApiFailure.unexpectedBody(statusCode: statusCode);
    return Map<String, dynamic>.from(data);
  }
}
