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

@ProviderFor(sightingById)
final sightingByIdProvider = SightingByIdFamily._();

final class SightingByIdProvider
    extends
        $FunctionalProvider<AsyncValue<Sighting>, Sighting, FutureOr<Sighting>>
    with $FutureModifier<Sighting>, $FutureProvider<Sighting> {
  SightingByIdProvider._({
    required SightingByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sightingByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sightingByIdHash();

  @override
  String toString() {
    return r'sightingByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Sighting> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Sighting> create(Ref ref) {
    final argument = this.argument as String;
    return sightingById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SightingByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sightingByIdHash() => r'c3d4e5f6071829384756a1b2c3d4e5f607182938';

final class SightingByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Sighting>, String> {
  SightingByIdFamily._()
    : super(
        retry: null,
        name: r'sightingByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SightingByIdProvider call(String id) =>
      SightingByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'sightingByIdProvider';
}
