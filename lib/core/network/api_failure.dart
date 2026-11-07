import 'package:dio/dio.dart';

/// Failure raised by [ApiClient] when the API does not answer with `ok: true`.
///
/// The API envelope is `{ok: true, data: …}` on success and
/// `{ok: false, error: {codigo, mensaje, detalles?}}` on failure, so every
/// failure carries a stable `codigo` the app can branch on plus a Spanish
/// message that is safe to show as-is.
class ApiFailure implements Exception {
  const ApiFailure({
    required this.mensaje,
    this.codigo,
    this.statusCode,
    this.detalles,
  });

  /// Message coming from the API, already written for the user.
  final String mensaje;

  /// Stable failure code, e.g. `NO_AUTENTICADO`.
  final String? codigo;

  /// HTTP status, when there was a response at all.
  final int? statusCode;

  /// Field errors, present only on validation failures.
  final List<Object?>? detalles;

  bool get isUnauthenticated => statusCode == 401 || codigo == 'NO_AUTENTICADO';

  bool get isForbidden => statusCode == 403 || codigo == 'SIN_PERMISO';

  /// Builds a failure from the API error envelope.
  factory ApiFailure.fromEnvelope(
    Map<String, dynamic> body, {
    int? statusCode,
  }) {
    final error = body['error'];
    if (error is Map) {
      final detalles = error['detalles'];
      return ApiFailure(
        mensaje: error['mensaje'] is String
            ? error['mensaje'] as String
            : _fallbackMessage(statusCode),
        codigo: error['codigo'] is String ? error['codigo'] as String : null,
        statusCode: statusCode,
        detalles: detalles is List ? detalles : null,
      );
    }
    return ApiFailure(
      mensaje: _fallbackMessage(statusCode),
      statusCode: statusCode,
    );
  }

  /// Maps a transport-level Dio error (no usable envelope) to a failure.
  factory ApiFailure.fromDio(DioException exception) {
    final response = exception.response;
    final data = response?.data;
    if (data is Map) {
      return ApiFailure.fromEnvelope(
        Map<String, dynamic>.from(data),
        statusCode: response?.statusCode,
      );
    }

    return ApiFailure(
      mensaje: exception.type == DioExceptionType.connectionError ||
              exception.type == DioExceptionType.connectionTimeout ||
              exception.type == DioExceptionType.receiveTimeout ||
              exception.type == DioExceptionType.sendTimeout
          ? 'No pudimos conectar con el servidor. Revisá tu conexión e intentá de nuevo.'
          : _fallbackMessage(response?.statusCode),
      statusCode: response?.statusCode,
    );
  }

  /// The response body was not the documented envelope.
  factory ApiFailure.unexpectedBody({int? statusCode}) =>
      ApiFailure(mensaje: _fallbackMessage(statusCode), statusCode: statusCode);

  static String _fallbackMessage(int? statusCode) {
    if (statusCode == 401) return 'Tu sesión venció. Iniciá sesión otra vez.';
    if (statusCode == 403) return 'No tenés permiso para ver esto.';
    if (statusCode != null && statusCode >= 500) {
      return 'El servidor no respondió. Intentá de nuevo en un momento.';
    }
    return 'Algo salió mal. Intentá de nuevo.';
  }

  @override
  String toString() =>
      'ApiFailure($codigo, status: $statusCode): $mensaje';
}
