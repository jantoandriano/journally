import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotesBlock extends StatelessWidget {
  const NotesBlock({super.key, required this.notes});

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
      ],
    );
  }
}
