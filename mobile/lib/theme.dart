import 'package:flutter/material.dart';

// Brewlog look: warm, dark "espresso" palette with a caramel accent.
class BrewColors {
  static const Color background = Color(0xFF17100B);
  static const Color surface = Color(0xFF1F1610);
  static const Color card = Color(0xFF281D15);
  static const Color cardHigh = Color(0xFF33261C);
  static const Color outline = Color(0xFF4A3A2E);
  static const Color caramel = Color(0xFFE8B87A);
  static const Color copper = Color(0xFFC08552);
  static const Color sage = Color(0xFF8FBF9F);
  static const Color text = Color(0xFFF3E9DD);
  static const Color muted = Color(0xFFB3A08F);

  // Chart series colors (distinguishable on the dark background)
  static const List<Color> series = <Color>[
    caramel, sage, Color(0xFF7FA7D9), Color(0xFFD98FB5), Color(0xFFB59BE0), copper,
  ];
}

ThemeData buildTheme() {
  final ColorScheme scheme = const ColorScheme.dark(
    primary: BrewColors.caramel,
    onPrimary: Color(0xFF2B1D14),
    primaryContainer: Color(0xFF5A3F28),
    onPrimaryContainer: BrewColors.text,
    secondary: BrewColors.copper,
    onSecondary: Color(0xFF2B1D14),
    tertiary: BrewColors.sage,
    surface: BrewColors.surface,
    onSurface: BrewColors.text,
    onSurfaceVariant: BrewColors.muted,
    surfaceContainerLowest: BrewColors.background,
    surfaceContainerLow: BrewColors.surface,
    surfaceContainer: BrewColors.card,
    surfaceContainerHigh: BrewColors.cardHigh,
    surfaceContainerHighest: Color(0xFF3D2E22),
    outline: BrewColors.outline,
    outlineVariant: Color(0xFF3A2C22),
    error: Color(0xFFE77B6E),
  );

  final ThemeData base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final TextTheme text = base.textTheme.apply(bodyColor: BrewColors.text, displayColor: BrewColors.text);

  return base.copyWith(
    scaffoldBackgroundColor: BrewColors.background,
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: text.labelSmall?.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: BrewColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: BrewColors.text),
    ),
    cardTheme: CardThemeData(
      color: BrewColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: BrewColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: BrewColors.caramel.withValues(alpha: 0.18),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> s) => TextStyle(
            fontSize: 11.5,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? BrewColors.caramel : BrewColors.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? BrewColors.caramel : BrewColors.muted,
          )),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BrewColors.cardHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BrewColors.caramel, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: BrewColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: BrewColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: BrewColors.cardHigh,
      selectedColor: BrewColors.caramel.withValues(alpha: 0.22),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(color: BrewColors.text, fontWeight: FontWeight.w500),
      checkmarkColor: BrewColors.caramel,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: BrewColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF33261C), space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    listTileTheme: const ListTileThemeData(iconColor: BrewColors.muted),
  );
}
