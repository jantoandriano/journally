# Riverpod + Feature-First Architecture — Design

## Context

Journally currently has a hand-rolled MVVM: `HomeViewModel extends
ChangeNotifier`, owned and disposed by `HomeScreen` (a
`StatefulWidget`), rebuilt via `ListenableBuilder`. Data comes from a
flat `lib/data/mock_entries.dart` list.

This works for one screen but doesn't scale: every new screen would
need its own hand-wired `ChangeNotifier` lifecycle, there's no
abstraction between "where entries come from" and "how the UI reads
them," and it isn't the pattern most Flutter teams/tutorials use — the
user is learning Flutter and wants the community-standard approach.

Goal: move to Riverpod (with code generation) for state + DI, and a
feature-first folder structure with a repository layer, using Home as
the first (and so far only) feature.

## Decisions made (via brainstorming Q&A)

- **DI**: Riverpod only — no `get_it`. Riverpod's provider graph *is*
  the DI mechanism; running both would be two competing systems.
- **Riverpod style**: code-generation (`@riverpod` annotations +
  `riverpod_generator`/`build_runner`), the current riverpod.dev
  default.
- **Layering**: feature-first with a repository layer
  (`domain`/`data`/`presentation`), no separate usecase/interactor
  layer — the notifier/provider calls the repository directly. Full
  Clean Architecture usecases are overkill at this size.
- **Scope**: re-architect Home *and* lay the app-wide skeleton
  (`ProviderScope`, `features/` convention) so the next screen has a
  pattern to copy.
- **Routing**: not now. Only one screen exists; `go_router` gets added
  when there's a second screen to navigate to. `main.dart` keeps
  `MaterialApp(home: ...)`.
- **Testing**: not written in this pass, but the repository being an
  interface and the notifier being pure logic means it's testable
  later without restructuring.

## Dependencies

Runtime:
- `flutter_riverpod`
- `riverpod_annotation`

Dev:
- `riverpod_generator`
- `build_runner`
- `custom_lint`
- `riverpod_lint` (catches common Riverpod mistakes, e.g. missing
  `ref.watch`, at analyze time)

`google_fonts` stays as-is. The old `ChangeNotifier`-based
`HomeViewModel` (`lib/viewmodels/home_view_model.dart`) is deleted —
superseded by the providers below.

## Folder structure

```
lib/
  features/
    home/
      domain/
        journal_entry.dart          # model (moved from lib/models/)
        journal_repository.dart     # abstract interface
      data/
        mock_journal_repository.dart  # impl backed by mock data
      presentation/
        home_screen.dart            # View — ConsumerStatefulWidget
        home_providers.dart         # @riverpod declarations
        widgets/
          header.dart
          search_bar.dart
          suggestion_chips.dart
          journal_card.dart
  main.dart
```

`lib/models/`, `lib/data/`, `lib/screens/`, `lib/viewmodels/` are
removed once their contents move into `features/home/`.

Splitting `home_screen.dart`'s private widgets (`_Header`,
`_SearchBar`, `_SuggestionChips`, `_JournalCard`, `_AiChip`,
`_OrderTag`) into `presentation/widgets/` addresses the file having
grown to ~300 lines doing View + all sub-widgets at once — each
widget file stays small and independently readable, matching the
"break into units with one clear purpose" principle.

## Providers and data flow

- `journalRepositoryProvider` (`Provider<JournalRepository>`) —
  resolves to `MockJournalRepository()`. Swapping to a real API/DB
  repository later means changing this one line; nothing downstream
  changes.
- `journalEntriesProvider` (`@riverpod` `FutureProvider`) — calls
  `ref.watch(journalRepositoryProvider).fetchEntries()`. `fetchEntries()`
  is `async` even though the mock resolves instantly, so the UI
  already handles the loading/error states a real backend would
  produce. Exposes `AsyncValue<List<JournalEntry>>`.
- `searchQueryProvider` (`@riverpod` `Notifier<String>`) — holds the
  current search text; replaces
  `HomeViewModel.searchQuery`/`updateSearchQuery`. Not wired to actual
  filtering yet (unchanged from before) — just state, same as the
  original spec.

`HomeScreen` becomes a `ConsumerStatefulWidget` (still needs
`TextEditingController` lifecycle management, so `Consumer`-per-widget
isn't enough on its own). It reads:
- `ref.watch(journalEntriesProvider)` → `.when(data:, loading:, error:)`
  to build the grid, header count, etc.
- `ref.watch(searchQueryProvider)` / `ref.read(searchQueryProvider.notifier)`
  for the search bar.

## Error handling

- **Loading**: `AsyncValue.loading()` branch shows a centered
  `CircularProgressIndicator` in place of the grid.
- **Error**: `AsyncValue.error()` branch shows a centered message
  ("Couldn't load your places.") — no retry logic yet, that's beyond
  this pass's scope.

## `main.dart`

Wrapped in `ProviderScope` (required root widget for any Riverpod
app):

```dart
void main() {
  runApp(const ProviderScope(child: JournallyApp()));
}
```

## Out of scope for this pass

- `go_router` / navigation
- Real search filtering logic
- Tests
- A real backend/repository implementation
- Usecase/interactor layer
