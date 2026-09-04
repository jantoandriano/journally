import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JournalSearchBar extends StatelessWidget {
  const JournalSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: colors.outline),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: colors.primary,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: GoogleFonts.manrope(
                  fontSize: 14,
                  color: colors.outline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _AiChip(colors: colors),
        ],
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            'AI',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 11 * 0.04,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
