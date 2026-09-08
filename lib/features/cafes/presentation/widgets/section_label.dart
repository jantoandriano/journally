import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 11.5 * 0.06,
              color: colors.outline,
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}
