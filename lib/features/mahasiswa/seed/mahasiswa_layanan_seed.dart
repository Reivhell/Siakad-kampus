/// Seed data fitur mahasiswa lanjutan (P1/P2).
///
/// Dipisah dari `mahasiswa_seed.dart` agar modul kanonis tetap ringkas.
/// Data in-memory ini menggantikan tabel Supabase pada MVP frontend.
library;

import '../../../app/formatters.dart';
import '../models/mahasiswa_layanan_models.dart';
import '../models/mahasiswa_models.dart';
import 'mahasiswa_seed.dart';

// ---------------------------------------------------------------------------
// 07 — Kurikulum S1 Teknik Informatika (total 144 SKS / 8 semester)
// ---------------------------------------------------------------------------

const List<KurikulumMk> kurikulumTi = [
  // Semester 1 — 16 SKS
  KurikulumMk(
    kode: 'TI101',
    nama: 'Pengantar Teknologi Informasi',
    sks: 3,
    semester: 1,
  ),
  KurikulumMk(kode: 'TI102', nama: 'Kalkulus', sks: 3, semester: 1),
  KurikulumMk(kode: 'TI103', nama: 'Pemrograman Dasar', sks: 3, semester: 1),
  KurikulumMk(kode: 'TI104', nama: 'Logika Digital', sks: 3, semester: 1),
  KurikulumMk(kode: 'MKU101', nama: 'Pancasila', sks: 2, semester: 1),
  KurikulumMk(kode: 'MKU103', nama: 'Pendidikan Agama', sks: 2, semester: 1),
  // Semester 2 — 22 SKS
  KurikulumMk(kode: 'TI105', nama: 'Struktur Data', sks: 3, semester: 2),
  KurikulumMk(kode: 'TI106', nama: 'Basis Data I', sks: 3, semester: 2),
  KurikulumMk(kode: 'TI107', nama: 'Jaringan Dasar', sks: 3, semester: 2),
  KurikulumMk(
    kode: 'TI108',
    nama: 'Algoritma & Pemrograman',
    sks: 3,
    semester: 2,
  ),
  KurikulumMk(kode: 'TI109', nama: 'Matematika Diskrit', sks: 3, semester: 2),
  KurikulumMk(kode: 'TI110', nama: 'Sistem Digital', sks: 3, semester: 2),
  KurikulumMk(kode: 'MKU102', nama: 'Bahasa Indonesia', sks: 2, semester: 2),
  KurikulumMk(kode: 'MKU104', nama: 'Kewarganegaraan', sks: 2, semester: 2),
  // Semester 3 — 15 SKS
  KurikulumMk(kode: 'TI201', nama: 'Pemrograman Lanjut', sks: 3, semester: 3),
  KurikulumMk(kode: 'TI202', nama: 'Sistem Operasi', sks: 3, semester: 3),
  KurikulumMk(
    kode: 'TI203',
    nama: 'Rekayasa Perangkat Lunak',
    sks: 3,
    semester: 3,
  ),
  KurikulumMk(kode: 'TI204', nama: 'Statistika', sks: 3, semester: 3),
  KurikulumMk(kode: 'TI205', nama: 'Pemrograman Web', sks: 3, semester: 3),
  // Semester 4 — 21 SKS
  KurikulumMk(kode: 'TI206', nama: 'Kecerdasan Buatan', sks: 3, semester: 4),
  KurikulumMk(kode: 'TI207', nama: 'Keamanan Informasi', sks: 3, semester: 4),
  KurikulumMk(kode: 'TI208', nama: 'Basis Data Lanjut', sks: 3, semester: 4),
  KurikulumMk(
    kode: 'TI209',
    nama: 'Proyek Perangkat Lunak',
    sks: 3,
    semester: 4,
  ),
  KurikulumMk(kode: 'TI210', nama: 'Technopreneurship', sks: 3, semester: 4),
  KurikulumMk(
    kode: 'TI211',
    nama: 'Pemrograman Berorientasi Objek',
    sks: 3,
    semester: 4,
  ),
  KurikulumMk(
    kode: 'TI212',
    nama: 'Basis Data Terdistribusi',
    sks: 3,
    semester: 4,
  ),
  // Semester 5 — 18 SKS
  KurikulumMk(kode: 'TI301', nama: 'Basis Data', sks: 3, semester: 5),
  KurikulumMk(kode: 'TI302', nama: 'Jaringan Komputer', sks: 3, semester: 5),
  KurikulumMk(
    kode: 'TI303',
    nama: 'Rekayasa Perangkat Lunak Lanjut',
    sks: 3,
    semester: 5,
  ),
  KurikulumMk(
    kode: 'TI304',
    nama: 'Sistem Operasi Lanjut',
    sks: 3,
    semester: 5,
  ),
  KurikulumMk(
    kode: 'TI305',
    nama: 'Pemrograman Web Lanjut',
    sks: 3,
    semester: 5,
  ),
  KurikulumMk(
    kode: 'TI306',
    nama: 'Kecerdasan Buatan Lanjut',
    sks: 3,
    semester: 5,
  ),
  // Semester 6 — 21 SKS
  KurikulumMk(kode: 'TI311', nama: 'Pemrograman Mobile', sks: 3, semester: 6),
  KurikulumMk(kode: 'TI312', nama: 'Cloud Computing', sks: 3, semester: 6),
  KurikulumMk(kode: 'TI313', nama: 'Analitik Data', sks: 3, semester: 6),
  KurikulumMk(
    kode: 'TI314',
    nama: 'Interaksi Manusia Komputer',
    sks: 3,
    semester: 6,
  ),
  KurikulumMk(kode: 'TI315', nama: 'Manajemen Proyek TI', sks: 3, semester: 6),
  KurikulumMk(kode: 'TI316', nama: 'Machine Learning', sks: 3, semester: 6),
  KurikulumMk(kode: 'TI317', nama: 'DevOps & CI/CD', sks: 3, semester: 6),
  // Semester 7 — 20 SKS
  KurikulumMk(kode: 'TI401', nama: 'Magang Industri', sks: 6, semester: 7),
  KurikulumMk(kode: 'TI402', nama: 'Capstone Project I', sks: 3, semester: 7),
  KurikulumMk(kode: 'TI403', nama: 'Etika Profesi', sks: 2, semester: 7),
  KurikulumMk(
    kode: 'TI404',
    nama: 'Kewirausahaan Digital',
    sks: 3,
    semester: 7,
  ),
  KurikulumMk(kode: 'TI405', nama: 'Topik Khusus', sks: 3, semester: 7),
  KurikulumMk(kode: 'TI409', nama: 'Kuliah Kerja Nyata', sks: 3, semester: 7),
  // Semester 8 — 11 SKS
  KurikulumMk(kode: 'TI406', nama: 'Capstone Project II', sks: 3, semester: 8),
  KurikulumMk(kode: 'TI407', nama: 'Skripsi', sks: 6, semester: 8),
  KurikulumMk(kode: 'TI408', nama: 'Ujian Komprehensif', sks: 2, semester: 8),
];

