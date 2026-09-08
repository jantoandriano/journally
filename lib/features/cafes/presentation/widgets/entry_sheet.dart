import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/date_format.dart';
import '../../domain/cafe_entry.dart';
import 'ai_recap.dart';
import 'attribute_tag.dart';
import 'entry_detail_divider.dart';
import 'entry_order_item_tile.dart';
import 'notes_block.dart';
import 'photo_strip.dart';
import 'rating_chip.dart';

class EntrySheet extends StatelessWidget {
  const EntrySheet({super.key, required this.entry});

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
          color: colors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.placeName,
                      style: GoogleFonts.fraunces(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  if (entry.rating != null) RatingChip(rating: entry.rating!),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 14, color: colors.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${entry.neighborhood}, ${entry.city} · Visited ${formatDate(entry.visitedAt)}',
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        color: colors.outline,
                      ),
                    ),
                  ),
                ],
              ),
              if (entry.attributes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final attribute in entry.attributes)
                      AttributeTag(label: attribute),
                  ],
                ),
              ],
              EntryDetailDivider(color: colors.outlineVariant),
              Text(
                'What I ordered',
                style: GoogleFonts.fraunces(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              for (final item in entry.orderItems)
                EntryOrderItemTile(item: item),
              EntryDetailDivider(color: colors.outlineVariant),
              NotesBlock(notes: entry.notes),
              const SizedBox(height: 12),
              const AiRecap(),
              EntryDetailDivider(color: colors.outlineVariant),
              PhotoStrip(entry: entry),
            ],
          ),
        ),
      ),
    );
  }
}
