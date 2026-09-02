import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:journally/features/home/domain/journal_entry.dart';
import 'package:journally/features/home/domain/journal_repository.dart';
import 'package:journally/features/home/presentation/entry_detail_screen.dart';
import 'package:journally/features/home/presentation/providers/home_providers.dart';

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
    required DateTime visitedAt,
    double? rating,
    String notes = '',
    List<String> attributes = const [],
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

  @override
  Future<void> uploadPhoto(String entryId, XFile photo) {
    throw UnimplementedError();
  }
}

JournalEntry _buildEntry({double? rating, List<String> attributes = const []}) =>
    JournalEntry(
      id: 'e1',
      placeName: 'Cafe One',
      neighborhood: 'Downtown',
      city: 'Metro City',
      orderItems: [
        OrderItem(name: 'Latte', price: 4.5),
        OrderItem(name: 'Croissant', price: 3.25, note: 'extra warm'),
      ],
      photoCount: 2,
      photoUrls: const [],
      gradientColors: const [Color(0xFFE7C9A5), Color(0xFFB8763F)],
      visitedAt: DateTime(2026, 3, 12),
      rating: rating,
      notes: 'Loved the corner table by the window.',
      attributes: attributes,
    );

void main() {
  testWidgets('shows place name, order items, and notes', (tester) async {
    final repo = _DetailFakeRepository(
      _buildEntry(rating: 4.5, attributes: const ['Cozy', 'Great pastries']),
    );

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
    expect(find.text('extra warm'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('Cozy'), findsOneWidget);
    expect(find.text('Loved the corner table by the window.'), findsOneWidget);
  });

  testWidgets('hides the rating chip when entry has no rating', (tester) async {
    final repo = _DetailFakeRepository(_buildEntry());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: EntryDetailScreen(entryId: 'e1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('deleting from the overflow menu calls deleteEntry and pops back', (
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

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repo.deleteCalled, isTrue);
    expect(find.text('Open detail'), findsOneWidget);
    expect(find.byType(EntryDetailScreen), findsNothing);
  });
}
