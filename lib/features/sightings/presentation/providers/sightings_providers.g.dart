// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sightings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sightingsRepository)
final sightingsRepositoryProvider = SightingsRepositoryProvider._();

final class SightingsRepositoryProvider
    extends
        $FunctionalProvider<
          SightingsRepository,
          SightingsRepository,
          SightingsRepository
        >
    with $Provider<SightingsRepository> {
  SightingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sightingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sightingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SightingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SightingsRepository create(Ref ref) {
    return sightingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SightingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SightingsRepository>(value),
    );
  }
}

String _$sightingsRepositoryHash() =>
    r'a1b2c3d4e5f6071829384756a1b2c3d4e5f60718';

@ProviderFor(sightings)
final sightingsProvider = SightingsProvider._();

final class SightingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Sighting>>,
          List<Sighting>,
          FutureOr<List<Sighting>>
        >
    with $FutureModifier<List<Sighting>>, $FutureProvider<List<Sighting>> {
  SightingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sightingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sightingsHash();

  @$internal
  @override
  $FutureProviderElement<List<Sighting>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Sighting>> create(Ref ref) {
    return sightings(ref);
  }
}

String _$sightingsHash() => r'b2c3d4e5f6071829384756a1b2c3d4e5f6071829';
