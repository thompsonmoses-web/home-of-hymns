import 'package:flutter/material.dart';

/// Palette lifted from styles.css :root and body.night
class HoH {
  static const accent = Color(0xFFF0BD26);
  static const accent2 = Color(0xFFD9A014);
  static const accentTextLight = Color(0xFF8A5F00);
  static const accentTextNight = Color(0xFFFFD24A);
  static const accentBlue = Color(0xFF0F4FB0);
  static const danger = Color(0xFFC23434);
  static const serif = 'Georgia';
}

class Pal {
  final bool night;
  final Color bg;
  final Color panel;
  final Color panel2;
  final Color text;
  final Color textSoft;
  final Color accent;
  final Color accentText;
  final Color border;
  final Color hover;

  Pal({
    required this.night,
    required this.bg,
    required this.panel,
    required this.panel2,
    required this.text,
    required this.textSoft,
    required this.accent,
    required this.accentText,
    required this.border,
    required this.hover,
  });

  factory Pal.light() => Pal(
        night: false,
        bg: const Color(0xFFF7F4EC),
        panel: const Color(0xFFFFFDF7),
        panel2: const Color(0xFFF1ECDD),
        text: const Color(0xFF211D13),
        textSoft: const Color(0xFF67614F),
        accent: HoH.accent,
        accentText: HoH.accentTextLight,
        border: const Color(0xFFE4DECE),
        hover: const Color(0xFFEEE8D8),
      );

  factory Pal.night() => Pal(
        night: true,
        bg: const Color(0xFF0D0D0A),
        panel: const Color(0xFF15150F),
        panel2: const Color(0xFF1D1D16),
        text: const Color(0xFFEAE9E0),
        textSoft: const Color(0xFF9A998F),
        accent: HoH.accent,
        accentText: HoH.accentTextNight,
        border: const Color(0xFF2C2C22),
        hover: const Color(0xFF23231A),
      );
}

ThemeData buildTheme(Pal p) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: p.night ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: HoH.accent,
      brightness: p.night ? Brightness.dark : Brightness.light,
      primary: HoH.accent,
      surface: p.panel,
    ),
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: p.panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: p.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.panel2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: p.textSoft),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.night ? const Color(0xFF33331F) : const Color(0xFF2A2517),
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    dividerTheme: DividerThemeData(color: p.border, space: 1, thickness: 1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: HoH.accent,
      selectionColor: HoH.accent.withValues(alpha: 0.35),
      selectionHandleColor: HoH.accent,
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}
