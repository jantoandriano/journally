import 'package:flutter/material.dart';

class PlaceSearchBackButton extends StatelessWidget {
  const PlaceSearchBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Icon(Icons.chevron_left, color: colors.onSurface, size: 22),
      ),
    );
  }
}
