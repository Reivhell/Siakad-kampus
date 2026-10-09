import 'curriculum.dart';

List<MataKuliah> seedMk() => [
  MataKuliah(
    id: 'mk-ti101',
    kode: 'TI101',
    nama: 'Algoritma & Pemrograman I',
    sks: 3,
    sksTeori: 2,
    sksPraktikum: 1,
    semesterDefault: 1,
  ),
  MataKuliah(
    id: 'mk-ti102',
    kode: 'TI102',
    nama: 'Matematika Diskrit',
    sks: 3,
    sksTeori: 3,
    sksPraktikum: 0,
    semesterDefault: 1,
  ),
  MataKuliah(
    id: 'mk-ti201',
    kode: 'TI201',
    nama: 'Struktur Data',
    sks: 3,
    sksTeori: 2,
    sksPraktikum: 1,
    semesterDefault: 2,
  ),
  MataKuliah(
    id: 'mk-ti202',
    kode: 'TI202',
    nama: 'Basis Data Dasar',
    sks: 3,
    sksTeori: 2,
    sksPraktikum: 1,
    semesterDefault: 2,
  ),
  MataKuliah(
    id: 'mk-ti301',
    kode: 'TI301',
    nama: 'Basis Data Lanjut',
    sks: 3,
    sksTeori: 2,
    sksPraktikum: 1,
    semesterDefault: 3,
  ),
  MataKuliah(
    id: 'mk-ti401',
    kode: 'TI401',
    nama: 'Rekayasa Perangkat Lunak',
    sks: 3,
    sksTeori: 3,
    sksPraktikum: 0,
    semesterDefault: 4,
  ),
  MataKuliah(
    id: 'mk-ti601',
    kode: 'TI601',
    nama: 'Metodologi Penelitian',
    sks: 2,
    sksTeori: 2,
    sksPraktikum: 0,
    semesterDefault: 6,
  ),
  MataKuliah(
    id: 'mk-ti801',
    kode: 'TI801',
    nama: 'Skripsi / Tugas Akhir',
    sks: 6,
    sksTeori: 6,
    sksPraktikum: 0,
    semesterDefault: 8,
    jenis: 'TUGAS_AKHIR',
  ),
];

List<Kurikulum> seedKurikulum() => [
  Kurikulum(
    id: 'k-2024',
    nama: 'Kurikulum 2024 (MBKM)',
    prodiId: 'p-ti',
    tahun: 2024,
    totalSksLulus: 144,
    aktif: true,
  ),
  Kurikulum(
    id: 'k-2020',
    nama: 'Kurikulum 2020',
    prodiId: 'p-ti',
    tahun: 2020,
    totalSksLulus: 144,
  ),
];

List<KurikulumMk> seedMapping() => [
  KurikulumMk(kurikulumId: 'k-2024', mkId: 'mk-ti101', semester: 1),
  KurikulumMk(kurikulumId: 'k-2024', mkId: 'mk-ti102', semester: 1),
  KurikulumMk(kurikulumId: 'k-2024', mkId: 'mk-ti201', semester: 2),
  KurikulumMk(kurikulumId: 'k-2024', mkId: 'mk-ti202', semester: 2),
  KurikulumMk(kurikulumId: 'k-2024', mkId: 'mk-ti301', semester: 3),
  KurikulumMk(kurikulumId: 'k-2024', mkId: 'mk-ti401', semester: 4),
  KurikulumMk(kurikulumId: 'k-2024', mkId: 'mk-ti601', semester: 6),
  KurikulumMk(kurikulumId: 'k-2024', mkId: 'mk-ti801', semester: 8),
];

List<PrereqRule> seedPrereq() => const [
  PrereqRule(
    kurikulumId: 'k-2024',
    mkId: 'mk-ti201',
    syaratMkId: 'mk-ti101',
    minHuruf: 'C',
  ),
  PrereqRule(
    kurikulumId: 'k-2024',
    mkId: 'mk-ti301',
    syaratMkId: 'mk-ti202',
    minHuruf: 'C',
  ),
  PrereqRule(
    kurikulumId: 'k-2024',
    mkId: 'mk-ti801',
    syaratMkId: 'mk-ti601',
    minHuruf: 'C',
  ),
  PrereqRule(
    kurikulumId: 'k-2024',
    mkId: 'mk-ti801',
    tipe: 'CREDIT_THRESHOLD',
    minSks: 120,
  ),
];
