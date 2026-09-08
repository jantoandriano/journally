import 'dart:convert';

import 'package:journally/core/api_config.dart';
import 'package:journally/core/gradient_palette.dart';
import 'package:journally/core/network/api_exception.dart';
import 'package:journally/features/sightings/domain/sighting.dart';
import 'package:journally/features/sightings/domain/sightings_repository.dart';
import 'package:http/http.dart' as http;

class HttpSightingRepository implements SightingsRepository {
  HttpSightingRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

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
    return decoded
        .map((json) => _toSightingEntry(json as Map<String, dynamic>))
        .toList();
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

    return _toSightingEntry(jsonDecode(response.body) as Map<String, dynamic>);
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
    return decoded
        .map((json) => _toSightingEntry(json as Map<String, dynamic>))
        .toList();
  }

  Sighting _toSightingEntry(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final photoUrls = (json['photoUrls'] as List<dynamic>?)?.cast<String>();
    final palette = pickGradient(id);
    final photoCount = photoUrls?.length ?? 0;
    final lat = (json['lat'] as num).toDouble();
    final lng = (json['lng'] as num).toDouble();
    final fedAtJson = json['fedAt'] as String?;

    return Sighting(
      id: id,
      animal: Species.values.byName(json['species'] as String),
      // API has no reverse-geocoded address yet, only coordinates.
      placeName: '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
      lat: lat,
      lng: lng,
      fed: json['fed'] as bool,
      fedAt: fedAtJson != null ? DateTime.parse(fedAtJson) : null,
      notes: (json['notes'] as String?) ?? '',
      photoCount: photoCount,
      gradientColors: palette,
      photoUrls: photoUrls,
    );
  }
}
