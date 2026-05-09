import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Base dark palette ─────────────────────────────────────────────────────
  static const Color bg          = Color(0xFF0F172A); // slate-900
  static const Color surface     = Color(0xFF1E293B); // slate-800
  static const Color surfaceHigh = Color(0xFF273549); // card elevated
  static const Color border      = Color(0x1FFFFFFF); // white 12%
  static const Color onSurface   = Color(0xFFF1F5F9); // slate-100
  static const Color muted       = Color(0xFF94A3B8); // slate-400
  static const Color primary     = Color(0xFF818CF8); // indigo-400
  static const Color primaryLight= Color(0x1A818CF8); // indigo 10%
  static const Color accent      = Color(0xFF34D399); // emerald

  // ── Per-theme accent colors (cards, icons) ────────────────────────────────
  static const Color themeQuotidien = Color(0xFFF59E0B); // amber
  static const Color themeSport     = Color(0xFF22C55E); // green
  static const Color themeVoyage    = Color(0xFF38BDF8); // sky
  static const Color themeTravail   = Color(0xFFA78BFA); // violet
  static const Color themeCulture   = Color(0xFFF472B6); // pink
  static const Color themeTech      = Color(0xFF2DD4BF); // teal
  static const Color themeSante     = Color(0xFFF87171); // red
  static const Color themeSocial    = Color(0xFFFB923C); // orange

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get shadowMd => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
  ];

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: accent,
        surface: surface,
        onSurface: onSurface,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.sora(
          color: onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: onSurface),
      ),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.sora(
          fontSize: 32, fontWeight: FontWeight.w800,
          color: onSurface, letterSpacing: -0.8,
        ),
        headlineLarge: GoogleFonts.sora(
          fontSize: 26, fontWeight: FontWeight.w700,
          color: onSurface, letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.sora(
          fontSize: 22, fontWeight: FontWeight.w700,
          color: onSurface, letterSpacing: -0.4,
        ),
        titleLarge: GoogleFonts.sora(
          fontSize: 17, fontWeight: FontWeight.w700,
          color: onSurface, letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.sora(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w400,
          color: onSurface, height: 1.55,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: muted, height: 1.55,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: muted, height: 1.5,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: onSurface, letterSpacing: 0.1,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryLight,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? primary : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(color: active ? primary : muted, size: 22);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.sora(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(color: border, space: 1),
      cardTheme: CardTheme(
        color: surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.sora(
          fontSize: 17, fontWeight: FontWeight.w700, color: onSurface,
        ),
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 14, color: muted, height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: GoogleFonts.dmSans(color: onSurface, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  // Backward-compat alias used in main.dart and screens
  static ThemeData get light => dark;
}
