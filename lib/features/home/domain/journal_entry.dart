import 'package:flutter/material.dart';

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.placeName,
    required this.neighborhood,
    required this.city,
    required this.orderItems,
    required this.photoCount,
    required this.photoUrls,
    required this.gradientColors,
    required this.visitedAt,
    this.rating,
    this.notes = '',
    this.attributes = const [],
    this.lat,
    this.lng,
    this.placeId,
  });

  final String id;
  final String placeName;
  final String neighborhood;
  final String city;
  final List<OrderItem> orderItems;
  final int photoCount;
  final List<String> photoUrls;
  final List<Color> gradientColors;
  final DateTime visitedAt;
  final double? rating;
  final String notes;
  final List<String> attributes;
  final double? lat;
  final double? lng;
  final String? placeId;
}

class OrderItem {
  OrderItem({required this.name, this.price, this.note});

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    name: j['name'] as String,
    price: (j['price'] as num?)?.toDouble(),
    note: j['note'] as String?,
  );

  final String name;
  final double? price;
  final String? note;

  /// Formatted as Indonesian Rupiah (e.g. "Rp 42.000") — whole rupiah,
  /// dot thousands separator, no decimals. `null` when there's no price.
  String? get formattedPrice => price == null ? null : _formatRupiah(price!);

  Map<String, dynamic> toJson() => {
    'name': name,
    if (price != null) 'price': price,
  };
}

String _formatRupiah(double amount) {
  final digits = amount.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'Rp $buffer';
}
