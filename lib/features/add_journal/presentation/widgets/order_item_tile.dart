import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journally/features/home/domain/journal_entry.dart';

import 'add_journal_colors.dart';

class OrderItemTile extends StatefulWidget {
  const OrderItemTile({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final OrderItem item;
  final ValueChanged<OrderItem> onChanged;
  final VoidCallback onRemove;

  @override
  State<OrderItemTile> createState() => _OrderItemTileState();
}

class _OrderItemTileState extends State<OrderItemTile> {
  late final _nameController = TextEditingController(text: widget.item.name);
  late final _noteController = TextEditingController(
    text: widget.item.note ?? '',
  );
  late final _priceController = TextEditingController(
    text: widget.item.price?.round().toString() ?? '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(
      OrderItem(
        name: _nameController.text,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        price: _priceController.text.isEmpty
            ? null
            : double.tryParse(_priceController.text),
      ),
    );
  }

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
        crossAxisAlignment: CrossAxisAlignment.center,
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
                TextField(
                  controller: _nameController,
                  onChanged: (_) => _emitChange(),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Item name',
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _noteController,
                  onChanged: (_) => _emitChange(),
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    color: colors.outline,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Add a note',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _priceController,
              onChanged: (_) => _emitChange(),
              textAlign: TextAlign.end,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
              decoration: InputDecoration(
                isDense: true,
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Price',
                hintStyle: GoogleFonts.manrope(
                  fontSize: 12.5,
                  color: colors.outline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: widget.onRemove,
            child: const Icon(Icons.close, size: 16, color: hairline),
          ),
        ],
      ),
    );
  }
}
