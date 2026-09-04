import 'package:journally/core/location_provider.dart';
import 'package:journally/features/sightings/data/http_sighting_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/sighting.dart';
import '../../domain/sightings_repository.dart';

part 'sightings_providers.g.dart';

/// Radius for "near me" sighting chips. Matches the backend's own default
/// (5km) — a reasonable "same part of the city" radius for Jakarta-scale
/// density, and keeps client/server assumptions in sync.
const nearMeRadiusKm = 5.0;

@riverpod
SightingsRepository sightingsRepository(Ref ref) {
  return HttpSightingRepository();
}

// Kept alive — see the matching note on journalEntries in home_providers.dart.
@Riverpod(keepAlive: true)
Future<List<Sighting>> sightings(Ref ref) {
  return ref.watch(sightingsRepositoryProvider).fetchSightings();
}

@riverpod
Future<Sighting> sightingById(Ref ref, String id) {
  return ref.watch(sightingsRepositoryProvider).fetchSightingById(id);
}

@riverpod
Future<List<Sighting>> nearbySightings(Ref ref, Species? species) async {
  final location = await ref.watch(deviceLocationProvider.future);
  return ref
      .watch(sightingsRepositoryProvider)
      .fetchNearbySightings(
        lat: location.lat,
        lng: location.lng,
        radiusKm: nearMeRadiusKm,
        species: species,
      );
}
