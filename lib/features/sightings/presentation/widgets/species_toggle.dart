import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/sighting.dart';

/// Cat/dog picker for the sighting composer.
class SpeciesToggle extends StatelessWidget {
  const SpeciesToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Species selected;
  final ValueChanged<Species> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final species in Species.values) ...[
          if (species != Species.values.first) const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(species),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected == species
                      ? colors.primaryContainer
                      : colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected == species
                        ? colors.primary
                        : colors.outlineVariant,
                  ),
                ),
                child: Center(
                  child: Text(
                    species == Species.cat ? 'Cat' : 'Dog',
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: selected == species
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
