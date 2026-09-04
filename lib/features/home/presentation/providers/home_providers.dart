import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/http_journal_repository.dart';
import '../../domain/journal_entry.dart';
import '../../domain/journal_repository.dart';

part 'home_providers.g.dart';

@riverpod
JournalRepository journalRepository(Ref ref) {
  return HttpJournalRepository();
}

// Kept alive (not autoDispose) — splash reads this future once during
// warm-up via `ref.read`, which doesn't itself keep an autoDispose provider
// alive. Splash rebuilds constantly (ticking animations), and a disposal
// between rebuilds would silently restart the fetch and leave the future
// splash captured never settling.
@Riverpod(keepAlive: true)
Future<List<JournalEntry>> journalEntries(Ref ref) {
  return ref.watch(journalRepositoryProvider).fetchEntries();
}

@riverpod
Future<JournalEntry> journalEntry(Ref ref, String id) {
  return ref.watch(journalRepositoryProvider).fetchEntryById(id);
}

/// Central Kemang, South Jakarta — used only by the "Near Kemang" cafe
/// chip. This is a one-off named-place override, not the user's device
/// location; the backend has no neighborhood-to-coordinate lookup, so
/// this is hardcoded here rather than invented server-side.
const kemangLat = -6.2607;
const kemangLng = 106.8133;
const kemangRadiusKm = 2.0;

@riverpod
Future<List<JournalEntry>> nearbyEntries(Ref ref) {
  return ref
      .watch(journalRepositoryProvider)
      .fetchNearbyEntries(
        lat: kemangLat,
        lng: kemangLng,
        radiusKm: kemangRadiusKm,
      );
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String value) => state = value;
}
