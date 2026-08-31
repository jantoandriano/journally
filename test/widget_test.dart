import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:journally/main.dart';

void main() {
  testWidgets('Home screen loads and shows the place count', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: JournallyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Journally'), findsOneWidget);
    expect(find.text('6 places visited'), findsOneWidget);
  });
}
