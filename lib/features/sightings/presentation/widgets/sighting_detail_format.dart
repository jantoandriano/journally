import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export '../../../../core/date_format.dart';

/// Shared accent used for "fed" status text across the detail screen.
const fedAccent = Color(0xFF8F5A2E);

({String street, String area}) splitPlace(String placeName) {
  final parts = placeName.split(',').map((p) => p.trim()).toList();
  if (parts.length < 2) return (street: placeName, area: '');
  return (street: parts.first, area: parts.sublist(1).join(', '));
}

Text sectionHeading(BuildContext context, String text) {
  return Text(
    text,
    style: GoogleFonts.fraunces(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}
