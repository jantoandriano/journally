import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotesField extends StatelessWidget {
  const NotesField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        minLines: 3,
        style: GoogleFonts.manrope(
          fontSize: 13.5,
          height: 1.6,
          color: colors.onSurfaceVariant,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'What did you notice?',
          hintStyle: GoogleFonts.manrope(
            fontSize: 13.5,
            height: 1.6,
            color: colors.outline,
          ),
        ),
      ),
    );
  }
}
