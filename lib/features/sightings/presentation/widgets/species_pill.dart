import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/sighting.dart';

/// Top-left "CAT"/"DOG" pill shown over a sighting card's photo area.
class SpeciesPill extends StatelessWidget {
  const SpeciesPill({super.key, required this.animal});

  final Species animal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        animal == Species.cat ? 'CAT' : 'DOG',
        style: GoogleFonts.manrope(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 10.5 * 0.03,
          color: Colors.white,
        ),
      ),
    );
  }
}
