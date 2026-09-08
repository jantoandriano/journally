import 'package:flutter/material.dart';

/// 1px rule with 22px of breathing room above and below, used between every
/// section of the sighting detail sheet.
class DetailSectionDivider extends StatelessWidget {
  const DetailSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Container(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}
