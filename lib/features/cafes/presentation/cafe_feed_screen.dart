import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/search_query_provider.dart';
import '../../../core/widgets/feed_scaffold.dart';
import '../../../core/widgets/home_tab_switch.dart';
import 'providers/cafe_providers.dart';
import 'widgets/cafe_card.dart';

const _cafeChips = ['Near Kemang'];

class CafesFeed extends ConsumerWidget {
  const CafesFeed({
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
    final entriesAsync = selectedChip == 0
        ? ref.watch(nearbyCafeProvider)
        : ref.watch(cafeEntriesProvider);

    return FeedScaffold(
      itemsAsync: entriesAsync,
      itemCountLabel: 'places visited',
      searchController: searchController,
      searchHintText: 'Search a place, dish, or area…',
      onSearchChanged: (value) =>
          ref.read(searchQueryProvider.notifier).update(value),
      tab: tab,
      onTabChanged: onTabChanged,
      chipLabels: _cafeChips,
      selectedChip: selectedChip,
      onChipChanged: onChipChanged,
      errorText: "Couldn't load your places.",
      itemBuilder: (context, entry) => CafeCard(entry: entry),
    );
  }
}
