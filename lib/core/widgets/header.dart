import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Header extends StatelessWidget {
  const Header({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journally',
          style: GoogleFonts.fraunces(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
