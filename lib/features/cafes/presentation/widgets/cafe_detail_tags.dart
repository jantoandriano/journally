import 'package:flutter/material.dart';

import '../../domain/cafe_entry.dart';
import 'attribute_tag.dart';

class CafeDetailTags extends StatelessWidget {
  const CafeDetailTags({super.key, required this.entry});

  final CafeEntry entry;

  @override
  Widget build(BuildContext context) {
    if (entry.attributes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final attribute in entry.attributes)
            AttributeTag(label: attribute),
        ],
      ),
    );
  }
}
