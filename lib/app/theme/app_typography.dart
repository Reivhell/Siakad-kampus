import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Skala tipografi SIAKAD. Spec: `design.md` §3.
///
/// Plus Jakarta Sans untuk semua teks; JetBrains Mono hanya untuk identifier
/// pendek (NIM, kode MK, ruang) — bukan paragraf.
abstract class AppTypography {
  static TextTheme get textTheme {
    final base = ThemeData.light().textTheme;
    return base
        .copyWith(
          displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 38,
            fontWeight: FontWeight.w700,
            height: 46 / 38,
            fontFeatures: _tabular,
          ),
          displaySmall: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 36 / 28,
            fontFeatures: _tabular,
          ),
          headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 32 / 24,
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 28 / 20,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 24 / 16,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 24 / 16,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 20 / 14,
          ),
          labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 20 / 14,
          ),
          labelMedium: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 16 / 12,
          ),
          labelSmall: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 14 / 10,
          ),
        )
        .apply(fontFamily: 'Plus Jakarta Sans');
  }

  /// NIM, kode MK, ruang, angka tabel yang harus sejajar.
  static TextStyle identifier(double size, {FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: 0.5,
      fontFeatures: _tabular,
    );
  }

  /// Angka metrik (IPK, SKS, jumlah mahasiswa) sejajar antar kolom.
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];
}
