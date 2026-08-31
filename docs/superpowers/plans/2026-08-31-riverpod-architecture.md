# Riverpod + Feature-First Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate Journally's Home feature from a hand-rolled `ChangeNotifier` MVVM to Riverpod (code-gen flavor) with a feature-first, repository-based folder structure, and wire the app root through `ProviderScope`.

**Architecture:** `lib/features/home/{domain,data,presentation}` — `domain` holds the `JournalEntry` model and the abstract `JournalRepository`; `data` holds `MockJournalRepository`; `presentation` holds the `@riverpod`-generated providers, the `HomeScreen` view, and its extracted sub-widgets. `journalEntriesProvider` is a `FutureProvider` exposing `AsyncValue<List<JournalEntry>>` so the UI already handles loading/error states a real backend would produce.

**Tech Stack:** Flutter, `flutter_riverpod`, `riverpod_annotation` + `riverpod_generator`/`build_runner` (codegen), `custom_lint`/`riverpod_lint`, `google_fonts` (unchanged).

**Spec:** `docs/superpowers/specs/2026-08-31-riverpod-architecture-design.md`

**Audience note:** the person executing this plan is new to Flutter and explicitly wants to be taught, not just handed finished files. Every task below includes a "Teaching note" explaining the *why* of the concept it introduces — read those out (or paraphrase them) as you go, don't just silently perform the file edits.

## Global Constraints

- DI is Riverpod only — never add `get_it` or any second DI mechanism.
- Riverpod code-gen style only (`@riverpod` annotations + `riverpod_generator`) — no hand-written `StateNotifierProvider`/`ChangeNotifierProvider` declarations.
- No `go_router` / navigation in this pass — `main.dart` keeps `MaterialApp(home: ...)`.
- No real search-filtering logic — `searchQueryProvider` only stores the text, same as the `HomeViewModel` it replaces.
- No usecase/interactor layer — the provider calls the repository directly.
- No automated tests written in this pass (per spec) — verification is `flutter analyze` plus manually running the app on Windows to confirm the UI still matches.
- `lib/models/`, `lib/data/`, `lib/viewmodels/`, and the old `lib/screens/home_screen.dart` are deleted once their contents move into `lib/features/home/`.

---

### Task 1: Add Riverpod dependencies and analyzer plugin config

**Files:**
- Modify: `pubspec.yaml`
- Modify: `analysis_options.yaml`

**Interfaces:**
- Consumes: nothing
- Produces: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `build_runner`, `custom_lint`, `riverpod_lint` available as imports for every later task.

**Teaching note:** Riverpod ships two packages you need: `flutter_riverpod` (the runtime — `ProviderScope`, `ConsumerWidget`, etc.) and `riverpod_annotation` (the `@riverpod` annotation itself). The dev-only packages (`riverpod_generator`, `build_runner`) don't ship in your app — they run at *build time* on your machine, read your `@riverpod`-annotated code, and write a matching `*.g.dart` file next to it containing the actual `Provider`/`FutureProvider`/`Notifier` boilerplate you'd otherwise hand-write. `riverpod_lint` (via the `custom_lint` engine) adds analyzer warnings specific to Riverpod mistakes — e.g. using `ref.read` inside `build()` instead of `ref.watch`, which silently breaks reactivity.

- [ ] **Step 1: Add the dependencies to `pubspec.yaml`**

In `pubspec.yaml`, change:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.8
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^6.0.0
```

to:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.8
  google_fonts: ^6.2.1
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^6.0.0
  riverpod_generator: ^2.6.3
  build_runner: ^2.4.13
  custom_lint: ^0.7.0
  riverpod_lint: ^2.6.4
```

- [ ] **Step 2: Enable the `custom_lint` analyzer plugin**

In `analysis_options.yaml`, `riverpod_lint`'s warnings only surface if the analyzer knows to load `custom_lint` as a plugin. Change:

```yaml
analyzer:
  exclude:
    - build/**
    - android/**
    - ios/**
    - web/**
    - windows/**
    - macos/**
    - linux/**
```

to:

```yaml
analyzer:
  plugins:
    - custom_lint
  exclude:
    - build/**
    - android/**
    - ios/**
    - web/**
    - windows/**
    - macos/**
    - linux/**
```

