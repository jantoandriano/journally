import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fixed bottom bar: "Edit sighting" pill + circular share button.
/// SafeArea(top: false) keeps its own bottom padding stacking with the
/// device inset instead of being swallowed by it.
class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow.withValues(alpha: 0.94),
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: colors.primary,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () {},
                  child: SizedBox(
                    height: 50,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Edit sighting',
                            style: GoogleFonts.manrope(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: colors.surface,
              shape: CircleBorder(
                side: BorderSide(color: colors.outlineVariant),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {},
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
