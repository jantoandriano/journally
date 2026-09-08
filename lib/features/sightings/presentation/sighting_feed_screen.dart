import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journally/core/search_query_provider.dart';
import 'package:journally/core/widgets/feed_scaffold.dart';
import 'package:journally/core/widgets/home_tab_switch.dart';
import 'package:journally/features/sightings/domain/sighting.dart';
import 'package:journally/features/sightings/presentation/providers/sightings_providers.dart';
import 'package:journally/features/sightings/presentation/widgets/sighting_card.dart';

const _sightingChips = ['Cats near me', 'Dogs near me'];

class SightingsFeed extends ConsumerWidget {
  const SightingsFeed({
    super.key,
    required this.searchController,
    required this.tab,
    required this.onTabChanged,
    required this.selectedChip,
    required this.onChipChanged,
  });

  final TextEditingController searchController;
  final HomeTab tab;
  final ValueChanged<HomeTab> onTabChanged;
  final int? selectedChip;
  final ValueChanged<int?> onChipChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sightingsAsync = switch (selectedChip) {
      0 => ref.watch(nearbySightingsProvider(Species.cat)),
      1 => ref.watch(nearbySightingsProvider(Species.dog)),
      _ => ref.watch(sightingsProvider),
    };

    return FeedScaffold(
      itemsAsync: sightingsAsync,
      itemCountLabel: 'sightings logged',
      searchController: searchController,
      searchHintText: 'Search a street, area, or animal…',
      onSearchChanged: (value) =>
          ref.read(searchQueryProvider.notifier).update(value),
      tab: tab,
      onTabChanged: onTabChanged,
      chipLabels: _sightingChips,
      selectedChip: selectedChip,
      onChipChanged: onChipChanged,
      errorText: "Couldn't load sightings.",
      itemBuilder: (context, sighting) => SightingCard(sighting: sighting),
    );
  }
}
