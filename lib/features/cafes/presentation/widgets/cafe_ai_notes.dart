import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CafeAiNotes extends StatelessWidget {
  const CafeAiNotes({super.key, required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: GoogleFonts.fraunces(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            notes,
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              height: 1.6,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        _CafeAiRecap(),
      ],
    );
  }
}

class _CafeAiRecap extends StatelessWidget {
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
          Icon(Icons.auto_awesome, size: 16, color: colors.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You tend to revisit cozy spots with great pastries.',
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
