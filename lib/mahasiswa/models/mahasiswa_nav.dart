import 'package:flutter/material.dart';

/// Destinasi portal mahasiswa.
///
/// 6 pertama = MVP kanonis (`Mahasiswa.md A12`), lalu modul pendukung
/// (Keuangan/UKT) dan ekstensi P1/P2: transkrip, bimbingan, surat, yudisium,
/// serta layanan pengajuan.
class MahasiswaDestination {
  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;

  const MahasiswaDestination(
    this.label,
    this.path,
    this.icon,
    this.selectedIcon,
  );
}

const mahasiswaDestinations = [
  MahasiswaDestination(
    'Beranda',
    '/mahasiswa',
    Icons.home_outlined,
    Icons.home,
  ),
  MahasiswaDestination(
    'KRS',
    '/mahasiswa/krs',
    Icons.fact_check_outlined,
    Icons.fact_check,
  ),
  MahasiswaDestination(
    'Jadwal',
    '/mahasiswa/jadwal',
    Icons.calendar_month_outlined,
    Icons.calendar_month,
  ),
  MahasiswaDestination(
    'Nilai',
    '/mahasiswa/nilai',
    Icons.grade_outlined,
    Icons.grade,
  ),
  MahasiswaDestination(
    'Presensi',
    '/mahasiswa/presensi',
    Icons.how_to_reg_outlined,
    Icons.how_to_reg,
  ),
  MahasiswaDestination(
    'Transkrip',
    '/mahasiswa/transkrip',
    Icons.workspace_premium_outlined,
    Icons.workspace_premium,
  ),
  MahasiswaDestination(
    'Keuangan',
    '/mahasiswa/keuangan',
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet,
  ),
  MahasiswaDestination(
    'Bimbingan',
    '/mahasiswa/bimbingan',
    Icons.forum_outlined,
    Icons.forum,
  ),
  MahasiswaDestination(
    'Surat',
    '/mahasiswa/surat',
    Icons.description_outlined,
    Icons.description,
  ),
  MahasiswaDestination(
    'Yudisium',
    '/mahasiswa/yudisium',
    Icons.celebration_outlined,
    Icons.celebration,
  ),
  MahasiswaDestination(
    'Pengajuan',
    '/mahasiswa/pengajuan',
    Icons.dynamic_feed_outlined,
    Icons.dynamic_feed,
  ),
  MahasiswaDestination(
    'Info Akademik',
    '/mahasiswa/info',
    Icons.campaign_outlined,
    Icons.campaign,
  ),
  MahasiswaDestination(
    'Profil',
    '/mahasiswa/profil',
    Icons.person_outline,
    Icons.person,
  ),
];

int navIndexForPath(String path) {
  final i = mahasiswaDestinations.indexWhere((d) => d.path == path);
  return i < 0 ? 0 : i;
}
