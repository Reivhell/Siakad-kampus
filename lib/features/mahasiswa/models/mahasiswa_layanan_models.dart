/// Model & aturan fitur mahasiswa tambahan (P1/P2).
///
/// Sumber: `fitur_mahasiswa/07_transkrip_dan_progress.md` s.d.
/// `12_layanan_pengajuan.md`. Semua model murni Dart agar mudah diuji tanpa
/// Flutter, mengikuti pola `mahasiswa_models.dart`.
library;

import 'mahasiswa_models.dart';

// ---------------------------------------------------------------------------
// Status pengajuan bersama
// ---------------------------------------------------------------------------

enum StatusPengajuan { pengajuan, disetujui, ditolak, selesai, dibatalkan }

extension StatusPengajuanX on StatusPengajuan {
  String get label => switch (this) {
    StatusPengajuan.pengajuan => 'PENGAJUAN',
    StatusPengajuan.disetujui => 'DISETUJUI',
    StatusPengajuan.ditolak => 'DITOLAK',
    StatusPengajuan.selesai => 'SELESAI',
    StatusPengajuan.dibatalkan => 'DIBATALKAN',
  };

  bool get menunggu => this == StatusPengajuan.pengajuan;
  bool get aktif =>
      this == StatusPengajuan.pengajuan || this == StatusPengajuan.disetujui;
}

// ---------------------------------------------------------------------------
// 07 — Transkrip & progress kurikulum
// ---------------------------------------------------------------------------

class KurikulumMk {
  final String kode;
  final String nama;
  final int sks;
  final int semester;
  final bool wajib;

  const KurikulumMk({
    required this.kode,
    required this.nama,
    required this.sks,
    required this.semester,
    this.wajib = true,
  });
}

enum StatusKurikulum { lulus, berjalan, belum }

extension StatusKurikulumX on StatusKurikulum {
  String get label => switch (this) {
    StatusKurikulum.lulus => 'LULUS',
    StatusKurikulum.berjalan => 'BERJALAN',
    StatusKurikulum.belum => 'BELUM',
  };
}

class KurikulumProgress {
  final KurikulumMk mk;
  final StatusKurikulum status;
  final String? huruf;

  const KurikulumProgress({required this.mk, required this.status, this.huruf});
}

class TranskripPeriode {
  final String periodeId;
  final String namaPeriode;
  final int semester;
  final List<NilaiRecord> rows;
  final double? ips;
  final int sks;

  const TranskripPeriode({
    required this.periodeId,
    required this.namaPeriode,
    required this.semester,
    required this.rows,
    required this.ips,
    required this.sks,
  });
}

// ---------------------------------------------------------------------------
// 08 — Bimbingan / dosen wali
// ---------------------------------------------------------------------------

enum StatusBimbingan { diajukan, disetujui, selesai, ditolak }

extension StatusBimbinganX on StatusBimbingan {
  String get label => switch (this) {
    StatusBimbingan.diajukan => 'MENUNGGU',
    StatusBimbingan.disetujui => 'DISETUJUI',
    StatusBimbingan.selesai => 'SELESAI',
    StatusBimbingan.ditolak => 'DITOLAK',
  };
}

class BimbinganEntry {
  final String id;
  final String npm;
  final String dosen;
  final DateTime tanggal;
  final String topik;
  final String? catatan;
  StatusBimbingan status;

  BimbinganEntry({
    required this.id,
    required this.npm,
    required this.dosen,
    required this.tanggal,
    required this.topik,
    this.catatan,
    this.status = StatusBimbingan.diajukan,
  });
}

// ---------------------------------------------------------------------------
// 10 — Surat akademik
// ---------------------------------------------------------------------------

enum JenisSurat {
  keteranganAktif,
  keteranganLulus,
  pengantarKerja,
  transkrip,
  cuti,
  beasiswa,
}

