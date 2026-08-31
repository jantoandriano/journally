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
  });

  final String id;
  final String placeName;
  final String neighborhood;
  final String city;
  final List<String> orderItems;
  final int photoCount;
  final List<Color> gradientColors;
}
