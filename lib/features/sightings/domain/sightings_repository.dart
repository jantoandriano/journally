import 'sighting.dart';

abstract class SightingsRepository {
  Future<List<Sighting>> fetchSightings();

  Future<Sighting> fetchSightingById(String id);
}