extension JenisSuratX on JenisSurat {
  String get label => switch (this) {
    JenisSurat.keteranganAktif => 'Surat Keterangan Aktif',
    JenisSurat.keteranganLulus => 'Surat Keterangan Lulus',
    JenisSurat.pengantarKerja => 'Surat Pengantar Kerja',
    JenisSurat.transkrip => 'Transkrip Akademik',
    JenisSurat.cuti => 'Surat Keterangan Cuti',
    JenisSurat.beasiswa => 'Surat Rekomendasi Beasiswa',
  };

  String get kode => switch (this) {
    JenisSurat.keteranganAktif => 'AKTIF',
    JenisSurat.keteranganLulus => 'LULUS',
    JenisSurat.pengantarKerja => 'KERJA',
    JenisSurat.transkrip => 'TRANSKRIP',
    JenisSurat.cuti => 'CUTI',
    JenisSurat.beasiswa => 'BEASISWA',
  };
}

enum StatusSurat { pengajuan, terbit, ditolak, dibatalkan }

extension StatusSuratX on StatusSurat {
  String get label => switch (this) {
    StatusSurat.pengajuan => 'PENGAJUAN',
    StatusSurat.terbit => 'TERBIT',
    StatusSurat.ditolak => 'DITOLAK',
    StatusSurat.dibatalkan => 'DIBATALKAN',
  };

  bool get bisaDibatalkan => this == StatusSurat.pengajuan;
}

class SuratAkademik {
  final String id;
  final String npm;
  final JenisSurat jenis;
  final String keperluan;
  StatusSurat status;
  DateTime diajukan;
  DateTime? terbit;
  String? nomor;
  String? verifikasiToken;

  SuratAkademik({
    required this.id,
    required this.npm,
    required this.jenis,
    required this.keperluan,
    required this.diajukan,
    this.status = StatusSurat.pengajuan,
    this.terbit,
    this.nomor,
    this.verifikasiToken,
  });

  String get verifikasiUrl =>
      'https://siakad.kampus.ac.id/verifikasi/${verifikasiToken ?? '-'}';
}

// ---------------------------------------------------------------------------
// 11 — Yudisium
// ---------------------------------------------------------------------------

class YudisiumPengajuan {
  final String npm;
  final DateTime diajukan;
  StatusPengajuan status;

  YudisiumPengajuan({
    required this.npm,
    required this.diajukan,
    this.status = StatusPengajuan.pengajuan,
  });
}

class YudisiumCek {
  final int sksLulus;
  final int sksTarget;
  final double? ipk;
  final bool adaNilaiE;
  final bool statusAktif;
  final bool adaTanggungan;
  final StatusPengajuan? pengajuan;

  const YudisiumCek({
    required this.sksLulus,
    required this.sksTarget,
    required this.ipk,
    required this.adaNilaiE,
    required this.statusAktif,
    this.adaTanggungan = false,
    this.pengajuan,
  });

  bool get sksCukup => sksLulus >= sksTarget;
  bool get ipkCukup => (ipk ?? 0) >= 2.0;
  bool get tanpaE => !adaNilaiE;
  bool get bebasTanggungan => !adaTanggungan;
  bool get semuaTercapai =>
      sksCukup && ipkCukup && tanpaE && statusAktif && bebasTanggungan;

  bool get bisaAjukan => semuaTercapai && pengajuan == null;
  double get progressSks =>
      sksTarget == 0 ? 0 : (sksLulus / sksTarget).clamp(0, 1).toDouble();

  List<String> get kekurangan {
    final out = <String>[];
    if (!sksCukup) out.add('SKS lulus kurang ${sksTarget - sksLulus}');
    if (!ipkCukup) out.add('IPK minimal 2.00');
    if (!tanpaE) out.add('Masih ada nilai E');
    if (!statusAktif) out.add('Status mahasiswa bukan AKTIF');
    if (!bebasTanggungan) out.add('Masih ada tanggungan keuangan');
    return out;
  }
}

// ---------------------------------------------------------------------------
// 12 — Layanan pengajuan (cuti, banding, konversi)
// ---------------------------------------------------------------------------

class PengajuanCuti {
  final String id;
  final String npm;
  final String periodeId;
  final String alasan;
  final DateTime diajukan;
  StatusPengajuan status;
  String? diputusOleh;
  String? catatan;

