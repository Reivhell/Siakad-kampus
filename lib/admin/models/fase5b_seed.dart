import 'feeder.dart';
import 'transfer.dart';

List<FeederIssue> seedFeederIssues() => const [
  FeederIssue(
    'BIODATA_MAHASISWA',
    '2610010099',
    'Rudi Hartono',
    'NIK 12 digit — butuh 16.',
    '/admin/civitas',
  ),
  FeederIssue(
    'BIODATA_MAHASISWA',
    '2510010031',
    ' Dewi Anggraini',
    'Nama ibu kandung kosong.',
    '/admin/civitas',
  ),
  FeederIssue(
    'PENUGASAN_DOSEN',
    'TI102-A',
    'Matematika Diskrit',
    'Belum ada dosen pengampu.',
    '/admin/perkuliahan',
  ),
  FeederIssue(
    'NILAI',
    'TI304-A',
    'Jaringan Lanjut',
    '35 baris DRAFT belum final.',
    '/admin/nilai',
  ),
];

class TransferCase {
  final String npm;
  final String nama;
  final String jalur;
  final String asal;
  final List<TransferMap> maps;
  String status;
  TransferCase({
    required this.npm,
    required this.nama,
    required this.jalur,
    required this.asal,
    required this.maps,
    this.status = 'VERIFIKASI',
  });
}

List<TransferCase> seedTransfer() => [
  TransferCase(
    npm: '2410010901',
    nama: 'Bagus Prasetyo',
    jalur: 'ALIH_JENJANG',
    asal: 'Politeknik Negeri Jakarta',
    maps: [
      TransferMap(
        asalKode: 'TI101',
        asalNama: 'Algoritma Pemrograman',
        asalSks: 3,
        asalHuruf: 'A',
        lokalMkId: 'mk-ti101',
        diakuiHuruf: 'A',
        diakuiBobot: 4.0,
      ),
      TransferMap(
        asalKode: 'TI205+TI206',
        asalNama: 'Praktikum+Teori Basis Data',
        asalSks: 4,
        asalHuruf: 'B',
        lokalMkId: 'mk-ti202',
        diakuiHuruf: 'AB',
        diakuiBobot: 3.5,
      ),
    ],
  ),
];

class LetterReq {
  final String id;
  final String npm;
  final String nama;
  final String jenis;
  final String kode;
  final String tujuan;
  String status;
  String? nomor;
  LetterReq({
    required this.id,
    required this.npm,
    required this.nama,
    required this.jenis,
    required this.kode,
    required this.tujuan,
    this.status = 'MENUNGGU_VERIFIKASI',
    this.nomor,
  });
}

List<LetterReq> seedLetters() => [
  LetterReq(
    id: 'l1',
    npm: '2210010001',
    nama: 'Aditya Pratama',
    jenis: 'Keterangan Mhs Aktif',
    kode: 'S.Ket-Aktif',
    tujuan: 'Tunjangan GP',
  ),
  LetterReq(
    id: 'l2',
    npm: '2610010002',
    nama: 'Siti Nurhaliza',
    jenis: 'Pengantar Magang PKL',
    kode: 'S.Peng-Magang',
    tujuan: 'PT Telkom',
  ),
  LetterReq(
    id: 'l3',
    npm: '2510010045',
    nama: 'Bagas Wicaksono',
    jenis: 'Izin Riset Skripsi',
    kode: 'S.Izin-Riset',
    tujuan: 'Diskominfo',
    status: 'SELESAI',
    nomor: '041/S.Izin-Riset/FTI-SIAKAD/IX/2026',
  ),
];
