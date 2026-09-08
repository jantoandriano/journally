import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journally/core/location_provider.dart';
import 'package:journally/core/widgets/button.dart';
import 'package:journally/core/widgets/section_divider.dart';
import 'package:journally/features/cafes/presentation/widgets/notes_field.dart';
import 'package:journally/features/cafes/presentation/widgets/photo_dropzone.dart';
import 'package:journally/features/cafes/presentation/widgets/save_bar.dart';
import 'package:journally/features/cafes/presentation/widgets/section_label.dart';
import 'package:journally/features/cafes/presentation/widgets/tag_pills.dart';

import '../domain/sighting.dart';
import 'providers/sightings_providers.dart';
import 'widgets/species_toggle.dart';

const _traitOptions = ['Adult', 'Friendly', 'No collar', 'Healthy'];

class SightingAddScreen extends ConsumerStatefulWidget {
  const SightingAddScreen({super.key});

  @override
  ConsumerState<SightingAddScreen> createState() => _SightingAddScreenState();
}

class _SightingAddScreenState extends ConsumerState<SightingAddScreen> {
  final List<XFile> _photos = [];
  Species _species = Species.cat;
  final _notesController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    setState(() => _photos.add(picked));
  }

  Future<void> _saveEntry() async {
    setState(() => _isSaving = true);
    final repository = ref.read(sightingsRepositoryProvider);
    try {
      final location = await ref.read(deviceLocationProvider.future);
      final sighting = await repository.createSighting(
        species: _species,
        lat: location.lat,
        lng: location.lng,
        notes: _notesController.text,
        attributes: _selectedTags.toList(),
      );

      var failedPhotos = 0;
      for (final photo in _photos) {
        try {
          await repository.uploadPhoto(sighting.id, photo);
        } catch (_) {
          failedPhotos++;
        }
      }

      ref.invalidate(sightingsProvider);
      if (mounted) {
        final navigator = Navigator.of(context);
        if (failedPhotos > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sighting saved, but $failedPhotos photo${failedPhotos == 1 ? '' : 's'} failed to upload.',
              ),
            ),
          );
        }
        navigator.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save — try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final location = ref.watch(deviceLocationProvider);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 116),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  JournalyButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'New Sighting',
                    style: GoogleFonts.fraunces(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Log a cat or dog you spotted',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PhotoDropzone(photos: _photos, onAdd: _addPhoto),
                  const SizedBox(height: 24),
                  const SectionLabel('Species'),
                  SpeciesToggle(
                    selected: _species,
                    onChanged: (value) => setState(() => _species = value),
                  ),
                  const SectionDivider(),
                  const SectionLabel('Location'),
                  Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        location.when(
                          data: (value) => value.isFallback
                              ? 'Using approximate location'
                              : '${value.lat.toStringAsFixed(4)}, ${value.lng.toStringAsFixed(4)}',
                          loading: () => 'Finding your location…',
                          error: (_, _) => 'Using approximate location',
                        ),
                        style: GoogleFonts.manrope(
                          fontSize: 12.5,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SectionDivider(),
                  const SectionLabel('Notes'),
                  NotesField(controller: _notesController),
                  const SectionDivider(),
                  const SectionLabel('Traits'),
                  TagPills(
                    options: _traitOptions,
                    selected: _selectedTags,
                    onToggle: (tag) => setState(() {
                      if (_selectedTags.contains(tag)) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    }),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SaveBar(
              isSaving: _isSaving,
              onSave: _saveEntry,
              onCancel: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
