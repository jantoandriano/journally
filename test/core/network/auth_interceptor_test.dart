import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/core/network/auth_interceptor.dart';

import '../../helpers/fake_http_client_adapter.dart';

void main() {
  test('attaches the current access token to every request', () async {
    final dio = Dio();
    String? currentToken = 'token-1';
    dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      expect(options.headers['Authorization'], 'Bearer token-1');
      return (statusCode: 200, data: {'ok': true});
    });
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        getAccessToken: () async => currentToken,
        onRefresh: () async => throw StateError('should not refresh'),
        onRefreshFailed: () async {},
      ),
    );

    final res = await dio.get('/entries');
    expect(res.statusCode, 200);
  });

  test('on a 401, refreshes once and retries the original request', () async {
    final dio = Dio();
    var callCount = 0;
    var refreshCalls = 0;
    String currentToken = 'expired-token';

    dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      callCount++;
      if (options.headers['Authorization'] == 'Bearer expired-token') {
        return (statusCode: 401, data: {'error': 'expired'});
      }
      expect(options.headers['Authorization'], 'Bearer fresh-token');
      return (statusCode: 200, data: {'ok': true});
    });

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        getAccessToken: () async => currentToken,
        onRefresh: () async {
          refreshCalls++;
          currentToken = 'fresh-token';
          return 'fresh-token';
        },
        onRefreshFailed: () async => fail('should not be called'),
      ),
    );

    final res = await dio.get('/entries');

    expect(res.statusCode, 200);
    expect(refreshCalls, 1);
    expect(callCount, 2); // original 401 + retry
  });

  test('concurrent 401s share a single in-flight refresh', () async {
    final dio = Dio();
    var refreshCalls = 0;
    String currentToken = 'expired-token';

    dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      if (options.headers['Authorization'] == 'Bearer expired-token') {
        return (statusCode: 401, data: {'error': 'expired'});
      }
      return (statusCode: 200, data: {'ok': true});
    });

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        getAccessToken: () async => currentToken,
        onRefresh: () async {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          currentToken = 'fresh-token';
          return 'fresh-token';
        },
        onRefreshFailed: () async => fail('should not be called'),
      ),
    );

    final results = await Future.wait([dio.get('/entries'), dio.get('/sightings')]);

    expect(results.every((r) => r.statusCode == 200), isTrue);
    expect(refreshCalls, 1);
  });

  test('calls onRefreshFailed and rethrows when refresh itself fails', () async {
    final dio = Dio();
    var refreshFailedCalls = 0;

    dio.httpClientAdapter = FakeHttpClientAdapter(
      (_) => (statusCode: 401, data: {'error': 'expired'}),
    );

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        getAccessToken: () async => 'expired-token',
        onRefresh: () async => throw StateError('refresh token invalid'),
        onRefreshFailed: () async => refreshFailedCalls++,
      ),
    );

    await expectLater(dio.get('/entries'), throwsA(isA<DioException>()));
    expect(refreshFailedCalls, 1);
  });
}
