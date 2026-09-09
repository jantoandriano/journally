import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/features/place_search/domain/place_search_repository.dart';
import 'package:journally/features/sightings/data/http_sighting_repository.dart';
import 'package:journally/features/sightings/domain/sighting.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_http_client_adapter.dart';

class FakePlaceSearchRepository extends Fake implements PlaceSearchRepository {
  @override
  Future<String> reverseGeocode({required double lat, required double lng}) async => 'Test Place';
}

void main() {
  Dio buildDio(FakeHttpClientAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.httpClientAdapter = adapter;
    return dio;
  }

  Map<String, dynamic> sightingJson({String id = 's1'}) => {
    'id': id,
    'species': 'cat',
    'lat': 0.0,
    'lng': 0.0,
    'notes': null,
    'fed': false,
    'fedAt': null,
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:00.000Z',
    'photoUrls': <dynamic>[],
    'attributes': <dynamic>[],
  };

  test('fetchSightings GETs /sightings and resolves place names', () async {
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/sightings');
        return (statusCode: 200, data: [sightingJson()]);
      }),
    );
    final repo = HttpSightingRepository(dio: dio, placeSearch: FakePlaceSearchRepository());

    final sightings = await repo.fetchSightings();

    expect(sightings, hasLength(1));
    expect(sightings.first.placeName, 'Test Place');
  });

  test('createSighting POSTs species/lat/lng to /sightings', () async {
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.path, '/sightings');
        expect(options.data, {
          'species': 'dog',
          'lat': 1.0,
          'lng': 2.0,
          'attributes': <String>[],
        });
        return (statusCode: 201, data: sightingJson());
      }),
    );
    final repo = HttpSightingRepository(dio: dio, placeSearch: FakePlaceSearchRepository());

    await repo.createSighting(species: Species.dog, lat: 1.0, lng: 2.0);
  });

  test('deleteSightById DELETEs /sightings/:id', () async {
    var called = false;
    final dio = buildDio(
      FakeHttpClientAdapter((options) {
        expect(options.method, 'DELETE');
        called = true;
        return (statusCode: 204, data: null);
      }),
    );
    final repo = HttpSightingRepository(dio: dio, placeSearch: FakePlaceSearchRepository());

    await repo.deleteSightById('s1');

    expect(called, isTrue);
  });
}
