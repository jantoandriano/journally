import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journally/core/date_format.dart';
import 'package:journally/features/cafes/domain/cafe_entry.dart';

class CafeDetailMeta extends StatelessWidget {
  const CafeDetailMeta({super.key, required this.entry});

  final CafeEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.place_outlined, size: 14, color: colors.outline),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${entry.neighborhood}, ${entry.city} · Visited ${formatDate(entry.visitedAt)}',
            style: GoogleFonts.manrope(fontSize: 12.5, color: colors.outline),
          ),
        ),
      ],
    );
  }
}
