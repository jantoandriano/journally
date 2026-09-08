import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/sighting.dart';
import 'sighting_detail_format.dart';

/// "Where I saw it" section: map placeholder + street/area + "Open map".
class DetailLocationCard extends StatelessWidget {
  const DetailLocationCard({super.key, required this.sighting});

  final Sighting sighting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final place = splitPlace(sighting.placeName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeading(context, 'Where I saw it'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MapPlaceholder(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${place.street}, ${place.area}',
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Open map',
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Placeholder only. Swap for a real map widget (e.g. GoogleMap / flutter_map)
/// fed sighting.lat/lng once available — drop the gradient/grid, keep the
/// pin overlay as a marker.
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final gridColor = colors.outlineVariant.withValues(alpha: 0.5);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 104,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.surfaceContainerHighest,
                    colors.surfaceContainerLow,
                  ],
                ),
              ),
            ),
            Column(
              children: List.generate(
                3,
                (_) => Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: gridColor, width: 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: List.generate(
                3,
                (_) => Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: gridColor, width: 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
