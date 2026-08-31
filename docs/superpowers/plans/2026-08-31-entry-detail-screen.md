# Entry Detail Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Detail screen (all photos, all order items + total spent, location, delete) reached by tapping a card on Home.

**Architecture:** Plain `Navigator.push` from `JournalCard` to a new `EntryDetailScreen` inside the existing `home` feature, backed by a Riverpod family provider (`journalEntryProvider(id)`) that calls two new `JournalRepository` methods (`fetchEntryById`, `deleteEntry`) already supported by the `journally-api` backend.

**Tech Stack:** Flutter, `flutter_riverpod` (code-gen `@riverpod`), `http`, `google_fonts`, `url_launcher`.

**Spec:** `docs/superpowers/specs/2026-08-31-entry-detail-screen-design.md`

## Global Constraints

- No `go_router` — navigation stays on plain `Navigator`/`MaterialPageRoute`.
- Detail lives inside `lib/features/home/`, not a new top-level feature (it shares `home`'s domain layer).
- Edit is out of scope — the Edit icon shows a "coming soon" snackbar, no edit screen is built.
- `ApiConfig` lives at `lib/core/api_config.dart` (already moved out of `features/home`).
- `flutter analyze` and `flutter test` must stay clean after every task.

---

### Task 1: Add `photoUrls` to `JournalEntry`

**Files:**
- Modify: `lib/features/home/domain/journal_entry.dart:1-27`
- Modify: `lib/features/home/data/http_journal_repository.dart:119-138`
- Modify: `test/widget_test.dart:10-25`

**Interfaces:**
- Produces: `JournalEntry.photoUrls` — `List<String>`, required constructor param, added after `photoCount`.

- [ ] **Step 1: Add the field to the model**

In `lib/features/home/domain/journal_entry.dart`, add `photoUrls` as a required field:

```dart
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.placeName,
    required this.neighborhood,
    required this.city,
    required this.orderItems,
    required this.photoCount,
    required this.photoUrls,
    required this.gradientColors,
    this.lat,
    this.lng,
    this.placeId,
  });

  final String id;
  final String placeName;
  final String neighborhood;
  final String city;
  final List<OrderItem> orderItems;
  final int photoCount;
  final List<String> photoUrls;
  final List<Color> gradientColors;
  final double? lat;
  final double? lng;
  final String? placeId;
}
```

- [ ] **Step 2: Run analyze to see the two call sites that now fail to compile**

Run: `flutter analyze`
Expected: errors at `http_journal_repository.dart` (`_toJournalEntry` missing `photoUrls`) and `test/widget_test.dart` (`_FakeJournalRepository.fetchEntries` missing `photoUrls`).

- [ ] **Step 3: Pass `photoUrls` through in `_toJournalEntry`**

In `lib/features/home/data/http_journal_repository.dart`, the local `photoUrls` variable already exists (it's how `photoCount` is computed) — just pass it into the constructor too:

```dart
  JournalEntry _toJournalEntry(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final photoUrls = (json['photoUrls'] as List<dynamic>).cast<String>();
    final palette = _gradientPalette[id.hashCode.abs() % _gradientPalette.length];

    return JournalEntry(
      id: id,
      placeName: json['placeName'] as String,
      neighborhood: json['neighborhood'] as String,
      city: json['city'] as String,
      orderItems: (json['orderItems'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      photoCount: photoUrls.length,
      photoUrls: photoUrls,
      gradientColors: palette,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      placeId: json['placeId'] as String?,
    );
  }
```

- [ ] **Step 4: Fix the fake repository in the widget test**

In `test/widget_test.dart`, add `photoUrls: const []` to the generated entries:

```dart
  Future<List<JournalEntry>> fetchEntries() async {
    return List.generate(
      6,
      (i) => JournalEntry(
        id: '$i',
        placeName: 'Place $i',
        neighborhood: 'Neighborhood $i',
        city: 'City',
        orderItems: [OrderItem(name: 'Item')],
        photoCount: 0,
        photoUrls: const [],
        gradientColors: const [Color(0xFFE7C9A5), Color(0xFFB8763F)],
      ),
    );
  }
```

- [ ] **Step 5: Run analyze and tests, confirm clean**

Run: `flutter analyze && flutter test`
Expected: no errors, `Home screen loads and shows the place count` passes.

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/domain/journal_entry.dart lib/features/home/data/http_journal_repository.dart test/widget_test.dart
git commit -m "Add photoUrls to JournalEntry for the detail gallery"
```

---

### Task 2: Add `fetchEntryById` and `deleteEntry` to the repository

**Files:**
- Modify: `lib/features/home/domain/journal_repository.dart:1-26`
- Modify: `lib/features/home/data/http_journal_repository.dart` (add two methods)
- Modify: `test/widget_test.dart` (stub the two new abstract methods)

**Interfaces:**
- Consumes: `JournalEntry`, `ApiConfig.baseUrl`, `JournalApiException` (all already in `http_journal_repository.dart`).
- Produces: `JournalRepository.fetchEntryById(String id) → Future<JournalEntry>`, `JournalRepository.deleteEntry(String id) → Future<void>`.

- [ ] **Step 1: Extend the abstract interface**

In `lib/features/home/domain/journal_repository.dart`:

```dart
import 'journal_entry.dart';

abstract class JournalRepository {
  Future<List<JournalEntry>> fetchEntries();

  Future<JournalEntry> fetchEntryById(String id);

  Future<void> deleteEntry(String id);

  Future<JournalEntry> createEntry({
    required String placeName,
    required String neighborhood,
    required String city,
    required List<OrderItem> orderItems,
    double? lat,
    double? lng,
    String? placeId,
  });

  Future<JournalEntry> updateEntry(
    String id, {
    String? placeName,
    String? neighborhood,
    String? city,
    List<OrderItem>? orderItems,
    double? lat,
    double? lng,
    String? placeId,
  });
}
```

- [ ] **Step 2: Run analyze to confirm the expected breakage**

Run: `flutter analyze`
Expected: errors — `HttpJournalRepository` and `_FakeJournalRepository` no longer implement all abstract members.

- [ ] **Step 3: Implement both methods in `HttpJournalRepository`**

In `lib/features/home/data/http_journal_repository.dart`, add these two methods (placed after `fetchEntries`, before `createEntry` — order doesn't matter, but keep GET/DELETE grouped near the other GET):

```dart
  @override
  Future<JournalEntry> fetchEntryById(String id) async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/entries/$id'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw JournalApiException(
        'GET /entries/$id failed with status ${response.statusCode}',
      );
    }

    return _toJournalEntry(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteEntry(String id) async {
    final response = await _client
        .delete(Uri.parse('${ApiConfig.baseUrl}/entries/$id'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 204) {
      throw JournalApiException(
        'DELETE /entries/$id failed with status ${response.statusCode}',
      );
    }
  }
```

- [ ] **Step 4: Stub the two methods in the widget test's fake repository**

In `test/widget_test.dart`, add stubs matching the style of the existing `createEntry`/`updateEntry` stubs (this fake only needs to compile — it's never exercised for these methods in `widget_test.dart`):

```dart
  @override
  Future<JournalEntry> fetchEntryById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEntry(String id) {
    throw UnimplementedError();
  }
```

- [ ] **Step 5: Run analyze and tests, confirm clean**

Run: `flutter analyze && flutter test`
Expected: no errors, existing test still passes.

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/domain/journal_repository.dart lib/features/home/data/http_journal_repository.dart test/widget_test.dart
git commit -m "Add fetchEntryById and deleteEntry to JournalRepository"
```

---

### Task 3: Extract `OpenInMapsButton` into a shared widget

**Files:**
- Create: `lib/features/home/presentation/widgets/open_in_maps_button.dart`
- Modify: `lib/features/home/presentation/widgets/journal_card.dart`

**Interfaces:**
- Produces: `OpenInMapsButton({required double lat, required double lng})` — public `StatelessWidget`.
- Consumes (Task 5, 6): imported as `widgets/open_in_maps_button.dart`.

**Teaching note:** This is a pure refactor — same widget, same behavior, just made public and moved so both `JournalCard` and the new `EntryDetailScreen` can use it instead of copy-pasting the deep-link logic twice.

- [ ] **Step 1: Create the shared widget file**

```dart
// lib/features/home/presentation/widgets/open_in_maps_button.dart
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
```

- [ ] **Step 2: Remove the private copy from `journal_card.dart` and use the shared one**

In `lib/features/home/presentation/widgets/journal_card.dart`:
- Delete the `import 'package:url_launcher/url_launcher.dart';` line (no longer needed here).
- Add `import 'open_in_maps_button.dart';`
- Delete the whole `_OpenInMapsButton` class (lines 122-143 in the current file).
- Change the usage from `_OpenInMapsButton(lat: entry.lat!, lng: entry.lng!)` to `OpenInMapsButton(lat: entry.lat!, lng: entry.lng!)`.

Resulting imports at the top of `journal_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/journal_entry.dart';
import 'open_in_maps_button.dart';
```

- [ ] **Step 3: Run analyze and tests, confirm clean**

Run: `flutter analyze && flutter test`
Expected: no errors, existing test still passes.

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/presentation/widgets/open_in_maps_button.dart lib/features/home/presentation/widgets/journal_card.dart
git commit -m "Extract OpenInMapsButton into a shared widget"
```

---

### Task 4: Add the `journalEntry` family provider

**Files:**
- Modify: `lib/features/home/presentation/home_providers.dart`
- Generated: `lib/features/home/presentation/home_providers.g.dart` (regenerated, do not hand-edit)

**Interfaces:**
- Consumes: `journalRepositoryProvider` (existing), `JournalRepository.fetchEntryById` (Task 2).
- Produces: `journalEntryProvider(String id) → AutoDisposeFutureProvider<JournalEntry>` — a **family** provider.

**Teaching note:** Every provider so far (`journalEntriesProvider`, `journalRepositoryProvider`) takes no argument — there's exactly one instance of each, ever. A family provider is different: `journalEntryProvider(id)` is parameterized, so Riverpod keeps a *separate cached instance per unique `id`* you call it with. Watch `journalEntryProvider('abc')` from one screen and `journalEntryProvider('xyz')` from another, and each gets its own independent fetch, loading state, and cache — navigating back to an `id` you already viewed reuses the cached result instead of refetching, until something calls `ref.invalidate(journalEntryProvider('abc'))`.

- [ ] **Step 1: Add the family provider function**

In `lib/features/home/presentation/home_providers.dart`, add this after the existing `journalEntries` provider:

```dart
@riverpod
Future<JournalEntry> journalEntry(Ref ref, String id) {
  return ref.watch(journalRepositoryProvider).fetchEntryById(id);
}
```

Full file should now read:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/http_journal_repository.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';

part 'home_providers.g.dart';

@riverpod
JournalRepository journalRepository(Ref ref) {
  return HttpJournalRepository();
}

@riverpod
Future<List<JournalEntry>> journalEntries(Ref ref) {
  return ref.watch(journalRepositoryProvider).fetchEntries();
}

@riverpod
Future<JournalEntry> journalEntry(Ref ref, String id) {
  return ref.watch(journalRepositoryProvider).fetchEntryById(id);
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String value) => state = value;
}
```

- [ ] **Step 2: Regenerate the provider code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: completes without errors; `home_providers.g.dart` now contains a `journalEntryProvider` family provider.

- [ ] **Step 3: Run analyze and tests, confirm clean**

Run: `flutter analyze && flutter test`
Expected: no errors, existing test still passes.

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/presentation/home_providers.dart lib/features/home/presentation/home_providers.g.dart
git commit -m "Add journalEntry family provider for fetching a single entry"
```

---

### Task 5: Build `EntryDetailScreen`

**Files:**
- Create: `lib/features/home/presentation/entry_detail_screen.dart`

**Interfaces:**
- Consumes: `journalEntryProvider(id)` (Task 4), `journalRepositoryProvider` + `journalEntriesProvider` (existing), `JournalEntry`/`OrderItem` (Task 1), `OpenInMapsButton` (Task 3), `ApiConfig.baseUrl` (existing, `lib/core/api_config.dart`).
- Produces: `EntryDetailScreen({required String entryId})` — a `ConsumerWidget`, used by Task 6.

**Teaching note:** `AsyncValue.when(loading:, error:, data:)` is the same pattern `HomeScreen` already uses for `journalEntriesProvider` — here it's driven by the family provider instead, watched with the specific `entryId` this screen was given.

- [ ] **Step 1: Write the screen**

```dart
// lib/features/home/presentation/entry_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_config.dart';
import '../domain/journal_entry.dart';
import 'home_providers.dart';
import 'widgets/open_in_maps_button.dart';

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(journalEntryProvider(entryId));
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: entryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Couldn't load this entry.",
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(journalEntryProvider(entryId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (entry) => _EntryDetailBody(entry: entry),
      ),
    );
  }
}

