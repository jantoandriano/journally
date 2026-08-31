# Entry Detail Screen — Design Spec

**Goal:** Add a Detail screen that shows a full journal entry (all photos, all order items with a spent total, location) reached by tapping a card on Home, with a working Delete action.

**Context:** The `home` feature currently only lists entries as cards (`JournalCard`) in a grid on `HomeScreen`. Cards aren't tappable, there's no navigation in the app yet (`FloatingActionButton.onPressed` is empty), and no `go_router` — navigation stays on plain `Navigator` (`MaterialPageRoute`) per an earlier decision to hold off on routing packages. The backend (`journally-api`) already supports `GET /entries/:id` and `DELETE /entries/:id`; the Flutter repository doesn't call either yet.

An **Edit** screen (with a location picker, Places autocomplete, Android-only map) is a separate, not-yet-built feature. This spec adds an Edit *entry point* on Detail (an icon button) that shows a "coming soon" snackbar until that screen exists — it does not build editing.

## Architecture

- **Navigation:** `JournalCard` is wrapped in a tap handler. Tapping pushes `EntryDetailScreen` via `Navigator.push(MaterialPageRoute(builder: (_) => EntryDetailScreen(entryId: entry.id)))`, passing only the `id` — not the already-loaded `JournalEntry` object.
- **Data fetch:** `EntryDetailScreen` watches a new Riverpod **family provider**, `journalEntryProvider(id)` (code-gen `@riverpod` function with a `String id` argument). A family provider is a provider parameterized by an argument — Riverpod keeps a separate cached instance per unique `id`, so navigating to entry A, then B, then back to A does not re-fetch A unless something invalidates it. This provider calls `ref.watch(journalRepositoryProvider).fetchEntryById(id)`.
- **Location in the codebase:** Detail lives inside the existing `home` feature (`lib/features/home/presentation/entry_detail_screen.dart`), not a new top-level feature. It's another view over the same `JournalEntry`/`JournalRepository` domain that `home` already owns; a separate feature would just duplicate that domain layer.
- **Repository additions:** `JournalRepository` gains:
  ```dart
  Future<JournalEntry> fetchEntryById(String id);
  Future<void> deleteEntry(String id);
  ```
  `HttpJournalRepository` implements these against `GET /entries/:id` (200 → parse, 404 → throw `JournalApiException`) and `DELETE /entries/:id` (204 → success, else throw).
- **Model addition:** `JournalEntry` gains `photoUrls: List<String>` (currently `HttpJournalRepository._toJournalEntry` reads the photo URLs from the API only to compute `photoCount` and discards them — the actual URLs are needed for the gallery). `photoCount` stays derived as `photoUrls.length`, kept as a separate field since the card already relies on it.

## Components

`lib/features/home/presentation/entry_detail_screen.dart` — `ConsumerWidget`:

- **AppBar:** default back button (from `Navigator.push`), `title: Text(entry.placeName)`, two `actions`:
  - Edit icon button → `ScaffoldMessenger.of(context).showSnackBar` with "Editing isn't built yet."
  - Delete icon button → opens the confirm dialog (below).
- **Photo gallery:** horizontal `PageView.builder` over `entry.photoUrls`, each page `Image.network('${ApiConfig.baseUrl}$url')`. If `photoUrls` is empty, show the same gradient placeholder box (`entry.gradientColors`) the card uses, so the screen never shows a blank gap.
- **Order items:** full list (no 2-item cap, unlike the card) — one row per `OrderItem` showing `name` and, if present, `price`. Below the list, a "Total spent" row summing all non-null `price` values (hidden if every item has no price).
- **Location:** the existing "Open in Maps" button, extracted from `journal_card.dart` into `lib/features/home/presentation/widgets/open_in_maps_button.dart` (a small `StatelessWidget` taking `lat`/`lng`) so both `JournalCard` and `EntryDetailScreen` share the exact same deep-link logic instead of duplicating it. Shown only when `entry.lat != null && entry.lng != null`.
- **Delete confirm dialog:** standard `AlertDialog` — "Delete this entry?" with Cancel / Delete actions.

## Data Flow

1. User taps a `JournalCard` on Home → `Navigator.push` with the entry's `id`.
2. `EntryDetailScreen` builds, `ref.watch(journalEntryProvider(entryId))` triggers `HttpJournalRepository.fetchEntryById(id)` → `GET /entries/:id`.
3. `AsyncValue.when` renders: `loading` → `CircularProgressIndicator`; `error` → error text + a Retry button (`ref.invalidate(journalEntryProvider(entryId))`); `data` → the full screen described above.
4. **Delete:** user taps delete icon → confirm dialog → on confirm, `await ref.read(journalRepositoryProvider).deleteEntry(id)` → on success, `ref.invalidate(journalEntriesProvider)` (so Home's list refetches) → `Navigator.pop(context)` back to Home. On failure, show a `SnackBar` with the error and stay on Detail (nothing is invalidated or popped).

## Error Handling

- Fetch failure (network error, 404, timeout): `AsyncValue.error` branch shows a short message ("Couldn't load this entry.") and a Retry button that invalidates the family provider to refetch.
- Delete failure: caught around the `deleteEntry` call; shows a `SnackBar` ("Couldn't delete — try again."); screen state is untouched so the user can retry.
- Network images (`Image.network`) use Flutter's built-in `errorBuilder` to show a placeholder icon instead of a broken-image glyph if a photo fails to load.

## Testing

- `test/entry_detail_screen_test.dart`, following the existing `widget_test.dart` pattern: override `journalRepositoryProvider` with a fake repository (extend the existing `_FakeJournalRepository` or add a small dedicated fake) that implements `fetchEntryById` and `deleteEntry`.
- Cases: (1) entry with photos/prices renders name, total, and photo count; (2) entry with no `lat`/`lng` hides the maps button; (3) tapping Delete → confirming → calls `deleteEntry` and pops the route (verify via a `Navigator` observer or by pumping inside a route stack with a Home stand-in).
- `flutter analyze` and `flutter test` must stay clean, matching the project's existing bar.

## Out of Scope

- The actual Edit screen (location picker, Places autocomplete, Android map) — separate future spec.
- Adding/removing photos from an entry.
- Pull-to-refresh or offline caching on Detail.
- go_router / deep linking to a specific entry from outside the app.
