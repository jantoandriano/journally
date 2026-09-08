import 'dart:convert';

import 'package:journally/core/api_config.dart';
import 'package:journally/core/network/api_exception.dart';
import 'package:journally/features/feeding_logs/domain/feeding_log_entry.dart';
import 'package:journally/features/feeding_logs/domain/feeding_logs_repository.dart';
import 'package:http/http.dart' as http;

class HttpFeedingLogsRepository implements FeedingLogsRepository {
  HttpFeedingLogsRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<FeedingLogEntry>> fetchFeedingLog(String sightingId) async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/sightings/$sightingId/feedings'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ApiException(
        'GET /sightings/$sightingId/feedings failed with status ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((json) => _toFeedingLogEntry(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FeedingLogEntry> createFeedingLogEntry(
    String sightingId, {
    String? note,
  }) async {
    final response = await _client
        .post(
          Uri.parse(
            '${ApiConfig.baseUrl}/sightings/$sightingId/feedings',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'note': ?note}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw ApiException(
        'POST /sightings/$sightingId/feedings failed with status ${response.statusCode}',
      );
    }

    return _toFeedingLogEntry(jsonDecode(response.body) as Map<String, dynamic>);
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
