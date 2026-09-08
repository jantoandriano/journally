import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/home_tab_switch.dart';
import '../../cafes/presentation/cafe_add_screen.dart';
import '../../cafes/presentation/cafe_feed_screen.dart';
import '../../sightings/presentation/sighting_add_screen.dart';
import '../../sightings/presentation/sighting_feed_screen.dart';

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
                  ? const CafeAddScreen()
                  : const SightingAddScreen(),
            ),
          ),
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _tab.index,
          children: [
            CafesFeed(
              searchController: _searchController,
              tab: _tab,
              onTabChanged: _setTab,
              selectedChip: _cafeChip,
              onChipChanged: _setCafeChip,
            ),
            SightingsFeed(
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
