import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _fedAccent = Color(0xFF8F5A2E);

/// Status pill showing whether a sighted animal was fed.
class FedPill extends StatelessWidget {
  const FedPill({super.key, required this.wasFed});

  final bool wasFed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: wasFed
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (wasFed) ...[
            const Icon(Icons.check, size: 12, color: _fedAccent),
            const SizedBox(width: 4),
          ],
          Text(
            wasFed ? 'Fed' : 'Not fed',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: wasFed ? _fedAccent : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