- [ ] **Step 3: Fetch the new packages**

Run: `flutter pub get`
Expected: exits 0, output ends with a dependency summary (no red error text). If a version conflict shows up, drop the affected package's version constraint (e.g. `flutter_riverpod: ^2.6.1` → no constraint) and re-run — don't hand-solve transitive version math.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock analysis_options.yaml
git commit -m "chore: add riverpod and riverpod_generator dependencies"
```

---

### Task 2: Domain layer — model and repository interface

**Files:**
- Create: `lib/features/home/domain/journal_entry.dart`
- Create: `lib/features/home/domain/journal_repository.dart`

**Interfaces:**
- Consumes: nothing
- Produces: `class JournalEntry` (fields: `id`, `placeName`, `neighborhood`, `city`, `orderItems` (`List<String>`), `photoCount` (`int`), `gradientColors` (`List<Color>`)); `abstract class JournalRepository` with `Future<List<JournalEntry>> fetchEntries()`.

**Teaching note:** `domain` is the layer that doesn't know *how* data is fetched — only *what* the app needs (a list of `JournalEntry`, fetched somehow). `JournalRepository` here is an abstract class with no implementation: it's a contract. Nothing in `domain` imports Riverpod, Dio, SQLite, or anything else — that's what keeps this layer swappable and easy to reason about in isolation. The concrete implementation (mock data now, a real API/DB later) lives one layer over, in `data`, and implements this contract.

- [ ] **Step 1: Create the model**

Create `lib/features/home/domain/journal_entry.dart`:

```dart
import 'package:flutter/material.dart';

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.placeName,
    required this.neighborhood,
    required this.city,
    required this.orderItems,
    required this.photoCount,
    required this.gradientColors,
  });

  final String id;
  final String placeName;
  final String neighborhood;
  final String city;
  final List<String> orderItems;
  final int photoCount;
  final List<Color> gradientColors;
}
```

- [ ] **Step 2: Create the repository interface**

Create `lib/features/home/domain/journal_repository.dart`:

```dart
import 'journal_entry.dart';

abstract class JournalRepository {
  Future<List<JournalEntry>> fetchEntries();
}
```

- [ ] **Step 3: Verify it analyzes cleanly**

Run: `flutter analyze lib/features/home/domain`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/domain
git commit -m "feat: add JournalEntry model and JournalRepository interface in domain layer"
```

---

### Task 3: Data layer — mock repository implementation

**Files:**
- Create: `lib/features/home/data/mock_journal_repository.dart`

**Interfaces:**
- Consumes: `JournalEntry`, `JournalRepository` from `lib/features/home/domain/`
- Produces: `class MockJournalRepository implements JournalRepository`

**Teaching note:** This is the concrete class that fulfills the `JournalRepository` contract from Task 2. Today it just returns an in-memory list wrapped in `Future` — but because callers only ever depend on the `JournalRepository` type (never on `MockJournalRepository` directly), swapping this for a real network/database-backed repository later is a one-file change: nothing in `presentation` needs to know or care.

- [ ] **Step 1: Create the mock repository**

Create `lib/features/home/data/mock_journal_repository.dart` (the six sample entries are carried over unchanged from the old `lib/data/mock_entries.dart`):

