import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/app/theme/app_colors.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final hi = math.max(_luminance(a), _luminance(b));
  final lo = math.min(_luminance(a), _luminance(b));
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('WCAG AA — Light Mode', () {
    test('teks utama & sekunder di atas kanvas terang', () {
      expect(contrast(AppColors.lightTextPrimary, AppColors.lightBg), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.lightTextSecondary, AppColors.lightSurface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.indigoBlue, AppColors.lightBg), greaterThanOrEqualTo(4.5));
    });

    test('ink badge di atas surface-nya', () {
      expect(contrast(AppColors.passInk, AppColors.passSurface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.alertInk, AppColors.alertSurface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.dangerInk, AppColors.warningSurface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.infoInk, AppColors.infoSurface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.neutralInk, AppColors.lightSurfaceRaised), greaterThanOrEqualTo(4.5));
    });

    test('tombol filled: teks putih di atas fill', () {
      expect(contrast(Colors.white, AppColors.indigoBlue), greaterThanOrEqualTo(4.5));
      expect(contrast(Colors.white, AppColors.destructive), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.lightTextPrimary, AppColors.goldAccent), greaterThanOrEqualTo(4.5));
    });
  });

  group('WCAG AA — Dark Mode (Nocturne Academic)', () {
    test('tiga tingkat teks di atas setiap lapisan', () {
      for (final surface in [AppColors.darkBg, AppColors.darkSurface, AppColors.darkSurfaceElevated]) {
        expect(contrast(AppColors.darkTextPrimary, surface), greaterThanOrEqualTo(4.5),
            reason: 'primary di atas $surface');
        expect(contrast(AppColors.darkTextSecondary, surface), greaterThanOrEqualTo(4.5),
            reason: 'secondary di atas $surface');
        expect(contrast(AppColors.darkTextMuted, surface), greaterThanOrEqualTo(4.5),
            reason: 'muted di atas $surface');
      }
    });

    test('aksen & jewel status sebagai teks', () {
      expect(contrast(AppColors.darkPrimary, AppColors.darkBg), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.darkGold, AppColors.darkSurface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.darkPass, AppColors.darkSurface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.darkAlert, AppColors.darkSurface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.darkDanger, AppColors.darkSurface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.darkInfo, AppColors.darkSurface), greaterThanOrEqualTo(4.5));
    });
  });

  group('Anti-pattern yang didokumentasikan', () {
    test('token fill bukan warna teks di atas terang (design.md §2.2)', () {
      // Kalau test ini GAGAL berarti ada yang memakai fill sebagai teks.
      expect(contrast(AppColors.pass, Colors.white), lessThan(4.5));
      expect(contrast(AppColors.goldAccent, AppColors.lightBg), lessThan(4.5));
    });
  });

  group('StatusBadge dark combos (status_badge.dart)', () {
    test('jewel di atas tint badge dark ≥ 4.5', () {
      expect(
        contrast(
          AppColors.darkPass,
          const Color(0xFF0C2B22),
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(
          AppColors.darkAlert,
          const Color(0xFF33240A),
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(
          AppColors.darkDanger,
          const Color(0xFF3B0F1B),
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(
          AppColors.darkInfo,
          const Color(0xFF0B2636),
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(
          AppColors.darkTextSecondary,
          AppColors.darkSurfaceInteractive,
        ),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}
