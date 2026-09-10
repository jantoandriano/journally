import 'dart:async';

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
      (_) async =>
          throw ApiException('POST /auth/refresh failed with status 401', statusCode: 401),
    );
    when(() => mockStorage.clear()).thenAnswer((_) async {});

    final controller = container.read(authControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(authControllerProvider), isA<AuthLoggedOut>());
    verify(() => mockStorage.clear()).called(1);
    // ignore: unnecessary_statements
    controller;
  });

  // I1 (transient-server contrast case): a non-401 ApiException (5xx, 429,
  // ...) during the cold-start refresh is a transient server problem, not
  // a rejection of the refresh token — it must be treated the same as a
  // network error: don't clear the stored session.
  test(
    'a transient server error (non-401 ApiException) during silent-login refresh leaves the '
    'stored session intact',
    () async {
      when(() => mockStorage.readSession()).thenAnswer(
        (_) async => const StoredSession(refreshToken: 'old-refresh', user: user),
      );
      when(() => mockRepo.refresh('old-refresh')).thenAnswer(
        (_) async =>
            throw ApiException('POST /auth/refresh failed with status 500', statusCode: 500),
      );

      final controller = container.read(authControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authControllerProvider), isA<AuthLoggedOut>());
      verifyNever(() => mockStorage.clear());
      // ignore: unnecessary_statements
      controller;
    },
  );

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

  // Regression test for the epoch race: logout()/forceLogout() nulling
  // `_refreshFuture` directly (I3, above) isn't enough on its own. A
  // refresh already in flight *before* the logout doesn't go through that
  // null — it's still running, and its `finally` block used to
  // unconditionally clear `_refreshFuture` on completion, regardless of
  // what had happened in the meantime. If a different user had since
  // logged in and started their *own* refresh, the stale refresh's
  // completion would wipe out that new refresh's in-flight guard,
  // allowing a third caller to start a second, unguarded concurrent
  // `/auth/refresh` call — exactly the bug this whole mechanism exists to
  // prevent. Worse, the stale refresh would also persist user A's rotated
  // token and state over user B's. `_authEpoch` fixes both: the stale
  // refresh's `finally` no longer touches `_refreshFuture` once the epoch
  // has moved on, and it no longer persists its result either.
  test(
    'a stale refresh completing after a logout+relogin as a different user does not clobber '
    "the new user's in-flight refresh or session (epoch race)",
    () async {
      const userA = AuthUser(id: 'uA', email: 'a@example.com');
      const userB = AuthUser(id: 'uB', email: 'b@example.com');

      // Storage is modeled as a real mutable store (rather than a fixed
      // stub) so it reflects whatever was most recently written, exactly
      // like the real TokenStorage would — this lets us assert on its
      // final contents instead of just verifying call arguments.
      StoredSession? storedSession;
      when(() => mockStorage.readSession()).thenAnswer((_) async => storedSession);
      when(
        () => mockStorage.saveSession(
          refreshToken: any(named: 'refreshToken'),
          user: any(named: 'user'),
        ),
      ).thenAnswer((invocation) async {
        storedSession = StoredSession(
          refreshToken: invocation.namedArguments[#refreshToken] as String,
          user: invocation.namedArguments[#user] as AuthUser,
        );
      });
      when(() => mockStorage.updateRefreshToken(any())).thenAnswer((invocation) async {
        final token = invocation.positionalArguments[0] as String;
        storedSession = StoredSession(refreshToken: token, user: storedSession!.user);
      });
      when(() => mockStorage.clear()).thenAnswer((_) async {
        storedSession = null;
      });
      when(() => mockRepo.logout(any())).thenAnswer((_) async {});

      final notifier = container.read(authControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero); // let build()'s silent login settle (no session)

      // User A logs in.
      when(
        () => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')),
      ).thenAnswer(
        (_) async =>
            const AuthResult(user: userA, accessToken: 'access-A0', refreshToken: 'refresh-A'),
      );
      await notifier.login(email: 'a@example.com', password: 'pwA');
      expect((container.read(authControllerProvider) as AuthLoggedIn).user.id, 'uA');

      // Refresh A starts and hangs mid-flight on a completer we control —
      // simulates a slow `/auth/refresh` round trip.
      final refreshACompleter = Completer<RefreshResult>();
      when(() => mockRepo.refresh('refresh-A')).thenAnswer((_) => refreshACompleter.future);
      final refreshAFuture = notifier.refreshAccessToken();
      await Future<void>.delayed(Duration.zero); // let it reach the completer and suspend there

      // The user logs out while refresh A is still in flight.
      await notifier.logout();
      expect(container.read(authControllerProvider), isA<AuthLoggedOut>());

      // ...then logs in again, as a different user B.
      when(
        () => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')),
      ).thenAnswer(
        (_) async =>
            const AuthResult(user: userB, accessToken: 'access-B0', refreshToken: 'refresh-B'),
      );
      await notifier.login(email: 'b@example.com', password: 'pwB');
      expect((container.read(authControllerProvider) as AuthLoggedIn).user.id, 'uB');

      // A 401 for user B starts refresh B, which also hangs mid-flight.
      final refreshBCompleter = Completer<RefreshResult>();
      when(() => mockRepo.refresh('refresh-B')).thenAnswer((_) => refreshBCompleter.future);
      final refreshBFuture = notifier.refreshAccessToken();
      await Future<void>.delayed(Duration.zero);

      // Now refresh A's underlying network call finally resolves — a
      // stale, late response for a session that no longer exists.
      refreshACompleter.complete(
        const RefreshResult(accessToken: 'access-A-stale', refreshToken: 'refresh-A-rotated'),
      );
      final tokenFromA = await refreshAFuture;
      // Whatever request refresh A was originally serving still gets a
      // token back so it can retry...
      expect(tokenFromA, 'access-A-stale');

      // ...but it must not have persisted user A's rotated token over
      // user B's, or flipped state back to a mixed-identity mess.
      expect(storedSession?.refreshToken, isNot('refresh-A-rotated'));
      expect((container.read(authControllerProvider) as AuthLoggedIn).user.id, 'uB');

      // And critically, it must not have clobbered refresh B's in-flight
      // guard: a third caller arriving now should join B's still-pending
      // future rather than starting an unguarded second concurrent
      // refresh.
      final thirdCallerFuture = notifier.refreshAccessToken();
      expect(identical(thirdCallerFuture, refreshBFuture), isTrue);

      // Finally, let refresh B resolve and confirm it (and only it) is
      // the one that gets persisted.
      refreshBCompleter.complete(
        const RefreshResult(accessToken: 'access-B-fresh', refreshToken: 'refresh-B-rotated'),
      );
      final tokenFromB = await refreshBFuture;
      expect(tokenFromB, 'access-B-fresh');
      final finalState = container.read(authControllerProvider) as AuthLoggedIn;
      expect(finalState.user.id, 'uB');
      expect(finalState.accessToken, 'access-B-fresh');
      expect(storedSession?.refreshToken, 'refresh-B-rotated');
    },
  );
}
