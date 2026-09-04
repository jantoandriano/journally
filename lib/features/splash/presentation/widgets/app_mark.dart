import 'package:flutter/material.dart';

import '../splash_timing.dart';

/// The 96px logo tile: a filled square whose icon swaps between a coffee
/// cup (cafes) and a paw print (sightings), cross-fading on [motif] — a
/// single repeating controller owned by the splash screen. Two pulse
/// rings loop independently behind/over the tile, owned locally.
class AppMark extends StatefulWidget {
  const AppMark({super.key, required this.motif});

  final Animation<double> motif;

  @override
  State<AppMark> createState() => _AppMarkState();
}

class _AppMarkState extends State<AppMark> with TickerProviderStateMixin {
  late final AnimationController _pulseA;
  late final AnimationController _pulseB;

  @override
  void initState() {
    super.initState();
    _pulseA = AnimationController(vsync: this, duration: SplashTiming.pulseLoop)
      ..repeat();
    _pulseB = AnimationController(
      vsync: this,
      duration: SplashTiming.pulseLoop,
    );
    Future.delayed(SplashTiming.pulseOffset, () {
      if (mounted) _pulseB.repeat();
    });
  }

  @override
  void dispose() {
    _pulseA.dispose();
    _pulseB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _PulseRing(animation: _pulseA, color: colors.primary),
          _Tile(motif: widget.motif, colors: colors),
          _PulseRing(animation: _pulseB, color: colors.primary),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.motif, required this.colors});

  final Animation<double> motif;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
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
      child: AnimatedBuilder(
        animation: motif,
        builder: (context, child) {
          final t = motif.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              _Motif(
                opacity: _cupOpacity(t),
                scale: _cupScale(t),
                rotationDeg: _cupRotationDeg(t),
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: CustomPaint(painter: _CoffeeCupPainter()),
                ),
              ),
              _Motif(
                opacity: _pawOpacity(t),
                scale: _pawScale(t),
                rotationDeg: _pawRotationDeg(t),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: CustomPaint(painter: _PawPrintPainter()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Motif swap timeline (t in [0, 1] across one _motif cycle):
//   [0.00, 0.34] cup holds, paw hidden
//   [0.34, 0.44] cup leaves (-> scale 0.70, -14deg), paw arrives (from scale 0.70, +14deg)
//   [0.44, 0.90] paw holds, cup hidden
//   [0.90, 1.00] paw leaves (-> scale 0.70, +14deg), cup arrives back (from scale 0.70, -14deg)
double _ease(double t) => Curves.easeInOut.transform(t.clamp(0.0, 1.0));

double _cupOpacity(double t) {
  if (t <= 0.34) return 1;
  if (t <= 0.44) return 1 - _ease((t - 0.34) / 0.10);
  if (t <= 0.90) return 0;
  return _ease((t - 0.90) / 0.10);
}

double _cupScale(double t) {
  if (t <= 0.34) return 1;
  if (t <= 0.44) return 1 - 0.30 * _ease((t - 0.34) / 0.10);
  if (t <= 0.90) return 0.70;
  return 0.70 + 0.30 * _ease((t - 0.90) / 0.10);
}

double _cupRotationDeg(double t) {
  if (t <= 0.34) return 0;
  if (t <= 0.44) return -14 * _ease((t - 0.34) / 0.10);
  if (t <= 0.90) return -14;
  return -14 + 14 * _ease((t - 0.90) / 0.10);
}

double _pawOpacity(double t) {
  if (t <= 0.34) return 0;
  if (t <= 0.44) return _ease((t - 0.34) / 0.10);
  if (t <= 0.90) return 1;
  return 1 - _ease((t - 0.90) / 0.10);
}

double _pawScale(double t) {
  if (t <= 0.34) return 0.70;
  if (t <= 0.44) return 0.70 + 0.30 * _ease((t - 0.34) / 0.10);
  if (t <= 0.90) return 1;
  return 1 - 0.30 * _ease((t - 0.90) / 0.10);
}

double _pawRotationDeg(double t) {
  if (t <= 0.34) return 14;
  if (t <= 0.44) return 14 - 14 * _ease((t - 0.34) / 0.10);
  if (t <= 0.90) return 0;
  return 14 * _ease((t - 0.90) / 0.10);
}

class _Motif extends StatelessWidget {
  const _Motif({
    required this.opacity,
    required this.scale,
    required this.rotationDeg,
    required this.child,
  });

  final double opacity;
  final double scale;
  final double rotationDeg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: Transform.rotate(
          angle: rotationDeg * 3.1415926535 / 180,
          child: child,
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: (0.45 * (1 - t)).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 1 + 0.34 * t,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(28),
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
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

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

class _PawPrintPainter extends CustomPainter {
  const _PawPrintPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    void ellipse(double cx, double cy, double rx, double ry) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
        paint,
      );
    }

    // 48x48 viewBox: one pad, four toes.
    ellipse(24, 32, 10.5, 8.5);
    ellipse(11.5, 21, 4.6, 6);
    ellipse(19.5, 13.5, 4.4, 6.2);
    ellipse(28.5, 13.5, 4.4, 6.2);
    ellipse(36.5, 21, 4.6, 6);
  }

  @override
  bool shouldRepaint(covariant _PawPrintPainter oldDelegate) => false;
}
