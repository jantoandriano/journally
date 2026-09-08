import 'dart:convert';

import 'package:journally/core/api_config.dart';
import 'package:journally/core/gradient_palette.dart';
import 'package:journally/core/network/api_exception.dart';
import 'package:journally/features/place_search/data/nominatim_place_search_repository.dart';
import 'package:journally/features/place_search/domain/place_search_repository.dart';
import 'package:journally/features/sightings/domain/sighting.dart';
import 'package:journally/features/sightings/domain/sightings_repository.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class HttpSightingRepository implements SightingsRepository {
  HttpSightingRepository({http.Client? client, PlaceSearchRepository? placeSearch})
    : _client = client ?? http.Client(),
      _placeSearch = placeSearch ?? NominatimPlaceSearchRepository();

  final http.Client _client;
  final PlaceSearchRepository _placeSearch;

  @override
  Future<List<Sighting>> fetchSightings() async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/sightings'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ApiException(
        'GET /sightings failed with status ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return Future.wait(
      decoded.map((json) => _toSightingEntry(json as Map<String, dynamic>)),
    );
  }

  @override
  Future<Sighting> fetchSightingById(String id) async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/sightings/$id'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ApiException(
        'GET /sightings/$id failed with status ${response.statusCode}',
      );
    }

    return await _toSightingEntry(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<Sighting>> fetchNearbySightings({
    required double lat,
    required double lng,
    double radiusKm = 5,
    Species? species,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sightings/nearby').replace(
      queryParameters: {
        'lat': '$lat',
        'lng': '$lng',
        'radiusKm': '$radiusKm',
        if (species != null) 'species': species.name,
      },
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ApiException(
        'GET /sightings/nearby failed with status ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return Future.wait(
      decoded.map((json) => _toSightingEntry(json as Map<String, dynamic>)),
    );
  }

  @override
  Future<Sighting> createSighting({
    required Species species,
    required double lat,
    required double lng,
    String? notes,
    List<String> attributes = const [],
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/sightings'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'species': species.name,
            'lat': lat,
            'lng': lng,
            'attributes': attributes,
            'notes': ?notes,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw ApiException(
        'POST /sightings failed with status ${response.statusCode}',
      );
    }

    return await _toSightingEntry(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> uploadPhoto(String sightingId, XFile photo) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/sightings/$sightingId/photos'),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        await photo.readAsBytes(),
        filename: photo.name,
      ),
    );

    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw ApiException(
        'POST /sightings/$sightingId/photos failed with status ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> deleteSightById(String id) async {
    final response = await _client
        .delete(Uri.parse('${ApiConfig.baseUrl}/sightings/$id'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 204) {
      throw ApiException(
        'DELETE /sightings/$id failed with status ${response.statusCode}',
      );
    }
  }

  Future<Sighting> _toSightingEntry(Map<String, dynamic> json) async {
    final id = json['id'] as String;
    final photoUrls = (json['photoUrls'] as List<dynamic>?)?.cast<String>();
    final palette = pickGradient(id);
    final photoCount = photoUrls?.length ?? 0;
    final lat = (json['lat'] as num).toDouble();
    final lng = (json['lng'] as num).toDouble();
    final fedAtJson = json['fedAt'] as String?;
    final placeName = await _resolvePlaceName(lat, lng);

    return Sighting(
      id: id,
      animal: Species.values.byName(json['species'] as String),
      placeName: placeName,
      lat: lat,
      lng: lng,
      fed: json['fed'] as bool,
      fedAt: fedAtJson != null ? DateTime.parse(fedAtJson) : null,
      notes: (json['notes'] as String?) ?? '',
      photoCount: photoCount,
      gradientColors: palette,
      photoUrls: photoUrls,
      attributes:
          (json['attributes'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  Future<String> _resolvePlaceName(double lat, double lng) async {
    try {
      return await _placeSearch.reverseGeocode(lat: lat, lng: lng);
    } catch (_) {
      // Geocoding is best-effort — fall back to raw coordinates rather
      // than failing the whole sighting fetch.
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }
}
