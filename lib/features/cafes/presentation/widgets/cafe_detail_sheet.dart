import 'package:flutter/material.dart';
import 'package:journally/core/widgets/section_divider.dart';
import 'package:journally/features/cafes/presentation/widgets/cafe_ai_notes.dart';
import 'package:journally/features/cafes/presentation/widgets/cafe_detail_meta.dart';
import 'package:journally/features/cafes/presentation/widgets/cafe_detail_order_list.dart';
import 'package:journally/features/cafes/presentation/widgets/cafe_detail_photo_strip.dart';
import 'package:journally/features/cafes/presentation/widgets/cafe_detail_tags.dart';
import 'package:journally/features/cafes/presentation/widgets/cafe_detail_title.dart';

import '../../domain/cafe_entry.dart';

class CafeDetailSheet extends StatelessWidget {
  const CafeDetailSheet({super.key, required this.entry});

  final CafeEntry entry;

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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          color: colors.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CafeDetailTitle(entry: entry),
              CafeDetailMeta(entry: entry),
              CafeDetailTags(entry: entry),
              SectionDivider(),
              CafeDetailOrderList(entry: entry),
              SectionDivider(),
              CafeAiNotes(notes: entry.notes),
              SectionDivider(),
              CafeDetailPhotoStrip(entry: entry),
            ],
          ),
        ),
      ),
    );
  }
}
