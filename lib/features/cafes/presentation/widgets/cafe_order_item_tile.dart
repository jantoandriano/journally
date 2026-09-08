import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/cafe_entry.dart';

class CafeOrderItemTile extends StatelessWidget {
  const CafeOrderItemTile({super.key, required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primaryContainer, colors.primary],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                if (item.note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.note!,
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      color: colors.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.formattedPrice != null)
            Text(
              item.formattedPrice!,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
