import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A minimal, hand-rolled [HttpClientAdapter] for tests — avoids adding an
/// external Dio-mocking package for what's a small, fully-controllable
/// fake. [handler] is called once per request; return the status code and
/// a JSON-encodable body (or `null` for an empty body).
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  final FutureOr<({int statusCode, Object? data})> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final result = await handler(options);
    final bytes = result.data == null
        ? Uint8List(0)
        : Uint8List.fromList(utf8.encode(jsonEncode(result.data)));

    return ResponseBody.fromBytes(
      bytes,
      result.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
