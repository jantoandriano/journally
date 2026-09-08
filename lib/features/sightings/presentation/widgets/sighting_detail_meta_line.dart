import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journally/features/sightings/domain/sighting.dart';
import 'package:journally/features/sightings/presentation/widgets/sighting_detail_format.dart';

/// Pin icon + "{street}, {area} · Seen {date}" line.
class SightingDetailMeta extends StatelessWidget {
  const SightingDetailMeta({super.key, required this.sighting});

  final Sighting sighting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final place = splitPlace(sighting.placeName);
    final seen = sighting.createdAt != null
        ? formatDate(sighting.createdAt!)
        : 'Unknown date';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.place_outlined, size: 14, color: colors.outline),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${place.street}, ${place.area} · Seen $seen',
            style: GoogleFonts.manrope(fontSize: 12.5, color: colors.outline),
          ),
        ),
      ],
    );
  }
}
