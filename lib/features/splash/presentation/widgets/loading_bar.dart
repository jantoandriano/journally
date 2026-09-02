import 'package:flutter/material.dart';

import '../splash_timing.dart';

/// 104x3 track with a 44%-wide thumb that slides left-to-right on a
/// repeating 1500ms ease-in-out loop. Owns its own controller.
class LoadingBar extends StatefulWidget {
  const LoadingBar({super.key});

  @override
  State<LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SplashTiming.loadingBarLoop,
    )..repeat(reverse: true);
    _position = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 104,
      height: 3,
      decoration: BoxDecoration(
        color: colors.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedBuilder(
        animation: _position,
        builder: (context, child) {
          return Align(
            alignment: Alignment(-1 + 2 * _position.value, 0),
            child: FractionallySizedBox(
              widthFactor: 0.44,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
