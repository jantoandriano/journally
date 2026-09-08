import 'package:flutter/material.dart';

/// Client-only placeholder gradients (the API has no concept of them) shown
/// behind photo areas until real photo rendering is built. [pickGradient]
/// picks deterministically per id, so the same entry always gets the same
/// gradient across app launches.
const gradientPalette = [
  [Color(0xFFE7C9A5), Color(0xFFB8763F)],
  [Color(0xFFD8C7E8), Color(0xFF8C6FAE)],
  [Color(0xFFC9E0D8), Color(0xFF5F9782)],
  [Color(0xFFF0D8B0), Color(0xFFC98A4B)],
  [Color(0xFFCFE0EE), Color(0xFF6B92B8)],
  [Color(0xFFE3D3C3), Color(0xFF9C7A5B)],
];

List<Color> pickGradient(String id) =>
    gradientPalette[id.hashCode.abs() % gradientPalette.length];
