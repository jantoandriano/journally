# Place Search — Design

## Context

`AddEntryScreen`'s "Add a place" field (`_PlaceFields`) is currently a
dead tap target — it shows a "Place picker coming soon" snackbar
(`_openPlacePicker` in `add_journal_screen.dart`). `JournalEntry` and
`JournalRepository.createEntry`/`updateEntry` already carry `placeId`,
`lat`, and `lng` alongside `placeName`/`neighborhood`/`city` — that
shape only makes sense fed by a real places search, not free text, so
this spec designs the picker that fills it.

Goal: a search-as-you-type place picker, following the existing
feature-first + repository + Riverpod pattern (`home` feature), that
returns a structured result `AddEntryScreen` merges into its form
state.

## Decisions made (via brainstorming Q&A)

- **Provider**: OpenStreetMap Nominatim. No API key or billing setup
  required, which matters for a personal-project app with no backend
  team managing secrets. Tradeoff accepted: Nominatim's fair-use policy
  caps at ~1 request/second and its address breakdown is less clean
  than Google Places, so neighborhood/city parsing needs fallback
  chains (see below) rather than one reliable field.
- **UI shape**: a dedicated full-screen search (`PlaceSearchScreen`),
  not a dialog/bottom sheet — typeahead needs a keyboard-visible text
  field plus a scrolling result list, which a dialog cramps.
- **Search-as-you-type strategy**: manual debounce in the screen's
  `State` (`Timer` reset on every keystroke, ~450ms), not a Riverpod
  `.family` provider keyed by query string. A family provider would
  cache one entry per keystroke, which is wasteful and doesn't help
  here since results aren't reused. The repository call itself stays a
  plain `Future`, invoked via `ref.read`.
- **Result identity**: Nominatim's `place_id` (an integer, not stable
  long-term but fine as this app's `JournalEntry.placeId` — same
  non-guaranteed-stable caveat already applies to Google's `place_id`
  in practice).
- **Minimum query length**: 3 characters before firing a request, to
  cut obviously-useless calls while typing.

## Dependencies

No new packages — Nominatim is a plain HTTPS JSON endpoint, reachable
with the `http` package already in use for `HttpJournalRepository`.

## Folder structure

```
lib/
  features/
    place_search/
      domain/
        place_search_result.dart        # model
        place_search_repository.dart    # abstract interface
      data/
        nominatim_place_search_repository.dart
      presentation/
        place_search_screen.dart        # search field + result list
        providers/
          place_search_providers.dart   # @riverpod placeSearchRepository
```

Mirrors `features/home/`'s `domain`/`data`/`presentation` split, kept
as its own feature (not nested under `home` or `add_journal`) since a
place picker is generic enough to be reused from other flows later
(e.g. editing a place on an existing entry) without a cross-feature
import.

## Domain model

```dart
class PlaceSearchResult {
  const PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.neighborhood,
    required this.city,
    required this.lat,
    required this.lng,
  });

  final String placeId;
  final String name;
  final String neighborhood;
  final String city;
  final double lat;
  final double lng;
}
```

`name`/`neighborhood`/`city` are always non-null strings (empty string
when Nominatim has no matching address component) — `_PlaceFields`'
neighborhood/city are plain text fields the user can already edit by
hand, so an empty prefill is fine; it doesn't block anything.

## Repository

```dart
abstract class PlaceSearchRepository {
  Future<List<PlaceSearchResult>> search(String query);
}
```

`NominatimPlaceSearchRepository` implementation:

- `GET https://nominatim.openstreetmap.org/search` with params
  `q=<query>&format=jsonv2&addressdetails=1&limit=8`.
- Required `User-Agent` header identifying the app + a contact means,
  per Nominatim's usage policy (generic/default user agents get
  blocked) — needs a real value filled in before shipping, not a
  placeholder.
- Maps each result's `address` object to `neighborhood`/`city` with
  fallback chains, since Nominatim's fields vary by locale/place type:
  - `neighborhood`: `address.suburb ?? address.neighbourhood ?? ''`
  - `city`: `address.city ?? address.town ?? address.village ?? address.county ?? ''`
- `name` uses the result's `name` field, falling back to the first
  segment of `display_name` if `name` is empty (some POI-less address
  results omit it).
- Same `JournalApiException`-style error on non-200, matching
  `HttpJournalRepository`'s convention.

## Providers

```dart
@riverpod
PlaceSearchRepository placeSearchRepository(Ref ref) {
  return NominatimPlaceSearchRepository();
}
```

No provider for search results themselves — see "search-as-you-type
strategy" above.

## `PlaceSearchScreen`

- `ConsumerStatefulWidget`, pushed via
  `Navigator.push<PlaceSearchResult>(context, MaterialPageRoute(...))`
  from `_openPlacePicker`.
- Same visual language as `AddEntryScreen` (background/surface/ink
  tokens, Manrope/Fraunces, no new colors): top row with back button,
  a single search field styled like `_SmallField`, results as a
  scrollable list of tappable rows (place icon + name + neighborhood,
  city subtext).
- States: idle (query < 3 chars) shows a prompt; loading shows a small
  inline spinner under the field (not a full-screen blocker — user is
  still typing); empty results shows "No places found"; error shows an
  inline retry-less message, matching `HomeScreen`'s
  "Couldn't load your places." pattern.
- Tapping a result: `Navigator.pop(context, result)`.

## Wiring into `AddEntryScreen`

- `_openPlacePicker` becomes `async`, pushes `PlaceSearchScreen`,
  awaits the popped `PlaceSearchResult?`.
- On a non-null result: `setState` fills `_placeName` (new state field,
  currently already present), plus new state fields `_placeId`,
  `_placeLat`, `_placeLng`; also overwrites
  `_neighborhoodController.text`/`_cityController.text` (user can still
  hand-edit after).
- `_saveEntry` passes `placeId: _placeId, lat: _placeLat, lng:
  _placeLng` into `createEntry` — currently those three are never sent
  even though `createEntry` already accepts them.

## Out of scope for this pass

- Current-location/GPS-based search ("near me").
- Map preview of the selected place.
- Result caching/offline support.
- Debounce/rate-limit handling beyond the client-side 450ms timer —
  no request queue or backoff if Nominatim 429s.
- Editing an existing entry's place (`updateEntry` isn't touched;
  entry editing overall isn't built yet).
