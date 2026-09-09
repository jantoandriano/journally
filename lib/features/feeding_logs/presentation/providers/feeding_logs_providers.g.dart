// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feeding_logs_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(feedingLogsRepository)
final feedingLogsRepositoryProvider = FeedingLogsRepositoryProvider._();

final class FeedingLogsRepositoryProvider
    extends
        $FunctionalProvider<
          FeedingLogsRepository,
          FeedingLogsRepository,
          FeedingLogsRepository
        >
    with $Provider<FeedingLogsRepository> {
  FeedingLogsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedingLogsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedingLogsRepositoryHash();

  @$internal
  @override
  $ProviderElement<FeedingLogsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FeedingLogsRepository create(Ref ref) {
    return feedingLogsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedingLogsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedingLogsRepository>(value),
    );
  }
}

String _$feedingLogsRepositoryHash() =>
    r'994b2b82d7906bee4207e970a6e826c79b143ad5';

@ProviderFor(feedingLog)
final feedingLogProvider = FeedingLogFamily._();

final class FeedingLogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FeedingLogEntry>>,
          List<FeedingLogEntry>,
          FutureOr<List<FeedingLogEntry>>
        >
    with
        $FutureModifier<List<FeedingLogEntry>>,
        $FutureProvider<List<FeedingLogEntry>> {
  FeedingLogProvider._({
    required FeedingLogFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'feedingLogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$feedingLogHash();

  @override
  String toString() {
    return r'feedingLogProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FeedingLogEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FeedingLogEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return feedingLog(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedingLogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedingLogHash() => r'68a6ea3a324c5c8702d9b359e70813db34d4f1ef';

final class FeedingLogFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<FeedingLogEntry>>, String> {
  FeedingLogFamily._()
    : super(
        retry: null,
        name: r'feedingLogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FeedingLogProvider call(String sightingId) =>
      FeedingLogProvider._(argument: sightingId, from: this);

  @override
  String toString() => r'feedingLogProvider';
}
