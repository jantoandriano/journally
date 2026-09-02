import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/nominatim_place_search_repository.dart';
import '../../domain/place_search_repository.dart';

part 'place_search_providers.g.dart';

@riverpod
PlaceSearchRepository placeSearchRepository(Ref ref) {
  return NominatimPlaceSearchRepository();
}
