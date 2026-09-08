import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../domain/cafe_entry.dart';
import '../domain/cafe_repository.dart';
import '../../../core/api_config.dart';
import '../../../core/gradient_palette.dart';
import '../../../core/network/api_exception.dart';

class HttpCafeRepository implements CafeRepository {
  HttpCafeRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<CafeEntry>> fetchCafes() async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/entries'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ApiException(
        'GET /entries failed with status ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((json) => _toCafeEntry(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CafeEntry> fetchCafeById(String id) async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/entries/$id'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ApiException(
        'GET /entries/$id failed with status ${response.statusCode}',
      );
    }

    return _toCafeEntry(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCafe(String id) async {
    final response = await _client
        .delete(Uri.parse('${ApiConfig.baseUrl}/entries/$id'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 204) {
      throw ApiException(
        'DELETE /entries/$id failed with status ${response.statusCode}',
      );
    }
  }

  @override
  Future<CafeEntry> createCafe({
    required String placeName,
    required String neighborhood,
    required String city,
    required List<OrderItem> orderItems,
    required DateTime visitedAt,
    double? rating,
    String notes = '',
    List<String> attributes = const [],
    double? lat,
    double? lng,
    String? placeId,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/entries'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'placeName': placeName,
            'neighborhood': neighborhood,
            'city': city,
            'orderItems': orderItems.map((item) => item.toJson()).toList(),
            'visitedAt': visitedAt.toIso8601String(),
            'notes': notes,
            'attributes': attributes,
            'rating': ?rating,
            'lat': ?lat,
            'lng': ?lng,
            'placeId': ?placeId,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw ApiException(
        'POST /entries failed with status ${response.statusCode}',
      );
    }

    return _toCafeEntry(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<CafeEntry> updateCafe(
    String id, {
    String? placeName,
    String? neighborhood,
    String? city,
    List<OrderItem>? orderItems,
    double? lat,
    double? lng,
    String? placeId,
  }) async {
    final response = await _client
        .patch(
          Uri.parse('${ApiConfig.baseUrl}/entries/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'placeName': ?placeName,
            'neighborhood': ?neighborhood,
            'city': ?city,
            if (orderItems != null)
              'orderItems': orderItems.map((item) => item.toJson()).toList(),
            'lat': ?lat,
            'lng': ?lng,
            'placeId': ?placeId,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ApiException(
        'PATCH /entries/$id failed with status ${response.statusCode}',
      );
    }

    return _toCafeEntry(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> uploadPhoto(String entryId, XFile photo) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/entries/$entryId/photos'),
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
        'POST /entries/$entryId/photos failed with status ${response.statusCode}',
      );
    }
  }

  @override
  Future<List<CafeEntry>> fetchNearbyCafe({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/entries/nearby').replace(
      queryParameters: {'lat': '$lat', 'lng': '$lng', 'radiusKm': '$radiusKm'},
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ApiException(
        'GET /entries/nearby failed with status ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((json) => _toCafeEntry(json as Map<String, dynamic>))
        .toList();
  }

  CafeEntry _toCafeEntry(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final photoUrls = (json['photoUrls'] as List<dynamic>).cast<String>();
    final palette = pickGradient(id);

    return CafeEntry(
      id: id,
      placeName: json['placeName'] as String,
      neighborhood: json['neighborhood'] as String,
      city: json['city'] as String,
      orderItems: (json['orderItems'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      photoCount: (json['photoCount'] as num?)?.toInt() ?? photoUrls.length,
      photoUrls: photoUrls,
      gradientColors: palette,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
      rating: (json['rating'] as num?)?.toDouble(),
      notes: json['notes'] as String? ?? '',
      attributes:
          (json['attributes'] as List<dynamic>?)?.cast<String>() ?? const [],
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      placeId: json['placeId'] as String?,
    );
  }
}