  PengajuanCuti({
    required this.id,
    required this.npm,
    required this.periodeId,
    required this.alasan,
    required this.diajukan,
    this.status = StatusPengajuan.pengajuan,
    this.diputusOleh,
    this.catatan,
  });
}

class BandingNilai {
  final String id;
  final String npm;
  final String kodeMk;
  final String namaMk;
  final String alasan;
  final DateTime diajukan;
  StatusPengajuan status;
  String? jawabanDosen;

  BandingNilai({
    required this.id,
    required this.npm,
    required this.kodeMk,
    required this.namaMk,
    required this.alasan,
    required this.diajukan,
    this.status = StatusPengajuan.pengajuan,
    this.jawabanDosen,
  });
}

enum JenisKonversi { pindahan, alihJenjang, mbkm }

extension JenisKonversiX on JenisKonversi {
  String get label => switch (this) {
    JenisKonversi.pindahan => 'Mahasiswa Pindahan',
    JenisKonversi.alihJenjang => 'Alih Jenjang',
    JenisKonversi.mbkm => 'MBKM / Magang Bersertifikat',
  };
}

class PengajuanKonversi {
  final String id;
  final String npm;
  final JenisKonversi jenis;
  final String institusiAsal;
  final int sksDimohonkan;
  final String catatan;
  final DateTime diajukan;
  StatusPengajuan status;
  String? hasilPemetaan;

  PengajuanKonversi({
    required this.id,
    required this.npm,
    required this.jenis,
    required this.institusiAsal,
    required this.sksDimohonkan,
    required this.catatan,
    required this.diajukan,
    this.status = StatusPengajuan.pengajuan,
    this.hasilPemetaan,
  });
}

// ---------------------------------------------------------------------------
// 09 — Kalender akademik
// ---------------------------------------------------------------------------

enum KategoriKalender { krs, uts, uas, yudisium, libur }

extension KategoriKalenderX on KategoriKalender {
  String get label => switch (this) {
    KategoriKalender.krs => 'KRS',
    KategoriKalender.uts => 'UTS',
    KategoriKalender.uas => 'UAS',
    KategoriKalender.yudisium => 'YUDISIUM',
    KategoriKalender.libur => 'LIBUR',
  };
}

class KalenderEvent {
  final String id;
  final String judul;
  final DateTime tanggal;
  final KategoriKalender kategori;
  final String? keterangan;

  const KalenderEvent({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.kategori,
    this.keterangan,
  });

  bool selesaiPada(DateTime now) =>
      tanggal.isBefore(DateTime(now.year, now.month, now.day));

  int sisaHari(DateTime now) {
    final hariIni = DateTime(now.year, now.month, now.day);
    final target = DateTime(tanggal.year, tanggal.month, tanggal.day);
    return target.difference(hariIni).inDays;
  }
}

// ---------------------------------------------------------------------------
// Validasi formulir layanan (murni, bisa diuji)
// ---------------------------------------------------------------------------

String? validasiTopikBimbingan(String topik) {
  final t = topik.trim();
  if (t.length < 8) return 'Topik bimbingan minimal 8 karakter.';
  if (t.length > 160) return 'Topik bimbingan maksimal 160 karakter.';
  return null;
}

String? validasiKeperluanSurat(String keperluan) {
  final k = keperluan.trim();
  if (k.length < 10) return 'Keperluan surat minimal 10 karakter.';
  if (k.length > 300) return 'Keperluan surat maksimal 300 karakter.';
  return null;
}

String? validasiAlasan(String alasan, {int minimal = 15}) {
  final a = alasan.trim();
  if (a.length < minimal) {
    return 'Alasan minimal $minimal karakter agar dapat diproses.';
  }
  if (a.length > 500) return 'Alasan maksimal 500 karakter.';
  return null;
}

String? validasiSksKonversi(int sks) {
  if (sks < 1 || sks > 144) return 'SKS yang dimohonkan harus 1–144.';
  return null;
}
