import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestionChips extends StatefulWidget {
  const SuggestionChips({super.key, required this.labels});

  final List<String> labels;

  @override
  State<SuggestionChips> createState() => _SuggestionChipsState();
}

class _SuggestionChipsState extends State<SuggestionChips> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: widget.labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedIndex == index;
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
              onTap: () =>
                  setState(() => _selectedIndex = selected ? null : index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                child: Text(
                  widget.labels[index],
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