```dart
import 'package:flutter/material.dart';

import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';

class MockJournalRepository implements JournalRepository {
  static final List<JournalEntry> _entries = [
    JournalEntry(
      id: '1',
      placeName: 'Kopi Manyar',
      neighborhood: 'Kemang',
      city: 'Jakarta',
      orderItems: const ['Iced Gula Aren Latte', 'Butter Croissant'],
      photoCount: 4,
      gradientColors: [const Color(0xFFE7C9A5), const Color(0xFFB8763F)],
    ),
    JournalEntry(
      id: '2',
      placeName: 'Sarah Coffee Bar',
      neighborhood: 'SCBD',
      city: 'Jakarta',
      orderItems: const ['Flat White', 'Avocado Toast', 'Cold Brew'],
      photoCount: 6,
      gradientColors: [const Color(0xFFD8C7E8), const Color(0xFF8C6FAE)],
    ),
    JournalEntry(
      id: '3',
      placeName: 'Tuku Coffee',
      neighborhood: 'Senopati',
      city: 'Jakarta',
      orderItems: const ['Es Kopi Susu'],
      photoCount: 2,
      gradientColors: [const Color(0xFFC9E0D8), const Color(0xFF5F9782)],
    ),
    JournalEntry(
      id: '4',
      placeName: 'Anomali Coffee',
      neighborhood: 'Menteng',
      city: 'Jakarta',
      orderItems: const ['Cappuccino', 'Banana Bread'],
      photoCount: 3,
      gradientColors: [const Color(0xFFF0D8B0), const Color(0xFFC98A4B)],
    ),
    JournalEntry(
      id: '5',
      placeName: 'Common Grounds',
      neighborhood: 'PIK',
      city: 'Jakarta',
      orderItems: const [
        'Matcha Latte',
        'Cinnamon Roll',
        'Americano',
        'Bagel',
      ],
      photoCount: 8,
      gradientColors: [const Color(0xFFCFE0EE), const Color(0xFF6B92B8)],
    ),
    JournalEntry(
      id: '6',
      placeName: 'Filosofi Kopi',
      neighborhood: 'Kemang',
      city: 'Jakarta',
      orderItems: const ['Vietnam Drip', 'Pisang Goreng'],
      photoCount: 5,
      gradientColors: [const Color(0xFFE3D3C3), const Color(0xFF9C7A5B)],
    ),
  ];

  @override
  Future<List<JournalEntry>> fetchEntries() async {
    return _entries;
  }
}
```

- [ ] **Step 2: Verify it analyzes cleanly**

Run: `flutter analyze lib/features/home/data`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/data
git commit -m "feat: add MockJournalRepository implementing JournalRepository"
```

---

### Task 4: Presentation providers — Riverpod codegen

**Files:**
- Create: `lib/features/home/presentation/home_providers.dart`
- Generated (by build_runner, do not hand-edit): `lib/features/home/presentation/home_providers.g.dart`

**Interfaces:**
- Consumes: `JournalRepository`, `JournalEntry` from `domain`; `MockJournalRepository` from `data`
- Produces: `journalRepositoryProvider` (`Provider<JournalRepository>`), `journalEntriesProvider` (`FutureProvider<List<JournalEntry>>`, read as `AsyncValue<List<JournalEntry>>`), `searchQueryProvider` (generated from `class SearchQuery`, notifier exposes `void update(String value)`, read as `String`).

**Teaching note:** This is the DI graph. `journalRepositoryProvider` is the single place that decides *which* `JournalRepository` implementation the app uses right now (`MockJournalRepository`) — every other provider or widget asks Riverpod for a `JournalRepository` and never constructs one itself, so this is the one line you'd change to point at a real backend later. `journalEntriesProvider` is a `FutureProvider`: Riverpod runs its function once, caches the `Future`'s result, and exposes it to widgets as an `AsyncValue` with three states (`loading`, `data`, `error`) baked in — that's what lets `HomeScreen` show a spinner or error message for free in Task 6, instead of you hand-writing that state machine. `SearchQuery` is a `Notifier<String>`: a small class holding one piece of mutable state (the search text) plus a method to change it — the direct Riverpod replacement for the old `HomeViewModel.searchQuery`/`updateSearchQuery`.

- [ ] **Step 1: Create the providers file**

Create `lib/features/home/presentation/home_providers.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/mock_journal_repository.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';

part 'home_providers.g.dart';

@riverpod
JournalRepository journalRepository(Ref ref) {
  return MockJournalRepository();
}

