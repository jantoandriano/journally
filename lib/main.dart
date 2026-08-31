import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/presentation/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: JournallyApp()));
}

/// Raw design tokens. Widgets never read these directly — they read
/// `Theme.of(context).colorScheme`, which maps onto these constants below.
class AppColors {
  const AppColors._();

  static const background = Color(0xFFF7F5F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF4F1EC);
  static const ink = Color(0xFF23201D);
  static const inkSoft = Color(0xFF756E66);
  static const inkFaint = Color(0xFFA89F95);
  static const line = Color(0xFFE7E2DB);
  static const accent = Color(0xFFB8763F);
  static const accentSoft = Color(0xFFF1E2D0);

  static const backgroundDark = Color(0xFF1C1A17);
  static const surfaceDark = Color(0xFF242220);
  static const surfaceAltDark = Color(0xFF2C2925);
  static const inkDark = Color(0xFFF7F5F2);
  static const inkSoftDark = Color(0xFFB8AFA3);
  static const inkFaintDark = Color(0xFF938A7E);
  static const lineDark = Color(0xFF3A362F);
  static const accentDark = Color(0xFFD79A63);
  static const accentSoftDark = Color(0xFF4A3524);
}

class JournallyApp extends StatelessWidget {
  const JournallyApp({super.key});

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.accent,
    onPrimary: Colors.white,
    primaryContainer: AppColors.accentSoft,
    onPrimaryContainer: AppColors.accent,
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.accentSoft,
    onSecondaryContainer: AppColors.accent,
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    surfaceContainerLow: AppColors.background,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceAlt,
    surfaceContainerHighest: AppColors.surfaceAlt,
    onSurfaceVariant: AppColors.inkSoft,
    outline: AppColors.inkFaint,
    outlineVariant: AppColors.line,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accentDark,
    onPrimary: Color(0xFF3A2A1C),
    primaryContainer: AppColors.accentSoftDark,
    onPrimaryContainer: AppColors.accentDark,
    secondary: AppColors.accentDark,
    onSecondary: Color(0xFF3A2A1C),
    secondaryContainer: AppColors.accentSoftDark,
    onSecondaryContainer: AppColors.accentDark,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.inkDark,
    surfaceContainerLow: AppColors.backgroundDark,
    surfaceContainer: AppColors.surfaceDark,
    surfaceContainerHigh: AppColors.surfaceAltDark,
    surfaceContainerHighest: AppColors.surfaceAltDark,
    onSurfaceVariant: AppColors.inkSoftDark,
    outline: AppColors.inkFaintDark,
    outlineVariant: AppColors.lineDark,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journally',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: _lightScheme, useMaterial3: true),
      darkTheme: ThemeData(colorScheme: _darkScheme, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
