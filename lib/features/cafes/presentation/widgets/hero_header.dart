import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cafe_entry.dart';
import '../providers/cafe_providers.dart';

class HeroHeader extends StatelessWidget {
  const HeroHeader({super.key, required this.entry});

  final CafeEntry entry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: entry.gradientColors,
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _HeroCircleButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: [
                const _HeroCircleButton(icon: Icons.bookmark_border),
                const SizedBox(width: 10),
                _HeroCircleButton(
                  icon: Icons.more_vert,
                  onTap: () => _showOverflowMenu(context),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: _PageDots(
              count: entry.photoCount == 0 ? 1 : entry.photoCount,
            ),
          ),
        ],
      ),
    );
  }

  void _showOverflowMenu(BuildContext context) {
    final consumerContext = context;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Delete entry'),
          onTap: () {
            Navigator.pop(sheetContext);
            _confirmDelete(consumerContext);
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final container = ProviderScope.containerOf(context);
    try {
      await container.read(cafeRepositoryProvider).deleteCafe(entry.id);
      container.invalidate(cafeEntriesProvider);
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

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: i == 0
                ? Container(
                    width: 18,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )
                : Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
      ],
    );
  }
}
