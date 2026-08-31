// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(journalRepository)
final journalRepositoryProvider = JournalRepositoryProvider._();

final class JournalRepositoryProvider
    extends
        $FunctionalProvider<
          JournalRepository,
          JournalRepository,
          JournalRepository
        >
    with $Provider<JournalRepository> {
  JournalRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journalRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journalRepositoryHash();

  @$internal
  @override
  $ProviderElement<JournalRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JournalRepository create(Ref ref) {
    return journalRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JournalRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JournalRepository>(value),
    );
  }
}

String _$journalRepositoryHash() => r'21109c0302bbf44d715ac65f21b4e9e57a11bcc2';

@ProviderFor(journalEntries)
final journalEntriesProvider = JournalEntriesProvider._();

final class JournalEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<JournalEntry>>,
          List<JournalEntry>,
          FutureOr<List<JournalEntry>>
        >
    with
        $FutureModifier<List<JournalEntry>>,
        $FutureProvider<List<JournalEntry>> {
  JournalEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journalEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journalEntriesHash();

  @$internal
  @override
  $FutureProviderElement<List<JournalEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<JournalEntry>> create(Ref ref) {
    return journalEntries(ref);
  }
}

String _$journalEntriesHash() => r'ac07e30eaaaedcc8242ef26a3d22c7dbaea285a0';

@ProviderFor(journalEntry)
final journalEntryProvider = JournalEntryFamily._();

final class JournalEntryProvider
    extends
        $FunctionalProvider<
          AsyncValue<JournalEntry>,
          JournalEntry,
          FutureOr<JournalEntry>
        >
    with $FutureModifier<JournalEntry>, $FutureProvider<JournalEntry> {
  JournalEntryProvider._({
    required JournalEntryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'journalEntryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$journalEntryHash();

  @override
  String toString() {
    return r'journalEntryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<JournalEntry> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<JournalEntry> create(Ref ref) {
    final argument = this.argument as String;
    return journalEntry(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is JournalEntryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$journalEntryHash() => r'0c2aa904ba432d71627b3a98c8e77c3a95295074';

final class JournalEntryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<JournalEntry>, String> {
  JournalEntryFamily._()
    : super(
        retry: null,
        name: r'journalEntryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  JournalEntryProvider call(String id) =>
      JournalEntryProvider._(argument: id, from: this);

  @override
  String toString() => r'journalEntryProvider';
}

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryProvider._();

final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
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
