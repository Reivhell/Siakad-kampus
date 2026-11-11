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

  // Semantics — border (garis badge pill, bukan teks)
  static const Color passBorder = Color(0xFFBBF7D0);
  static const Color alertBorder = Color(0xFFFDE68A);
  static const Color dangerBorder = Color(0xFFFECACA);
  static const Color infoBorder = Color(0xFFBAE6FD);

  // Prestige gold — HANYA pencapaian (cumlaude/star). Bukan status/info.
  static const Color goldSurface = Color(0xFFFFF9C4);
  static const Color goldBorder = Color(0xFFFDE68A);
  static const Color goldIcon = Color(0xFFA16207); // 4.91:1 di atas goldSurface
  static const Color goldInk = Color(0xFF854D0E); // 6.83:1 di atas goldSurface

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
  static const Color darkPass = Color(0xFF32D583); // 7.93:1 di atas successSurface
  static const Color darkAlert = Color(0xFFF7B944); // 8.57:1 di atas warningSurface
  static const Color darkDanger = Color(0xFFF43F5E); // 4.50:1 di atas dangerSurface
  static const Color darkInfo = Color(0xFF38BDF8); // 7.29:1 di atas infoSurface

  // Dark badge surfaces — pasangan jewel di atas, border hairline.
  static const Color darkSuccessSurface = Color(0xFF0C2B22);
  static const Color darkSuccessBorder = Color(0xFF14532D);
  static const Color darkWarningSurface = Color(0xFF33240A);
  static const Color darkWarningBorder = Color(0xFF92400E);
  static const Color darkDangerSurface = Color(0xFF3B0F1B);
  static const Color darkDangerBorder = Color(0xFF9F1239);
  static const Color darkInfoSurface = Color(0xFF0B2636);
  static const Color darkInfoBorder = Color(0xFF0C4A6E);

  // Bezel gradients + shadow — elevasi bespoke, bukan gray slop.
  static const Color darkBezelTop = Color(0xFF12203A);
  static const Color bezelShadow = Color(0x0A0F172A);

  // Theme roles — primary container + disabled.
  static const Color primaryContainer = Color(0xFFDCE6FF); // 8.29:1 ink indigo
  static const Color disabledBorder = Color(0xFFCBD5E1);
}
