import 'dart:convert';

import 'package:journally/core/api_config.dart';
import 'package:journally/features/home/data/http_journal_repository.dart';
import 'package:journally/features/sightings/domain/sighting.dart';
import 'package:journally/features/sightings/domain/sightings_repository.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// [JournalEntry.gradientColors] is a client-only placeholder (the API has
/// no concept of it) shown behind the photo area until real photo rendering
/// is built. Picked deterministically per entry so the same entry always
/// gets the same gradient across app launches.
const _gradientPalette = [
  [Color(0xFFE7C9A5), Color(0xFFB8763F)],
  [Color(0xFFD8C7E8), Color(0xFF8C6FAE)],
  [Color(0xFFC9E0D8), Color(0xFF5F9782)],
  [Color(0xFFF0D8B0), Color(0xFFC98A4B)],
  [Color(0xFFCFE0EE), Color(0xFF6B92B8)],
  [Color(0xFFE3D3C3), Color(0xFF9C7A5B)],
];

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
      throw JournalApiException(
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
      throw JournalApiException(
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
      throw JournalApiException(
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
    final palette =
        _gradientPalette[id.hashCode.abs() % _gradientPalette.length];
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
