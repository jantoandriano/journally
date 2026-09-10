import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/domain/auth_state.dart';
import 'core/auth/presentation/providers/auth_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/cafes/presentation/providers/cafe_providers.dart';
import 'features/sightings/presentation/providers/sightings_providers.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: JournallyApp()));
}

class JournallyApp extends ConsumerWidget {
  const JournallyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `cafeEntriesProvider` and `sightingsProvider` are kept alive and
    // nothing else invalidates them on an auth transition, so a previous
    // account's cached cafés/sightings would otherwise survive a logout
    // and still be shown after a different account logs in on the same
    // device without restarting the app. Invalidate both whenever the
    // authenticated identity actually changes: entering AuthLoggedIn from
    // something else (covers login, signup, and a successful silent
    // login) and entering AuthLoggedOut from something else (covers
    // logout, so stale data isn't held even while logged out). Deliberately
    // *not* triggered by an AuthLoggedIn -> AuthLoggedIn transition — that
    // happens on every access-token refresh (refreshAccessToken() also
    // sets AuthLoggedIn), and refetching the whole café/sighting list on
    // every token refresh would be wasteful churn unrelated to identity.
    //
    // Registered here — under ProviderScope, above MaterialApp/the screen
    // tree — rather than inside a screen, since this widget (and
    // everything returned by its build) persists for the whole app
    // lifetime, not a single pushed/popped screen's.
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final enteredLoggedIn = next is AuthLoggedIn && previous is! AuthLoggedIn;
      final enteredLoggedOut = next is AuthLoggedOut && previous is! AuthLoggedOut;
      if (enteredLoggedIn || enteredLoggedOut) {
        ref.invalidate(cafeEntriesProvider);
        ref.invalidate(sightingsProvider);
      }
    });

    return MaterialApp(
      title: 'Journally',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
