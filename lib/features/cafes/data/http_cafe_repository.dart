import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/cafe_entry.dart';
import '../domain/cafe_repository.dart';
import '../../../core/gradient_palette.dart';
import '../../../core/network/api_exception.dart';

class HttpCafeRepository implements CafeRepository {
  HttpCafeRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<CafeEntry>> fetchCafes() async {
    try {
      final response = await _dio.get<List<dynamic>>('/entries');
      return response.data!
          .map((json) => _toCafeEntry(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException('GET /entries failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<CafeEntry> fetchCafeById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/entries/$id');
      return _toCafeEntry(response.data!);
    } on DioException catch (e) {
      throw ApiException('GET /entries/$id failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<void> deleteCafe(String id) async {
    try {
      await _dio.delete('/entries/$id');
    } on DioException catch (e) {
      throw ApiException('DELETE /entries/$id failed with status ${e.response?.statusCode}');
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
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/entries',
        data: {
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
        },
      );
      return _toCafeEntry(response.data!);
    } on DioException catch (e) {
      throw ApiException('POST /entries failed with status ${e.response?.statusCode}');
    }
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
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/entries/$id',
        data: {
          'placeName': ?placeName,
          'neighborhood': ?neighborhood,
          'city': ?city,
          if (orderItems != null)
            'orderItems': orderItems.map((item) => item.toJson()).toList(),
          'lat': ?lat,
          'lng': ?lng,
          'placeId': ?placeId,
        },
      );
      return _toCafeEntry(response.data!);
    } on DioException catch (e) {
      throw ApiException('PATCH /entries/$id failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<void> uploadPhoto(String entryId, XFile photo) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromBytes(await photo.readAsBytes(), filename: photo.name),
      });
      await _dio.post('/entries/$entryId/photos', data: formData);
    } on DioException catch (e) {
      throw ApiException(
        'POST /entries/$entryId/photos failed with status ${e.response?.statusCode}',
      );
    }
  }

  @override
  Future<List<CafeEntry>> fetchNearbyCafe({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/entries/nearby',
        queryParameters: {'lat': lat, 'lng': lng, 'radiusKm': radiusKm},
      );
      return response.data!
          .map((json) => _toCafeEntry(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException('GET /entries/nearby failed with status ${e.response?.statusCode}');
    }
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
      attributes: (json['attributes'] as List<dynamic>?)?.cast<String>() ?? const [],
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      placeId: json['placeId'] as String?,
    );
  }
}
