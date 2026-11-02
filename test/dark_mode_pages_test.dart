import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/krs/admin_krs_page.dart';
import 'package:siakad_kampus/app/theme/app_colors.dart';
import 'package:siakad_kampus/app/theme/siakad_theme.dart';
import 'package:siakad_kampus/features/auth/login_page.dart';
import 'package:siakad_kampus/features/mahasiswa/providers/mahasiswa_providers.dart';
import 'package:siakad_kampus/features/mahasiswa/repositories/mahasiswa_repository.dart';
import 'package:siakad_kampus/features/mahasiswa/seed/mahasiswa_seed.dart';
import 'package:siakad_kampus/mahasiswa/dashboard/beranda_page.dart';
import 'package:siakad_kampus/mahasiswa/info/info_akademik_page.dart';
import 'package:siakad_kampus/mahasiswa/jadwal/jadwal_page.dart';
import 'package:siakad_kampus/mahasiswa/keuangan/keuangan_page.dart';
import 'package:siakad_kampus/mahasiswa/krs/krs_page.dart';
import 'package:siakad_kampus/mahasiswa/nilai/nilai_page.dart';
import 'package:siakad_kampus/mahasiswa/presensi/presensi_page.dart';
import 'package:siakad_kampus/mahasiswa/profil/profil_page.dart';

import 'helpers/contrast.dart';

Widget _wrapDark(
  Widget page, {
  String npm = npmSiti,
  MahasiswaRepository? repo,
}) {
  final repository = repo ?? MahasiswaRepository.seed();
  return ProviderScope(
    overrides: [
      mahasiswaRepositoryProvider.overrideWith((ref) => repository),
      currentNpmProvider.overrideWithValue(npm),
    ],
    child: MaterialApp(
      theme: SiakadTheme.light,
      darkTheme: SiakadTheme.dark,
      themeMode: ThemeMode.dark,
      home: Scaffold(body: page),
    ),
  );
}

/// Semua latar solid/gradien yang berada tepat di belakang sebuah teks.
/// Berhenti di lapisan pertama yang benar-benar menutup (opaque).
List<Color> _backgroundsOf(Element element) {
  final result = <Color>[];
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is Material) {
      final color = widget.color;
      if (color != null && color.a >= 0.99) {
        result.add(color);
        return false;
      }
    } else if (widget is ColoredBox) {
      if (widget.color.a >= 0.99) {
        result.add(widget.color);
        return false;
      }
    } else if (widget is DecoratedBox) {
      final decoration = widget.decoration;
      if (decoration is BoxDecoration) {
        final color = decoration.color;
        if (color != null && color.a >= 0.99) {
          result.add(color);
          return false;
        }
        final gradient = decoration.gradient;
        if (gradient != null) {
          result.addAll(gradient.colors.where((c) => c.a >= 0.99));
          if (result.isNotEmpty) return false;
        }
      }
    }
    return true;
  });
  return result;
}

/// Gagal kalau ada teks yang kontrasnya di bawah ambang WCAG AA terhadap
/// latar tempat ia dirender.
void expectReadableText(WidgetTester tester, {String? page}) {
  final failures = <String>[];
  final finder = find.byType(Text);
  for (final element in finder.evaluate()) {
    final text = element.widget as Text;
    final value = text.data ?? text.textSpan?.toPlainText();
    if (value == null || value.trim().isEmpty) continue;

    final style = DefaultTextStyle.of(element).style.merge(text.style);
    final color = style.color;
    if (color == null || color.a == 0) continue;

    // Kontrol yang dinonaktifkan dikecualikan dari WCAG AA.
    var disabled = false;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is ButtonStyleButton) {
        disabled = !widget.enabled;
        return false;
      }
      return true;
    });
    if (disabled) continue;

    final backgrounds = _backgroundsOf(element);
    if (backgrounds.isEmpty) continue;

    final fontSize = style.fontSize ?? 14;
    final bold =
        (style.fontWeight?.value ?? FontWeight.w400.value) >=
        FontWeight.w600.value;
    final minimum = minimumContrastFor(fontSize: fontSize, bold: bold);

    for (final background in backgrounds) {
      final effective = Color.alphaBlend(color, background);
      final ratio = contrast(effective, background);
      if (ratio < minimum) {
        failures.add(
          '"${value.length > 60 ? '${value.substring(0, 60)}…' : value}" '
          'kontras ${ratio.toStringAsFixed(2)} < ${minimum.toStringAsFixed(1)} '
          '(${fontSize.toStringAsFixed(0)}px) di atas $background',
        );
      }
    }
  }
  expect(
    failures,
    isEmpty,
    reason:
        'Kontras teks gelap gagal${page == null ? '' : ' di $page'}:\n${failures.join('\n')}',
  );
}

Future<void> _pumpAt(
  WidgetTester tester,
  Widget page,
  Size size, {
  String npm = npmSiti,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(_wrapDark(page, npm: npm));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

const _sizes = [Size(390, 844), Size(1440, 900)];

void main() {
  final pages = <String, Widget Function()>{
    'Beranda': () => const BerandaPage(),
    'KRS': () => const KrsPage(),
    'Jadwal': () => const JadwalPage(),
    'Nilai': () => const NilaiPage(),
    'Presensi': () => const PresensiPage(),
    'Profil': () => const ProfilPage(),
    'Keuangan': () => const KeuanganPage(),
    'Info Akademik': () => const InfoAkademikPage(),
    'Login': () => const LoginPage(),
    'Admin KRS': () => const AdminKrsPage(),
  };

  group('Dark mode — semua halaman', () {
    for (final entry in pages.entries) {
      for (final size in _sizes) {
        testWidgets(
          '${entry.key} ${size.width.toInt()}x${size.height.toInt()}: '
          'tanpa overflow & teks terbaca',
          (tester) async {
            await _pumpAt(tester, entry.value(), size);
            expectReadableText(tester, page: entry.key);
          },
        );
      }
    }
  });

  testWidgets('dark mode: gate UKT Reza tetap terbaca', (tester) async {
    await _pumpAt(tester, const KrsPage(), const Size(390, 844), npm: npmReza);
    expect(
      find.textContaining('UKT/SPP periode ini belum lunas'),
      findsOneWidget,
    );
    expectReadableText(tester, page: 'KRS (gate)');
  });

  testWidgets('dark mode: keuangan Reza (tagihan belum lunas) terbaca', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      const KeuanganPage(),
      const Size(390, 844),
      npm: npmReza,
    );
    expect(find.text('KRS TERKUNCI'), findsOneWidget);
    expectReadableText(tester, page: 'Keuangan (belum lunas)');
  });

  testWidgets('dark mode: teks bawaan memakai warna terang, bukan hitam', (
    tester,
  ) async {
    await _pumpAt(tester, const BerandaPage(), const Size(390, 844));
    final element = find.text('Halo, Siti Nurhaliza').evaluate().single;
    final style = DefaultTextStyle.of(element).style;
    expect(style.color, isNotNull);
    expect(contrast(style.color!, AppColors.darkBg), greaterThanOrEqualTo(4.5));
  });
}