List<KurikulumMk> seedKurikulum() => List.of(kurikulumTi);

// ---------------------------------------------------------------------------
// Nilai lengkap Ayu (demo kelulusan/yudisium) — 144 SKS tanpa nilai E
// ---------------------------------------------------------------------------

String _periodeUntukSemester(int semester) {
  final ganjil = semester.isOdd;
  if (semester <= 2) {
    return ganjil ? '2022-2023-GANJIL' : '2022-2023-GENAP';
  }
  if (semester <= 4) {
    return ganjil ? '2023-2024-GANJIL' : '2023-2024-GENAP';
  }
  if (semester <= 6) {
    return ganjil ? '2024-2025-GANJIL' : '2024-2025-GENAP';
  }
  return ganjil ? '2025-2026-GANJIL' : '2025-2026-GENAP';
}

const _polaHuruf = ['A', 'AB', 'A', 'B', 'AB', 'A', 'B', 'AB'];

List<NilaiRecord> seedNilaiAyu() {
  final out = <NilaiRecord>[];
  for (final mk in kurikulumTi) {
    final huruf = _polaHuruf[mk.semester % _polaHuruf.length];
    final periode = _periodeUntukSemester(mk.semester);
    final tanggal = switch (periode) {
      '2022-2023-GANJIL' => DateTime(2023, 1, 20),
      '2022-2023-GENAP' => DateTime(2023, 6, 23),
      '2023-2024-GANJIL' => DateTime(2024, 1, 19),
      '2023-2024-GENAP' => DateTime(2024, 6, 21),
      '2024-2025-GANJIL' => DateTime(2025, 1, 24),
      _ => DateTime(2025, 6, 27),
    };
    out.add(
      NilaiRecord(
        npm: npmAyu,
        periodeId: periode,
        kodeMk: mk.kode,
        namaMk: mk.nama,
        sks: mk.sks,
        uts: 85,
        uas: 88,
        tugas: 90,
        akhir: 87,
        huruf: huruf,
        sudahFinal: true,
        disubmitPada: formatTanggal(tanggal),
      ),
    );
  }
  return out;
}

