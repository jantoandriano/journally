import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/core/network/api_exception.dart';
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

  test('does not attempt refresh for a 401 on an /auth/ endpoint', () async {
    final dio = Dio();
    var refreshCalls = 0;
    dio.httpClientAdapter = FakeHttpClientAdapter(
      (_) => (statusCode: 401, data: {'error': 'invalid credentials'}),
    );
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        getAccessToken: () async => 'token',
        onRefresh: () async {
          refreshCalls++;
          return 'new-token';
        },
        onRefreshFailed: () async {},
      ),
    );

    await expectLater(dio.post('/auth/login'), throwsA(isA<DioException>()));
    expect(refreshCalls, 0);
  });

  test('does not attempt refresh for a non-401 error', () async {
    final dio = Dio();
    var refreshCalls = 0;
    dio.httpClientAdapter = FakeHttpClientAdapter(
      (_) => (statusCode: 500, data: {'error': 'server error'}),
    );
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        getAccessToken: () async => 'token',
        onRefresh: () async {
          refreshCalls++;
          return 'new-token';
        },
        onRefreshFailed: () async {},
      ),
    );

    await expectLater(dio.get('/entries'), throwsA(isA<DioException>()));
    expect(refreshCalls, 0);
  });

  test('refresh future resets so a later 401 triggers a fresh refresh', () async {
    final dio = Dio();
    var refreshCalls = 0;
    String currentToken = 'expired-token-1';

    dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      final authHeader = options.headers['Authorization'];
      if (authHeader == 'Bearer expired-token-1' || authHeader == 'Bearer expired-token-2') {
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
          currentToken = 'fresh-token-$refreshCalls';
          return currentToken;
        },
        onRefreshFailed: () async => fail('should not be called'),
      ),
    );

    final firstRes = await dio.get('/entries');
    expect(firstRes.statusCode, 200);
    expect(refreshCalls, 1);

    // Simulate the newly-refreshed token later expiring too, independently.
    currentToken = 'expired-token-2';
    final secondRes = await dio.get('/sightings');
    expect(secondRes.statusCode, 200);
    expect(refreshCalls, 2);
  });

  // I5: Dio.fetch() re-runs the full interceptor chain, error interceptors
  // included. If the SAME retried request 401s again (clock skew, a
  // resource-level 401 unrelated to the access token, the user was
  // deleted server-side, ...), a fresh refresh has already reset
  // `_refreshFuture` to null by the time that second 401 arrives, so
  // without a retry marker this would refresh-and-retry again
  // unboundedly.
  test('does not loop refresh/retry when a retried request 401s again', () async {
    final dio = Dio();
    var refreshCalls = 0;
    var refreshFailedCalls = 0;

    // Every request 401s no matter what token is attached — a
    // persistently-401ing endpoint.
    dio.httpClientAdapter = FakeHttpClientAdapter(
      (_) => (statusCode: 401, data: {'error': 'still expired'}),
    );

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        getAccessToken: () async => 'expired-token',
        onRefresh: () async {
          refreshCalls++;
          return 'fresh-token-$refreshCalls';
        },
        onRefreshFailed: () async => refreshFailedCalls++,
      ),
    );

    await expectLater(dio.get('/entries'), throwsA(isA<DioException>()));

    // Exactly one refresh-and-retry cycle — the retry's own 401 is passed
    // through instead of triggering a second refresh.
    expect(refreshCalls, 1);
  });

  // I1: a network-level refresh failure (no response — connection error,
  // timeout, offline device) is not a rejection of the refresh token
  // itself, so it must not force a logout. Only a real ApiException (an
  // actual response from the server) should.
  test('a network-level refresh failure does not force a logout', () async {
    final dio = Dio();
    var refreshFailedCalls = 0;

    dio.httpClientAdapter = FakeHttpClientAdapter(
      (_) => (statusCode: 401, data: {'error': 'expired'}),
    );

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        getAccessToken: () async => 'expired-token',
        onRefresh: () async => throw NetworkException('connection failed'),
        onRefreshFailed: () async => refreshFailedCalls++,
      ),
    );

    // The original 401 still surfaces (nothing to retry with), but the
    // failure must not be treated as a definitive auth rejection.
    await expectLater(dio.get('/entries'), throwsA(isA<DioException>()));
    expect(refreshFailedCalls, 0);
  });

  // I2: Dio's FormData can only be sent once — a second finalize() throws
  // `StateError('The FormData has already been finalized...')`. A photo
  // upload that straddles a token refresh must have its retry use a fresh
  // clone of the original FormData, or the retry itself blows up.
  test('replays a FormData request safely after a 401-triggered refresh', () async {
    final dio = Dio();
    var callCount = 0;
    String currentToken = 'expired-token';

    dio.httpClientAdapter = FakeHttpClientAdapter((options) {
      callCount++;
      if (options.headers['Authorization'] == 'Bearer expired-token') {
        return (statusCode: 401, data: {'error': 'expired'});
      }
      expect(options.headers['Authorization'], 'Bearer fresh-token');
      expect(options.data, isA<FormData>());
      return (statusCode: 200, data: {'ok': true});
    });

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        getAccessToken: () async => currentToken,
        onRefresh: () async {
          currentToken = 'fresh-token';
          return 'fresh-token';
        },
        onRefreshFailed: () async => fail('should not be called'),
      ),
    );

    final formData = FormData.fromMap({'field': 'value'});
    final res = await dio.post('/entries/1/photos', data: formData);

    expect(res.statusCode, 200);
    // Original 401 + successful retry — proves the retry didn't blow up
    // trying to re-finalize the same FormData instance.
    expect(callCount, 2);
  });
}
