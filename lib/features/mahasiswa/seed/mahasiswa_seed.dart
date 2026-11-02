/// Seed lokal fitur mahasiswa — pengganti sementara Supabase pada MVP.
///
/// Sesuai keputusan implementasi: data in-memory dulu (pola sama dengan
/// `lib/admin/models/users_seed.dart`), sehingga aplikasi berjalan penuh
/// tanpa backend. Aturan bisnis tetap di repository agar mudah dipindah
/// ke `sia_backend_core` + Supabase saat fase backend dimulai.
library;

import '../../../app/formatters.dart';
import '../models/mahasiswa_models.dart';

const String periodeAktifId = '2026-2027-GANJIL';
const String npmSiti = '2410010015';
const String npmReza = '2410010016';
const String npmRendy = '2510010002';

List<PeriodeAkademik> seedPeriode() => [
  PeriodeAkademik(
    id: '2024-2025-GANJIL',
    nama: '2024/2025 GANJIL',
    krsMulai: DateTime(2024, 8, 5),
    krsSelesai: DateTime(2024, 9, 13),
    utsMulai: DateTime(2024, 10, 21),
    uasMulai: DateTime(2024, 12, 23),
  ),
  PeriodeAkademik(
    id: '2024-2025-GENAP',
    nama: '2024/2025 GENAP',
    krsMulai: DateTime(2025, 2, 3),
    krsSelesai: DateTime(2025, 3, 14),
    utsMulai: DateTime(2025, 4, 21),
    uasMulai: DateTime(2025, 6, 23),
  ),
  PeriodeAkademik(
    id: '2025-2026-GANJIL',
    nama: '2025/2026 GANJIL',
    krsMulai: DateTime(2025, 8, 4),
    krsSelesai: DateTime(2025, 9, 12),
    utsMulai: DateTime(2025, 10, 20),
    uasMulai: DateTime(2025, 12, 22),
  ),
  PeriodeAkademik(
    id: '2025-2026-GENAP',
    nama: '2025/2026 GENAP',
    krsMulai: DateTime(2026, 2, 2),
    krsSelesai: DateTime(2026, 3, 13),
    utsMulai: DateTime(2026, 4, 20),
    uasMulai: DateTime(2026, 6, 22),
  ),
  PeriodeAkademik(
    id: periodeAktifId,
    nama: '2026/2027 GANJIL',
    krsMulai: DateTime(2026, 8, 3),
    krsSelesai: DateTime(2026, 9, 11),
    utsMulai: DateTime(2026, 10, 19),
    uasMulai: DateTime(2026, 12, 21),
    aktif: true,
  ),
];

List<MahasiswaProfile> seedProfiles() => [
  MahasiswaProfile(
    npm: npmSiti,
    nama: 'Siti Nurhaliza',
    prodi: 'S1 Teknik Informatika',
    jenjang: 'S1',
    tahunMasuk: 2024,
    semester: 5,
    status: StatusMahasiswa.aktif,
    dosenWali: 'Dr. Hendra Wijaya',
    email: 'siti.261001@mhs.kampus.ac.id',
    telepon: '+62 812-3456-7890',
  ),
  MahasiswaProfile(
    npm: npmReza,
    nama: 'Reza Pratama',
    prodi: 'S1 Teknik Informatika',
    jenjang: 'S1',
    tahunMasuk: 2024,
    semester: 5,
    status: StatusMahasiswa.aktif,
    dosenWali: 'Dr. Hendra Wijaya',
    email: 'reza.241016@mhs.kampus.ac.id',
    telepon: '+62 813-2211-4455',
  ),
  MahasiswaProfile(
    npm: npmRendy,
    nama: 'Rendy Firmansyah',
    prodi: 'S1 Sistem Informasi',
    jenjang: 'S1',
    tahunMasuk: 2025,
    semester: 3,
    status: StatusMahasiswa.aktif,
    dosenWali: 'Rina Kartika, M.Kom.',
    email: 'rendy.251002@mhs.kampus.ac.id',
    telepon: '+62 811-9090-1234',
  ),
];