class _EntryDetailBody extends ConsumerWidget {
  const _EntryDetailBody({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final total = entry.orderItems
        .map((item) => item.price)
        .whereType<double>()
        .fold<double>(0, (sum, price) => sum + price);
    final hasAnyPrice = entry.orderItems.any((item) => item.price != null);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: colors.surface,
          title: Text(entry.placeName),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Editing isn't built yet.")),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 240,
            child: entry.photoUrls.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: entry.gradientColors,
                      ),
                    ),
                  )
                : PageView.builder(
                    itemCount: entry.photoUrls.length,
                    itemBuilder: (context, index) => Image.network(
                      '${ApiConfig.baseUrl}${entry.photoUrls[index]}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: colors.surfaceContainerHigh,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: colors.outline,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Icon(Icons.place_outlined, size: 15, color: colors.outline),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${entry.neighborhood}, ${entry.city}',
                    style: GoogleFonts.manrope(fontSize: 13, color: colors.outline),
                  ),
                ),
                if (entry.lat != null && entry.lng != null)
                  OpenInMapsButton(lat: entry.lat!, lng: entry.lng!),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order',
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in entry.orderItems)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        if (item.price != null)
                          Text(
                            '\$${item.price!.toStringAsFixed(2)}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (hasAnyPrice) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total spent',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(journalRepositoryProvider).deleteEntry(entry.id);
      ref.invalidate(journalEntriesProvider);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't delete — try again.")),
        );
      }
    }
  }
}
```

- [ ] **Step 2: Run analyze and tests, confirm clean**

Run: `flutter analyze && flutter test`
Expected: no errors (this screen isn't reachable yet, but it must compile standalone). Existing test still passes.

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/presentation/entry_detail_screen.dart
git commit -m "Add EntryDetailScreen"
```

