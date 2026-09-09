import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/core/auth/data/token_storage.dart';
import 'package:journally/core/auth/domain/auth_repository.dart';
import 'package:journally/core/auth/domain/auth_user.dart';
import 'package:journally/core/auth/presentation/providers/auth_providers.dart';
import 'package:journally/core/auth/domain/auth_state.dart';
import 'package:journally/features/auth/presentation/login_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AuthUser(id: 'fallback', email: 'fallback@example.com'));
  });

  testWidgets('entering valid credentials logs in via AuthController', (tester) async {
    final mockRepo = MockAuthRepository();
    final mockStorage = MockTokenStorage();
    when(() => mockStorage.readSession()).thenAnswer((_) async => null);
    when(() => mockStorage.saveSession(refreshToken: any(named: 'refreshToken'), user: any(named: 'user')))
        .thenAnswer((_) async {});
    when(() => mockRepo.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer(
      (_) async => const AuthResult(
        user: AuthUser(id: 'u1', email: 'a@b.com'),
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith((ref) => mockRepo),
        tokenStorageProvider.overrideWith((ref) => mockStorage),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_email_field')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('login_password_field')), 'password123');
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(container.read(authControllerProvider), isA<AuthLoggedIn>());
  });
}
