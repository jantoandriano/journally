import 'journal_entry.dart';

abstract class JournalRepository {
  Future<List<JournalEntry>> fetchEntries();

  Future<JournalEntry> fetchEntryById(String id);

  Future<void> deleteEntry(String id);

  Future<JournalEntry> createEntry({
    required String placeName,
    required String neighborhood,
    required String city,
    required List<OrderItem> orderItems,
    double? lat,
    double? lng,
    String? placeId,
  });

  Future<JournalEntry> updateEntry(
    String id, {
    String? placeName,
    String? neighborhood,
    String? city,
    List<OrderItem>? orderItems,
    double? lat,
    double? lng,
    String? placeId,
  });
}
