import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// ThemeData terpusat. Spec: `design.md` §9.
abstract class SiakadTheme {
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(999));

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.indigoBlue,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFDCE6FF),
        onPrimaryContainer: AppColors.indigoBlue,
        secondary: AppColors.goldAccent,
        onSecondary: AppColors.lightTextPrimary,
        secondaryContainer: AppColors.lightSurfaceRaised,
        onSecondaryContainer: AppColors.lightTextPrimary,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.destructive,
        onError: Colors.white,
        outline: AppColors.lightBorder,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: AppTypography.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.indigoBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radiusMd,
          side: BorderSide(color: AppColors.lightBorder),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radiusSm,
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusSm,
          borderSide: BorderSide(color: AppColors.indigoBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusSm,
          borderSide: BorderSide(color: AppColors.destructive),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: radiusSm,
          borderSide: BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightBorder, space: 1),
      // Teks tile terpilih = indigo (8.1:1 di atas secondaryContainer).
      // Default M3 (primary) juga lolos di light, eksplisit agar terkunci.
      listTileTheme: const ListTileThemeData(
        selectedColor: AppColors.indigoBlue,
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkBg,
        primaryContainer: AppColors.darkSurfaceInteractive,
        onPrimaryContainer: Color(0xFFDCE6FF),
        secondary: AppColors.darkGold,
        onSecondary: AppColors.darkBg,
        secondaryContainer: AppColors.darkSurfaceInteractive,
        onSecondaryContainer: AppColors.darkTextPrimary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.darkDanger,
        onError: AppColors.darkBg,
        outline: AppColors.darkBorder,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: AppTypography.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radiusMd,
          side: BorderSide(color: AppColors.darkBorder),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radiusSm,
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusSm,
          borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusSm,
          borderSide: BorderSide(color: AppColors.darkDanger),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, space: 1),
      // Teks tile terpilih = starlight (~7:1). Default M3 (primary #4F75FF)
      // hanya 2.6:1 di atas secondaryContainer — gagal AA, dilarang.
      listTileTheme: const ListTileThemeData(
        selectedColor: AppColors.darkTextPrimary,
      ),
    );
  }
}
