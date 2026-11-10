import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flowtop/core/constants/app_constants.dart';

/// A high-contrast, lime-on-graphite design system.
class AppTheme {
  AppTheme._();

  static ThemeData lightTheme() => _build(Brightness.light);
  static ThemeData darkTheme() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF101110) : const Color(0xFFF5F6F0);
    final card = dark ? const Color(0xFF1A1C1A) : Colors.white;
    final onSurface = dark ? const Color(0xFFF5F6F2) : const Color(0xFF171B16);
    final muted = dark ? const Color(0xFFA2A69D) : const Color(0xFF62685F);
    final accent = dark ? AppColors.primary : const Color(0xFF527900);
    final divider = dark ? const Color(0xFF30332E) : const Color(0xFFE2E5DB);
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: accent,
      onPrimary: dark ? const Color(0xFF141A08) : Colors.white,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: muted,
      error: AppColors.error,
    );
    final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme);
    final text = base.textTheme.apply(bodyColor: onSurface, displayColor: onSurface);
    return base.copyWith(
      scaffoldBackgroundColor: surface,
      cardColor: card,
      dividerColor: divider,
      textTheme: text.copyWith(
        bodyMedium: text.bodyMedium?.copyWith(color: muted, height: 1.45),
        bodySmall: text.bodySmall?.copyWith(color: muted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accent, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: accent, foregroundColor: scheme.onPrimary, elevation: 0,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      )),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: accent, foregroundColor: scheme.onPrimary,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: onSurface, side: BorderSide(color: divider),
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: accent)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent, foregroundColor: scheme.onPrimary, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: dark ? const Color(0xFF151615) : Colors.white,
        selectedItemColor: accent, unselectedItemColor: muted, elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
      ),
    );
  }
}
