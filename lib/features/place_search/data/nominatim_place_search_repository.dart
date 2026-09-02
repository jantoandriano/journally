import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/place_search_repository.dart';
import '../domain/place_search_result.dart';

class NominatimPlaceSearchRepository implements PlaceSearchRepository {
  NominatimPlaceSearchRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _userAgent = 'Journally/1.0';

  @override
  Future<List<PlaceSearchResult>> search(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '8',
    });

    final response = await _client
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw PlaceSearchApiException(
        'GET /search failed with status ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((json) => _toPlaceSearchResult(json as Map<String, dynamic>))
        .toList();
  }

  PlaceSearchResult _toPlaceSearchResult(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? const {};
    final displayName = json['display_name'] as String? ?? '';
    final name = (json['name'] as String?)?.isNotEmpty ?? false
        ? json['name'] as String
        : displayName.split(',').first.trim();

    final neighborhood =
        address['suburb'] as String? ??
        address['neighbourhood'] as String? ??
        '';
    final city =
        address['city'] as String? ??
        address['town'] as String? ??
        address['village'] as String? ??
        address['county'] as String? ??
        '';

    return PlaceSearchResult(
      placeId: json['place_id'].toString(),
      name: name,
      neighborhood: neighborhood,
      city: city,
      lat: double.parse(json['lat'] as String),
      lng: double.parse(json['lon'] as String),
    );
  }
}

class PlaceSearchApiException implements Exception {
  PlaceSearchApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
