import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../home/presentation/widgets/photo_count_badge.dart';
import '../../domain/sighting.dart';
import 'fed_pill.dart';
import 'species_pill.dart';

class SightingCard extends StatelessWidget {
  const SightingCard({super.key, required this.sighting});

  final Sighting sighting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: sighting.gradientColors,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: SpeciesPill(animal: sighting.animal),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PhotoCountBadge(photoCount: sighting.photoCount),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              sighting.description,
              style: GoogleFonts.fraunces(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            FedPill(wasFed: sighting.wasFed),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 13, color: colors.outline),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    '${sighting.street}, ${sighting.area}',
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      color: colors.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
