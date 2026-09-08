import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenInMapsButton extends StatelessWidget {
  const OpenInMapsButton({super.key, required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => launchUrl(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
        mode: LaunchMode.externalApplication,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(Icons.directions_outlined, size: 15, color: colors.primary),
      ),
    );
  }
}
