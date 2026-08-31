import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/journal_entry.dart';
import '../entry_detail_screen.dart';
import 'open_in_maps_button.dart';

class JournalCard extends StatelessWidget {
  const JournalCard({super.key, required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visibleItems = entry.orderItems.take(2).toList();
    final extraCount = entry.orderItems.length - visibleItems.length;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EntryDetailScreen(entryId: entry.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: entry.gradientColors,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '1/${entry.photoCount}',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.placeName,
            style: GoogleFonts.fraunces(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in visibleItems)
                _OrderTag(
                  label: item.price != null
                      ? '${item.name} · \$${item.price!.toStringAsFixed(2)}'
                      : item.name,
                ),
              if (extraCount > 0) _OrderTag(label: '+$extraCount'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 13, color: colors.outline),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  '${entry.neighborhood}, ${entry.city}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: colors.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (entry.lat != null && entry.lng != null)
                OpenInMapsButton(lat: entry.lat!, lng: entry.lng!),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderTag extends StatelessWidget {
  const _OrderTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colors.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
