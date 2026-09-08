import 'package:image_picker/image_picker.dart';

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

  Future<Sighting> createSighting({
    required Species species,
    required double lat,
    required double lng,
    String? notes,
    List<String> attributes = const [],
  });

  Future<void> uploadPhoto(String sightingId, XFile photo);

  Future<void> deleteSightById(String id);
}
