import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/date_format.dart';

bool _isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

class PlaceFields extends StatelessWidget {
  const PlaceFields({
    super.key,
    required this.placeName,
    required this.neighborhoodController,
    required this.cityController,
    required this.visitDate,
    required this.onPickDate,
    required this.onTapPlace,
  });

  final String? placeName;
  final TextEditingController neighborhoodController;
  final TextEditingController cityController;
  final DateTime visitDate;
  final VoidCallback onPickDate;
  final VoidCallback onTapPlace;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        GestureDetector(
          onTap: onTapPlace,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.place_outlined, size: 18, color: colors.outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    placeName ?? 'Add a place',
                    style: GoogleFonts.manrope(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: colors.outline),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SmallField(
                controller: neighborhoodController,
                hint: 'Neighborhood',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmallField(controller: cityController, hint: 'City'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: colors.outline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formatDate(visitDate),
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (_isToday(visitDate))
                  Text(
                    'Today',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.outline,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallField extends StatelessWidget {
  const _SmallField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          style: GoogleFonts.manrope(fontSize: 13.5, color: colors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: hint,
            hintStyle: GoogleFonts.manrope(
              fontSize: 13.5,
              color: colors.outline,
            ),
          ),
        ),
      ),
    );
  }
}
