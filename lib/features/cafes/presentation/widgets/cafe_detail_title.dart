import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journally/features/cafes/domain/cafe_entry.dart';

/// Headline description + fed/not-fed status chip.
class CafeDetailTitle extends StatelessWidget {
  const CafeDetailTitle({super.key, required this.entry});

  final CafeEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            entry.placeName,
            style: GoogleFonts.fraunces(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: 27 * -0.01,
              color: colors.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
