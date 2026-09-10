import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:journally/core/auth/data/token_storage.dart';
import 'package:journally/core/auth/domain/auth_repository.dart';
import 'package:journally/core/auth/domain/auth_state.dart';
import 'package:journally/core/auth/domain/auth_user.dart';
import 'package:journally/core/auth/presentation/providers/auth_providers.dart';
import 'package:journally/features/cafes/domain/cafe_entry.dart';
import 'package:journally/features/cafes/domain/cafe_repository.dart';
import 'package:journally/features/cafes/presentation/providers/cafe_providers.dart';
import 'package:journally/features/sightings/domain/sighting.dart';
import 'package:journally/features/sightings/domain/sightings_repository.dart';
import 'package:journally/features/sightings/presentation/providers/sightings_providers.dart';
import 'package:journally/main.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _AuthUserFake extends Fake implements AuthUser {}

/// A cafe repository whose `fetchCafes()` result depends on whatever
/// [currentUser] points to *at the time it's called* — lets a test assert
/// a later fetch actually re-ran (rather than returning a stale cached
/// value) after the "current user" changes.
class _SwitchableCafeRepository implements CafeRepository {
  _SwitchableCafeRepository(this.currentUser);

  String Function() currentUser;
  int fetchCalls = 0;

  @override
  Future<List<CafeEntry>> fetchCafes() async {
    fetchCalls++;
    final user = currentUser();
    return [
      CafeEntry(
        id: 'cafe-$user',
        placeName: 'Cafe $user',
        neighborhood: 'Neighborhood',
        city: 'City',
        orderItems: const [],
        photoCount: 0,
        photoUrls: const [],
        gradientColors: const [Color(0xFFE7C9A5), Color(0xFFB8763F)],
        visitedAt: DateTime(2026, 1, 1),
      ),
    ];
  }

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
  }) => throw UnimplementedError();
}

/// See [_SwitchableCafeRepository] — same idea for sightings.
class _SwitchableSightingsRepository implements SightingsRepository {
  _SwitchableSightingsRepository(this.currentUser);

  String Function() currentUser;
  int fetchCalls = 0;

  @override
  Future<List<Sighting>> fetchSightings() async {
    fetchCalls++;
    final user = currentUser();
    return [
      Sighting(
        id: 'sighting-$user',
        animal: Species.cat,
        placeName: 'Place $user',
        gradientColors: const [Color(0xFFE7C9A5), Color(0xFFB8763F)],
        fed: false,
        notes: '',
        photoCount: 0,
        attributes: const [],
      ),
    ];
  }

  @override
  Future<Sighting> fetchSightingById(String id) => throw UnimplementedError();

  @override
  Future<List<Sighting>> fetchNearbySightings({
    required double lat,
    required double lng,
    double radiusKm = 5,
    Species? species,
  }) => throw UnimplementedError();

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

  @override
  Future<void> deleteSightById(String id) => throw UnimplementedError();
}

void main() {
  // C2: cafeEntriesProvider and sightingsProvider are `keepAlive`, and
  // nothing used to invalidate them on an auth transition — a previous
  // account's cached café/sighting list would survive a logout and still
  // be shown to a different account that logs in on the same device
  // without restarting the app. JournallyApp (lib/main.dart) now registers
  // a `ref.listen<AuthState>` that invalidates both providers whenever the
  // authenticated identity changes. This test exercises that through the
  // real widget tree (JournallyApp under ProviderScope) rather than a bare
  // ProviderContainer, since the listener lives in JournallyApp's build
  // method — a plain container wouldn't run it at all.
  setUpAll(() {
    registerFallbackValue(_AuthUserFake());
  });

  testWidgets(
    'logging out and back in as a different user refetches cafe and sighting data instead of reusing the previous account\'s cache',
    (tester) async {
      const userA = AuthUser(id: 'user-a', email: 'a@example.com');
      const userB = AuthUser(id: 'user-b', email: 'b@example.com');

      final mockTokenStorage = _MockTokenStorage();
      when(() => mockTokenStorage.readSession()).thenAnswer((_) async => null);
      when(
        () => mockTokenStorage.saveSession(
          refreshToken: any(named: 'refreshToken'),
          user: any(named: 'user'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockTokenStorage.clear()).thenAnswer((_) async {});

      final mockAuthRepository = _MockAuthRepository();
      when(() => mockAuthRepository.logout(any())).thenAnswer((_) async {});

      var currentUser = 'A';
      final cafeRepo = _SwitchableCafeRepository(() => currentUser);
      final sightingsRepo = _SwitchableSightingsRepository(() => currentUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWith((ref) => mockTokenStorage),
            authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            cafeRepositoryProvider.overrideWithValue(cafeRepo),
            sightingsRepositoryProvider.overrideWithValue(sightingsRepo),
          ],
          child: const JournallyApp(),
        ),
      );

      // Let the splash screen's fixed hand-off timeline (animations +
      // pending Future.delayed timers) fully play out, exactly as
      // test/widget_test.dart does — otherwise its still-pending timers
      // trip flutter_test's end-of-test invariant check. No stored
      // session, so auth resolution (and hence the hand-off) happens
      // quickly regardless.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final container = ProviderScope.containerOf(tester.element(find.byType(JournallyApp)));

      expect(container.read(authControllerProvider), isA<AuthLoggedOut>());

      // Log in as user A and read their café/sighting data.
      when(
        () => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async =>
            const AuthResult(user: userA, accessToken: 'access-a', refreshToken: 'refresh-a'),
      );
      await container.read(authControllerProvider.notifier).login(email: 'a@example.com', password: 'pw');
      await tester.pump();

      final cafesA = await container.read(cafeEntriesProvider.future);
      final sightingsA = await container.read(sightingsProvider.future);
      expect(cafesA.single.placeName, 'Cafe A');
      expect(sightingsA.single.placeName, 'Place A');

      // Log out, then log in as a *different* user, without restarting the
      // app (mirrors the real bug scenario).
      await container.read(authControllerProvider.notifier).logout();
      await tester.pump();
      expect(container.read(authControllerProvider), isA<AuthLoggedOut>());

      currentUser = 'B';
      when(
        () => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async =>
            const AuthResult(user: userB, accessToken: 'access-b', refreshToken: 'refresh-b'),
      );
      await container.read(authControllerProvider.notifier).login(email: 'b@example.com', password: 'pw');
      await tester.pump();

      final cafesB = await container.read(cafeEntriesProvider.future);
      final sightingsB = await container.read(sightingsProvider.future);

      // The critical assertion: user B sees their own data, not a stale
      // cache of user A's.
      expect(cafesB.single.placeName, 'Cafe B');
      expect(sightingsB.single.placeName, 'Place B');
      // And the underlying repositories were actually re-queried (not
      // just re-read from a cached AsyncData) — at least once for A's
      // login and once more for B's.
      expect(cafeRepo.fetchCalls, greaterThanOrEqualTo(2));
      expect(sightingsRepo.fetchCalls, greaterThanOrEqualTo(2));
    },
  );
}
