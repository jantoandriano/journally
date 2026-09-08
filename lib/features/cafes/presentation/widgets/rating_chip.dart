import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RatingChip extends StatelessWidget {
  const RatingChip({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: colors.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: colors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
