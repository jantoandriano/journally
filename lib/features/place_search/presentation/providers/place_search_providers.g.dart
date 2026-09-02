// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(placeSearchRepository)
final placeSearchRepositoryProvider = PlaceSearchRepositoryProvider._();

final class PlaceSearchRepositoryProvider
    extends
        $FunctionalProvider<
          PlaceSearchRepository,
          PlaceSearchRepository,
          PlaceSearchRepository
        >
    with $Provider<PlaceSearchRepository> {
  PlaceSearchRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeSearchRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeSearchRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlaceSearchRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlaceSearchRepository create(Ref ref) {
    return placeSearchRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceSearchRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceSearchRepository>(value),
    );
  }
}

String _$placeSearchRepositoryHash() =>
    r'81ea018722564d2a7d8efea704008b4d9592b077';
