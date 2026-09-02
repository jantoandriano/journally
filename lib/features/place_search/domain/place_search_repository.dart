import 'place_search_result.dart';

abstract class PlaceSearchRepository {
  Future<List<PlaceSearchResult>> search(String query);
}
