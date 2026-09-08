import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: JournallyApp()));
}

class JournallyApp extends StatelessWidget {
  const JournallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journally',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
