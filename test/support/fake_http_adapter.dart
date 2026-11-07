import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Dio adapter fake: answers with whatever [responder] returns, so the API
/// layer is tested without a socket.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.responder);

  /// Receives the outgoing request and returns the response body.
  final Future<ResponseBody> Function(RequestOptions options) responder;

  /// Requests seen by the adapter, in order.
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Builds a JSON [ResponseBody] for a fake adapter.
ResponseBody jsonBody(Object? body, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// A [Dio] wired to [adapter], with no timeouts to keep tests fast.
Dio dioWith(FakeHttpAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
}