@riverpod
Future<List<JournalEntry>> journalEntries(Ref ref) {
  return ref.watch(journalRepositoryProvider).fetchEntries();
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String value) => state = value;
}
```

- [ ] **Step 2: Run the code generator**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: ends with `[INFO] Succeeded after ...` and a new file `lib/features/home/presentation/home_providers.g.dart` now exists containing generated `journalRepositoryProvider`, `journalEntriesProvider`, `searchQueryProvider`, `SearchQuery` definitions.

- [ ] **Step 3: Verify it analyzes cleanly**

Run: `flutter analyze lib/features/home/presentation/home_providers.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/presentation/home_providers.dart lib/features/home/presentation/home_providers.g.dart
git commit -m "feat: add Riverpod providers for journal repository, entries, and search query"
```

---

### Task 5: Presentation widgets — extract from the old home_screen.dart

**Files:**
- Create: `lib/features/home/presentation/widgets/header.dart`
- Create: `lib/features/home/presentation/widgets/search_bar.dart`
- Create: `lib/features/home/presentation/widgets/suggestion_chips.dart`
- Create: `lib/features/home/presentation/widgets/journal_card.dart`

**Interfaces:**
- Consumes: `JournalEntry` from `lib/features/home/domain/journal_entry.dart`
- Produces: `class Header`, `class JournalSearchBar`, `class SuggestionChips`, `class JournalCard` — all public `StatelessWidget`s, used by `HomeScreen` in Task 6.

**Teaching note:** This step is pure refactor, not new Riverpod concepts — it splits the private widget classes that were living inside the old `home_screen.dart` (`_Header`, `_SearchBar`, `_SuggestionChips`, `_JournalCard`, plus their private helpers `_AiChip`/`_OrderTag`) into their own files under `presentation/widgets/`, each promoted from a private (`_Name`) to a public (`Name`) class so `home_screen.dart` can import and use them. One rename to flag: the search bar widget is renamed `JournalSearchBar` instead of `SearchBar`, because Flutter's `material.dart` already exports a built-in `SearchBar` widget (Material 3) — reusing that name would shadow it and confuse imports.

- [ ] **Step 1: Create the header widget**

Create `lib/features/home/presentation/widgets/header.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Header extends StatelessWidget {
  const Header({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journally',
          style: GoogleFonts.fraunces(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count places visited',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Create the search bar widget**

Create `lib/features/home/presentation/widgets/search_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JournalSearchBar extends StatelessWidget {
  const JournalSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search a place, dish, or area…',
                hintStyle: GoogleFonts.manrope(
                  fontSize: 14,
                  color: colors.outline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _AiChip(colors: colors),
        ],
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            'AI',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create the suggestion chips widget**

Create `lib/features/home/presentation/widgets/suggestion_chips.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestionChips extends StatelessWidget {
  const SuggestionChips({super.key});

  static const _labels = [
    'Near Kemang',
    'Iced coffee spots',
    'Visited this month',
    'Good for laptop work',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Text(
              _labels[index],
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Create the journal card widget**

Create `lib/features/home/presentation/widgets/journal_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/journal_entry.dart';

class JournalCard extends StatelessWidget {
  const JournalCard({super.key, required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visibleItems = entry.orderItems.take(2).toList();
    final extraCount = entry.orderItems.length - visibleItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: entry.gradientColors,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '1/${entry.photoCount}',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.placeName,
          style: GoogleFonts.fraunces(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final item in visibleItems) _OrderTag(label: item),
            if (extraCount > 0) _OrderTag(label: '+$extraCount'),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.place_outlined, size: 13, color: colors.outline),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                '${entry.neighborhood}, ${entry.city}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: colors.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OrderTag extends StatelessWidget {
  const _OrderTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colors.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
```

- [ ] **Step 5: Verify it analyzes cleanly**

Run: `flutter analyze lib/features/home/presentation/widgets`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/presentation/widgets
git commit -m "feat: extract Home widgets into presentation/widgets"
```

---

### Task 6: Cutover — rewire HomeScreen and main.dart, delete the old tree

**Files:**
- Create: `lib/features/home/presentation/home_screen.dart`
- Modify: `lib/main.dart`
- Delete: `lib/screens/home_screen.dart`, `lib/screens/` (now empty)
- Delete: `lib/viewmodels/home_view_model.dart`, `lib/viewmodels/` (now empty)
- Delete: `lib/models/journal_entry.dart`, `lib/models/` (now empty)
- Delete: `lib/data/mock_entries.dart`, `lib/data/` (now empty)

**Interfaces:**
- Consumes: `journalEntriesProvider`, `searchQueryProvider` from `home_providers.dart`; `Header`, `JournalSearchBar`, `SuggestionChips`, `JournalCard` from `presentation/widgets/`
- Produces: `class HomeScreen extends ConsumerStatefulWidget` — the app's root screen, unchanged public contract (`const HomeScreen()`, no constructor params) so `main.dart` barely changes.

**Teaching note:** Two new Riverpod concepts land here. First, `ConsumerStatefulWidget`/`ConsumerState` — the Riverpod-aware version of `StatefulWidget`/`State` — gives `build()` a `ref` object, which is how a widget reads providers (`ref.watch(...)` to reactively rebuild when a provider's value changes, `ref.read(...)` for one-off reads like calling a notifier method from a callback). We still need `ConsumerState` rather than a plain `ConsumerWidget` because we own a `TextEditingController` that needs `dispose()`. Second, `AsyncValue.when(...)`: `journalEntriesProvider` is a `FutureProvider`, so `ref.watch` on it returns an `AsyncValue`, and `.when` forces you to handle all three states (`loading`, `error`, `data`) before you can get at the actual `List<JournalEntry>` — the compiler won't let you forget the loading/error UI the way plain `mockEntries` let you skip it before.

- [ ] **Step 1: Create the new HomeScreen**

Create `lib/features/home/presentation/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_providers.dart';
import 'widgets/header.dart';
import 'widgets/journal_card.dart';
import 'widgets/search_bar.dart';
import 'widgets/suggestion_chips.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final entriesAsync = ref.watch(journalEntriesProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: entriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text(
              "Couldn't load your places.",
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          data: (entries) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Header(count: entries.length),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: JournalSearchBar(
                    controller: _searchController,
                    onChanged: (value) =>
                        ref.read(searchQueryProvider.notifier).update(value),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 16),
                sliver: const SliverToBoxAdapter(child: SuggestionChips()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => JournalCard(entry: entries[index]),
                    childCount: entries.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update main.dart**

In `lib/main.dart`, change the import and `main()`:

```dart
import 'screens/home_screen.dart';

void main() {
  runApp(const JournallyApp());
}
```

to:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/presentation/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: JournallyApp()));
}
```

`JournallyApp`'s body (the `ColorScheme`s, `MaterialApp`, `home: const HomeScreen()`) is unchanged — only the two lines above move.

**Teaching note:** `ProviderScope` is the widget that actually stores every provider's state. It has to sit above everything that calls `ref.watch`/`ref.read` — in practice, wrapping the whole `runApp(...)` call, once, at the root, is the standard place for it. Forget it and every `ref.watch` call in the app throws at runtime.

- [ ] **Step 3: Delete the old files**

```bash
rm lib/screens/home_screen.dart
rm lib/viewmodels/home_view_model.dart
rm lib/models/journal_entry.dart
rm lib/data/mock_entries.dart
rmdir lib/screens lib/viewmodels lib/models lib/data
```

- [ ] **Step 4: Verify the whole app analyzes cleanly**

Run: `flutter analyze`
Expected: `No issues found!` — this catches any leftover import of the deleted `lib/models`/`lib/data`/`lib/viewmodels`/`lib/screens` paths.

- [ ] **Step 5: Run the app and visually confirm**

Run: `flutter run -d windows`
Expected: builds without error; the window shows the same UI as before (header, search bar with AI chip, suggestion chips, 2-column card grid, FAB) — this pass is a pure architecture change, the UI must look identical. Watch the terminal for a brief loading spinner flash before the grid appears — that's `journalEntriesProvider`'s `loading` state, proof the `AsyncValue` plumbing is live even though the mock data resolves almost instantly.

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/presentation/home_screen.dart lib/main.dart
git add -u lib/screens lib/viewmodels lib/models lib/data
git commit -m "feat: cut HomeScreen over to Riverpod providers and feature-first structure"
```

---

## Final structure check

After Task 6, `lib/` should look like:

```
lib/
  features/
    home/
      domain/
        journal_entry.dart
        journal_repository.dart
      data/
        mock_journal_repository.dart
      presentation/
        home_screen.dart
        home_providers.dart
        home_providers.g.dart
        widgets/
          header.dart
          search_bar.dart
          suggestion_chips.dart
          journal_card.dart
  main.dart
```

No `lib/models/`, `lib/data/`, `lib/viewmodels/`, or `lib/screens/` remain.
