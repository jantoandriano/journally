import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'header.dart';
import 'home_tab_switch.dart';
import 'search_bar.dart';
import 'suggestion_chips.dart';

/// Shared scroll layout for the cafes and sightings feeds: header, tab
/// switch, search bar, suggestion chips, then a two-column grid built from
/// [itemsAsync]. Grid spacing, loading/error states, and the search hookup
/// all live here once instead of being copy-pasted per feed.
class FeedScaffold<T> extends StatelessWidget {
  const FeedScaffold({
    super.key,
    required this.itemsAsync,
    required this.itemCountLabel,
    required this.searchController,
    required this.searchHintText,
    required this.onSearchChanged,
    required this.tab,
    required this.onTabChanged,
    required this.chipLabels,
    required this.selectedChip,
    required this.onChipChanged,
    required this.errorText,
    required this.itemBuilder,
  });

  final AsyncValue<List<T>> itemsAsync;

  /// e.g. "places visited" -> "6 places visited" / "… places visited".
  final String itemCountLabel;

  final TextEditingController searchController;
  final String searchHintText;
  final ValueChanged<String> onSearchChanged;

  final HomeTab tab;
  final ValueChanged<HomeTab> onTabChanged;

  final List<String> chipLabels;
  final int? selectedChip;
  final ValueChanged<int?> onChipChanged;

  final String errorText;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final subtitle = itemsAsync.when(
      data: (items) => '${items.length} $itemCountLabel',
      loading: () => '… $itemCountLabel',
      error: (_, _) => '0 $itemCountLabel',
    );

    final Widget contentSliver = itemsAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(errorText, style: TextStyle(color: colors.onSurfaceVariant)),
        ),
      ),
      data: (items) {
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 14,
              childAspectRatio: 0.58,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => itemBuilder(context, items[index]),
              childCount: items.length,
            ),
          ),
        );
      },
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(child: Header(subtitle: subtitle)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: HomeTabSwitch(tab: tab, onChanged: onTabChanged),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: JournalySearchBar(
              controller: searchController,
              hintText: searchHintText,
              onChanged: onSearchChanged,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(top: 16),
          sliver: SliverToBoxAdapter(
            child: SuggestionChips(
              labels: chipLabels,
              selectedIndex: selectedChip,
              onSelected: onChipChanged,
            ),
          ),
        ),
        contentSliver,
      ],
    );
  }
}
