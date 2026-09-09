import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/features/feeding_logs/data/http_feeding_logs_repository.dart';

import '../../helpers/fake_http_client_adapter.dart';

void main() {
  Dio buildDio(FakeHttpClientAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.httpClientAdapter = adapter;
    return dio;
  }

  test('fetchFeedingLog GETs /sightings/:id/feedings', () async {
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/sightings/s1/feedings');
        return (
          statusCode: 200,
          data: [
            {
              'id': 'f1',
              'sightingId': 's1',
              'note': 'Wet food',
              'createdAt': '2026-01-01T00:00:00.000Z',
            },
          ],
        );
      }),
    );
    final repo = HttpFeedingLogsRepository(dio: dio);

    final entries = await repo.fetchFeedingLog('s1');

    expect(entries, hasLength(1));
    expect(entries.first.note, 'Wet food');
  });

  test('createFeedingLogEntry POSTs the note', () async {
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/sightings/s1/feedings');
        expect(options.data, {'note': 'Dry kibble'});
        return (
          statusCode: 201,
          data: {
            'id': 'f2',
            'sightingId': 's1',
            'note': 'Dry kibble',
            'createdAt': '2026-01-01T00:00:00.000Z',
          },
        );
      }),
    );
    final repo = HttpFeedingLogsRepository(dio: dio);

    final entry = await repo.createFeedingLogEntry('s1', note: 'Dry kibble');

    expect(entry.note, 'Dry kibble');
  });
}
