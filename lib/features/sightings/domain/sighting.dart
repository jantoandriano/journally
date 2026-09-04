import 'package:flutter/material.dart';

enum Species { cat, dog }

class Sighting {
  const Sighting({
    required this.id,
    required this.animal,
    required this.description,
    required this.street,
    required this.area,
    required this.photoCount,
    required this.wasFed,
    required this.seenAt,
    required this.gradientColors,
  });

  final String id;
  final Species animal;
  final String description;
  final String street;
  final String area;
  final int photoCount;
  final bool wasFed;
  final DateTime seenAt;
  final List<Color> gradientColors;
}
