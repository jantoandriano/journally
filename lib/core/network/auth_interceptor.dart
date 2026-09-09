import 'package:dio/dio.dart';

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
    final isAuthEndpoint = err.requestOptions.path.startsWith('/auth/');
    if (err.response?.statusCode != 401 || isAuthEndpoint) {
      handler.next(err);
      return;
    }

    String newToken;
    try {
      newToken = await (_refreshFuture ??= _refresh());
    } catch (_) {
      await onRefreshFailed();
      handler.next(err);
      return;
    }

    try {
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newToken';
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
