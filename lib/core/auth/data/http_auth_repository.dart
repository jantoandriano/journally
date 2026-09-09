import 'package:dio/dio.dart';

import '../../api_config.dart';
import '../../network/api_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  final Dio _dio;

  @override
  Future<AuthResult> signup({required String email, required String password}) =>
      _authenticate('/auth/signup', email, password);

  @override
  Future<AuthResult> login({required String email, required String password}) =>
      _authenticate('/auth/login', email, password);

  Future<AuthResult> _authenticate(String path, String email, String password) async {
    try {
      final response = await _dio.post(path, data: {'email': email, 'password': password});
      final data = response.data as Map<String, dynamic>;
      return AuthResult(
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } on DioException catch (e) {
      throw ApiException('POST $path failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<RefreshResult> refresh(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      final data = response.data as Map<String, dynamic>;
      return RefreshResult(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } on DioException catch (e) {
      throw ApiException('POST /auth/refresh failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } on DioException {
      // Best-effort — the local session is cleared regardless of the
      // server-side result.
    }
  }
}
