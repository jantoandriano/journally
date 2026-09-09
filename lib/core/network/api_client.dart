import 'package:dio/dio.dart';

import '../api_config.dart';
import 'auth_interceptor.dart';

Dio buildApiClient({
  required Future<String?> Function() getAccessToken,
  required Future<String> Function() onRefresh,
  required Future<void> Function() onRefreshFailed,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      getAccessToken: getAccessToken,
      onRefresh: onRefresh,
      onRefreshFailed: onRefreshFailed,
    ),
  );
  return dio;
}
