import 'sighting.dart';

abstract class SightingsRepository {
  Future<List<Sighting>> fetchSightings();
}
