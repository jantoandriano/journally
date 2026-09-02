import 'package:flutter/material.dart';

import '../splash_timing.dart';

/// The 96px logo tile: a filled square with a line-art coffee cup and two
/// looping steam strokes. Owns its own steam animation — independent of the
/// splash screen's entrance/hand-off controller.
class AppMark extends StatefulWidget {
  const AppMark({super.key});

  @override
  State<AppMark> createState() => _AppMarkState();
}

class _AppMarkState extends State<AppMark> with TickerProviderStateMixin {
  late final AnimationController _steamA;
  late final AnimationController _steamB;

  @override
  void initState() {
    super.initState();
    _steamA = AnimationController(
      vsync: this,
      duration: SplashTiming.steamLoop,
    )..repeat();
    _steamB = AnimationController(
      vsync: this,
      duration: SplashTiming.steamLoop,
    );
    Future.delayed(SplashTiming.steamOffset, () {
      if (mounted) _steamB.repeat();
    });
  }

  @override
  void dispose() {
    _steamA.dispose();
    _steamB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.32),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 13,
            child: SizedBox(
              width: 46,
              height: 16,
              child: Stack(
                children: [
                  _SteamStroke(animation: _steamA, left: 14),
                  _SteamStroke(animation: _steamB, left: 26),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              width: 46,
              height: 46,
              child: CustomPaint(painter: _CoffeeCupPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SteamStroke extends StatelessWidget {
  const _SteamStroke({required this.animation, required this.left});

  final Animation<double> animation;
  final double left;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Rises ~7px and fades out over the loop.
        final t = animation.value;
        final dy = -7 * t;
        final opacity = 0.8 * (1 - t);
        return Positioned(
          left: left,
          bottom: 0,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: 2.4,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1.2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CoffeeCupPainter extends CustomPainter {
  const _CoffeeCupPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Cup body: open-top trapezoid, narrower at the base.
    final body = Path()
      ..moveTo(w * 0.16, h * 0.28)
      ..lineTo(w * 0.20, h * 0.72)
      ..quadraticBezierTo(w * 0.22, h * 0.80, w * 0.32, h * 0.80)
      ..lineTo(w * 0.62, h * 0.80)
      ..quadraticBezierTo(w * 0.72, h * 0.80, w * 0.74, h * 0.72)
      ..lineTo(w * 0.78, h * 0.28);
    canvas.drawPath(body, paint);

    // Handle: arc on the right side of the cup.
    final handleRect = Rect.fromLTWH(w * 0.74, h * 0.36, w * 0.22, h * 0.28);
    canvas.drawArc(handleRect, -1.35, 2.7, false, paint);

    // Saucer rule beneath the cup.
    canvas.drawLine(
      Offset(w * 0.08, h * 0.92),
      Offset(w * 0.86, h * 0.92),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CoffeeCupPainter oldDelegate) => false;
}
