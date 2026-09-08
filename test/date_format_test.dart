import 'package:flutter_test/flutter_test.dart';
import 'package:journally/core/date_format.dart';

void main() {
  test('formatDateTime shows the local time, not the UTC time', () {
    final utc = DateTime.utc(2026, 3, 12, 23, 30);
    final local = utc.toLocal();

    expect(formatDateTime(utc), formatDateTime(local));
  });

  test('formatDate shows the local date, not the UTC date', () {
    final utc = DateTime.utc(2026, 3, 12, 23, 30);
    final local = utc.toLocal();

    expect(formatDate(utc), formatDate(local));
  });
}
