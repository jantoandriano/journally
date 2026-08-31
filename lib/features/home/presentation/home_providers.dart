import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/http_journal_repository.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';

part 'home_providers.g.dart';

@riverpod
JournalRepository journalRepository(Ref ref) {
  return HttpJournalRepository();
}

@riverpod
Future<List<JournalEntry>> journalEntries(Ref ref) {
  return ref.watch(journalRepositoryProvider).fetchEntries();
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String value) => state = value;
}
