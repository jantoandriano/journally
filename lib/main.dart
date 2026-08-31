import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/presentation/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: JournallyApp()));
}

class JournallyApp extends StatelessWidget {
  const JournallyApp({super.key});

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFB8763F),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFF1E2D0),
    onPrimaryContainer: Color(0xFFB8763F),
    secondary: Color(0xFFB8763F),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFF1E2D0),
    onSecondaryContainer: Color(0xFFB8763F),
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    surface: Color(0xFFF7F5F2),
    onSurface: Color(0xFF23201D),
    surfaceContainer: Colors.white,
    surfaceContainerHigh: Color(0xFFF4F1EC),
    surfaceContainerHighest: Color(0xFFF4F1EC),
    onSurfaceVariant: Color(0xFF756E66),
    outline: Color(0xFFA89F95),
    outlineVariant: Color(0xFFE7E2DB),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFD79A63),
    onPrimary: Color(0xFF3A2A1C),
    primaryContainer: Color(0xFF4A3524),
    onPrimaryContainer: Color(0xFFD79A63),
    secondary: Color(0xFFD79A63),
    onSecondary: Color(0xFF3A2A1C),
    secondaryContainer: Color(0xFF4A3524),
    onSecondaryContainer: Color(0xFFD79A63),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF1C1A17),
    onSurface: Color(0xFFF7F5F2),
    surfaceContainer: Color(0xFF242220),
    surfaceContainerHigh: Color(0xFF2C2925),
    surfaceContainerHighest: Color(0xFF2C2925),
    onSurfaceVariant: Color(0xFFB8AFA3),
    outline: Color(0xFF938A7E),
    outlineVariant: Color(0xFF3A362F),
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
