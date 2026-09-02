import 'package:flutter/material.dart';

class EntryDetailDivider extends StatelessWidget {
  const EntryDetailDivider({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Divider(height: 1, thickness: 1, color: color),
    );
  }
}
