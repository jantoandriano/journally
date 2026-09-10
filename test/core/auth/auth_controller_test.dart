import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/core/auth/data/token_storage.dart';
import 'package:journally/core/auth/domain/auth_repository.dart';
import 'package:journally/core/auth/domain/auth_state.dart';
import 'package:journally/core/auth/domain/auth_user.dart';
import 'package:journally/core/auth/presentation/providers/auth_providers.dart';
import 'package:journally/core/network/api_exception.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

class _AuthUserFake extends Fake implements AuthUser {}

void main() {
  late MockAuthRepository mockRepo;
  late MockTokenStorage mockStorage;
  late ProviderContainer container;

  const user = AuthUser(id: 'u1', email: 'a@b.com');

  setUpAll(() {
    registerFallbackValue(_AuthUserFake());
  });

  setUp(() {
    mockRepo = MockAuthRepository();
    mockStorage = MockTokenStorage();
    when(() => mockStorage.readSession()).thenAnswer((_) async => null);

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith((ref) => mockRepo),
        tokenStorageProvider.overrideWith((ref) => mockStorage),
      ],
    );
    addTearDown(container.dispose);
  });

  test('starts loggedOut when there is no stored session', () async {
    final controller = container.read(authControllerProvider.notifier);
    // build() kicks off an async silent-login check — wait for it.
    await Future<void>.delayed(Duration.zero);

    expect(container.read(authControllerProvider), isA<AuthLoggedOut>());
    // ignore: unnecessary_statements
    controller;
  });

  test('login transitions to loggedIn and persists the session', () async {
    when(
      () => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')),
    ).thenAnswer(
      (_) async =>
          const AuthResult(user: user, accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    when(
      () => mockStorage.saveSession(
        refreshToken: any(named: 'refreshToken'),
        user: any(named: 'user'),
      ),
    ).thenAnswer((_) async {});

    await container.read(authControllerProvider.notifier).login(email: 'a@b.com', password: 'pw');

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthLoggedIn>());
    expect((state as AuthLoggedIn).accessToken, 'access-1');
  });

  test('a failed login leaves state loggedOut', () async {
    when(
      () => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')),
    ).thenThrow(Exception('invalid credentials'));

    await expectLater(
      container.read(authControllerProvider.notifier).login(email: 'a@b.com', password: 'wrong'),
      throwsException,
    );

    expect(container.read(authControllerProvider), isA<AuthLoggedOut>());
  });

  test('refreshAccessToken rotates the stored token and updates state', () async {
    when(() => mockStorage.readSession()).thenAnswer(
      (_) async => const StoredSession(refreshToken: 'old-refresh', user: user),
    );
    when(() => mockRepo.refresh('old-refresh')).thenAnswer(
      (_) async => const RefreshResult(accessToken: 'access-2', refreshToken: 'refresh-2'),
    );
    when(() => mockStorage.updateRefreshToken('refresh-2')).thenAnswer((_) async {});

    final token = await container.read(authControllerProvider.notifier).refreshAccessToken();

    expect(token, 'access-2');
    final state = container.read(authControllerProvider);
    expect((state as AuthLoggedIn).accessToken, 'access-2');
  });

  test('forceLogout clears storage and sets loggedOut', () async {
    when(() => mockStorage.clear()).thenAnswer((_) async {});

    await container.read(authControllerProvider.notifier).forceLogout();

    expect(container.read(authControllerProvider), isA<AuthLoggedOut>());
    verify(() => mockStorage.clear()).called(1);
  });

  // C1: two independent code paths can each try to refresh at cold start —
  // AuthController's own silent-login check, and (separately) anything
  // that drives a direct refreshAccessToken() call (e.g. the interceptor
  // reacting to an unauthenticated request that 401s before auth has
  // resolved). Two concurrent /auth/refresh calls for the same refresh
  // token trip the backend's reuse-detection and revoke the whole
  // session. refreshAccessToken() and _trySilentLogin() now share one
  // single-flight `_refreshFuture`, so no matter which one gets there
  // first, the repository's refresh() is only ever called once.
  test(
    'cold-start silent login racing a direct refreshAccessToken() call shares a single in-flight refresh',
    () async {
      when(() => mockStorage.readSession()).thenAnswer(
        (_) async => const StoredSession(refreshToken: 'old-refresh', user: user),
      );
      when(() => mockStorage.updateRefreshToken(any())).thenAnswer((_) async {});

      var refreshCalls = 0;
      when(() => mockRepo.refresh('old-refresh')).thenAnswer((_) async {
        refreshCalls++;
        // A real network round trip takes some time — long enough for
        // both the silent-login path (already in flight from build()) and
        // a direct caller to race each other before either completes.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const RefreshResult(accessToken: 'access-x', refreshToken: 'refresh-x');
      });

      // Reading `.notifier` triggers build(), which fires off
      // _trySilentLogin() (unawaited) and immediately suspends it on the
      // first `await storage.readSession()`.
      final notifier = container.read(authControllerProvider.notifier);

      // A second, independent trigger — a direct refreshAccessToken()
      // call, exactly like the interceptor would make — racing the
      // still-in-flight silent login.
      final directToken = await notifier.refreshAccessToken();

      // Let _trySilentLogin's own await chain (which shares the same
      // future) fully settle too.
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(refreshCalls, 1);
      expect(directToken, 'access-x');
      final state = container.read(authControllerProvider);
      expect(state, isA<AuthLoggedIn>());
      expect((state as AuthLoggedIn).accessToken, 'access-x');
    },
  );

  // I1: a network-level failure (no response at all) during the
  // cold-start refresh must not be treated the same as the server
  // rejecting the refresh token — don't clear the stored session, so a
  // later retry (e.g. the next cold start) can still use it.
  test(
    'a network error during silent-login refresh leaves the stored session intact',
    () async {
      when(() => mockStorage.readSession()).thenAnswer(
        (_) async => const StoredSession(refreshToken: 'old-refresh', user: user),
      );
      when(
        () => mockRepo.refresh('old-refresh'),
      ).thenAnswer((_) async => throw NetworkException('connection failed'));

      final controller = container.read(authControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authControllerProvider), isA<AuthLoggedOut>());
      verifyNever(() => mockStorage.clear());
      // ignore: unnecessary_statements
      controller;
    },
  );

  // I1 (contrast case): a definitive rejection of the refresh token itself
  // (a real ApiException from a non-2xx response) is a genuine logout —
  // the stored session is no longer useful and should be cleared.
  test('a rejected refresh token during silent login clears the stored session', () async {
    when(() => mockStorage.readSession()).thenAnswer(
      (_) async => const StoredSession(refreshToken: 'old-refresh', user: user),
    );
    when(() => mockRepo.refresh('old-refresh')).thenAnswer(
      (_) async => throw ApiException('POST /auth/refresh failed with status 401'),
    );
    when(() => mockStorage.clear()).thenAnswer((_) async {});

    final controller = container.read(authControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(authControllerProvider), isA<AuthLoggedOut>());
    verify(() => mockStorage.clear()).called(1);
    // ignore: unnecessary_statements
    controller;
  });

  // I3: logout() and an in-flight refresh share no mutual exclusion of
  // their own. If a request is in flight (triggering a refresh) when the
  // user taps logout, the refresh completing afterward must not write a
  // fresh refresh token back to storage or flip state back to logged in —
  // that would silently undo the logout and orphan an unrevoked refresh
  // token on the device.
  test(
    'a logout that lands while a refresh is in flight does not resurrect the session',
    () async {
      when(
        () => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')),
      ).thenAnswer(
        (_) async =>
            const AuthResult(user: user, accessToken: 'access-1', refreshToken: 'refresh-1'),
      );
      when(
        () => mockStorage.saveSession(
          refreshToken: any(named: 'refreshToken'),
          user: any(named: 'user'),
        ),
      ).thenAnswer((_) async {});

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.login(email: 'a@b.com', password: 'pw');
      expect(container.read(authControllerProvider), isA<AuthLoggedIn>());

      when(() => mockStorage.readSession()).thenAnswer(
        (_) async => const StoredSession(refreshToken: 'refresh-1', user: user),
      );
      when(() => mockRepo.refresh('refresh-1')).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const RefreshResult(accessToken: 'access-late', refreshToken: 'refresh-late');
      });
      when(() => mockStorage.updateRefreshToken(any())).thenAnswer((_) async {});
      when(() => mockRepo.logout(any())).thenAnswer((_) async {});
      when(() => mockStorage.clear()).thenAnswer((_) async {});

      // A request is in flight and triggers a refresh that won't resolve
      // for a bit (mirrors the interceptor calling refreshAccessToken()).
      final refreshFuture = notifier.refreshAccessToken();

      // ...but the user taps logout before that refresh resolves.
      await notifier.logout();
      expect(container.read(authControllerProvider), isA<AuthLoggedOut>());

      final token = await refreshFuture;

      // The interceptor's immediate need — a token to retry the request
      // it was serving — is still satisfied...
      expect(token, 'access-late');
      // ...but the logout itself is not undone: state stays logged out,
      // and the rotated refresh token from the in-flight refresh is never
      // persisted.
      expect(container.read(authControllerProvider), isA<AuthLoggedOut>());
      verifyNever(() => mockStorage.updateRefreshToken('refresh-late'));
    },
  );
}
