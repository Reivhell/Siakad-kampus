import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/app/theme/app_colors.dart';
import 'package:siakad_kampus/app/theme/siakad_theme.dart';

import 'helpers/contrast.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WCAG AA — Light Mode', () {
    test('teks utama & sekunder di atas kanvas terang', () {
      expect(
        contrast(AppColors.lightTextPrimary, AppColors.lightBg),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.lightTextSecondary, AppColors.lightSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.indigoBlue, AppColors.lightBg),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('ink badge di atas surface-nya', () {
      expect(
        contrast(AppColors.passInk, AppColors.passSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.alertInk, AppColors.alertSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.dangerInk, AppColors.warningSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.infoInk, AppColors.infoSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.neutralInk, AppColors.lightSurfaceRaised),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('tombol filled: teks putih di atas fill', () {
      expect(
        contrast(Colors.white, AppColors.indigoBlue),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(Colors.white, AppColors.destructive),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.lightTextPrimary, AppColors.goldAccent),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('WCAG AA — Dark Mode (Nocturne Academic)', () {
    test('tiga tingkat teks di atas setiap lapisan', () {
      for (final surface in [
        AppColors.darkBg,
        AppColors.darkSurface,
        AppColors.darkSurfaceElevated,
      ]) {
        expect(
          contrast(AppColors.darkTextPrimary, surface),
          greaterThanOrEqualTo(4.5),
          reason: 'primary di atas $surface',
        );
        expect(
          contrast(AppColors.darkTextSecondary, surface),
          greaterThanOrEqualTo(4.5),
          reason: 'secondary di atas $surface',
        );
        expect(
          contrast(AppColors.darkTextMuted, surface),
          greaterThanOrEqualTo(4.5),
          reason: 'muted di atas $surface',
        );
      }
    });

    test('aksen & jewel status sebagai teks', () {
      expect(
        contrast(AppColors.darkPrimary, AppColors.darkBg),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.darkGold, AppColors.darkSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.darkPass, AppColors.darkSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.darkAlert, AppColors.darkSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.darkDanger, AppColors.darkSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.darkInfo, AppColors.darkSurface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('ink banner/badge di atas dark semantic surface', () {
      expect(
        contrast(AppColors.darkPass, AppColors.darkPassSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.darkAlert, AppColors.darkAlertSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.darkDanger, AppColors.darkDangerSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.darkInfo, AppColors.darkInfoSurface),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('Tema memetakan warna teks dengan benar', () {
    testWidgets('light mode gelap, dark mode terang', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SiakadTheme.light,
          darkTheme: SiakadTheme.dark,
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: Text('probe')),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        SiakadTheme.light.textTheme.bodyMedium?.color,
        AppColors.lightTextPrimary,
      );
      expect(
        SiakadTheme.light.textTheme.displaySmall?.color,
        AppColors.lightTextPrimary,
      );
      expect(
        SiakadTheme.dark.textTheme.bodyMedium?.color,
        AppColors.darkTextPrimary,
      );
      expect(
        SiakadTheme.dark.textTheme.displaySmall?.color,
        AppColors.darkTextPrimary,
      );
    });

    testWidgets('tidak ada gaya teks tema gelap yang masih hitam', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SiakadTheme.dark,
          home: const Scaffold(body: Text('probe')),
        ),
      );
      await tester.pumpAndSettle();

      final colors = [
        SiakadTheme.dark.textTheme.displayLarge?.color,
        SiakadTheme.dark.textTheme.displaySmall?.color,
        SiakadTheme.dark.textTheme.headlineLarge?.color,
        SiakadTheme.dark.textTheme.headlineMedium?.color,
        SiakadTheme.dark.textTheme.titleMedium?.color,
        SiakadTheme.dark.textTheme.bodyLarge?.color,
        SiakadTheme.dark.textTheme.bodyMedium?.color,
        SiakadTheme.dark.textTheme.labelLarge?.color,
        SiakadTheme.dark.textTheme.labelMedium?.color,
        SiakadTheme.dark.textTheme.labelSmall?.color,
      ];
      for (final color in colors) {
        expect(color, isNotNull);
        expect(contrast(color!, AppColors.darkBg), greaterThanOrEqualTo(4.5));
      }
    });
  });

  group('Anti-pattern yang didokumentasikan', () {
    test('token fill bukan warna teks di atas terang (design.md §2.2)', () {
      // Kalau test ini GAGAL berarti ada yang memakai fill sebagai teks.
      expect(contrast(AppColors.pass, Colors.white), lessThan(4.5));
      expect(contrast(AppColors.goldAccent, AppColors.lightBg), lessThan(4.5));
    });

    test('ink light-only tidak boleh dipakai di kanvas gelap', () {
      // Regresi: `neutralInk`/`dangerInk` di atas permukaan gelap tidak
      // terbaca — pakai `colorScheme.onSurfaceVariant` atau `dark*`.
      expect(
        contrast(AppColors.neutralInk, AppColors.darkSurface),
        lessThan(4.5),
      );
      expect(
        contrast(AppColors.dangerInk, AppColors.darkSurface),
        lessThan(4.5),
      );
    });
  });
}
