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
    r'b548e9e7553fcbd99a597367c93a2a845762efb7';

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
        isAutoDispose: false,
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

String _$sightingsHash() => r'63615d27b7700d19cfd6f2a970c259308db5cbc3';

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
  $FutureProviderElement<Sighting> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

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

String _$sightingByIdHash() => r'8891114741f976b9a695da9db996fc71137212f0';

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

@ProviderFor(nearbySightings)
final nearbySightingsProvider = NearbySightingsFamily._();

final class NearbySightingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Sighting>>,
          List<Sighting>,
          FutureOr<List<Sighting>>
        >
    with $FutureModifier<List<Sighting>>, $FutureProvider<List<Sighting>> {
  NearbySightingsProvider._({
    required NearbySightingsFamily super.from,
    required Species? super.argument,
  }) : super(
         retry: null,
         name: r'nearbySightingsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nearbySightingsHash();

  @override
  String toString() {
    return r'nearbySightingsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Sighting>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Sighting>> create(Ref ref) {
    final argument = this.argument as Species?;
    return nearbySightings(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NearbySightingsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nearbySightingsHash() => r'823e9eed93598ff28ff64c5e24416d8940259616';

final class NearbySightingsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Sighting>>, Species?> {
  NearbySightingsFamily._()
    : super(
        retry: null,
        name: r'nearbySightingsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NearbySightingsProvider call(Species? species) =>
      NearbySightingsProvider._(argument: species, from: this);

  @override
  String toString() => r'nearbySightingsProvider';
}
