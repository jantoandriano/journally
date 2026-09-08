import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _tagOptions = [
  'Good wifi',
  'Quiet',
  'Laptop friendly',
  'Outdoor seating',
  'Power outlets',
  'Late hours',
];

class TagPills extends StatelessWidget {
  const TagPills({super.key, required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in _tagOptions)
          GestureDetector(
            onTap: () => onToggle(tag),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: selected.contains(tag)
                    ? colors.primaryContainer
                    : colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected.contains(tag)
                      ? colors.primary
                      : colors.outlineVariant,
                ),
              ),
              child: Text(
                tag,
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected.contains(tag)
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
