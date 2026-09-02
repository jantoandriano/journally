import 'package:flutter/material.dart';

/// Two soft background circles, static — no animation. Clipped by the
/// screen edges via the parent [Stack]'s default hard-edge clip.
class AmbientShapes extends StatelessWidget {
  const AmbientShapes({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _Circle(
              size: 280,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primaryContainer, colors.surfaceContainerLow],
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _Circle(
              size: 300,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.surfaceContainerHighest,
                  const Color(0xFFEFE7DC),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.gradient});

  final double size;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
    );
  }
}
