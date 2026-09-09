import 'package:dio/dio.dart';
import 'package:journally/core/network/api_exception.dart';
import 'package:journally/features/feeding_logs/domain/feeding_log_entry.dart';
import 'package:journally/features/feeding_logs/domain/feeding_logs_repository.dart';

class HttpFeedingLogsRepository implements FeedingLogsRepository {
  HttpFeedingLogsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<FeedingLogEntry>> fetchFeedingLog(String sightingId) async {
    try {
      final response = await _dio.get<List<dynamic>>('/sightings/$sightingId/feedings');
      return response.data!
          .map((json) => _toFeedingLogEntry(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        'GET /sightings/$sightingId/feedings failed with status ${e.response?.statusCode}',
      );
    }
  }

  @override
  Future<FeedingLogEntry> createFeedingLogEntry(String sightingId, {String? note}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sightings/$sightingId/feedings',
        data: {'note': ?note},
      );
      return _toFeedingLogEntry(response.data!);
    } on DioException catch (e) {
      throw ApiException(
        'POST /sightings/$sightingId/feedings failed with status ${e.response?.statusCode}',
      );
    }
  }

  FeedingLogEntry _toFeedingLogEntry(Map<String, dynamic> json) {
    return FeedingLogEntry(
      id: json['id'] as String,
      sightingId: json['sightingId'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
