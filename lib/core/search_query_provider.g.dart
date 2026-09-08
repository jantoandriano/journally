// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_query_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared search text shown by both the cafes and sightings feeds — the two
/// feeds share one search bar via [HomeScreen]'s single controller.

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryProvider._();

/// Shared search text shown by both the cafes and sightings feeds — the two
/// feeds share one search bar via [HomeScreen]'s single controller.
final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  /// Shared search text shown by both the cafes and sightings feeds — the two
  /// feeds share one search bar via [HomeScreen]'s single controller.
  SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'9f97403b5659152608c0dbc158267442c72403bc';

/// Shared search text shown by both the cafes and sightings feeds — the two
/// feeds share one search bar via [HomeScreen]'s single controller.

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
