import 'package:flutter/material.dart';
import 'package:journally/features/cafes/domain/cafe_entry.dart';
import 'package:journally/features/cafes/presentation/widgets/photo_strip.dart';

class CafeDetailPhotoStrip extends StatelessWidget {
  const CafeDetailPhotoStrip({super.key, required this.entry});
  final CafeEntry entry;

  @override
  Widget build(BuildContext context) {
    return PhotoStrip(entry: entry);
  }
}
