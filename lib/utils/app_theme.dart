import 'package:flutter/material.dart';

/// Single source of truth for all design tokens.
/// Every screen and widget must use these — no hardcoded values.
abstract class AppTheme {
  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color contractor = Color(0xFF1565C0); // blue
  static const Color citizen    = Color(0xFF2E7D32); // green
  static const Color driver     = Color(0xFFE65100); // deep orange
  static const Color bmc        = Color(0xFF1A237E); // deep indigo

  // ── Semantic colours ───────────────────────────────────────────────────────
  static const Color success  = Color(0xFF2E7D32);
  static const Color warning  = Color(0xFFF57F17);
  static const Color error    = Color(0xFFC62828);
  static const Color info     = Color(0xFF1565C0);
  static const Color pending  = Color(0xFF546E7A);

  // ── Neutral palette ────────────────────────────────────────────────────────
  static const Color bg        = Color(0xFFF4F6F9); // page background
  static const Color surface   = Colors.white;       // card / input background
  static const Color divider   = Color(0xFFE0E0E0);
  static const Color textPrimary   = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFFADB5BD);

  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double spXS  = 4;
  static const double spSM  = 8;
  static const double spMD  = 16;
  static const double spLG  = 24;
  static const double spXL  = 32;

  // ── Border radius ──────────────────────────────────────────────────────────
  static const double radiusSM  = 8;
  static const double radiusMD  = 12;
  static const double radiusLG  = 16;
  static const double radiusFull = 100;

  // ── Elevation ──────────────────────────────────────────────────────────────
  static const double elevationCard   = 1;
  static const double elevationModal  = 4;

  // ── Typography ─────────────────────────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
      fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary);
  static const TextStyle heading2 = TextStyle(
      fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary);
  static const TextStyle heading3 = TextStyle(
      fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary);
  static const TextStyle body = TextStyle(
      fontSize: 14, color: textPrimary);
  static const TextStyle bodySmall = TextStyle(
      fontSize: 13, color: textSecondary);
  static const TextStyle caption = TextStyle(
      fontSize: 12, color: textSecondary);
  static const TextStyle label = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600);

  // ── Gap widgets ────────────────────────────────────────────────────────────
  static const SizedBox gapXS = SizedBox(height: spXS);
  static const SizedBox gapSM = SizedBox(height: spSM);
  static const SizedBox gapMD = SizedBox(height: spMD);
  static const SizedBox gapLG = SizedBox(height: spLG);
  static const SizedBox gapXL = SizedBox(height: spXL);

  // ── Reusable decorations ───────────────────────────────────────────────────
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusMD),
    boxShadow: const [
      BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
  );

  static BoxDecoration inputDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusMD),
    border: Border.all(color: divider),
  );

  // ── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: bmc,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: bg,
    cardColor: surface,
    cardTheme: CardThemeData(
      elevation: elevationCard,
      shadowColor: const Color(0x14000000),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD)),
      color: surface,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: spMD, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: const BorderSide(color: bmc, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: const BorderSide(color: error),
      ),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: const BorderSide(color: divider),
        textStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    dividerTheme: const DividerThemeData(
      color: divider, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG)),
      elevation: elevationModal,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM)),
    ),
  );

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns the brand colour for a given role string.
  static Color roleColor(String role) {
    switch (role) {
      case 'contractor': return contractor;
      case 'citizen':    return citizen;
      case 'driver':     return driver;
      case 'bmc':        return bmc;
      default:           return bmc;
    }
  }

  /// Standard page padding
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: spMD, vertical: spMD);
}
