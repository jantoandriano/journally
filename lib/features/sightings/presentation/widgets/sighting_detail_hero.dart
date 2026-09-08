import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/sighting.dart';

/// 420px hero photo area. Sits above [DetailSheet] as a plain [Column]
/// child — the sheet's own [Transform.translate] creates the -28px overlap.
class DetailHero extends StatelessWidget {
  const DetailHero({super.key, required this.sighting});

  final Sighting sighting;

  static const height = 420.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: sighting.gradientColors,
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _CircleButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: [
                _CircleButton(icon: Icons.bookmark_border, onTap: () {}),
                const SizedBox(width: 8),
                _CircleButton(icon: Icons.more_vert, onTap: () {}),
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
                child: Center(child: _SpeciesPill(animal: sighting.animal)),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: _PhotoDots(count: sighting.photoCount, activeIndex: 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.onSurface.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
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

class _PhotoDots extends StatelessWidget {
  const _PhotoDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isActive ? 1 : 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
