import 'package:journally/features/sightings/data/http_sighting_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/sighting.dart';
import '../../domain/sightings_repository.dart';

part 'sightings_providers.g.dart';

@riverpod
SightingsRepository sightingsRepository(Ref ref) {
  return HttpSightingRepository();
}

@riverpod
Future<List<Sighting>> sightings(Ref ref) {
  return ref.watch(sightingsRepositoryProvider).fetchSightings();
}

@riverpod
Future<Sighting> sightingById(Ref ref, String id) {
  return ref.watch(sightingsRepositoryProvider).fetchSightingById(id);
}
