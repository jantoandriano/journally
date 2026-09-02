import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'add_journal_colors.dart';

class AiDraftRow extends StatelessWidget {
  const AiDraftRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: deepAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Turn these into a written note',
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: deepAccent,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: deepAccent),
        ],
      ),
    );
  }
}
