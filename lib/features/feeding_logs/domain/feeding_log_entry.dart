class FeedingLogEntry {
  const FeedingLogEntry({
    required this.id,
    required this.sightingId,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String sightingId;
  final String? note;
  final DateTime createdAt;
}
