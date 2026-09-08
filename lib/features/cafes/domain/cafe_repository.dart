import 'package:image_picker/image_picker.dart';

import 'cafe_entry.dart';

abstract class CafeRepository {
  Future<List<CafeEntry>> fetchCafes();

  Future<CafeEntry> fetchCafeById(String id);

  Future<void> deleteCafe(String id);

  Future<void> uploadPhoto(String entryId, XFile photo);

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
  });

  Future<CafeEntry> updateCafe(
    String id, {
    String? placeName,
    String? neighborhood,
    String? city,
    List<OrderItem>? orderItems,
    double? lat,
    double? lng,
    String? placeId,
  });

  Future<List<CafeEntry>> fetchNearbyCafe({
    required double lat,
    required double lng,
    double radiusKm = 5,
  });
}
