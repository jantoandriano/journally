import 'feeding_log_entry.dart';

abstract class FeedingLogsRepository {
  Future<List<FeedingLogEntry>> fetchFeedingLog(String sightingId);

  Future<FeedingLogEntry> createFeedingLogEntry(
    String sightingId, {
    String? note,
  });
}
