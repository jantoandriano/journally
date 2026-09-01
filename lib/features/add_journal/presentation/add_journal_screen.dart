import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journally/features/home/domain/journal_entry.dart';
import 'package:journally/features/home/presentation/providers/home_providers.dart';

const _hairline = Color(0xFFD9D2C8);
const _deepAccent = Color(0xFF8F5A2E);

const _tagOptions = [
  'Good wifi',
  'Quiet',
  'Laptop friendly',
  'Outdoor seating',
  'Power outlets',
  'Late hours',
];

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

bool _isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

class AddEntryScreen extends ConsumerStatefulWidget {
  const AddEntryScreen({super.key});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final List<String> _photos = [];
  double _rating = 0;
  final List<OrderItem> _orderItems = [];
  final _notesController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final Set<String> _selectedTags = {};
  DateTime _visitDate = DateTime.now();
  String? _placeName;
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _addPhoto() {
    setState(() => _photos.add('photo-${_photos.length}'));
  }

  void _addOrderItem() {
    setState(() => _orderItems.add(OrderItem(name: 'New item')));
  }

  void _removeOrderItem(int index) {
    setState(() => _orderItems.removeAt(index));
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

  void _openPlacePicker() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Place picker coming soon')),
    );
  }

  Future<void> _saveEntry() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(journalRepositoryProvider)
          .createEntry(
            placeName: _placeName ?? '',
            neighborhood: _neighborhoodController.text,
            city: _cityController.text,
            orderItems: _orderItems,
            visitedAt: _visitDate,
            rating: _rating > 0 ? _rating : null,
            notes: _notesController.text,
            attributes: _selectedTags.toList(),
          );
      ref.invalidate(journalEntriesProvider);
      if (mounted) Navigator.pop(context);
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
                      _BackButton(onTap: () => Navigator.pop(context)),
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
                    'New entry',
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
                    style: GoogleFonts.manrope(fontSize: 13, color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  _PhotoDropzone(photos: _photos, onAdd: _addPhoto),
                  const SizedBox(height: 24),
                  const _SectionLabel('Place'),
                  _PlaceFields(
                    placeName: _placeName,
                    neighborhoodController: _neighborhoodController,
                    cityController: _cityController,
                    visitDate: _visitDate,
                    onPickDate: _pickDate,
                    onTapPlace: _openPlacePicker,
                  ),
                  const _Divider(),
                  const _SectionLabel('Rating'),
                  _RatingRow(
                    rating: _rating,
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                  const _Divider(),
                  _SectionLabel(
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
                    _OrderItemTile(
                      item: _orderItems[i],
                      onRemove: () => _removeOrderItem(i),
                    ),
                  const _Divider(),
                  const _SectionLabel('Notes'),
                  _NotesField(controller: _notesController),
                  const SizedBox(height: 12),
                  const _AiDraftRow(),
                  const _Divider(),
                  const _SectionLabel('Tags'),
                  _TagPills(
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
            child: _SaveBar(
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Icon(Icons.chevron_left, color: colors.onSurface, size: 22),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 11.5 * 0.06,
              color: colors.outline,
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(height: 1, thickness: 1, color: colors.outlineVariant),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 6).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _PhotoDropzone extends StatefulWidget {
  const _PhotoDropzone({required this.photos, required this.onAdd});

  final List<String> photos;
  final VoidCallback onAdd;

  @override
  State<_PhotoDropzone> createState() => _PhotoDropzoneState();
}

class _PhotoDropzoneState extends State<_PhotoDropzone> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget box = AspectRatio(
      aspectRatio: 3 / 2,
      child: Container(
        decoration: BoxDecoration(
          color: _pressed ? colors.primaryContainer : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: _pressed ? Border.all(color: colors.primary, width: 1.5) : null,
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
                child: Icon(Icons.camera_alt_outlined, color: colors.primary, size: 20),
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
                style: GoogleFonts.manrope(fontSize: 11.5, color: colors.outline),
              ),
            ],
          ),
        ),
      ),
    );

    if (!_pressed) {
      box = CustomPaint(
        foregroundPainter: _DashedBorderPainter(radius: 16, color: _hairline),
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
              for (final _ in widget.photos) _PhotoSquare(colors: colors),
              _AddPhotoSquare(colors: colors, onTap: widget.onAdd),
            ],
          ),
        ],
      ],
    );
  }
}

class _PhotoSquare extends StatelessWidget {
  const _PhotoSquare({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primaryContainer, colors.primary],
          ),
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

class _PlaceFields extends StatelessWidget {
  const _PlaceFields({
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
              child: _SmallField(controller: neighborhoodController, hint: 'Neighborhood'),
            ),
            const SizedBox(width: 10),
            Expanded(child: _SmallField(controller: cityController, hint: 'City')),
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
                Icon(Icons.calendar_today_outlined, size: 16, color: colors.outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _formatDate(visitDate),
                    style: GoogleFonts.manrope(fontSize: 13.5, color: colors.onSurface),
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
            hintStyle: GoogleFonts.manrope(fontSize: 13.5, color: colors.outline),
          ),
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.onChanged});

  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final filled = rating.round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          for (var i = 1; i <= 5; i++)
            Padding(
              padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
              child: GestureDetector(
                onTap: () => onChanged(i.toDouble()),
                child: Icon(
                  i <= filled ? Icons.star : Icons.star_border,
                  size: 26,
                  color: i <= filled ? colors.primary : _hairline,
                ),
              ),
            ),
          const Spacer(),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.fraunces(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item, required this.onRemove});

  final OrderItem item;
  final VoidCallback onRemove;

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
                const SizedBox(height: 2),
                Text(
                  item.note ?? 'Add a note',
                  style: GoogleFonts.manrope(fontSize: 11.5, color: colors.outline),
                ),
              ],
            ),
          ),
          if (item.formattedPrice != null) ...[
            Text(
              item.formattedPrice!,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
          ],
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: _hairline),
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});

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
        style: GoogleFonts.manrope(fontSize: 13.5, height: 1.6, color: colors.onSurfaceVariant),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'What did you notice?',
          hintStyle: GoogleFonts.manrope(fontSize: 13.5, height: 1.6, color: colors.outline),
        ),
      ),
    );
  }
}

class _AiDraftRow extends StatelessWidget {
  const _AiDraftRow();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: _deepAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Turn these into a written note',
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _deepAccent,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: _deepAccent),
        ],
      ),
    );
  }
}

class _TagPills extends StatelessWidget {
  const _TagPills({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in _tagOptions)
          GestureDetector(
            onTap: () => onToggle(tag),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: selected.contains(tag) ? colors.primaryContainer : colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected.contains(tag) ? colors.primary : colors.outlineVariant,
                ),
              ),
              child: Text(
                tag,
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected.contains(tag) ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Save entry',
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
          InkWell(
            onTap: onCancel,
            customBorder: const CircleBorder(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Icon(Icons.close, color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
