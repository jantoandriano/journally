import 'package:flutter/material.dart';

enum Species { cat, dog }

class Sighting {
  const Sighting({
    required this.id,
    required this.animal,
    required this.placeName,
    this.fedAt,
    required this.gradientColors,
    required this.fed,
    required this.notes,
    required this.photoCount,
    this.photoUrls,
    this.lat,
    this.lng,
    this.placeId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final Species animal;
  final double? lat;
  final double? lng;
  final String notes;
  final String placeName;
  final bool fed;
  final DateTime? fedAt;
  final List<Color> gradientColors;
  final List<String>? photoUrls;
  final String? placeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int photoCount;
}
