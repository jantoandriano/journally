import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';
import '../../../core/api_config.dart';

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

class HttpJournalRepository implements JournalRepository {
  HttpJournalRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<JournalEntry>> fetchEntries() async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/entries'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw JournalApiException(
        'GET /entries failed with status ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((json) => _toJournalEntry(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<JournalEntry> fetchEntryById(String id) async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/entries/$id'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw JournalApiException(
        'GET /entries/$id failed with status ${response.statusCode}',
      );
    }

    return _toJournalEntry(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteEntry(String id) async {
    final response = await _client
        .delete(Uri.parse('${ApiConfig.baseUrl}/entries/$id'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 204) {
      throw JournalApiException(
        'DELETE /entries/$id failed with status ${response.statusCode}',
      );
    }
  }

  @override
  Future<JournalEntry> createEntry({
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
      throw JournalApiException(
        'POST /entries failed with status ${response.statusCode}',
      );
    }

    return _toJournalEntry(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<JournalEntry> updateEntry(
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
      throw JournalApiException(
        'PATCH /entries/$id failed with status ${response.statusCode}',
      );
    }

    return _toJournalEntry(jsonDecode(response.body) as Map<String, dynamic>);
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
      throw JournalApiException(
        'POST /entries/$entryId/photos failed with status ${response.statusCode}',
      );
    }
  }

  JournalEntry _toJournalEntry(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final photoUrls = (json['photoUrls'] as List<dynamic>).cast<String>();
    final palette =
        _gradientPalette[id.hashCode.abs() % _gradientPalette.length];

    return JournalEntry(
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

class JournalApiException implements Exception {
  JournalApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
