import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/sighting.dart';
import 'sighting_detail_format.dart';

/// Headline description + fed/not-fed status chip.
class DetailIdentity extends StatelessWidget {
  const DetailIdentity({super.key, required this.sighting});

  final Sighting sighting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            sighting.notes,
            style: GoogleFonts.fraunces(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: 27 * -0.01,
              color: colors.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _StatusChip(fed: sighting.fed),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.fed});

  final bool fed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: fed ? colors.primaryContainer : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fed) ...[
            const Icon(Icons.check, size: 14, color: fedAccent),
            const SizedBox(width: 4),
          ],
          Text(
            fed ? 'Fed' : 'Not fed',
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: fed ? fedAccent : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pin icon + "{street}, {area} · Seen {date}" line.
class DetailMetaLine extends StatelessWidget {
  const DetailMetaLine({super.key, required this.sighting});

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
        Icon(Icons.place_outlined, size: 13, color: colors.outline),
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

/// Wrapped static trait pills (Adult, Friendly, No collar, Healthy) — not on
/// the Sighting model yet, placeholder until traits are modeled.
class DetailTraitPills extends StatelessWidget {
  const DetailTraitPills({super.key});

  static const _traits = ['Adult', 'Friendly', 'No collar', 'Healthy'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _traits.map((trait) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            trait,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}
