// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cafe_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cafeRepository)
final cafeRepositoryProvider = CafeRepositoryProvider._();

final class CafeRepositoryProvider
    extends $FunctionalProvider<CafeRepository, CafeRepository, CafeRepository>
    with $Provider<CafeRepository> {
  CafeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cafeRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cafeRepositoryHash();

  @$internal
  @override
  $ProviderElement<CafeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CafeRepository create(Ref ref) {
    return cafeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CafeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CafeRepository>(value),
    );
  }
}

String _$cafeRepositoryHash() => r'499b684132e308253b8b1c12012957030f911cf3';

@ProviderFor(cafeEntries)
final cafeEntriesProvider = CafeEntriesProvider._();

final class CafeEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CafeEntry>>,
          List<CafeEntry>,
          FutureOr<List<CafeEntry>>
        >
    with $FutureModifier<List<CafeEntry>>, $FutureProvider<List<CafeEntry>> {
  CafeEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cafeEntriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cafeEntriesHash();

  @$internal
  @override
  $FutureProviderElement<List<CafeEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CafeEntry>> create(Ref ref) {
    return cafeEntries(ref);
  }
}

String _$cafeEntriesHash() => r'5e8b3e4adfbb9f519a0ee016b215767fe565396d';

@ProviderFor(cafeEntry)
final cafeEntryProvider = CafeEntryFamily._();

final class CafeEntryProvider
    extends
        $FunctionalProvider<
          AsyncValue<CafeEntry>,
          CafeEntry,
          FutureOr<CafeEntry>
        >
    with $FutureModifier<CafeEntry>, $FutureProvider<CafeEntry> {
  CafeEntryProvider._({
    required CafeEntryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cafeEntryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cafeEntryHash();

  @override
  String toString() {
    return r'cafeEntryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CafeEntry> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CafeEntry> create(Ref ref) {
    final argument = this.argument as String;
    return cafeEntry(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CafeEntryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cafeEntryHash() => r'315ed400806efae236dfe93d0458e2fc9202d336';

final class CafeEntryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CafeEntry>, String> {
  CafeEntryFamily._()
    : super(
        retry: null,
        name: r'cafeEntryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CafeEntryProvider call(String id) =>
      CafeEntryProvider._(argument: id, from: this);

  @override
  String toString() => r'cafeEntryProvider';
}

@ProviderFor(nearbyCafe)
final nearbyCafeProvider = NearbyCafeProvider._();

final class NearbyCafeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CafeEntry>>,
          List<CafeEntry>,
          FutureOr<List<CafeEntry>>
        >
    with $FutureModifier<List<CafeEntry>>, $FutureProvider<List<CafeEntry>> {
  NearbyCafeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyCafeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyCafeHash();

  @$internal
  @override
  $FutureProviderElement<List<CafeEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CafeEntry>> create(Ref ref) {
    return nearbyCafe(ref);
  }
}

String _$nearbyCafeHash() => r'a84ecebc24c3bd2039a0c817d908ca51ca3cb894';
