import 'package:flutter/material.dart';

/// Token warna SIAKAD. Spec + tabel rasio kontras: `design.md` §2.
///
/// Aturan utama: token fill (`pass`, `alert`, `warning`, `info`, `goldAccent`)
/// TIDAK boleh dipakai sebagai warna teks di atas permukaan terang. Untuk teks
/// pada badge, pakai pasangan `*Ink` di bawah — semuanya sudah diuji >= 4.5:1.
abstract class AppColors {
  // Brand
  static const Color indigoBlue = Color(0xFF1E3A8A);
  static const Color indigoLight = Color(0xFF3B82F6);
  static const Color elegantNavy = Color(0xFF172554);
  static const Color snowWhite = Color(0xFFF8FAFC);
  static const Color goldAccent = Color(0xFFFFEE2E);

  // Semantics — fill
  static const Color pass = Color(0xFF3FD478);
  static const Color passSurface = Color(0xFFDCFCE7);
  static const Color alert = Color(0xFFE1E11E);
  static const Color alertSurface = Color(0xFFFEF3C7);
  static const Color warning = Color(0xFFEC1431);
  static const Color warningSurface = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0369A1);
  static const Color infoSurface = Color(0xFFE0F2FE);

  // Semantics — ink (teks di atas surface terang)
  static const Color passInk = Color(0xFF15803D); // 4.57:1 di atas passSurface
  static const Color alertInk = Color(0xFF845A09); // 5.47:1 di atas alertSurface
  static const Color dangerInk = Color(0xFFB91C1C); // 5.30:1 di atas warningSurface
  static const Color infoInk = Color(0xFF0369A1); // 5.17:1 di atas infoSurface
  static const Color neutralInk = Color(0xFF475569); // 6.92:1 di atas slate100

  // Aksi destruktif
  static const Color destructive = Color(0xFFC81E30); // 5.7:1 teks putih

  // Light Neutral
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B); // 4.76:1 di atas putih
  static const Color lightTextDisabled = Color(0xFF94A3B8); // exempt WCAG
  static const Color lightSurfaceRaised = Color(0xFFF1F5F9);

  // Dark Neutral (Nocturne Academic)
  static const Color darkBg = Color(0xFF060A17);
  static const Color darkSurface = Color(0xFF0E172B);
  static const Color darkSurfaceElevated = Color(0xFF16233B);
  static const Color darkSurfaceInteractive = Color(0xFF1E2F50);
  static const Color darkBorder = Color(0xFF1E2E4A);
  static const Color darkTextPrimary = Color(0xFFEDF2F7); // 17.53:1 di atas darkBg
  static const Color darkTextSecondary = Color(0xFF8FA1BC); // 6.80:1 di atas darkSurface
  static const Color darkTextMuted = Color(0xFF7A8CAD); // 5.26:1 di atas darkSurface
  static const Color darkPrimary = Color(0xFF4F75FF);
  static const Color darkGold = Color(0xFFF5CD68); // 11.75:1 di atas darkSurface

  // Dark Semantics
  static const Color darkPass = Color(0xFF32D583);
  static const Color darkAlert = Color(0xFFF7B944);
  static const Color darkDanger = Color(0xFFF43F5E);
  static const Color darkInfo = Color(0xFF38BDF8);
}
