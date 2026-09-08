import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestionChips extends StatelessWidget {
  const SuggestionChips({
    super.key,
    required this.labels,
    this.selectedIndex,
    this.onSelected,
  });

  final List<String> labels;
  final int? selectedIndex;
  final ValueChanged<int?>? onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = selectedIndex == index;
          return Material(
            color: selected ? colors.primaryContainer : colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
              side: BorderSide(
                color: selected ? colors.primary : colors.outlineVariant,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(19),
              splashColor: colors.surfaceContainerHighest,
              highlightColor: colors.surfaceContainerHighest,
              onTap: () => onSelected?.call(selected ? null : index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
