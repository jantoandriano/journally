import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/journal_entry.dart';
import 'providers/home_providers.dart';
import 'widgets/bottom_action_bar.dart';
import 'widgets/entry_sheet.dart';
import 'widgets/hero_header.dart';

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(journalEntryProvider(entryId));
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: entryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Couldn't load this entry.",
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(journalEntryProvider(entryId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (entry) => _EntryDetailBody(entry: entry),
      ),
    );
  }
}

class _EntryDetailBody extends StatelessWidget {
  const _EntryDetailBody({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  HeroHeader(entry: entry),
                  EntrySheet(entry: entry),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BottomActionBar(entry: entry),
        ),
      ],
    );
  }
}
