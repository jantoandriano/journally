import 'sighting.dart';

abstract class SightingsRepository {
  Future<List<Sighting>> fetchSightings();

  Future<Sighting> fetchSightingById(String id);

  Future<List<Sighting>> fetchNearbySightings({
    required double lat,
    required double lng,
    double radiusKm = 5,
    Species? species,
  });
}
