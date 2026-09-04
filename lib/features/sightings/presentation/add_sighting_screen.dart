import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Placeholder — the sighting composer isn't built yet.
class AddSightingScreen extends StatelessWidget {
  const AddSightingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colors.surfaceContainerLow,
        title: Text(
          'Log a sighting',
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
      ),
      body: Center(
        child: Text(
          'Coming soon.',
          style: GoogleFonts.manrope(color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}
