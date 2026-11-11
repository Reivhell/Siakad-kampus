import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme/siakad_theme.dart';
import '../features/mahasiswa/providers/mahasiswa_providers.dart';
import 'bimbingan/bimbingan_page.dart';
import 'dashboard/beranda_page.dart';
import 'info/info_akademik_page.dart';
import 'jadwal/jadwal_page.dart';
import 'keuangan/keuangan_page.dart';
import 'krs/krs_page.dart';
import 'mahasiswa_shell.dart';
import 'nilai/nilai_page.dart';
import 'pengajuan/pengajuan_page.dart';
import 'presensi/presensi_page.dart';
import 'profil/profil_page.dart';
import 'surat/surat_page.dart';
import 'transkrip/transkrip_page.dart';
import 'yudisium/yudisium_page.dart';

class MahasiswaRouter extends StatefulWidget {
  final String npm;
  final VoidCallback onLogout;

  const MahasiswaRouter({
    super.key,
    required this.npm,
    required this.onLogout,
  });

  @override
  State<MahasiswaRouter> createState() => _MahasiswaRouterState();
}

class _MahasiswaRouterState extends State<MahasiswaRouter> {
  late final GoRouter _router = GoRouter(
    initialLocation: '/mahasiswa',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MahasiswaShell(
          currentPath: state.uri.path,
          child: child,
          onLogout: widget.onLogout,
        ),
        routes: [
          GoRoute(path: '/mahasiswa', builder: (_, _) => const BerandaPage()),
          GoRoute(path: '/mahasiswa/krs', builder: (_, _) => const KrsPage()),
          GoRoute(path: '/mahasiswa/jadwal', builder: (_, _) => const JadwalPage()),
          GoRoute(path: '/mahasiswa/nilai', builder: (_, _) => const NilaiPage()),
          GoRoute(path: '/mahasiswa/presensi', builder: (_, _) => const PresensiPage()),
          GoRoute(path: '/mahasiswa/transkrip', builder: (_, _) => const TranskripPage()),
          GoRoute(path: '/mahasiswa/keuangan', builder: (_, _) => const KeuanganPage()),
          GoRoute(path: '/mahasiswa/bimbingan', builder: (_, _) => const BimbinganPage()),
          GoRoute(path: '/mahasiswa/surat', builder: (_, _) => const SuratPage()),
          GoRoute(path: '/mahasiswa/yudisium', builder: (_, _) => const YudisiumPage()),
          GoRoute(path: '/mahasiswa/pengajuan', builder: (_, _) => const PengajuanPage()),
          GoRoute(path: '/mahasiswa/profil', builder: (_, _) => const ProfilPage()),
          GoRoute(path: '/mahasiswa/info', builder: (_, _) => const InfoAkademikPage()),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      studentIdentifierProvider.overrideWithValue(widget.npm),
    ],
    child: MaterialApp.router(
      title: 'SIAKAD · Mahasiswa',
      theme: SiakadTheme.light,
      darkTheme: SiakadTheme.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    ),
  );
}
