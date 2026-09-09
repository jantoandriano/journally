import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/core/auth/data/http_auth_repository.dart';
import 'package:journally/core/network/api_exception.dart';

import '../../helpers/fake_http_client_adapter.dart';

void main() {
  late Dio dio;
  late HttpAuthRepository repository;

  Dio buildDio(FakeHttpClientAdapter adapter) {
    final dio = Dio();
    dio.httpClientAdapter = adapter;
    return dio;
  }

  test('login posts credentials and parses the token pair', () async {
    dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/auth/login');
        expect(options.data, {'email': 'a@b.com', 'password': 'pw'});
        return (
          statusCode: 200,
          data: {
            'user': {'id': 'u1', 'email': 'a@b.com'},
            'accessToken': 'access-1',
            'refreshToken': 'refresh-1',
          },
        );
      }),
    );
    repository = HttpAuthRepository(dio: dio);

    final result = await repository.login(email: 'a@b.com', password: 'pw');

    expect(result.user.id, 'u1');
    expect(result.accessToken, 'access-1');
    expect(result.refreshToken, 'refresh-1');
  });

  test('login throws ApiException on a non-2xx response', () async {
    dio = buildDio(
      FakeHttpClientAdapter(
        (_) => (statusCode: 401, data: {'error': 'Invalid email or password'}),
      ),
    );
    repository = HttpAuthRepository(dio: dio);

    expect(
      () => repository.login(email: 'a@b.com', password: 'wrong'),
      throwsA(isA<ApiException>()),
    );
  });

  test('signup posts to /auth/signup', () async {
    dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/auth/signup');
        return (
          statusCode: 201,
          data: {
            'user': {'id': 'u2', 'email': 'new@b.com'},
            'accessToken': 'access-2',
            'refreshToken': 'refresh-2',
          },
        );
      }),
    );
    repository = HttpAuthRepository(dio: dio);

    final result = await repository.signup(email: 'new@b.com', password: 'pw');

    expect(result.user.email, 'new@b.com');
  });

  test('refresh posts the refresh token and returns a new pair', () async {
    dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/auth/refresh');
        expect(options.data, {'refreshToken': 'old-refresh'});
        return (statusCode: 200, data: {'accessToken': 'access-3', 'refreshToken': 'refresh-3'});
      }),
    );
    repository = HttpAuthRepository(dio: dio);

    final result = await repository.refresh('old-refresh');

    expect(result.accessToken, 'access-3');
    expect(result.refreshToken, 'refresh-3');
  });

  test('logout does not throw even if the server call fails', () async {
    dio = buildDio(FakeHttpClientAdapter((_) => (statusCode: 500, data: null)));
    repository = HttpAuthRepository(dio: dio);

    await expectLater(repository.logout('refresh-1'), completes);
  });
}
