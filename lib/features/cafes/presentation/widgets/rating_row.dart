import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cafe_add_colors.dart';

class RatingRow extends StatelessWidget {
  const RatingRow({super.key, required this.rating, required this.onChanged});

  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final filled = rating.round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          for (var i = 1; i <= 5; i++)
            Padding(
              padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
              child: GestureDetector(
                onTap: () => onChanged(i.toDouble()),
                child: Icon(
                  i <= filled ? Icons.star : Icons.star_border,
                  size: 26,
                  color: i <= filled ? colors.primary : hairline,
                ),
              ),
            ),
          const Spacer(),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.fraunces(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
