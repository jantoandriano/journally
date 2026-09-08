import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journally/features/cafes/domain/cafe_entry.dart';

import 'cafe_order_item_tile.dart';

class CafeDetailOrderList extends StatelessWidget {
  const CafeDetailOrderList({super.key, required this.entry});
  final CafeEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What I ordered',
          style: GoogleFonts.fraunces(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        for (final item in entry.orderItems) CafeOrderItemTile(item: item),
      ],
    );
  }
}
