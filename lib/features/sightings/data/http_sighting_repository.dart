import 'package:dio/dio.dart';
import 'package:journally/core/gradient_palette.dart';
import 'package:journally/core/network/api_exception.dart';
import 'package:journally/features/place_search/data/nominatim_place_search_repository.dart';
import 'package:journally/features/place_search/domain/place_search_repository.dart';
import 'package:journally/features/sightings/domain/sighting.dart';
import 'package:journally/features/sightings/domain/sightings_repository.dart';
import 'package:image_picker/image_picker.dart';

class HttpSightingRepository implements SightingsRepository {
  HttpSightingRepository({required Dio dio, PlaceSearchRepository? placeSearch})
    : _dio = dio,
      _placeSearch = placeSearch ?? NominatimPlaceSearchRepository();

  final Dio _dio;
  final PlaceSearchRepository _placeSearch;

  @override
  Future<List<Sighting>> fetchSightings() async {
    try {
      final response = await _dio.get<List<dynamic>>('/sightings');
      return Future.wait(
        response.data!.map((json) => _toSightingEntry(json as Map<String, dynamic>)),
      );
    } on DioException catch (e) {
      throw ApiException('GET /sightings failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<Sighting> fetchSightingById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/sightings/$id');
      return await _toSightingEntry(response.data!);
    } on DioException catch (e) {
      throw ApiException('GET /sightings/$id failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<List<Sighting>> fetchNearbySightings({
    required double lat,
    required double lng,
    double radiusKm = 5,
    Species? species,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/sightings/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radiusKm': radiusKm,
          if (species != null) 'species': species.name,
        },
      );
      return Future.wait(
        response.data!.map((json) => _toSightingEntry(json as Map<String, dynamic>)),
      );
    } on DioException catch (e) {
      throw ApiException('GET /sightings/nearby failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<Sighting> createSighting({
    required Species species,
    required double lat,
    required double lng,
    String? notes,
    List<String> attributes = const [],
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sightings',
        data: {
          'species': species.name,
          'lat': lat,
          'lng': lng,
          'attributes': attributes,
          'notes': ?notes,
        },
      );
      return await _toSightingEntry(response.data!);
    } on DioException catch (e) {
      throw ApiException('POST /sightings failed with status ${e.response?.statusCode}');
    }
  }

  @override
  Future<void> uploadPhoto(String sightingId, XFile photo) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromBytes(await photo.readAsBytes(), filename: photo.name),
      });
      await _dio.post('/sightings/$sightingId/photos', data: formData);
    } on DioException catch (e) {
      throw ApiException(
        'POST /sightings/$sightingId/photos failed with status ${e.response?.statusCode}',
      );
    }
  }

  @override
  Future<void> deleteSightById(String id) async {
    try {
      await _dio.delete('/sightings/$id');
    } on DioException catch (e) {
      throw ApiException('DELETE /sightings/$id failed with status ${e.response?.statusCode}');
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
    final createdAtJson = json['createdAt'] as String?;
    final updatedAtJson = json['updatedAt'] as String?;
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
      createdAt: createdAtJson != null ? DateTime.parse(createdAtJson) : null,
      updatedAt: updatedAtJson != null ? DateTime.parse(updatedAtJson) : null,
      attributes: (json['attributes'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  Future<String> _resolvePlaceName(double lat, double lng) async {
    try {
      return await _placeSearch.reverseGeocode(lat: lat, lng: lng);
    } catch (_) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }
}
