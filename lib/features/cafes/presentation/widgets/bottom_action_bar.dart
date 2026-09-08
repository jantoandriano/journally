import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/cafe_entry.dart';

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.entry});

  final CafeEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        border: Border(top: BorderSide(color: colors.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Editing isn't built yet.")),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit entry',
                      style: GoogleFonts.manrope(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Icon(Icons.ios_share, size: 20, color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}
