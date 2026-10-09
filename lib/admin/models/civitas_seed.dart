import 'civitas.dart';

List<Mahasiswa> seedMahasiswa() => [
  Mahasiswa(
    npm: '2610010001',
    nama: 'Aditya Pratama',
    prodiId: 'p-ti',
    angkatan: 2026,
    sks: 20,
    ipk: 3.85,
    dosenWali: '0412088501',
  ),
  Mahasiswa(
    npm: '2610010002',
    nama: 'Amanda Putri Lestari',
    prodiId: 'p-ti',
    angkatan: 2026,
    sks: 20,
    ipk: 3.70,
  ),
  Mahasiswa(
    npm: '2510010045',
    nama: 'Bagas Wicaksono',
    prodiId: 'p-ti',
    angkatan: 2025,
    status: 'CUTI',
    sks: 42,
    ipk: 2.45,
  ),
  Mahasiswa(
    npm: '2310010012',
    nama: 'Dimas Surya Nugraha',
    prodiId: 'p-ti',
    angkatan: 2023,
    sks: 88,
    ipk: 1.95,
  ),
  Mahasiswa(
    npm: '2210010088',
    nama: 'Fajar Kurniawan',
    prodiId: 'p-ti',
    angkatan: 2022,
    status: 'LULUS',
    sks: 144,
    ipk: 3.92,
  ),
];

List<Dosen> seedDosenCivitas() => [
  Dosen(
    nidn: '0412088501',
    nama: 'Dr. Aris Munandar',
    prodiId: 'p-ti',
    bebanSks: 14,
  ),
  Dosen(
    nidn: '0420119002',
    nama: 'Budi Santoso, M.T.',
    prodiId: 'p-ti',
    bebanSks: 18,
  ),
  Dosen(
    nidn: '0405128703',
    nama: 'Dr. Hendra Wijaya',
    prodiId: 'p-si',
    bebanSks: 8,
  ),
  Dosen(
    nidn: '0419079204',
    nama: 'Siti Rahayu, M.Kom.',
    prodiId: 'p-si',
    status: 'TUGAS_BELAJAR',
    bebanSks: 0,
  ),
];

const facultyCodeTI = '100';
