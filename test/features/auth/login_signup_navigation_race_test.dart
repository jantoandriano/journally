import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:journally/core/auth/data/token_storage.dart';
import 'package:journally/core/auth/domain/auth_repository.dart';
import 'package:journally/core/auth/domain/auth_user.dart';
import 'package:journally/core/auth/presentation/providers/auth_providers.dart';
import 'package:journally/features/auth/presentation/login_screen.dart';
import 'package:journally/features/auth/presentation/signup_screen.dart';
import 'package:journally/features/cafes/domain/cafe_entry.dart';
import 'package:journally/features/cafes/domain/cafe_repository.dart';
import 'package:journally/features/cafes/presentation/providers/cafe_providers.dart';
import 'package:journally/features/home/presentation/home_screen.dart';
import 'package:journally/features/sightings/domain/sighting.dart';
import 'package:journally/features/sightings/domain/sightings_repository.dart';
import 'package:journally/features/sightings/presentation/providers/sightings_providers.dart';

/// Counts `Navigator.push`-family calls so the test can detect a *wasteful*
/// double navigation even in cases where both would still coincidentally
/// converge on the same final screen (e.g. the second push's
/// `pushAndRemoveUntil` clears the first push's route, so the tree looks
/// identical at rest either way — only the push count tells them apart).
class _CountingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
  }
}

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _EmptyCafeRepository implements CafeRepository {
  @override
  Future<List<CafeEntry>> fetchCafes() async => const [];
  @override
  Future<CafeEntry> fetchCafeById(String id) => throw UnimplementedError();
  @override
  Future<void> deleteCafe(String id) => throw UnimplementedError();
  @override
  Future<CafeEntry> createCafe({
    required String placeName,
    required String neighborhood,
    required String city,
    required List<OrderItem> orderItems,
    required DateTime visitedAt,
    double? rating,
    String notes = '',
    List<String> attributes = const [],
    double? lat,
    double? lng,
    String? placeId,
  }) => throw UnimplementedError();
  @override
  Future<CafeEntry> updateCafe(
    String id, {
    String? placeName,
    String? neighborhood,
    String? city,
    List<OrderItem>? orderItems,
    double? lat,
    double? lng,
    String? placeId,
  }) => throw UnimplementedError();
  @override
  Future<void> uploadPhoto(String entryId, XFile photo) => throw UnimplementedError();
  @override
  Future<List<CafeEntry>> fetchNearbyCafe({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async => const [];
}

class _EmptySightingsRepository implements SightingsRepository {
  @override
  Future<List<Sighting>> fetchSightings() async => const [];
  @override
  Future<Sighting> fetchSightingById(String id) => throw UnimplementedError();
  @override
  Future<List<Sighting>> fetchNearbySightings({
    required double lat,
    required double lng,
    double radiusKm = 5,
    Species? species,
  }) async => const [];
  @override
  Future<void> deleteSightById(String id) => throw UnimplementedError();
  @override
  Future<Sighting> createSighting({
    required Species species,
    required double lat,
    required double lng,
    String? notes,
    List<String> attributes = const [],
  }) => throw UnimplementedError();
  @override
  Future<void> uploadPhoto(String sightingId, XFile photo) => throw UnimplementedError();
}

void main() {
  setUpAll(() {
    registerFallbackValue(const AuthUser(id: 'fallback', email: 'fallback@example.com'));
  });

  testWidgets(
    'signing up from SignupScreen (pushed on top of LoginScreen) navigates to '
    'HomeScreen exactly once, without a stale-context exception from the '
    'still-mounted LoginScreen underneath',
    (tester) async {
      final mockTokenStorage = _MockTokenStorage();
      when(() => mockTokenStorage.readSession()).thenAnswer((_) async => null);
      when(
        () => mockTokenStorage.saveSession(
          refreshToken: any(named: 'refreshToken'),
          user: any(named: 'user'),
        ),
      ).thenAnswer((_) async {});

      final mockAuthRepository = _MockAuthRepository();
      when(
        () => mockAuthRepository.signup(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const AuthResult(
          user: AuthUser(id: 'u1', email: 'new@example.com'),
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
        ),
      );

      final observer = _CountingNavigatorObserver();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWith((ref) => mockTokenStorage),
            authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            cafeRepositoryProvider.overrideWithValue(_EmptyCafeRepository()),
            sightingsRepositoryProvider.overrideWithValue(_EmptySightingsRepository()),
          ],
          child: MaterialApp(
            navigatorObservers: [observer],
            home: const LoginScreen(),
          ),
        ),
      );
      // Let the silent-login check resolve (no stored session -> loggedOut)
      // so LoginScreen's own listener is armed on a settled AuthLoggedOut
      // state before we push SignupScreen on top of it.
      await tester.pumpAndSettle();

      // Push SignupScreen on top — LoginScreen stays mounted underneath,
      // exactly as described in the reported race.
      await tester.tap(find.text('Need an account? Sign up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);
      // LoginScreen is still mounted underneath (offstage, hence
      // skipOffstage: false) — its ref.listen is still live, which is the
      // precondition for the race this test exercises.
      expect(find.byType(LoginScreen, skipOffstage: false), findsOneWidget);

      await tester.enterText(find.byKey(const Key('signup_email_field')), 'new@example.com');
      await tester.enterText(find.byKey(const Key('signup_password_field')), 'password123');

      final pushesBeforeSubmit = observer.pushCount;
      await tester.tap(find.byKey(const Key('signup_submit_button')));
      // Both LoginScreen's and SignupScreen's ref.listen fire off of the
      // same AuthLoggedIn transition here — this is exactly the race.
      await tester.pumpAndSettle();

      // No exception (e.g. "Looking up a deactivated widget's ancestor" /
      // using a disposed context) from either listener.
      expect(tester.takeException(), isNull);

      // Exactly one additional push happened as a result of the
      // AuthLoggedIn transition — not two. Without the isCurrent guard,
      // both LoginScreen's and SignupScreen's listeners call
      // pushAndRemoveUntil, which (since the second call's
      // pushAndRemoveUntil clears the first call's freshly-pushed route)
      // converges on the same final tree either way — so only this push
      // count, not the resting widget tree, distinguishes the buggy
      // double-navigation from the fixed single navigation.
      expect(observer.pushCount - pushesBeforeSubmit, 1);

      // Exactly one HomeScreen results — not a double-push, and the old
      // Login/Signup routes were cleared by pushAndRemoveUntil.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(SignupScreen), findsNothing);
    },
  );
}