Kelas _kelas({
  required String id,
  required String kode,
  required String kodeMk,
  required String namaMk,
  required String dosen,
  required int terdaftar,
  required int hari,
  required String mulai,
  required String selesai,
  String? ruangan,
  int sks = 3,
  int kapasitas = 30,
}) => Kelas(
  id: id,
  kode: kode,
  kodeMk: kodeMk,
  namaMk: namaMk,
  sks: sks,
  dosen: dosen,
  kapasitas: kapasitas,
  jadwal: [
    JadwalSlot(hari: hari, jamMulai: mulai, jamSelesai: selesai, ruangan: ruangan),
  ],
  periodeId: periodeAktifId,
  jumlahTerdaftar: terdaftar,
);

/// Katalog kelas periode aktif. TI309 sengaja penuh dan TI310 sengaja
/// bentrok dengan TI301 agar validasi KRS bisa didemokan.
List<Kelas> seedKelas() => [
  _kelas(
    id: 'K-TI301-A',
    kode: 'TI301-A',
    kodeMk: 'TI301',
    namaMk: 'Basis Data',
    dosen: 'Dr. Hendra Wijaya',
    terdaftar: 24,
    hari: 1,
    mulai: '08:00',
    selesai: '09:40',
    ruangan: 'Lab-1',
  ),
  _kelas(
    id: 'K-TI302-B',
    kode: 'TI302-B',
    kodeMk: 'TI302',
    namaMk: 'Jaringan Komputer',
    dosen: 'Budi Santoso, M.T.',
    terdaftar: 28,
    hari: 1,
    mulai: '10:00',
    selesai: '11:40',
    ruangan: 'R-201',
  ),
  _kelas(
    id: 'K-TI303-A',
    kode: 'TI303-A',
    kodeMk: 'TI303',
    namaMk: 'Rekayasa Perangkat Lunak',
    dosen: 'Dr. Aris Munandar',
    terdaftar: 22,
    hari: 2,
    mulai: '08:00',
    selesai: '09:40',
    ruangan: 'R-202',
  ),
  _kelas(
    id: 'K-TI304-B',
    kode: 'TI304-B',
    kodeMk: 'TI304',
    namaMk: 'Sistem Operasi',
    dosen: 'Rina Kartika, M.Kom.',
    terdaftar: 29,
    hari: 2,
    mulai: '13:00',
    selesai: '14:40',
    ruangan: 'R-203',
  ),
  _kelas(
    id: 'K-TI305-A',
    kode: 'TI305-A',
    kodeMk: 'TI305',
    namaMk: 'Pemrograman Web',
    dosen: 'Budi Santoso, M.T.',
    terdaftar: 18,
    hari: 3,
    mulai: '08:00',
    selesai: '09:40',
    ruangan: 'Lab-2',
  ),
  _kelas(
    id: 'K-TI306-A',
    kode: 'TI306-A',
    kodeMk: 'TI306',
    namaMk: 'Kecerdasan Buatan',
    dosen: 'Dr. Hendra Wijaya',
    terdaftar: 20,
    hari: 3,
    mulai: '10:00',
    selesai: '11:40',
    ruangan: 'R-204',
  ),
  _kelas(
    id: 'K-TI307-A',
    kode: 'TI307-A',
    kodeMk: 'TI307',
    namaMk: 'Keamanan Informasi',
    dosen: 'Dr. Aris Munandar',
    terdaftar: 12,
    hari: 4,
    mulai: '08:00',
    selesai: '09:40',
    ruangan: 'R-205',
  ),
  _kelas(
    id: 'K-TI308-A',
    kode: 'TI308-A',
    kodeMk: 'TI308',
    namaMk: 'Data Mining',
    dosen: 'Rina Kartika, M.Kom.',
    terdaftar: 15,
    hari: 4,
    mulai: '13:00',
    selesai: '14:40',
    ruangan: 'Lab-3',
  ),
  _kelas(
    id: 'K-TI309-E',
    kode: 'TI309-E',
    kodeMk: 'TI309',
    namaMk: 'Etika Profesi',
    dosen: 'Dr. Aris Munandar',
    terdaftar: 30,
    hari: 5,
    mulai: '08:00',
    selesai: '09:40',
    ruangan: 'R-206',
    kapasitas: 30,
  ),
  _kelas(
    id: 'K-TI310-A',
    kode: 'TI310-A',
    kodeMk: 'TI310',
    namaMk: 'Sistem Terdistribusi',
    dosen: 'Budi Santoso, M.T.',
    terdaftar: 16,
    hari: 1,
    mulai: '08:00',
    selesai: '09:40',
    ruangan: 'R-207',
  ),
];

