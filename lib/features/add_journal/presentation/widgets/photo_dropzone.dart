import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'add_journal_colors.dart';
import 'dashed_border_painter.dart';

class PhotoDropzone extends StatefulWidget {
  const PhotoDropzone({super.key, required this.photos, required this.onAdd});

  final List<XFile> photos;
  final VoidCallback onAdd;

  @override
  State<PhotoDropzone> createState() => _PhotoDropzoneState();
}

class _PhotoDropzoneState extends State<PhotoDropzone> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget box = AspectRatio(
      aspectRatio: 3 / 2,
      child: Container(
        decoration: BoxDecoration(
          color: _pressed
              ? colors.primaryContainer
              : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: _pressed
              ? Border.all(color: colors.primary, width: 1.5)
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Add a photo',
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'This one becomes the cover',
                style: GoogleFonts.manrope(
                  fontSize: 11.5,
                  color: colors.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!_pressed) {
      box = CustomPaint(
        foregroundPainter: DashedBorderPainter(radius: 16, color: hairline),
        child: box,
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onAdd,
          child: box,
        ),
        if (widget.photos.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final photo in widget.photos)
                _PhotoSquare(colors: colors, photo: photo),
              _AddPhotoSquare(colors: colors, onTap: widget.onAdd),
            ],
          ),
        ],
      ],
    );
  }
}

class _PhotoSquare extends StatelessWidget {
  const _PhotoSquare({required this.colors, required this.photo});

  final ColorScheme colors;
  final XFile photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 66,
        height: 66,
        child: FutureBuilder<Uint8List>(
          future: photo.readAsBytes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.primaryContainer, colors.primary],
                  ),
                ),
              );
            }
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          },
        ),
      ),
    );
  }
}

class _AddPhotoSquare extends StatelessWidget {
  const _AddPhotoSquare({required this.colors, required this.onTap});

  final ColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Icon(Icons.add, color: colors.outline),
      ),
    );
  }
}
