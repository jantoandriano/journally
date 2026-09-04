import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum HomeTab { cafes, sightings }

class HomeTabSwitch extends StatelessWidget {
  const HomeTabSwitch({super.key, required this.tab, required this.onChanged});

  final HomeTab tab;
  final ValueChanged<HomeTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Cafes',
              selected: tab == HomeTab.cafes,
              icon: (color) => Icon(
                Icons.local_cafe_outlined,
                size: 15,
                color: color,
              ),
              onTap: () => onChanged(HomeTab.cafes),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _Segment(
              label: 'Sightings',
              selected: tab == HomeTab.sightings,
              icon: (color) => _PawIcon(size: 15, color: color),
              onTap: () => onChanged(HomeTab.sightings),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Widget Function(Color color) icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.onSurface : colors.outline;

    return Material(
      color: selected ? colors.surface : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: selected
            ? BorderSide(color: colors.outlineVariant)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: SizedBox(
          height: 38,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon(color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A filled paw print: one pad ellipse plus four toe ellipses.
class _PawIcon extends StatelessWidget {
  const _PawIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PawPainter(color),
    );
  }
}

class _PawPainter extends CustomPainter {
  _PawPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.68),
        width: w * 0.56,
        height: h * 0.42,
      ),
      paint,
    );

    const toeCenters = [
      Offset(0.22, 0.32),
      Offset(0.40, 0.16),
      Offset(0.60, 0.16),
      Offset(0.78, 0.32),
    ];
    for (final c in toeCenters) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx * w, c.dy * h),
          width: w * 0.24,
          height: h * 0.30,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PawPainter oldDelegate) =>
      oldDelegate.color != color;
}
