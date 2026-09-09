import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client_providers.dart';
import '../../data/http_cafe_repository.dart';
import '../../domain/cafe_entry.dart';
import '../../domain/cafe_repository.dart';

part 'cafe_providers.g.dart';

@riverpod
CafeRepository cafeRepository(Ref ref) {
  return HttpCafeRepository(dio: ref.watch(apiClientProvider));
}

// Kept alive (not autoDispose) — splash reads this future once during
// warm-up via `ref.read`, which doesn't itself keep an autoDispose provider
// alive. Splash rebuilds constantly (ticking animations), and a disposal
// between rebuilds would silently restart the fetch and leave the future
// splash captured never settling.
@Riverpod(keepAlive: true)
Future<List<CafeEntry>> cafeEntries(Ref ref) {
  return ref.watch(cafeRepositoryProvider).fetchCafes();
}

@riverpod
Future<CafeEntry> cafeEntry(Ref ref, String id) {
  return ref.watch(cafeRepositoryProvider).fetchCafeById(id);
}

/// Central Kemang, South Jakarta — used only by the "Near Kemang" cafe
/// chip. This is a one-off named-place override, not the user's device
/// location; the backend has no neighborhood-to-coordinate lookup, so
/// this is hardcoded here rather than invented server-side.
const kemangLat = -6.2607;
const kemangLng = 106.8133;
const kemangRadiusKm = 2.0;

@riverpod
Future<List<CafeEntry>> nearbyCafe(Ref ref) {
  return ref
      .watch(cafeRepositoryProvider)
      .fetchNearbyCafe(
        lat: kemangLat,
        lng: kemangLng,
        radiusKm: kemangRadiusKm,
      );
}
