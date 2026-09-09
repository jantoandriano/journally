import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/features/cafes/data/http_cafe_repository.dart';

import '../../helpers/fake_http_client_adapter.dart';

void main() {
  Dio buildDio(FakeHttpClientAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.httpClientAdapter = adapter;
    return dio;
  }

  Map<String, dynamic> cafeJson({String id = 'c1'}) => {
    'id': id,
    'placeName': 'Blue Bottle',
    'neighborhood': 'Hayes Valley',
    'city': 'San Francisco',
    'orderItems': <dynamic>[],
    'photoCount': 0,
    'photoUrls': <dynamic>[],
    'visitedAt': '2026-01-01T00:00:00.000Z',
    'rating': null,
    'notes': '',
    'attributes': <dynamic>[],
    'lat': null,
    'lng': null,
    'placeId': null,
  };

  test('fetchCafes GETs /entries and parses the list', () async {
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/entries');
        return (statusCode: 200, data: [cafeJson()]);
      }),
    );
    final repo = HttpCafeRepository(dio: dio);

    final cafes = await repo.fetchCafes();

    expect(cafes, hasLength(1));
    expect(cafes.first.placeName, 'Blue Bottle');
  });

  test('fetchCafeById GETs /entries/:id', () async {
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/entries/c1');
        return (statusCode: 200, data: cafeJson());
      }),
    );
    final repo = HttpCafeRepository(dio: dio);

    final cafe = await repo.fetchCafeById('c1');

    expect(cafe.id, 'c1');
  });

  test('deleteCafe DELETEs /entries/:id', () async {
    var called = false;
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.method, 'DELETE');
        called = true;
        return (statusCode: 204, data: null);
      }),
    );
    final repo = HttpCafeRepository(dio: dio);

    await repo.deleteCafe('c1');

    expect(called, isTrue);
  });
}
