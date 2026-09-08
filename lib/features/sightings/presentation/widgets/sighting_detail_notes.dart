import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sighting_detail_format.dart';

/// Static placeholder notes paragraph. The Sighting model only has one
/// `notes` field, already used as the identity headline — real notes need a
/// separate field.
class SightingDetailNotes extends StatelessWidget {
  const SightingDetailNotes({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Regularly seen resting near the entrance in the afternoon. '
        "Approaches slowly but doesn't shy away from people offering food.",
        style: GoogleFonts.manrope(
          fontSize: 13.5,
          height: 1.6,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Static AI observation row. Copy is hardcoded for now.
class SightingDetailAiObservation extends StatelessWidget {
  const SightingDetailAiObservation({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: fedAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Appears well-fed and comfortable around people — likely a '
              'friendly neighborhood regular.',
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: fedAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