---

### Task 6: Wire navigation from `JournalCard`

**Files:**
- Modify: `lib/features/home/presentation/widgets/journal_card.dart`

**Interfaces:**
- Consumes: `EntryDetailScreen` (Task 5).

**Teaching note:** `Navigator.push` puts a new screen on top of the current one (with a back button/gesture to return) — the simplest form of navigation, no routing package needed. `MaterialPageRoute` is the standard "slide in a new screen" transition for Material apps.

- [ ] **Step 1: Add the import and wrap the card body**

In `lib/features/home/presentation/widgets/journal_card.dart`, add the import:

```dart
import '../entry_detail_screen.dart';
```

Then wrap the returned `Column` in a `GestureDetector`:

```dart
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visibleItems = entry.orderItems.take(2).toList();
    final extraCount = entry.orderItems.length - visibleItems.length;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EntryDetailScreen(entryId: entry.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ...existing children, unchanged...
        ],
      ),
    );
  }
```

(Only the outermost `return` changes — the `Column` and all its children stay exactly as they are today, just nested one level deeper inside the `GestureDetector`.)

- [ ] **Step 2: Run analyze and tests, confirm clean**

Run: `flutter analyze && flutter test`
Expected: no errors, existing test still passes.

- [ ] **Step 3: Manually verify in the running app**

