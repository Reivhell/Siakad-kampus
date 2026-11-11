import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/app/theme/siakad_theme.dart';
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

Widget _wrap(
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
  testWidgets('beranda menampilkan KPI, hari ini, dan status KRS', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 2000));
    await tester.pumpWidget(_wrap(const BerandaPage()));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Siti Nurhaliza'), findsOneWidget);
    expect(find.text('IPK'), findsOneWidget);
    expect(find.text('SKS Lulus'), findsOneWidget);
    expect(find.text('IPS Terakhir'), findsOneWidget);
    expect(find.text('Status KRS'), findsOneWidget);
    expect(find.text('AKTIF'), findsWidgets);
    expect(find.textContaining('Presensi kritis'), findsOneWidget);
  });

  testWidgets('KRS mahasiswa lunas: MK terdaftar + katalog', (tester) async {
    await _setSurface(tester, const Size(1280, 2400));
    await tester.pumpWidget(_wrap(const KrsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Kartu Rencana Studi'), findsOneWidget);
    expect(find.text('AKTIF'), findsWidgets);
    expect(find.text('Basis Data'), findsWidgets);
    expect(find.text('Ajukan KRS'), findsNothing);
  });

  testWidgets('KRS mahasiswa belum lunas: gate UKT memblokir', (tester) async {
    await _setSurface(tester, const Size(1280, 2400));
    await tester.pumpWidget(_wrap(const KrsPage(), npm: npmReza));
    await tester.pumpAndSettle();

    expect(find.textContaining('UKT/SPP periode ini belum lunas'), findsOneWidget);
    expect(find.textContaining('Belum ada MK di KRS'), findsOneWidget);
  });

  testWidgets('keuangan: tagihan belum lunas mengunci KRS', (tester) async {
    await _setSurface(tester, const Size(1000, 1400));
    await tester.pumpWidget(_wrap(const KeuanganPage(), npm: npmReza));
    await tester.pumpAndSettle();

    expect(find.text('Tagihan UKT/SPP'), findsOneWidget);
    expect(find.text('KRS TERKUNCI'), findsOneWidget);
    expect(find.text('BELUM'), findsOneWidget);
    expect(find.text('Total tunggakan'), findsOneWidget);
  });

  testWidgets('nilai menampilkan KHS + status draft', (tester) async {
    await _setSurface(tester, const Size(1280, 1600));
    await tester.pumpWidget(_wrap(const NilaiPage()));
    await tester.pumpAndSettle();

    expect(find.text('Kartu Hasil Studi'), findsOneWidget);
    expect(find.text('IPK'), findsOneWidget);
    expect(find.text('Basis Data'), findsOneWidget);
    expect(find.text('DRAFT'), findsWidgets);
  });

  testWidgets('presensi menampilkan persentase dan status kritis', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1000, 2000));
    await tester.pumpWidget(_wrap(const PresensiPage()));
    await tester.pumpAndSettle();

    expect(find.text('Presensi Saya'), findsOneWidget);
    expect(find.text('Jaringan Komputer'), findsOneWidget);
    expect(find.text('Kritis'), findsWidgets);
    expect(find.text('69%'), findsOneWidget);
  });

  testWidgets('jadwal menampilkan kelas dari KRS aktif', (tester) async {
    await _setSurface(tester, const Size(800, 2000));
    await tester.pumpWidget(_wrap(const JadwalPage()));
    await tester.pumpAndSettle();

    expect(find.text('Jadwal Kuliah'), findsOneWidget);
    expect(find.text('Basis Data'), findsOneWidget);
    expect(find.text('Lab-1'), findsWidgets);
  });

  testWidgets('profil menampilkan identitas dan dosen wali', (tester) async {
    await _setSurface(tester, const Size(1000, 1600));
    await tester.pumpWidget(_wrap(const ProfilPage()));
    await tester.pumpAndSettle();

    expect(find.text('Profil Mahasiswa'), findsOneWidget);
    expect(find.text('2410010015'), findsWidgets);
    expect(find.text('Dr. Hendra Wijaya'), findsOneWidget);
  });

  testWidgets('info akademik menampilkan periode aktif + pengumuman', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1000, 1600));
    await tester.pumpWidget(_wrap(const InfoAkademikPage()));
    await tester.pumpAndSettle();

    expect(find.text('Info Akademik'), findsOneWidget);
    expect(find.text('2026/2027 GANJIL'), findsOneWidget);
    expect(find.text('Jendela KRS'), findsOneWidget);
    expect(find.text('PENTING'), findsOneWidget);
  });
}
