import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:journally/features/home/domain/journal_entry.dart';
import 'package:journally/features/home/presentation/widgets/journal_card.dart';

void main() {
  testWidgets('does not overflow in a narrow grid cell with wrapping tags', (
    tester,
  ) async {
    final entry = JournalEntry(
      id: 'e1',
      placeName: 'A Very Long Cafe Name That Might Wrap',
      neighborhood: 'Some Long Neighborhood Name',
      city: 'City',
      orderItems: [
        OrderItem(name: 'Espresso', price: 3.5),
        OrderItem(name: 'Croissant', price: 3.75),
        OrderItem(name: 'Cold Brew', price: 4.5),
      ],
      photoCount: 3,
      photoUrls: const [],
      gradientColors: const [Color(0xFFE7C9A5), Color(0xFFB8763F)],
      visitedAt: DateTime(2026, 1, 1),
    );

    // Mirrors the grid's actual cell math at a narrow window width, where
    // the fixed text stack (name/tags/location) is most likely to exceed
    // the cell's height budget.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 140,
              height: 140 / 0.58,
              child: JournalCard(entry: entry),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
