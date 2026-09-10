import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Marks a [RequestOptions] as having already been through one
/// refresh-and-retry cycle. Set on the retried request before it re-enters
/// the interceptor chain via [Dio.fetch] — see [AuthInterceptor.onError].
const _authRetriedKey = '__authRetried';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required this.getAccessToken,
    required this.onRefresh,
    required this.onRefreshFailed,
  }) : _dio = dio;

  final Dio _dio;
  final Future<String?> Function() getAccessToken;
  final Future<String> Function() onRefresh;
  final Future<void> Function() onRefreshFailed;

  Future<String>? _refreshFuture;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // A request that already went through one refresh-and-retry cycle and
    // still came back 401 (clock skew, a resource-level 401 unrelated to
    // the access token, the user was deleted server-side, ...) must not
    // trigger another refresh cycle — `_refreshFuture` has already been
    // reset by the previous cycle's `finally`, so without this guard a
    // persistently-401ing endpoint would loop refresh/retry unboundedly.
    if (err.requestOptions.extra[_authRetriedKey] == true) {
      handler.next(err);
      return;
    }

    final isAuthEndpoint = err.requestOptions.path.startsWith('/auth/');
    if (err.response?.statusCode != 401 || isAuthEndpoint) {
      handler.next(err);
      return;
    }

    String newToken;
    try {
      newToken = await (_refreshFuture ??= _refresh());
    } catch (e) {
      // Only a definitive rejection of the refresh token (a real
      // ApiException from a non-2xx response) should force a logout. A
      // network-level failure (NetworkException, or anything else that
      // isn't a confirmed rejection) shouldn't log the user out or touch
      // stored state — just let the original 401 propagate as a retriable
      // failure.
      if (e is! NetworkException) {
        await onRefreshFailed();
      }
      handler.next(err);
      return;
    }

    try {
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newToken'
        ..extra[_authRetriedKey] = true;
      // Dio's FormData can only be sent once — finalize() throws on a
      // second call. A retried request whose original body was FormData
      // (e.g. a photo upload) needs a fresh clone or the retry blows up
      // with a misleading StateError instead of actually replaying.
      if (retryOptions.data is FormData) {
        retryOptions.data = (retryOptions.data as FormData).clone();
      }
      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } catch (retryError) {
      handler.next(retryError is DioException ? retryError : err);
    }
  }

  Future<String> _refresh() async {
    try {
      return await onRefresh();
    } finally {
      _refreshFuture = null;
    }
  }
}
