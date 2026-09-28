import 'package:flutter/material.dart';

import '../widgets/status_badge.dart';

/// Seed dummy realistis — ganti Riverpod+Supabase di Fase 2+.
/// Sumber angka: fitur_admin/01 §3.1–§3.11.
abstract class DashboardSeed {
  static const periode = 'Ganjil 2025/2026';
  static const periodeRange = '1 Sep 2025 – 31 Jan 2026 • 78 hari tersisa';

  static const kpis = [
    _Kpi(
      icon: Icons.calendar_month_outlined,
      label: 'Periode Aktif',
      value: 'Ganjil 25/26',
      sub: 'Minggu ke-8 dari 16 • 50% berjalan',
    ),
    _Kpi(
      icon: Icons.school_outlined,
      label: 'Mahasiswa Aktif',
      value: '1.420',
      sub: 'Baru 312 • Cuti 18 • Lulus 96',
    ),
    _Kpi(
      icon: Icons.co_present_outlined,
      label: 'Dosen Aktif',
      value: '78',
      sub: 'Rasio ideal 1 : 18',
    ),
    _Kpi(
      icon: Icons.meeting_room_outlined,
      label: 'Kelas Dibuka',
      value: '112',
      sub: '108 berdosen • 4 tanpa dosen',
    ),
    _Kpi(
      icon: Icons.how_to_reg_outlined,
      label: 'Partisipasi KRS',
      value: '94,2%',
      sub: '1.338 / 1.420 sudah kunci',
    ),
    _Kpi(
      icon: Icons.emoji_events_outlined,
      label: 'Rata-rata IPK',
      value: '3.24',
      sub: 'Semester lalu • mutu terjaga',
      starGold: true,
    ),
  ];

  static const warnings = [
    _Warn(
      title: '3 kelas kuota penuh (100%)',
      sub: 'IF-3204 • SI-2101 • TI-101',
      tone: BadgeTone.danger,
      action: 'Buka Paralel',
    ),
    _Warn(
      title: '2 kelas kurang peminat (< 5 mhs)',
      sub: 'MK pilihan semester 7',
      tone: BadgeTone.pending,
      action: 'Evaluasi',
    ),
    _Warn(
      title: '4 dosen belum finalisasi nilai UTS',
      sub: 'H-7 deadline 14 Okt 2026',
      tone: BadgeTone.pending,
      action: 'Remind',
    ),
    _Warn(
      title: '12 mhs kehadiran < 75%',
      sub: 'Terancam tidak ikut UAS',
      tone: BadgeTone.danger,
      action: 'Skrining',
    ),
    _Warn(
      title: '4 kelas tanpa ruangan',
      sub: 'id_ruangan IS NULL',
      tone: BadgeTone.info,
      action: 'Alokasi',
    ),
  ];

  static const queue = [
    _Task(
      title: 'Force-add KRS • 261001044 → IF-3204-A',
      sub: 'Wajib prasyarat lulus • kuota habis',
      tone: BadgeTone.pending,
    ),
    _Task(
      title: 'Buka kunci nilai • TI-101 (Dosen H.)',
      sub: 'Berita acara terlampir',
      tone: BadgeTone.info,
    ),
    _Task(
      title: 'Cuti akademik • 261000987',
      sub: 'Berkas + bebas tanggungan OK',
      tone: BadgeTone.neutral,
    ),
    _Task(
      title: 'Reset password • 3 tiket',
      sub: 'Akun terkunci lupa sandi',
      tone: BadgeTone.neutral,
    ),
  ];

  static const liveLog = [
    _Log('10:45', 'Dosen H. memfinalisasi nilai TI-101'),
    _Log('10:30', 'Admin override KRS mhs 261001001'),
    _Log('09:15', 'Mahasiswa Y ajukan cuti semester'),
    _Log('08:50', 'Dosen R. absen kelas SI-2101 P3'),
  ];

  static const prodiBars = [
    _Bar('TI', 0.92),
    _Bar('SI', 0.68),
    _Bar('MI', 0.44),
    _Bar('TK', 0.31),
  ];
}

class _Kpi {
  final IconData icon;
  final String label, value, sub;
  final bool starGold;
  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.starGold = false,
  });
}

class _Warn {
  final String title, sub, action;
  final BadgeTone tone;
  const _Warn({
    required this.title,
    required this.sub,
    required this.tone,
    required this.action,
  });
}

class _Task {
  final String title, sub;
  final BadgeTone tone;
  const _Task({required this.title, required this.sub, required this.tone});
}

class _Log {
  final String time, text;
  const _Log(this.time, this.text);
}

class _Bar {
  final String label;
  final double frac;
  const _Bar(this.label, this.frac);
}