Run: `flutter run -d windows` (with `journally-api` running locally)
Tap a card → confirm `EntryDetailScreen` opens showing that entry's name, photos/placeholder, order items, total, and (if the entry has coordinates) the maps button. Tap back → confirm it returns to Home.

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/presentation/widgets/journal_card.dart
git commit -m "Navigate to EntryDetailScreen when a card is tapped"
```

---

### Task 7: Tests for `EntryDetailScreen`

**Files:**
- Create: `test/entry_detail_screen_test.dart`

**Interfaces:**
- Consumes: `EntryDetailScreen`, `journalRepositoryProvider`, `JournalRepository`, `JournalEntry`, `OrderItem` (all from prior tasks).

- [ ] **Step 1: Write the test file**

```dart
// test/entry_detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:journally/features/home/domain/journal_entry.dart';
import 'package:journally/features/home/domain/journal_repository.dart';
import 'package:journally/features/home/presentation/entry_detail_screen.dart';
import 'package:journally/features/home/presentation/home_providers.dart';

class _DetailFakeRepository implements JournalRepository {
  _DetailFakeRepository(this.entry);

  final JournalEntry entry;
  bool deleteCalled = false;
  bool deleteShouldFail = false;

  @override
  Future<List<JournalEntry>> fetchEntries() async => [entry];

