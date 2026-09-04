import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_provider.g.dart';

/// Central Jakarta (Monas) — used whenever we can't get a real device fix
/// (permission denied, location services disabled, timeout, or any other
/// error). Matches the "Jakarta" theming already shown on the splash screen.
const jakartaFallbackLat = -6.1754;
const jakartaFallbackLng = 106.8272;

class DeviceLocation {
  const DeviceLocation({
    required this.lat,
    required this.lng,
    required this.isFallback,
  });

  final double lat;
  final double lng;
  final bool isFallback;
}

const _fallback = DeviceLocation(
  lat: jakartaFallbackLat,
  lng: jakartaFallbackLng,
  isFallback: true,
);

@riverpod
Future<DeviceLocation> deviceLocation(Ref ref) async {
  try {
    // Wraps the whole sequence, not just getCurrentPosition — an unanswered
    // browser permission prompt has no timeout of its own and would
    // otherwise hang splash's warm-up forever.
    return await _resolveDeviceLocation().timeout(const Duration(seconds: 8));
  } catch (_) {
    // Any failure (timeout, platform exception, plugin unavailable, etc.)
    // — never throw past this provider.
    return _fallback;
  }
}

Future<DeviceLocation> _resolveDeviceLocation() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return _fallback;
  }

  if (!await Geolocator.isLocationServiceEnabled()) {
    return _fallback;
  }

  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
  );
  return DeviceLocation(
    lat: position.latitude,
    lng: position.longitude,
    isFallback: false,
  );
}
