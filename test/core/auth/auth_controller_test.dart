import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/core/auth/data/token_storage.dart';
import 'package:journally/core/auth/domain/auth_repository.dart';
import 'package:journally/core/auth/domain/auth_state.dart';
import 'package:journally/core/auth/domain/auth_user.dart';
import 'package:journally/core/auth/presentation/providers/auth_providers.dart';
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
}
