import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_config.dart';
import '../domain/journal_entry.dart';
import 'home_providers.dart';
import 'widgets/open_in_maps_button.dart';

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(journalEntryProvider(entryId));
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
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

class _EntryDetailBody extends ConsumerWidget {
  const _EntryDetailBody({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final total = entry.orderItems
        .map((item) => item.price)
        .whereType<double>()
        .fold<double>(0, (sum, price) => sum + price);
    final hasAnyPrice = entry.orderItems.any((item) => item.price != null);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: colors.surface,
          title: Text(entry.placeName),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Editing isn't built yet.")),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 240,
            child: entry.photoUrls.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: entry.gradientColors,
                      ),
                    ),
                  )
                : PageView.builder(
                    itemCount: entry.photoUrls.length,
                    itemBuilder: (context, index) => Image.network(
                      '${ApiConfig.baseUrl}${entry.photoUrls[index]}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: colors.surfaceContainerHigh,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: colors.outline,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Icon(Icons.place_outlined, size: 15, color: colors.outline),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${entry.neighborhood}, ${entry.city}',
                    style: GoogleFonts.manrope(fontSize: 13, color: colors.outline),
                  ),
                ),
                if (entry.lat != null && entry.lng != null)
                  OpenInMapsButton(lat: entry.lat!, lng: entry.lng!),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order',
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in entry.orderItems)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        if (item.price != null)
                          Text(
                            '\$${item.price!.toStringAsFixed(2)}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (hasAnyPrice) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total spent',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(journalRepositoryProvider).deleteEntry(entry.id);
      ref.invalidate(journalEntriesProvider);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't delete — try again.")),
        );
      }
    }
  }
}
