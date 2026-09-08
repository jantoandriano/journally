import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journally/features/cafes/domain/cafe_entry.dart';
import 'package:journally/features/cafes/presentation/providers/cafe_providers.dart';
import 'package:journally/features/place_search/domain/place_search_result.dart';
import 'package:journally/features/place_search/presentation/place_search_screen.dart';

import 'widgets/ai_draft_row.dart';
import 'widgets/back_button.dart';
import 'widgets/notes_field.dart';
import 'widgets/order_item_tile.dart';
import 'widgets/photo_dropzone.dart';
import 'widgets/place_fields.dart';
import 'widgets/rating_row.dart';
import 'widgets/save_bar.dart';
import 'widgets/section_divider.dart';
import 'widgets/section_label.dart';
import 'widgets/tag_pills.dart';

class CafeAddScreen extends ConsumerStatefulWidget {
  const CafeAddScreen({super.key});

  @override
  ConsumerState<CafeAddScreen> createState() => _CafeAddScreenState();
}

class _CafeAddScreenState extends ConsumerState<CafeAddScreen> {
  final List<XFile> _photos = [];
  double _rating = 0;
  final List<OrderItem> _orderItems = [];
  final List<Key> _orderItemKeys = [];
  final _notesController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final Set<String> _selectedTags = {};
  DateTime _visitDate = DateTime.now();
  String? _placeName;
  String? _placeId;
  double? _placeLat;
  double? _placeLng;
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
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

  void _addOrderItem() {
    setState(() {
      _orderItems.add(OrderItem(name: 'New item'));
      _orderItemKeys.add(UniqueKey());
    });
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
      _orderItemKeys.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _openPlacePicker() async {
    final result = await Navigator.push<PlaceSearchResult>(
      context,
      MaterialPageRoute(builder: (_) => const PlaceSearchScreen()),
    );
    if (result == null) return;
    setState(() {
      _placeName = result.name;
      _placeId = result.placeId;
      _placeLat = result.lat;
      _placeLng = result.lng;
      _neighborhoodController.text = result.neighborhood;
      _cityController.text = result.city;
    });
  }

  Future<void> _saveEntry() async {
    setState(() => _isSaving = true);
    final repository = ref.read(cafeRepositoryProvider);
    try {
      final entry = await repository.createCafe(
        placeName: _placeName ?? '',
        neighborhood: _neighborhoodController.text,
        city: _cityController.text,
        orderItems: _orderItems,
        visitedAt: _visitDate,
        rating: _rating > 0 ? _rating : null,
        notes: _notesController.text,
        attributes: _selectedTags.toList(),
        lat: _placeLat,
        lng: _placeLng,
        placeId: _placeId,
      );

      var failedPhotos = 0;
      for (final photo in _photos) {
        try {
          await repository.uploadPhoto(entry.id, photo);
        } catch (_) {
          failedPhotos++;
        }
      }

      ref.invalidate(cafeEntriesProvider);
      if (mounted) {
        final navigator = Navigator.of(context);
        if (failedPhotos > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Entry saved, but $failedPhotos photo${failedPhotos == 1 ? '' : 's'} failed to upload.',
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
                  Row(
                    children: [
                      AddEntryBackButton(onTap: () => Navigator.pop(context)),
                      const Spacer(),
                      Text(
                        'Draft saved',
                        style: GoogleFonts.manrope(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'New Journal',
                    style: GoogleFonts.fraunces(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Log a cafe you visited',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PhotoDropzone(photos: _photos, onAdd: _addPhoto),
                  const SizedBox(height: 24),
                  const SectionLabel('Place'),
                  PlaceFields(
                    placeName: _placeName,
                    neighborhoodController: _neighborhoodController,
                    cityController: _cityController,
                    visitDate: _visitDate,
                    onPickDate: _pickDate,
                    onTapPlace: _openPlacePicker,
                  ),
                  const SectionDivider(),
                  const SectionLabel('Rating'),
                  RatingRow(
                    rating: _rating,
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                  const SectionDivider(),
                  SectionLabel(
                    'What I ordered',
                    trailing: TextButton(
                      onPressed: _addOrderItem,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '+ Add item',
                        style: GoogleFonts.manrope(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                  for (var i = 0; i < _orderItems.length; i++)
                    OrderItemTile(
                      key: _orderItemKeys[i],
                      item: _orderItems[i],
                      onChanged: (updated) =>
                          setState(() => _orderItems[i] = updated),
                      onRemove: () => _removeOrderItem(i),
                    ),
                  const SectionDivider(),
                  const SectionLabel('Notes'),
                  NotesField(controller: _notesController),
                  const SizedBox(height: 12),
                  const AiDraftRow(),
                  const SectionDivider(),
                  const SectionLabel('Tags'),
                  TagPills(
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