  @override
  Future<JournalEntry> fetchEntryById(String id) async => entry;

  @override
  Future<void> deleteEntry(String id) async {
    deleteCalled = true;
    if (deleteShouldFail) {
      throw Exception('boom');
    }
  }

  @override
  Future<JournalEntry> createEntry({
    required String placeName,
    required String neighborhood,
    required String city,
    required List<OrderItem> orderItems,
    double? lat,
    double? lng,
    String? placeId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<JournalEntry> updateEntry(
    String id, {
    String? placeName,
    String? neighborhood,
    String? city,
    List<OrderItem>? orderItems,
    double? lat,
    double? lng,
    String? placeId,
  }) {
    throw UnimplementedError();
  }
}

JournalEntry _buildEntry({double? lat, double? lng}) => JournalEntry(
  id: 'e1',
  placeName: 'Cafe One',
  neighborhood: 'Downtown',
  city: 'Metro City',
  orderItems: [
    OrderItem(name: 'Latte', price: 4.5),
    OrderItem(name: 'Croissant', price: 3.25),
  ],
  photoCount: 2,
  photoUrls: const ['/uploads/a.jpg', '/uploads/b.jpg'],
  gradientColors: const [Color(0xFFE7C9A5), Color(0xFFB8763F)],
  lat: lat,
  lng: lng,
);

void main() {
  testWidgets('shows order items and total spent', (tester) async {
    final repo = _DetailFakeRepository(_buildEntry(lat: 40.0, lng: -73.0));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: EntryDetailScreen(entryId: 'e1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cafe One'), findsOneWidget);
    expect(find.text('Latte'), findsOneWidget);
    expect(find.text('Croissant'), findsOneWidget);
    expect(find.text('\$7.75'), findsOneWidget);
  });

  testWidgets('hides open-in-maps button when entry has no coordinates', (
    tester,
  ) async {
    final repo = _DetailFakeRepository(_buildEntry());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: EntryDetailScreen(entryId: 'e1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.directions_outlined), findsNothing);
  });

  testWidgets('confirming delete calls deleteEntry and pops back', (
    tester,
  ) async {
    final repo = _DetailFakeRepository(_buildEntry());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EntryDetailScreen(entryId: 'e1'),
                    ),
                  ),
                  child: const Text('Open detail'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();
    expect(find.byType(EntryDetailScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repo.deleteCalled, isTrue);
    expect(find.text('Open detail'), findsOneWidget);
    expect(find.byType(EntryDetailScreen), findsNothing);
  });
}
```

- [ ] **Step 2: Run the new tests**

Run: `flutter test test/entry_detail_screen_test.dart -v`
Expected: all 3 tests pass.

- [ ] **Step 3: Run the full suite**

Run: `flutter analyze && flutter test`
Expected: clean, both test files pass.

- [ ] **Step 4: Commit**

```bash
git add test/entry_detail_screen_test.dart
git commit -m "Add tests for EntryDetailScreen"
```

---

## After All Tasks

All 7 tasks land directly on `main` (matches this project's existing pattern — solo learning project, no feature branches used so far). Once done: **REQUIRED SUB-SKILL:** use superpowers:finishing-a-development-branch to do the final test-suite check-in — on a normal (non-worktree) repo with everything already on `main`, this reduces to confirming the suite is green and the work is complete.
