import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sightings/domain/sighting.dart';
import '../../sightings/presentation/add_sighting_screen.dart';
import '../../sightings/presentation/providers/sightings_providers.dart';
import '../../sightings/presentation/widgets/sighting_card.dart';
import '../../add_journal/presentation/add_journal_screen.dart';
import 'providers/home_providers.dart';
import 'widgets/header.dart';
import 'widgets/home_tab_switch.dart';
import 'widgets/journal_card.dart';
import 'widgets/search_bar.dart';
import 'widgets/suggestion_chips.dart';

// Only chips backed by a real API query are offered — no client-side-only
// filters (no structured fields exist server-side for "iced coffee",
// "visited this month", "laptop friendly", "not fed yet", or "seen this
// week", so those were decorative and have been removed).
const _cafeChips = ['Near Kemang'];

const _sightingChips = ['Cats near me', 'Dogs near me'];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  HomeTab _tab = HomeTab.cafes;
  int? _cafeChip;
  int? _sightingChip;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      floatingActionButton: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.38),
              blurRadius: 20,
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _tab == HomeTab.cafes
                  ? const AddEntryScreen()
                  : const AddSightingScreen(),
            ),
          ),
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _tab.index,
          children: [
            _CafesFeed(
              searchController: _searchController,
              tab: _tab,
              onTabChanged: _setTab,
              selectedChip: _cafeChip,
              onChipChanged: _setCafeChip,
            ),
            _SightingsFeed(
              searchController: _searchController,
              tab: _tab,
              onTabChanged: _setTab,
              selectedChip: _sightingChip,
              onChipChanged: _setSightingChip,
            ),
          ],
        ),
      ),
    );
  }

  void _setTab(HomeTab tab) => setState(() => _tab = tab);
  void _setCafeChip(int? chip) => setState(() => _cafeChip = chip);
  void _setSightingChip(int? chip) => setState(() => _sightingChip = chip);
}

class _CafesFeed extends ConsumerWidget {
  const _CafesFeed({
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
        ? ref.watch(nearbyEntriesProvider)
        : ref.watch(journalEntriesProvider);
    final colors = Theme.of(context).colorScheme;

    final subtitle = entriesAsync.when(
      data: (entries) => '${entries.length} places visited',
      loading: () => '… places visited',
      error: (_, _) => '0 places visited',
    );

    final Widget contentSliver = entriesAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            "Couldn't load your places.",
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      ),
      data: (entries) {
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
              (context, index) => JournalCard(entry: entries[index]),
              childCount: entries.length,
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
            child: JournalSearchBar(
              controller: searchController,
              hintText: 'Search a place, dish, or area…',
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).update(value),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(top: 16),
          sliver: SliverToBoxAdapter(
            child: SuggestionChips(
              labels: _cafeChips,
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

class _SightingsFeed extends ConsumerWidget {
  const _SightingsFeed({
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
    final colors = Theme.of(context).colorScheme;

    final subtitle = sightingsAsync.when(
      data: (sightings) => '${sightings.length} sightings logged',
      loading: () => '… sightings logged',
      error: (_, _) => '0 sightings logged',
    );

    final Widget contentSliver = sightingsAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            "Couldn't load sightings.",
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      ),
      data: (sightings) {
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
              (context, index) => SightingCard(sighting: sightings[index]),
              childCount: sightings.length,
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
            child: JournalSearchBar(
              controller: searchController,
              hintText: 'Search a street, area, or animal…',
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).update(value),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(top: 16),
          sliver: SliverToBoxAdapter(
            child: SuggestionChips(
              labels: _sightingChips,
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
