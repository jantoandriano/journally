import 'package:flutter/material.dart';

import '../../domain/sighting.dart';
import 'sighting_detail_feeding_log.dart';
import 'sighting_detail_identity.dart';
import 'sighting_detail_location_card.dart';
import 'sighting_detail_notes.dart';
import 'sighting_detail_photo_strip.dart';
import 'sighting_detail_section_divider.dart';

/// Content container overlapping the hero, assembling every section below
/// the photo: identity, location, notes, feeding log, photos.
class DetailSheet extends StatelessWidget {
  const DetailSheet({super.key, required this.sighting});

  final Sighting sighting;

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
              DetailIdentity(sighting: sighting),
              const SizedBox(height: 10),
              DetailMetaLine(sighting: sighting),
              const SizedBox(height: 14),
              const DetailTraitPills(),
              const DetailSectionDivider(),
              DetailLocationCard(sighting: sighting),
              const DetailSectionDivider(),
              const DetailNotesBlock(),
              const SizedBox(height: 12),
              const DetailAiObservation(),
              const DetailSectionDivider(),
              DetailFeedingLog(sighting: sighting),
              const DetailSectionDivider(),
              DetailPhotoStrip(sighting: sighting),
            ],
          ),
        ),
      ),
    );
  }
}
