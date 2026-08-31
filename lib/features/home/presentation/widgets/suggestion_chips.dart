import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestionChips extends StatelessWidget {
  const SuggestionChips({super.key});

  static const _labels = [
    'Near Kemang',
    'Iced coffee spots',
    'Visited this month',
    'Good for laptop work',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Text(
              _labels[index],
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          );
        },
      ),
    );
  }
}
