import 'place_search_result.dart';

abstract class PlaceSearchRepository {
  Future<List<PlaceSearchResult>> search(String query);

  /// Resolves a coordinate to a human-readable place description
  /// (e.g. "Jl. Sudirman, Jakarta Selatan").
  Future<String> reverseGeocode({required double lat, required double lng});
}
