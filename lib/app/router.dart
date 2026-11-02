import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../admin/admin_shell.dart';
import '../features/auth/auth_providers.dart';
import '../features/auth/login_page.dart';
import '../mahasiswa/dashboard/beranda_page.dart';
import '../mahasiswa/info/info_akademik_page.dart';
import '../mahasiswa/jadwal/jadwal_page.dart';
import '../mahasiswa/keuangan/keuangan_page.dart';
import '../mahasiswa/krs/krs_page.dart';
import '../mahasiswa/mahasiswa_shell.dart';
import '../mahasiswa/nilai/nilai_page.dart';
import '../mahasiswa/presensi/presensi_page.dart';
import '../mahasiswa/profil/profil_page.dart';

/// Route kanonis `Mahasiswa.md §4` + `/mahasiswa/keuangan` (fitur UKT/SPP).
/// Guard di sini hanya navigasi; otorisasi final nanti di RLS Supabase.
final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.read(authSessionProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: session,
    redirect: (context, state) {
      final account = session.account;
      final loc = state.matchedLocation;
      final atLogin = loc == '/login';

      if (account == null) return atLogin ? null : '/login';
      if (atLogin) return account.isAdmin ? '/admin' : '/mahasiswa';
      if (account.isAdmin && loc.startsWith('/mahasiswa')) return '/admin';
      if (!account.isAdmin && loc.startsWith('/admin')) return '/mahasiswa';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/admin', builder: (_, _) => const AdminShell()),
      ShellRoute(
        builder: (context, state, child) => MahasiswaShell(
          currentPath: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(path: '/mahasiswa', builder: (_, _) => const BerandaPage()),
          GoRoute(path: '/mahasiswa/krs', builder: (_, _) => const KrsPage()),
          GoRoute(
            path: '/mahasiswa/jadwal',
            builder: (_, _) => const JadwalPage(),
          ),
          GoRoute(
            path: '/mahasiswa/nilai',
            builder: (_, _) => const NilaiPage(),
          ),
          GoRoute(
            path: '/mahasiswa/presensi',
            builder: (_, _) => const PresensiPage(),
          ),
          GoRoute(
            path: '/mahasiswa/keuangan',
            builder: (_, _) => const KeuanganPage(),
          ),
          GoRoute(
            path: '/mahasiswa/profil',
            builder: (_, _) => const ProfilPage(),
          ),
          GoRoute(
            path: '/mahasiswa/info',
            builder: (_, _) => const InfoAkademikPage(),
          ),
        ],
      ),
    ],
  );
});
