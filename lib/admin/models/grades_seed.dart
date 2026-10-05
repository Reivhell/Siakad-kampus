class KelasNilai {
  final String kelasId;
  final String kode;
  final String mkNama;
  final String dosen;
  final int peserta;
  final int terisi;
  bool finalisasi;
  DateTime? unlockHingga;
  KelasNilai({
    required this.kelasId,
    required this.kode,
    required this.mkNama,
    required this.dosen,
    required this.peserta,
    required this.terisi,
    this.finalisasi = false,
    this.unlockHingga,
  });

  String get status {
    if (finalisasi) return 'FINAL';
    if (unlockHingga != null) return 'TERBUKA';
    if (terisi == 0) return 'KOSONG';
    return 'DRAFT';
  }
}

List<KelasNilai> seedKelasNilai() => [
  KelasNilai(
    kelasId: 'kl-ti101a',
    kode: 'TI101-A',
    mkNama: 'Algoritma & Pemrograman I',
    dosen: 'Dr. Aris Munandar',
    peserta: 40,
    terisi: 40,
    finalisasi: true,
  ),
  KelasNilai(
    kelasId: 'kl-ti202a',
    kode: 'TI202-B',
    mkNama: 'Basis Data Terdistribusi',
    dosen: 'Hendra W., M.Eng.',
    peserta: 38,
    terisi: 20,
  ),
  KelasNilai(
    kelasId: 'kl-ti301b',
    kode: 'TI304-A',
    mkNama: 'Jaringan Komputer Lanjut',
    dosen: 'Budi Santoso, M.T.',
    peserta: 35,
    terisi: 0,
  ),
  KelasNilai(
    kelasId: 'kl-tanpa-dosen',
    kode: 'TI401-A',
    mkNama: 'Rekayasa Perangkat Lunak',
    dosen: 'Dr. Siti Nurhaliza',
    peserta: 32,
    terisi: 30,
    unlockHingga: DateTime(2026, 9, 30, 12),
  ),
];

const defaultWeights = {
  'Tugas': 20.0,
  'UTS': 30.0,
  'UAS': 40.0,
  'Presensi': 10.0,
};