/// KRS Siti sudah AKTIF pada periode berjalan (6 MK, 18 SKS).
List<KrsEntry> seedKrs() => [
  KrsEntry(
    id: 'KRS-SITI-01',
    npm: npmSiti,
    kelasId: 'K-TI301-A',
    periodeId: periodeAktifId,
    status: StatusKrs.aktif,
  ),
  KrsEntry(
    id: 'KRS-SITI-02',
    npm: npmSiti,
    kelasId: 'K-TI302-B',
    periodeId: periodeAktifId,
    status: StatusKrs.aktif,
  ),
  KrsEntry(
    id: 'KRS-SITI-03',
    npm: npmSiti,
    kelasId: 'K-TI303-A',
    periodeId: periodeAktifId,
    status: StatusKrs.aktif,
  ),
  KrsEntry(
    id: 'KRS-SITI-04',
    npm: npmSiti,
    kelasId: 'K-TI304-B',
    periodeId: periodeAktifId,
    status: StatusKrs.aktif,
  ),
  KrsEntry(
    id: 'KRS-SITI-05',
    npm: npmSiti,
    kelasId: 'K-TI305-A',
    periodeId: periodeAktifId,
    status: StatusKrs.aktif,
  ),
  KrsEntry(
    id: 'KRS-SITI-06',
    npm: npmSiti,
    kelasId: 'K-TI306-A',
    periodeId: periodeAktifId,
    status: StatusKrs.aktif,
  ),
];

const Map<String, double> _angkaHuruf = {
  'A': 92,
  'AB': 86,
  'B': 79,
  'BC': 73,
  'C': 66,
  'D': 55,
  'E': 40,
};

NilaiRecord _nilai(
  String npm,
  String periode,
  String kodeMk,
  String namaMk,
  String? huruf, {
  bool sudahFinal = true,
  String? disubmitPada,
}) {
  final angka = huruf == null ? null : _angkaHuruf[huruf];
  return NilaiRecord(
    npm: npm,
    periodeId: periode,
    kodeMk: kodeMk,
    namaMk: namaMk,
    sks: 3,
    uts: angka == null ? null : angka - 4,
    uas: angka == null ? null : angka + 1,
    tugas: angka == null ? null : angka + 2,
    akhir: angka,
    huruf: huruf,
    sudahFinal: huruf != null && sudahFinal,
    disubmitPada: huruf == null ? null : disubmitPada,
  );
}

