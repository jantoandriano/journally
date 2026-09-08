import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:journally/features/cafes/presentation/widgets/notes_field.dart';
import 'package:journally/features/feeding_logs/domain/feeding_log_entry.dart';
import 'package:journally/features/feeding_logs/presentation/providers/feeding_logs_providers.dart';

import '../../domain/sighting.dart';
import 'sighting_detail_format.dart';

/// Feeding log heading + entry cards, backed by the feeding log API.
class SightingDetailFeedingLog extends ConsumerWidget {
  const SightingDetailFeedingLog({super.key, required this.sighting});

  final Sighting sighting;

  Future<void> _logFeed(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeading(context, 'Log a feed'),
            const SizedBox(height: 12),
            NotesField(controller: controller),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
    if (note == null) return;

    final repository = ref.read(feedingLogsRepositoryProvider);
    await repository.createFeedingLogEntry(
      sighting.id,
      note: note.trim().isEmpty ? null : note.trim(),
    );
    ref.invalidate(feedingLogProvider(sighting.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(feedingLogProvider(sighting.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: sectionHeading(context, 'Feeding log')),
            TextButton(
              onPressed: () => _logFeed(context, ref),
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
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        entriesAsync.when(
          data: (entries) => entries.isEmpty
              ? Text(
                  'No feeds logged today.',
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                )
              : Column(
                  children: [
                    for (final entry in entries) ...[
                      _FeedEntryCard(entry: entry),
                      if (entry != entries.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, stackTrace) => Text('$error'),
        ),
      ],
    );
  }
}

class _FeedEntryCard extends StatelessWidget {
  const _FeedEntryCard({required this.entry});

  final FeedingLogEntry entry;

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
                entry.note?.isNotEmpty == true ? entry.note! : 'Fed',
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatDateTime(entry.createdAt),
                style: GoogleFonts.manrope(fontSize: 11.5, color: colors.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
