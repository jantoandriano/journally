import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Journally" title plus the flanked tagline beneath it.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          'Journally',
          style: GoogleFonts.fraunces(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            height: 1.0,
            letterSpacing: -0.6,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Rule(),
            const SizedBox(width: 9),
            Text(
              'STREET CATS & DOGS',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 12 * 0.14,
                color: colors.outline,
              ),
            ),
            const SizedBox(width: 9),
            _Rule(),
          ],
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Container(width: 18, height: 1, color: const Color(0xFFD9D2C8));
  }
}
