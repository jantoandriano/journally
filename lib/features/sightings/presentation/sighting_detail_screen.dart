import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/sightings_providers.dart';
import 'widgets/sighting_detail_hero.dart';
import 'widgets/sighting_detail_sheet.dart';

class SightingDetailScreen extends ConsumerWidget {
  const SightingDetailScreen({super.key, required this.sightingId});

  final String sightingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sightingAsync = ref.watch(sightingByIdProvider(sightingId));

    return Scaffold(
      body: sightingAsync.when(
        data: (sighting) => Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SightingDetailHero(sight: sighting),
                      SightingDetailSheet(sight: sighting),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
      ),
    );
  }
}
