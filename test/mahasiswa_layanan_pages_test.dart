import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/app/theme/siakad_theme.dart';
import 'package:siakad_kampus/features/mahasiswa/providers/mahasiswa_providers.dart';
import 'package:siakad_kampus/features/mahasiswa/repositories/mahasiswa_repository.dart';
import 'package:siakad_kampus/features/mahasiswa/seed/mahasiswa_seed.dart';
import 'package:siakad_kampus/mahasiswa/bimbingan/bimbingan_page.dart';
import 'package:siakad_kampus/mahasiswa/dashboard/beranda_page.dart';
import 'package:siakad_kampus/mahasiswa/info/info_akademik_page.dart';
import 'package:siakad_kampus/mahasiswa/pengajuan/pengajuan_page.dart';
import 'package:siakad_kampus/mahasiswa/surat/surat_page.dart';
import 'package:siakad_kampus/mahasiswa/transkrip/transkrip_page.dart';
import 'package:siakad_kampus/mahasiswa/yudisium/yudisium_page.dart';

Widget _wrap(Widget page, {String npm = npmSiti, MahasiswaRepository? repo}) {
  final repository = repo ?? MahasiswaRepository.seed();
  return ProviderScope(
    overrides: [
      mahasiswaRepositoryProvider.overrideWith((ref) => repository),
      currentNpmProvider.overrideWithValue(npm),
    ],
    child: MaterialApp(
      theme: SiakadTheme.light,
      home: Scaffold(body: page),
    ),
  );
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
}

void main() {
  testWidgets('transkrip menampilkan progress kurikulum + watermark', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 2200));
    await tester.pumpWidget(_wrap(const TranskripPage()));
    await tester.pumpAndSettle();

    expect(find.text('Transkrip & Progress'), findsOneWidget);
    expect(find.textContaining('SEMENTARA'), findsOneWidget);
    expect(find.text('Progress per semester'), findsOneWidget);
    expect(find.text('Transkrip nilai'), findsOneWidget);
    expect(find.text('Semester 5'), findsOneWidget);
  });

  testWidgets('bimbingan menampilkan PA dan log konsultasi', (tester) async {
    await _setSurface(tester, const Size(1000, 1800));
    await tester.pumpWidget(_wrap(const BimbinganPage()));
    await tester.pumpAndSettle();

    expect(find.text('Bimbingan & Dosen Wali'), findsOneWidget);
    expect(find.text('Dr. Hendra Wijaya'), findsWidgets);
    expect(find.text('Log konsultasi'), findsOneWidget);
    expect(find.text('Ajukan konsultasi'), findsOneWidget);
  });

  testWidgets('surat menampilkan riwayat + aksi QR surat terbit', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1000, 1600));
    await tester.pumpWidget(_wrap(const SuratPage()));
    await tester.pumpAndSettle();

    expect(find.text('Surat Akademik'), findsOneWidget);
    expect(find.text('Surat Keterangan Aktif'), findsOneWidget);
    expect(find.text('Lihat QR'), findsOneWidget);
    expect(find.text('Batalkan'), findsOneWidget);
  });

  testWidgets('yudisium Siti belum memenuhi syarat', (tester) async {
    await _setSurface(tester, const Size(1000, 2000));
    await tester.pumpWidget(_wrap(const YudisiumPage()));
    await tester.pumpAndSettle();

    expect(find.text('Yudisium'), findsOneWidget);
    expect(find.text('Checklist kelulusan'), findsOneWidget);
    expect(
      find.textContaining('Belum memenuhi syarat yudisium'),
      findsOneWidget,
    );
    final tombol = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Ajukan Yudisium'),
    );
    expect(tombol.onPressed, isNull);
  });

  testWidgets('yudisium Ayu memenuhi syarat dan bisa mengajukan', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1000, 2000));
    await tester.pumpWidget(_wrap(const YudisiumPage(), npm: npmAyu));
    await tester.pumpAndSettle();

    expect(find.text('144 / 144'), findsOneWidget);
    expect(
      find.textContaining('Seluruh syarat kelulusan terpenuhi'),
      findsOneWidget,
    );
    final tombol = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Ajukan Yudisium'),
    );
    expect(tombol.onPressed, isNotNull);
  });

  testWidgets('pengajuan berpindah tab banding nilai', (tester) async {
    await _setSurface(tester, const Size(1000, 1800));
    await tester.pumpWidget(_wrap(const PengajuanPage()));
    await tester.pumpAndSettle();

    expect(find.text('Pengajuan Akademik'), findsOneWidget);
    expect(find.text('Cuti'), findsWidgets);

    await tester.tap(find.text('Banding Nilai'));
    await tester.pumpAndSettle();

    expect(find.text('Banding nilai'), findsOneWidget);
    expect(find.text('TI108 · Algoritma & Pemrograman'), findsOneWidget);
  });

  testWidgets('info akademik menandai semua pengumuman dibaca', (tester) async {
    await _setSurface(tester, const Size(1000, 2000));
    await tester.pumpWidget(_wrap(const InfoAkademikPage()));
    await tester.pumpAndSettle();

    expect(find.text('Info Akademik'), findsOneWidget);
    expect(find.text('Agenda mendatang'), findsOneWidget);
    expect(find.text('Tandai dibaca (2)'), findsOneWidget);

    await tester.tap(find.text('Tandai dibaca (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Tandai dibaca (2)'), findsNothing);
    expect(find.text('Sudah dibaca'), findsWidgets);
  });

  testWidgets('beranda menampilkan pintasan layanan mahasiswa', (tester) async {
    await _setSurface(tester, const Size(1280, 2200));
    await tester.pumpWidget(_wrap(const BerandaPage()));
    await tester.pumpAndSettle();

    expect(find.text('Layanan mahasiswa'), findsOneWidget);
    expect(find.text('Transkrip'), findsOneWidget);
    expect(find.text('Yudisium'), findsOneWidget);
    expect(find.text('Pengajuan'), findsOneWidget);
  });

  group('tanpa overflow di layar kecil', () {
    final pages = <String, Widget Function()>{
      'Transkrip': () => const TranskripPage(),
      'Bimbingan': () => const BimbinganPage(),
      'Surat': () => const SuratPage(),
      'Yudisium': () => const YudisiumPage(),
      'Pengajuan': () => const PengajuanPage(),
      'Info Akademik': () => const InfoAkademikPage(),
      'Beranda': () => const BerandaPage(),
    };

    for (final entry in pages.entries) {
      testWidgets(entry.key, (tester) async {
        await _setSurface(tester, const Size(390, 844));
        await tester.pumpWidget(_wrap(entry.value()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
