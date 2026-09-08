import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Top-right "1/{photoCount}" pill shown over a card's photo area.
class PhotoCountBadge extends StatelessWidget {
  const PhotoCountBadge({super.key, required this.photoCount});

  final int photoCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.camera_alt, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '1/$photoCount',
            style: GoogleFonts.manrope(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
