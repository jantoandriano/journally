import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_query_provider.g.dart';

/// Shared search text shown by both the cafes and sightings feeds — the two
/// feeds share one search bar via [HomeScreen]'s single controller.
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String value) => state = value;
}