// ---------------------------------------------------------------------------
// 08 — Bimbingan / dosen wali
// ---------------------------------------------------------------------------

List<BimbinganEntry> seedBimbingan() => [
  BimbinganEntry(
    id: 'BIM-SITI-01',
    npm: npmSiti,
    dosen: 'Dr. Hendra Wijaya',
    tanggal: DateTime(2026, 9, 4),
    topik: 'Konsultasi rencana KRS semester 5',
    catatan: 'Disetujui. Disarankan menambah 1 MK pilihan agar 21 SKS.',
    status: StatusBimbingan.selesai,
  ),
  BimbinganEntry(
    id: 'BIM-SITI-02',
    npm: npmSiti,
    dosen: 'Dr. Hendra Wijaya',
    tanggal: DateTime(2026, 10, 2),
    topik: 'Diskusi kesulitan Jaringan Komputer',
    catatan: 'Akan dibahas pada sesi konsultasi Jumat pekan ini.',
    status: StatusBimbingan.disetujui,
  ),
  BimbinganEntry(
    id: 'BIM-SITI-03',
    npm: npmSiti,
    dosen: 'Dr. Hendra Wijaya',
    tanggal: DateTime(2026, 11, 5),
    topik: 'Rencana magang industri semester 7',
    status: StatusBimbingan.diajukan,
  ),
  BimbinganEntry(
    id: 'BIM-REZA-01',
    npm: npmReza,
    dosen: 'Dr. Hendra Wijaya',
    tanggal: DateTime(2026, 9, 18),
    topik: 'Konsultasi kendala UKT dan rencana KRS',
    catatan: 'Ajukan dispensasi ke admin akademik dengan bukti pendukung.',
    status: StatusBimbingan.selesai,
  ),
  BimbinganEntry(
    id: 'BIM-AYU-01',
    npm: npmAyu,
    dosen: 'Dr. Hendra Wijaya',
    tanggal: DateTime(2026, 10, 28),
    topik: 'Persiapan yudisium dan verifikasi 144 SKS',
    catatan: 'Berkas yudisium lengkap, silakan ajukan melalui portal.',
    status: StatusBimbingan.selesai,
  ),
];

// ---------------------------------------------------------------------------
// 10 — Surat akademik
// ---------------------------------------------------------------------------

