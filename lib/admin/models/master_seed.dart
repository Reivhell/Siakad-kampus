import 'master_data.dart';

List<Prodi> seedProdi() => [
  Prodi(
    id: 'p-ti',
    kode: '10',
    nama: 'Teknik Informatika',
    jenjang: 'S1',
    gelar: 'S.Kom.',
    studentCount: 640,
  ),
  Prodi(
    id: 'p-si',
    kode: '20',
    nama: 'Sistem Informasi',
    jenjang: 'S1',
    gelar: 'S.Kom.',
    studentCount: 480,
  ),
  Prodi(
    id: 'p-mi',
    kode: '30',
    nama: 'Manajemen Informatika',
    jenjang: 'D3',
    gelar: 'A.Md.Kom.',
    studentCount: 210,
  ),
  Prodi(
    id: 'p-ak',
    kode: '40',
    nama: 'Akuntansi',
    jenjang: 'S1',
    gelar: 'S.Ak.',
  ),
];

List<Periode> seedPeriode() => [
  Periode(
    id: 'per-2526-ganjil',
    nama: 'Ganjil 2025/2026',
    tahun: '2025/2026',
    semester: 'GANJIL',
    mulai: DateTime(2025, 9, 1),
    selesai: DateTime(2026, 1, 24),
    aktif: true,
  ),
  Periode(
    id: 'per-2425-genap',
    nama: 'Genap 2024/2025',
    tahun: '2024/2025',
    semester: 'GENAP',
    mulai: DateTime(2025, 2, 3),
    selesai: DateTime(2025, 6, 28),
  ),
  Periode(
    id: 'per-2425-ganjil',
    nama: 'Ganjil 2024/2025',
    tahun: '2024/2025',
    semester: 'GANJIL',
    mulai: DateTime(2024, 9, 2),
    selesai: DateTime(2025, 1, 25),
  ),
];

List<Ruangan> seedRuangan() => [
  Ruangan(
    id: 'r-lab1',
    kode: 'LAB-KOMP-1',
    nama: 'Lab Komputer 1',
    kapasitas: 40,
    gedung: 'Gedung Lab Terpadu',
    tipe: 'LABORATORIUM_KOMPUTER',
  ),
  Ruangan(
    id: 'r-a201',
    kode: 'GD-A-201',
    nama: 'Ruang Teori Multimedia 1',
    kapasitas: 60,
    gedung: 'Gedung Teori A',
  ),
  Ruangan(
    id: 'r-audit',
    kode: 'AUDIT-01',
    nama: 'Auditorium Utama',
    kapasitas: 300,
    gedung: 'Gedung Rektorat',
    tipe: 'AUDITORIUM',
  ),
  Ruangan(
    id: 'r-renov',
    kode: 'GD-B-102',
    nama: 'Ruang Teori B-102',
    kapasitas: 50,
    gedung: 'Gedung Teori B',
    tersedia: false,
  ),
];
