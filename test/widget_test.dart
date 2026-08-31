import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:journally/features/home/domain/journal_entry.dart';
import 'package:journally/features/home/domain/journal_repository.dart';
import 'package:journally/features/home/presentation/home_providers.dart';
import 'package:journally/main.dart';

class _FakeJournalRepository implements JournalRepository {
  @override
  Future<List<JournalEntry>> fetchEntries() async {
    return List.generate(
      6,
      (i) => JournalEntry(
        id: '$i',
        placeName: 'Place $i',
        neighborhood: 'Neighborhood $i',
        city: 'City',
        orderItems: [OrderItem(name: 'Item')],
        photoCount: 0,
        gradientColors: const [Color(0xFFE7C9A5), Color(0xFFB8763F)],
      ),
    );
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

void main() {
  testWidgets('Home screen loads and shows the place count', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            _FakeJournalRepository(),
          ),
        ],
        child: const JournallyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Journally'), findsOneWidget);
    expect(find.text('6 places visited'), findsOneWidget);
  });
}
