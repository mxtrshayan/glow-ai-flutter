import 'package:flutter/material.dart';

const bg = Color(0xFFFDF6F9),
    ink = Color(0xFF2D1B26),
    muted = Color(0xFF735561);
const primary = Color(0xFF9D3F60),
    soft = Color(0xFFF9EEF2),
    border = Color(0xFFEDD5E0),
    plum = Color(0xFF462535);

bool isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;
Color surfaceOf(BuildContext context) => Theme.of(context).colorScheme.surface;
Color inkOf(BuildContext context) => Theme.of(context).colorScheme.onSurface;
Color mutedOf(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant;
Color accentOf(BuildContext context) => Theme.of(context).colorScheme.primary;
Color borderOf(BuildContext context) =>
    Theme.of(context).colorScheme.outlineVariant;

ThemeData glowTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
        primary: dark ? const Color(0xFFF0AAC3) : primary,
        onPrimary: dark ? const Color(0xFF481A2D) : Colors.white,
        surface: dark ? const Color(0xFF291F26) : Colors.white,
        onSurface: dark ? const Color(0xFFF8EAF0) : ink,
        onSurfaceVariant: dark ? const Color(0xFFD1B9C4) : muted,
        outlineVariant: dark ? const Color(0xFF59434F) : border,
      );
  final background = dark ? const Color(0xFF1B151A) : bg;
  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: dark ? const Color(0xFF573244) : const Color(0xFFF5DDE7),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, color: scheme.onSurface),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      showDragHandle: true,
    ),
    dividerColor: scheme.outlineVariant,
  );
}

Widget title(String s, {double size = 32, Color? color}) => Builder(
  builder: (context) => Text(
    s,
    style: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color ?? inkOf(context),
      height: 1.25,
    ),
  ),
);
Widget copy(String s, {double size = 14, Color? color}) => Builder(
  builder: (context) => Text(
    s,
    style: TextStyle(
      fontFamily: 'Poppins',
      fontSize: size,
      color: color ?? mutedOf(context),
      height: 1.6,
    ),
  ),
);
Widget eyebrow(String s) => Builder(
  builder: (context) => Text(
    s.toUpperCase(),
    style: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 10,
      letterSpacing: 2.2,
      color: accentOf(context),
      fontWeight: FontWeight.w600,
    ),
  ),
);