List<NilaiRecord> seedNilai() => [
  // Siti — semester 1 (2024/2025 GANJIL)
  _nilai(npmSiti, '2024-2025-GANJIL', 'TI101', 'Pengantar Teknologi Informasi', 'A', disubmitPada: '24 Jan 2025'),
  _nilai(npmSiti, '2024-2025-GANJIL', 'TI102', 'Kalkulus', 'AB', disubmitPada: '24 Jan 2025'),
  _nilai(npmSiti, '2024-2025-GANJIL', 'TI103', 'Pemrograman Dasar', 'A', disubmitPada: '24 Jan 2025'),
  _nilai(npmSiti, '2024-2025-GANJIL', 'MKU101', 'Pancasila', 'B', disubmitPada: '24 Jan 2025'),
  _nilai(npmSiti, '2024-2025-GANJIL', 'TI104', 'Logika Digital', 'AB', disubmitPada: '24 Jan 2025'),
  // Siti — semester 2 (2024/2025 GENAP)
  _nilai(npmSiti, '2024-2025-GENAP', 'TI105', 'Struktur Data', 'A', disubmitPada: '27 Jun 2025'),
  _nilai(npmSiti, '2024-2025-GENAP', 'TI106', 'Basis Data I', 'B', disubmitPada: '27 Jun 2025'),
  _nilai(npmSiti, '2024-2025-GENAP', 'TI107', 'Jaringan Dasar', 'AB', disubmitPada: '27 Jun 2025'),
  _nilai(npmSiti, '2024-2025-GENAP', 'MKU102', 'Bahasa Indonesia', 'A', disubmitPada: '27 Jun 2025'),
  _nilai(npmSiti, '2024-2025-GENAP', 'TI108', 'Algoritma & Pemrograman', 'BC', disubmitPada: '27 Jun 2025'),
  // Siti — semester 3 (2025/2026 GANJIL)
  _nilai(npmSiti, '2025-2026-GANJIL', 'TI201', 'Pemrograman Lanjut', 'AB', disubmitPada: '23 Jan 2026'),
  _nilai(npmSiti, '2025-2026-GANJIL', 'TI202', 'Sistem Operasi', 'A', disubmitPada: '23 Jan 2026'),
  _nilai(npmSiti, '2025-2026-GANJIL', 'TI203', 'Rekayasa Perangkat Lunak', 'B', disubmitPada: '23 Jan 2026'),
  _nilai(npmSiti, '2025-2026-GANJIL', 'TI204', 'Statistika', 'AB', disubmitPada: '23 Jan 2026'),
  _nilai(npmSiti, '2025-2026-GANJIL', 'TI205', 'Pemrograman Web', 'A', disubmitPada: '23 Jan 2026'),
  // Siti — semester 4 (2025/2026 GENAP)
  _nilai(npmSiti, '2025-2026-GENAP', 'TI206', 'Kecerdasan Buatan', 'B', disubmitPada: '26 Jun 2026'),
  _nilai(npmSiti, '2025-2026-GENAP', 'TI207', 'Keamanan Informasi', 'AB', disubmitPada: '26 Jun 2026'),
  _nilai(npmSiti, '2025-2026-GENAP', 'TI208', 'Basis Data Lanjut', 'A', disubmitPada: '26 Jun 2026'),
  _nilai(npmSiti, '2025-2026-GENAP', 'TI209', 'Proyek Perangkat Lunak', 'B', disubmitPada: '26 Jun 2026'),
  _nilai(npmSiti, '2025-2026-GENAP', 'TI210', 'Technopreneurship', 'AB', disubmitPada: '26 Jun 2026'),
  // Siti — semester berjalan (sebagian masih DRAFT / belum diinput)
  _nilai(npmSiti, periodeAktifId, 'TI301', 'Basis Data', 'A', disubmitPada: '18 Sep 2026'),
  _nilai(npmSiti, periodeAktifId, 'TI302', 'Jaringan Komputer', 'AB', disubmitPada: '18 Sep 2026'),
  _nilai(npmSiti, periodeAktifId, 'TI303', 'Rekayasa Perangkat Lunak', 'B', sudahFinal: false),
  _nilai(npmSiti, periodeAktifId, 'TI304', 'Sistem Operasi', 'BC', sudahFinal: false),
  _nilai(npmSiti, periodeAktifId, 'TI305', 'Pemrograman Web', null),
  _nilai(npmSiti, periodeAktifId, 'TI306', 'Kecerdasan Buatan', null),
  // Reza belum punya nilai periode berjalan.
];

const List<String> _topik = [
  'Kontrak kuliah & pengantar',
  'Konsep dasar',
  'Latihan terbimbing',
  'Studi kasus',
  'Diskusi kelompok',
  'Kuis',
  'Praktik laboratorium',
  'Presentasi',
  'Review materi',
  'Proyek mini',
  'Evaluasi formatif',
  'Pendalaman materi',
  'Simulasi',
  'Konsultasi tugas',
  'Review menjelang UTS',
  'Persiapan UAS',
];

