import 'package:flutter/material.dart';
import 'package:journally/core/widgets/section_divider.dart';
import 'package:journally/features/sightings/presentation/widgets/sighting_detail_meta_line.dart';
import 'package:journally/features/sightings/presentation/widgets/sighting_detail_tags.dart';

import '../../domain/sighting.dart';
import 'sighting_detail_feeding_log.dart';
import 'sighting_detail_identity.dart';
import 'sighting_detail_location_card.dart';
import 'sighting_detail_notes.dart';
import 'sighting_detail_photo_strip.dart';

/// Content container overlapping the hero, assembling every section below
/// the photo: identity, location, notes, feeding log, photos.
class SightingDetailSheet extends StatelessWidget {
  const SightingDetailSheet({super.key, required this.sight});

  final Sighting sight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Transform.translate(
      offset: const Offset(0, -28),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 112),
          color: colors.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SightingDetailTitle(sighting: sight),
              SightingDetailMeta(sighting: sight),
              SightingDetailTraitTags(sighting: sight),
              SectionDivider(),
              SightingDetailLocationCard(sighting: sight),
              SectionDivider(),
              SightingDetailNotes(),
              SightingDetailAiObservation(),
              SectionDivider(),
              SightingDetailFeedingLog(sighting: sight),
              SectionDivider(),
              SightingDetailPhotoStrip(sighting: sight),
            ],
          ),
        ),
      ),
    );
  }
}
