import 'package:flutter/material.dart';

/// 8 destinasi portal mahasiswa. 6 pertama = MVP kanonis, Keuangan = fitur
/// UKT/SPP, Info Akademik = periode + pengumuman (`09`).
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
    'Keuangan',
    '/mahasiswa/keuangan',
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet,
  ),
  MahasiswaDestination(
    'Profil',
    '/mahasiswa/profil',
    Icons.person_outline,
    Icons.person,
  ),
  MahasiswaDestination(
    'Info Akademik',
    '/mahasiswa/info',
    Icons.campaign_outlined,
    Icons.campaign,
  ),
];

int navIndexForPath(String path) {
  final i = mahasiswaDestinations.indexWhere((d) => d.path == path);
  return i < 0 ? 0 : i;
}