List<SuratAkademik> seedSurat() => [
  SuratAkademik(
    id: 'SRT-SITI-01',
    npm: npmSiti,
    jenis: JenisSurat.keteranganAktif,
    keperluan: 'Persyaratan pengajuan beasiswa Peningkatan Prestasi Akademik.',
    diajukan: DateTime(2026, 10, 20),
    status: StatusSurat.terbit,
    terbit: DateTime(2026, 10, 22),
    nomor: '421/SIAKAD/XI/2026',
    verifikasiToken: 'SITI-AKTIF-2026',
  ),
  SuratAkademik(
    id: 'SRT-SITI-02',
    npm: npmSiti,
    jenis: JenisSurat.pengantarKerja,
    keperluan: 'Surat pengantar magang di PT Nusantara Digital.',
    diajukan: DateTime(2026, 11, 5),
    status: StatusSurat.pengajuan,
  ),
  SuratAkademik(
    id: 'SRT-AYU-01',
    npm: npmAyu,
    jenis: JenisSurat.keteranganLulus,
    keperluan: 'Persyaratan melamar kerja setelah yudisium.',
    diajukan: DateTime(2026, 11, 1),
    status: StatusSurat.terbit,
    terbit: DateTime(2026, 11, 3),
    nomor: '422/SIAKAD/XI/2026',
    verifikasiToken: 'AYU-LULUS-2026',
  ),
];

// ---------------------------------------------------------------------------
// 12 — Banding nilai, cuti, konversi
// ---------------------------------------------------------------------------

List<BandingNilai> seedBanding() => [
  BandingNilai(
    id: 'BND-SITI-01',
    npm: npmSiti,
    kodeMk: 'TI108',
    namaMk: 'Algoritma & Pemrograman',
    alasan:
        'Nilai tugas dan UAS sudah sesuai, namun komponen kehadiran tidak '
        'tercatat pada pertemuan 8 dan 9.',
    diajukan: DateTime(2026, 7, 2),
    status: StatusPengajuan.ditolak,
    jawabanDosen:
        'Setelah pengecekan presensi, kehadiran tercatat lengkap. Nilai final '
        'dipertahankan.',
  ),
  BandingNilai(
    id: 'BND-SITI-02',
    npm: npmSiti,
    kodeMk: 'TI304',
    namaMk: 'Sistem Operasi',
    alasan:
        'Nilai UAS 81 tidak muncul pada KHS, sedangkan berita acara menyebutkan '
        'nilai tersebut sudah diserahkan dosen pengampu.',
    diajukan: DateTime(2026, 11, 6),
    status: StatusPengajuan.pengajuan,
  ),
];

List<PengajuanCuti> seedCuti() => [];

List<PengajuanKonversi> seedKonversi() => [];

// ---------------------------------------------------------------------------
// 09 — Kalender akademik diturunkan dari periode yang ada
// ---------------------------------------------------------------------------

List<KalenderEvent> kalenderDariPeriode(List<PeriodeAkademik> periode) {
  final out = <KalenderEvent>[];
  for (final p in periode) {
    out.add(
      KalenderEvent(
        id: '${p.id}-KRS',
        judul: 'Pengisian KRS ${p.nama}',
        tanggal: p.krsMulai,
        kategori: KategoriKalender.krs,
        keterangan:
            'Buka ${formatTanggal(p.krsMulai)} – '
            '${formatTanggal(p.krsSelesai)}',
      ),
    );
    out.add(
      KalenderEvent(
        id: '${p.id}-UTS',
        judul: 'Ujian Tengah Semester ${p.nama}',
        tanggal: p.utsMulai,
        kategori: KategoriKalender.uts,
      ),
    );
    out.add(
      KalenderEvent(
        id: '${p.id}-UAS',
        judul: 'Ujian Akhir Semester ${p.nama}',
        tanggal: p.uasMulai,
        kategori: KategoriKalender.uas,
      ),
    );
    final yudisium = p.uasMulai.add(const Duration(days: 30));
    out.add(
      KalenderEvent(
        id: '${p.id}-YUDISIUM',
        judul: 'Yudisium ${p.nama}',
        tanggal: yudisium,
        kategori: KategoriKalender.yudisium,
        keterangan: 'Batas akhir verifikasi berkas kelulusan',
      ),
    );
    out.add(
      KalenderEvent(
        id: '${p.id}-LIBUR',
        judul: 'Libur antar semester ${p.nama}',
        tanggal: p.uasMulai.add(const Duration(days: 45)),
        kategori: KategoriKalender.libur,
        keterangan: 'Nilai akhir disahkan sebelum semester berikutnya',
      ),
    );
  }
  out.sort((a, b) => a.tanggal.compareTo(b.tanggal));
  return out;
}
