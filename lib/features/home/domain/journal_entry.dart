import 'package:flutter/material.dart';

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.placeName,
    required this.neighborhood,
    required this.city,
    required this.orderItems,
    required this.photoCount,
    required this.gradientColors,
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
  final List<Color> gradientColors;
  final double? lat;
  final double? lng;
  final String? placeId;
}

class OrderItem {
  OrderItem({required this.name, this.price});

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    name: j['name'] as String,
    price: (j['price'] as num?)?.toDouble(),
  );

  final String name;
  final double? price;

  Map<String, dynamic> toJson() => {
    'name': name,
    if (price != null) 'price': price,
  };
}
