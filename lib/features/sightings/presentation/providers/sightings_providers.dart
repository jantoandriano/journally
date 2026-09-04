import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/mock_sightings_repository.dart';
import '../../domain/sighting.dart';
import '../../domain/sightings_repository.dart';

part 'sightings_providers.g.dart';

@riverpod
SightingsRepository sightingsRepository(Ref ref) {
  return MockSightingsRepository();
}

@riverpod
Future<List<Sighting>> sightings(Ref ref) {
  return ref.watch(sightingsRepositoryProvider).fetchSightings();
}
