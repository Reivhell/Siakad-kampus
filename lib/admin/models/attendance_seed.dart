import 'attendance.dart';

const mingguBerjalan = 11;

List<KelasPresensi> seedKelasPresensi() => const [
  KelasPresensi(
    kelasId: 'kl-ti101a',
    kode: 'TI101-A',
    mkNama: 'Algoritma & Pemrograman I',
    dosen: 'Dr. Aris Munandar',
    realisasi: 11,
  ),
  KelasPresensi(
    kelasId: 'kl-ti202a',
    kode: 'TI202-B',
    mkNama: 'Basis Data Lanjut',
    dosen: 'Hendra W., M.Eng.',
    realisasi: 10,
  ),
  KelasPresensi(
    kelasId: 'kl-ti301b',
    kode: 'TI304-A',
    mkNama: 'Jaringan Komputer Lanjut',
    dosen: 'Budi Santoso, M.T.',
    realisasi: 6,
  ),
  KelasPresensi(
    kelasId: 'kl-tanpa-dosen',
    kode: 'TI401-A',
    mkNama: 'Rekayasa Perangkat Lunak',
    dosen: 'Dr. Siti Nurhaliza',
    realisasi: 11,
  ),
];

List<SkriningMhs> seedSkrining() => [
  SkriningMhs(
    npm: '2410010012',
    nama: 'Dimas Surya Nugraha',
    kelasId: 'kl-ti101a',
    total: 11,
    hadir: 7,
  ),
  SkriningMhs(
    npm: '2410010045',
    nama: 'Rina Marlina',
    kelasId: 'kl-ti101a',
    total: 11,
    hadir: 8,
  ),
  SkriningMhs(
    npm: '2310010007',
    nama: 'Agus Setiawan',
    kelasId: 'kl-ti301b',
    total: 6,
    hadir: 3,
  ),
];
