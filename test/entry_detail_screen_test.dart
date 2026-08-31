import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:journally/features/home/domain/journal_entry.dart';
import 'package:journally/features/home/domain/journal_repository.dart';
import 'package:journally/features/home/presentation/entry_detail_screen.dart';
import 'package:journally/features/home/presentation/home_providers.dart';

class _DetailFakeRepository implements JournalRepository {
  _DetailFakeRepository(this.entry);

  final JournalEntry entry;
  bool deleteCalled = false;
  bool deleteShouldFail = false;

  @override
  Future<List<JournalEntry>> fetchEntries() async => [entry];

  @override
  Future<JournalEntry> fetchEntryById(String id) async => entry;

  @override
  Future<void> deleteEntry(String id) async {
    deleteCalled = true;
    if (deleteShouldFail) {
      throw Exception('boom');
    }
  }

  @override
  Future<JournalEntry> createEntry({
    required String placeName,
    required String neighborhood,
    required String city,
    required List<OrderItem> orderItems,
    double? lat,
    double? lng,
    String? placeId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<JournalEntry> updateEntry(
    String id, {
    String? placeName,
    String? neighborhood,
    String? city,
    List<OrderItem>? orderItems,
    double? lat,
    double? lng,
    String? placeId,
  }) {
    throw UnimplementedError();
  }
}

JournalEntry _buildEntry({double? lat, double? lng}) => JournalEntry(
  id: 'e1',
  placeName: 'Cafe One',
  neighborhood: 'Downtown',
  city: 'Metro City',
  orderItems: [
    OrderItem(name: 'Latte', price: 4.5),
    OrderItem(name: 'Croissant', price: 3.25),
  ],
  photoCount: 2,
  photoUrls: const ['/uploads/a.jpg', '/uploads/b.jpg'],
  gradientColors: const [Color(0xFFE7C9A5), Color(0xFFB8763F)],
  lat: lat,
  lng: lng,
);

void main() {
  testWidgets('shows order items and total spent', (tester) async {
    final repo = _DetailFakeRepository(_buildEntry(lat: 40.0, lng: -73.0));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: EntryDetailScreen(entryId: 'e1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cafe One'), findsOneWidget);
    expect(find.text('Latte'), findsOneWidget);
    expect(find.text('Croissant'), findsOneWidget);
    expect(find.text('\$7.75'), findsOneWidget);
  });

  testWidgets('hides open-in-maps button when entry has no coordinates', (
    tester,
  ) async {
    final repo = _DetailFakeRepository(_buildEntry());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: EntryDetailScreen(entryId: 'e1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.directions_outlined), findsNothing);
  });

  testWidgets('confirming delete calls deleteEntry and pops back', (
    tester,
  ) async {
    final repo = _DetailFakeRepository(_buildEntry());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EntryDetailScreen(entryId: 'e1'),
                    ),
                  ),
                  child: const Text('Open detail'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();
    expect(find.byType(EntryDetailScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repo.deleteCalled, isTrue);
    expect(find.text('Open detail'), findsOneWidget);
    expect(find.byType(EntryDetailScreen), findsNothing);
  });
}
