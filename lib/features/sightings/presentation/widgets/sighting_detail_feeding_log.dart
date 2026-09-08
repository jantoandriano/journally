import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/sighting.dart';
import 'sighting_detail_format.dart';

class _FeedEntry {
  const _FeedEntry(this.what, this.time);

  final String what;
  final DateTime time;
}

/// Feeding log heading + entry cards. Entries are static placeholders — the
/// Sighting model has no feeding log collection yet.
class SightingDetailFeedingLog extends StatelessWidget {
  const SightingDetailFeedingLog({super.key, required this.sighting});

  final Sighting sighting;

  static final _entries = [
    _FeedEntry('Wet food', DateTime(2026, 9, 7, 18, 40)),
    _FeedEntry('Dry kibble', DateTime(2026, 9, 6, 8, 15)),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: sectionHeading(context, 'Feeding log')),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Log a feed',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final entry in _entries) ...[
          _FeedEntryCard(entry: entry),
          if (entry != _entries.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _FeedEntryCard extends StatelessWidget {
  const _FeedEntryCard({required this.entry});

  final _FeedEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rice_bowl, size: 16, color: colors.primary),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.what,
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatDateTime(entry.time),
                style: GoogleFonts.manrope(
                  fontSize: 11.5,
                  color: colors.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
