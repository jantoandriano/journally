import 'package:flutter/material.dart';
import 'package:journally/features/cafes/presentation/widgets/attribute_tag.dart';
import 'package:journally/features/sightings/domain/sighting.dart';

/// Wrapped static trait pills (Adult, Friendly, No collar, Healthy) — not on
/// the Sighting model yet, placeholder until traits are modeled.
class SightingDetailTraitTags extends StatelessWidget {
  const SightingDetailTraitTags({super.key, required this.sighting});

  final Sighting sighting;

  @override
  Widget build(BuildContext context) {
    if (sighting.attributes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final attribute in sighting.attributes)
            AttributeTag(label: attribute),
        ],
      ),
    );
  }
}