List<PresensiRecord> _presensi(
  String npm,
  String kelasId, {
  required int hadir,
  int izin = 0,
  int sakit = 0,
  int alpha = 0,
}) {
  final urutan = <String>[
    ...List.filled(hadir, 'HADIR'),
    ...List.filled(izin, 'IZIN'),
    ...List.filled(sakit, 'SAKIT'),
    ...List.filled(alpha, 'ALPHA'),
  ];
  final out = <PresensiRecord>[];
  for (var i = 0; i < 16; i++) {
    out.add(
      PresensiRecord(
        npm: npm,
        kelasId: kelasId,
        pertemuanKe: i + 1,
        tanggal: formatTanggal(DateTime(2026, 9, 7).add(Duration(days: 7 * i))),
        topik: _topik[i % _topik.length],
        status: i < urutan.length ? urutan[i] : null,
      ),
    );
  }
  return out;
}

List<PresensiRecord> seedPresensi() => [
  // Siti — 6 kelas berjalan.
  ..._presensi(npmSiti, 'K-TI301-A', hadir: 14, izin: 1),
  ..._presensi(npmSiti, 'K-TI302-B', hadir: 11, izin: 2, sakit: 1, alpha: 2),
  ..._presensi(npmSiti, 'K-TI303-A', hadir: 13, sakit: 1, izin: 1),
  ..._presensi(npmSiti, 'K-TI304-B', hadir: 16),
  ..._presensi(npmSiti, 'K-TI305-A', hadir: 12, izin: 1, sakit: 1, alpha: 2),
  ..._presensi(npmSiti, 'K-TI306-A', hadir: 15, izin: 1),
];

List<Tagihan> seedTagihan() => [
  Tagihan(
    id: 'TGH-SITI-01',
    npm: npmSiti,
    jenis: 'UKT',
    periodeId: '2025-2026-GENAP',
    nominal: 4500000,
    status: TagihanStatus.lunas,
    tanggalBayar: '10 Feb 2026',
  ),
  Tagihan(
    id: 'TGH-SITI-02',
    npm: npmSiti,
    jenis: 'UKT',
    periodeId: periodeAktifId,
    nominal: 4500000,
    status: TagihanStatus.lunas,
    tanggalBayar: '5 Agu 2026',
  ),
  Tagihan(
    id: 'TGH-REZA-01',
    npm: npmReza,
    jenis: 'UKT',
    periodeId: periodeAktifId,
    nominal: 4500000,
  ),
  Tagihan(
    id: 'TGH-RENDY-01',
    npm: npmRendy,
    jenis: 'UKT',
    periodeId: periodeAktifId,
    nominal: 5000000,
  ),
];

List<Pengumuman> seedPengumuman() => [
  Pengumuman(
    id: 'PGM-01',
    judul: 'Jendela KRS Ganjil 2026/2027',
    isi:
        'Pengisian KRS dibuka 3–11 Agustus 2026. Mahasiswa wajib melunasi '
        'UKT/SPP sebelum mengajukan KRS.',
    tanggal: DateTime(2026, 8, 3),
    penting: true,
  ),
  Pengumuman(
    id: 'PGM-02',
    judul: 'Jadwal UTS 19–30 Oktober 2026',
    isi:
        'Ujian Tengah Semester dilaksanakan sesuai jadwal masing-masing '
        'mata kuliah. Kartu ujian dapat diunduh dari portal.',
    tanggal: DateTime(2026, 9, 15),
  ),
  Pengumuman(
    id: 'PGM-03',
    judul: 'Beasiswa Peningkatan Prestasi Akademik',
    isi:
        'Pendaftaran beasiswa PPA dibuka hingga 30 November 2026. '
        'Syarat: IPK minimal 3.00 dan tidak sedang menerima beasiswa lain.',
    tanggal: DateTime(2026, 10, 1),
  ),
];
