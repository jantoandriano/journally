import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:journally/core/auth/data/token_storage.dart';
import 'package:journally/core/auth/domain/auth_repository.dart';
import 'package:journally/core/auth/domain/auth_user.dart';
import 'package:journally/core/auth/presentation/providers/auth_providers.dart';
import 'package:journally/core/location_provider.dart';
import 'package:journally/features/cafes/domain/cafe_entry.dart';
import 'package:journally/features/cafes/domain/cafe_repository.dart';
import 'package:journally/features/cafes/presentation/providers/cafe_providers.dart';
import 'package:journally/features/sightings/domain/sighting.dart';
import 'package:journally/features/sightings/domain/sightings_repository.dart';
import 'package:journally/features/sightings/presentation/providers/sightings_providers.dart';
import 'package:journally/main.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeJournalRepository implements CafeRepository {
  @override
  Future<List<CafeEntry>> fetchCafes() async {
    return List.generate(
      6,
      (i) => CafeEntry(
        id: '$i',
        placeName: 'Place $i',
        neighborhood: 'Neighborhood $i',
        city: 'City',
        orderItems: [OrderItem(name: 'Item')],
        photoCount: 0,
        photoUrls: const [],
        gradientColors: const [Color(0xFFE7C9A5), Color(0xFFB8763F)],
        visitedAt: DateTime(2026, 1, 1),
      ),
    );
  }

  @override
  Future<CafeEntry> fetchCafeById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCafe(String id) {
    throw UnimplementedError();
  }

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
  }) {
    throw UnimplementedError();
  }

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> uploadPhoto(String entryId, XFile photo) {
    throw UnimplementedError();
  }

  @override
  Future<List<CafeEntry>> fetchNearbyCafe({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) {
    throw UnimplementedError();
  }
}

class _FakeSightingsRepository implements SightingsRepository {
  @override
  Future<List<Sighting>> fetchSightings() async => const [];

  @override
  Future<Sighting> fetchSightingById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<Sighting>> fetchNearbySightings({
    required double lat,
    required double lng,
    double radiusKm = 5,
    Species? species,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteSightById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Sighting> createSighting({
    required Species species,
    required double lat,
    required double lng,
    String? notes,
    List<String> attributes = const [],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> uploadPhoto(String sightingId, XFile photo) {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('Home screen loads and shows the place count', (
    WidgetTester tester,
  ) async {
    // The splash screen now gates on auth state (Task 26), which requires
    // resolving authControllerProvider's silent-login check. The real
    // TokenStorage is backed by FlutterSecureStorage's platform channel,
    // which has no handler under flutter test and hangs indefinitely rather
    // than erroring — so a stored session is faked here purely to let that
    // resolve quickly to logged-in, matching this test's original intent of
    // exercising the home screen with fake data repositories.
    const testUser = AuthUser(id: 'test-user', email: 'test@example.com');
    final mockTokenStorage = _MockTokenStorage();
    when(
      () => mockTokenStorage.readSession(),
    ).thenAnswer((_) async => const StoredSession(refreshToken: 'refresh-1', user: testUser));
    when(
      () => mockTokenStorage.updateRefreshToken(any()),
    ).thenAnswer((_) async {});
    final mockAuthRepository = _MockAuthRepository();
    when(() => mockAuthRepository.refresh(any())).thenAnswer(
      (_) async => const RefreshResult(accessToken: 'access-1', refreshToken: 'refresh-2'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWith((ref) => mockTokenStorage),
          authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
          cafeRepositoryProvider.overrideWithValue(_FakeJournalRepository()),
          // Avoids depending on real (even synthetically-faked-400) HTTP
          // timing under flutter test — that resolves on a real IO turn,
          // not a microtask, and the splash's fixed manual pump sequence
          // below doesn't allocate slack for it.
          sightingsRepositoryProvider.overrideWithValue(
            _FakeSightingsRepository(),
          ),
          // Avoids depending on the real geolocator platform channel (which
          // has no handler under flutter test and would otherwise leave the
          // splash's warm-up future pending on a real-wall-clock timeout
          // that pump(duration) never advances).
          deviceLocationProvider.overrideWith(
            (ref) async => const DeviceLocation(
              lat: jakartaFallbackLat,
              lng: jakartaFallbackLng,
              isFallback: true,
            ),
          ),
        ],
        child: const JournallyApp(),
      ),
    );

    // The splash screen holds two infinitely-repeating animations (steam,
    // loading bar), so `pumpAndSettle` would hang here — pump the splash's
    // fixed hand-off timeline explicitly instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('6 places visited'), findsOneWidget);
  });
}
