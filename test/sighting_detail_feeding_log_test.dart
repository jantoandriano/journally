import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:journally/features/feeding_logs/domain/feeding_log_entry.dart';
import 'package:journally/features/feeding_logs/domain/feeding_logs_repository.dart';
import 'package:journally/features/feeding_logs/presentation/providers/feeding_logs_providers.dart';
import 'package:journally/features/sightings/domain/sighting.dart';
import 'package:journally/features/sightings/presentation/widgets/sighting_detail_feeding_log.dart';

class _FakeFeedingLogsRepository implements FeedingLogsRepository {
  _FakeFeedingLogsRepository(this.entries);

  final List<FeedingLogEntry> entries;
  String? createdNote;
  bool createCalled = false;

  @override
  Future<List<FeedingLogEntry>> fetchFeedingLog(String sightingId) async =>
      entries;

  @override
  Future<FeedingLogEntry> createFeedingLogEntry(
    String sightingId, {
    String? note,
  }) async {
    createCalled = true;
    createdNote = note;
    final entry = FeedingLogEntry(
      id: 'new-entry',
      sightingId: sightingId,
      note: note,
      createdAt: DateTime(2026, 9, 8, 9, 0),
    );
    entries.insert(0, entry);
    return entry;
  }
}

Sighting _buildSighting() => const Sighting(
  id: 's1',
  animal: Species.cat,
  placeName: '0.0000, 0.0000',
  gradientColors: [Color(0xFFE7C9A5), Color(0xFFB8763F)],
  fed: false,
  notes: '',
  photoCount: 0,
  attributes: [],
);

void main() {
  testWidgets('shows feeding log entries fetched from the repository', (
    tester,
  ) async {
    final repo = _FakeFeedingLogsRepository([
      FeedingLogEntry(
        id: 'e1',
        sightingId: 's1',
        note: 'Wet food',
        createdAt: DateTime(2026, 9, 7, 18, 40),
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [feedingLogsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: SightingDetailFeedingLog(sighting: _buildSighting()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wet food'), findsOneWidget);
  });

  testWidgets('logging a feed calls the repository and refreshes the list', (
    tester,
  ) async {
    final repo = _FakeFeedingLogsRepository([]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [feedingLogsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: SightingDetailFeedingLog(sighting: _buildSighting()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log a feed'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Dry kibble');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.createCalled, isTrue);
    expect(repo.createdNote, 'Dry kibble');
    expect(find.text('Dry kibble'), findsOneWidget);
  });
}
