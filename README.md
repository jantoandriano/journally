# journally

A new Flutter project.

## Project structure

Code is organized by feature under `lib/features/<feature>/`, each with
`presentation/`, `domain/`, and `data/` subfolders. A screen gets its own
feature folder when it owns a distinct flow and its own local state (e.g.
`add_journal`, a write flow). A screen that's a drill-down of another
feature's data — `entry_detail_screen.dart`, which reads `home`'s
`journalEntryProvider` and `JournalEntry` model — stays inside that
feature (`home/presentation/`) instead of getting its own folder, to
avoid importing providers/domain models across feature boundaries.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
