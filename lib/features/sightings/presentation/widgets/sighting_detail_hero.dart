import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journally/core/widgets/button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journally/features/sightings/presentation/providers/sightings_providers.dart';

import '../../domain/sighting.dart';

/// 420px hero photo area. Sits above [DetailSheet] as a plain [Column]
/// child — the sheet's own [Transform.translate] creates the -28px overlap.
class SightingDetailHero extends StatelessWidget {
  const SightingDetailHero({super.key, required this.sight});

  final Sighting sight;

  static const height = 420.0;

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
                colors: sight.gradientColors,
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: JournalyButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: [
                const JournalyButton(icon: Icons.bookmark_border),
                const SizedBox(width: 10),
                JournalyButton(
                  icon: Icons.more_vert,
                  onTap: () => _showOverflowMenu(context),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                height: 38,
                child: Center(child: _SpeciesPill(animal: sight.animal)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: _Dots(count: sight.photoCount == 0 ? 1 : sight.photoCount),
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
          title: const Text('Delete sight'),
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
        title: const Text('Delete this sight?'),
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
      await container
          .read(sightingsRepositoryProvider)
          .deleteSightById(sight.id);
      container.invalidate(sightingsProvider);
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

class _SpeciesPill extends StatelessWidget {
  const _SpeciesPill({required this.animal});

  final Species animal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            animal == Species.cat ? 'CAT' : 'DOG',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 11 * 0.05,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count});

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
