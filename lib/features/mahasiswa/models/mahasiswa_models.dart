/// Model + aturan bisnis fitur mahasiswa (MVP P0 + UKT/SPP).
///
/// Sengaja tanpa dependensi Flutter agar logika inti mudah diuji murni —
/// pola sama dengan `lib/admin/models/*` (Fase 1). Sumber aturan:
/// `fitur_mahasiswa/01`–`06`, `09` dan `Mahasiswa.md §3a`.
library;

// ---------------------------------------------------------------------------
// Enum & konstanta
// ---------------------------------------------------------------------------

enum StatusMahasiswa { aktif, cuti, lulus, dropOut }

extension StatusMahasiswaX on StatusMahasiswa {
  String get label => switch (this) {
    StatusMahasiswa.aktif => 'AKTIF',
    StatusMahasiswa.cuti => 'CUTI',
    StatusMahasiswa.lulus => 'LULUS',
    StatusMahasiswa.dropOut => 'DO',
  };

  bool get bisaAmbilKrs => this == StatusMahasiswa.aktif;
}

enum StatusKrs { draft, menungguApproval, aktif, batal }

extension StatusKrsX on StatusKrs {
  String get label => switch (this) {
    StatusKrs.draft => 'DRAFT',
    StatusKrs.menungguApproval => 'MENUNGGU APPROVAL',
    StatusKrs.aktif => 'AKTIF',
    StatusKrs.batal => 'BATAL',
  };
}

enum TagihanStatus { belum, lunas }

/// Bobot huruf mutu — `fitur_mahasiswa/01_dashboard.md §3`.
const Map<String, double> bobotHuruf = {
  'A': 4.0,
  'AB': 3.5,
  'B': 3.0,
  'BC': 2.5,
  'C': 2.0,
  'D': 1.0,
  'E': 0.0,
};

const List<String> namaHari = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

String hariLabel(int isoWeekday) =>
    namaHari[(isoWeekday - 1).clamp(0, 6)];

// ---------------------------------------------------------------------------
// Entitas
// ---------------------------------------------------------------------------

class PeriodeAkademik {
  final String id;
  final String nama;
  final DateTime krsMulai;
  final DateTime krsSelesai;
  final DateTime utsMulai;
  final DateTime uasMulai;
  final bool aktif;

  const PeriodeAkademik({
    required this.id,
    required this.nama,
    required this.krsMulai,
    required this.krsSelesai,
    required this.utsMulai,
    required this.uasMulai,
    this.aktif = false,
  });
}

class MahasiswaProfile {
  final String npm;
  final String nama;
  final String prodi;
  final String jenjang;
  final int tahunMasuk;
  final int semester;
  final StatusMahasiswa status;
  final String dosenWali;
  final String email;
  String telepon;
  String? avatarUrl;

  MahasiswaProfile({
    required this.npm,
    required this.nama,
    required this.prodi,
    required this.jenjang,
    required this.tahunMasuk,
    required this.semester,
    required this.status,
    required this.dosenWali,
    required this.email,
    required this.telepon,
    this.avatarUrl,
  });

  /// NPM kanonis: `^[0-9]{10}$` (`02_profil_dan_status.md §2`).
  bool get npmValid => RegExp(r'^[0-9]{10}$').hasMatch(npm);
}

class JadwalSlot {
  final int hari; // ISO weekday 1..7
  final String jamMulai; // HH:mm
  final String jamSelesai; // HH:mm
  final String? ruangan;

  const JadwalSlot({
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    this.ruangan,
  });

  String get ruanganTampil => ruangan ?? 'Ruang menyusul';
}

class Kelas {
  final String id;
  final String kode;
  final String kodeMk;
  final String namaMk;
  final int sks;
  final String dosen;
  final int kapasitas;
  final List<JadwalSlot> jadwal;
  final String periodeId;
  int jumlahTerdaftar;

  Kelas({
    required this.id,
    required this.kode,
    required this.kodeMk,
    required this.namaMk,
    required this.sks,
    required this.dosen,
    required this.kapasitas,
    required this.jadwal,
    required this.periodeId,
    required this.jumlahTerdaftar,
  });

  bool get penuh => jumlahTerdaftar >= kapasitas;
}

class KrsEntry {
  final String id;
  final String npm;
  final String kelasId;
  final String periodeId;
  StatusKrs status;
  String? catatanPa;

  KrsEntry({
    required this.id,
    required this.npm,
    required this.kelasId,
    required this.periodeId,
    this.status = StatusKrs.draft,
    this.catatanPa,
  });
}

class NilaiRecord {
  final String npm;
  final String periodeId;
  final String kodeMk;
  final String namaMk;
  final int sks;
  final double? uts;
  final double? uas;
  final double? tugas;
  final double? akhir;
  final String? huruf;
  final bool sudahFinal;
  final String? disubmitPada;

  const NilaiRecord({
    required this.npm,
    required this.periodeId,
    required this.kodeMk,
    required this.namaMk,
    required this.sks,
    this.uts,
    this.uas,
    this.tugas,
    this.akhir,
    this.huruf,
    this.sudahFinal = false,
    this.disubmitPada,
  });
}

class PresensiRecord {
  final String npm;
  final String kelasId;
  final int pertemuanKe;
  final String tanggal;
  final String? topik;
  final String? status; // HADIR | IZIN | SAKIT | ALPHA | null (belum dicatat)

  const PresensiRecord({
    required this.npm,
    required this.kelasId,
    required this.pertemuanKe,
    required this.tanggal,
    this.topik,
    this.status,
  });
}

class Tagihan {
  final String id;
  final String npm;
  final String jenis; // UKT | SPP
  final String periodeId;
  final int nominal;
  TagihanStatus status;
  String? tanggalBayar;

  Tagihan({
    required this.id,
    required this.npm,
    required this.jenis,
    required this.periodeId,
    required this.nominal,
    this.status = TagihanStatus.belum,
    this.tanggalBayar,
  });
}

class Pengumuman {
  final String id;
  final String judul;
  final String isi;
  final DateTime tanggal;
  final bool penting;

  const Pengumuman({
    required this.id,
    required this.judul,
    required this.isi,
    required this.tanggal,
    this.penting = false,
  });
}

// ---------------------------------------------------------------------------
// Hasil validasi & gate
// ---------------------------------------------------------------------------

class HasilValidasi {
  final bool ok;
  final String? pesan;
  const HasilValidasi.ok()
    : ok = true,
      pesan = null;
  const HasilValidasi.gagal(this.pesan) : ok = false;
}

class GateKrs {
  final bool lolos;
  final String? pesan;
  const GateKrs.lolos()
    : lolos = true,
      pesan = null;
  const GateKrs.blokir(this.pesan) : lolos = false;
}

// ---------------------------------------------------------------------------
// Aturan bisnis murni
// ---------------------------------------------------------------------------

/// Plafon SKS dari IPS lalu — `fitur_mahasiswa/03_krs.md §2`.
int maxSks({required int semester, required double? ipsLalu}) {
  if (semester <= 2 || ipsLalu == null) return 20;
  if (ipsLalu >= 3.0) return 24;
  if (ipsLalu >= 2.5) return 21;
  if (ipsLalu >= 2.0) return 18;
  if (ipsLalu >= 1.5) return 15;
  return 12;
}

/// IPS = Σ(bobot × SKS) / ΣSKS — hanya baris yang sudah punya huruf final.
double? ipsDari(Iterable<NilaiRecord> rows) {
  var totalSks = 0;
  var totalMutu = 0.0;
  for (final r in rows) {
    final huruf = r.huruf;
    if (huruf == null) continue;
    final bobot = bobotHuruf[huruf];
    if (bobot == null) continue;
    totalSks += r.sks;
    totalMutu += bobot * r.sks;
  }
  if (totalSks == 0) return null;
  return totalMutu / totalSks;
}

/// SKS lulus = huruf final ada dan bukan E (`01_dashboard.md §3`).
/// Baris DRAFT belum dianggap lulus karena nilainya belum disahkan.
int sksLulus(Iterable<NilaiRecord> rows) => rows
    .where((r) => r.sudahFinal && r.huruf != null && r.huruf != 'E')
    .fold(0, (acc, r) => acc + r.sks);

/// Total SKS yang sudah dinilai (bukan E) — dipakai IPK.
double? ipkDari(Iterable<NilaiRecord> rows) => ipsDari(rows);

class RekapPresensi {
  final String kelasId;
  final int hadir;
  final int tercatat;

  const RekapPresensi({
    required this.kelasId,
    required this.hadir,
    required this.tercatat,
  });

  /// Belum dicatat dosen tidak dihitung alpha (`06_presensi_saya.md`).
  double? get persen => tercatat == 0 ? null : hadir / tercatat * 100;

  bool get kritis => persen != null && persen! < 75;
  bool get perhatian => persen != null && persen! >= 75 && persen! < 85;
}

RekapPresensi rekapPresensi(
  String kelasId,
  Iterable<PresensiRecord> rows,
) {
  var hadir = 0;
  var tercatat = 0;
  for (final r in rows) {
    if (r.kelasId != kelasId || r.status == null) continue;
    tercatat++;
    if (r.status == 'HADIR') hadir++;
  }
  return RekapPresensi(kelasId: kelasId, hadir: hadir, tercatat: tercatat);
}

bool jadwalBentrok(JadwalSlot a, JadwalSlot b) {
  if (a.hari != b.hari) return false;
  return a.jamMulai.compareTo(b.jamSelesai) < 0 &&
      b.jamMulai.compareTo(a.jamSelesai) < 0;
}

/// Validasi tambah kelas ke KRS — `03_krs.md §2`.
HasilValidasi validasiTambahKrs({
  required Kelas kandidat,
  required List<Kelas> terpilih,
  required int sksTerpilih,
  required int plafonSks,
  required GateKrs gate,
  required StatusMahasiswa statusMahasiswa,
}) {
  if (!statusMahasiswa.bisaAmbilKrs) {
    return HasilValidasi.gagal(
      'Status mahasiswa ${statusMahasiswa.label} — pengambilan KRS dikunci.',
    );
  }
  if (!gate.lolos) return HasilValidasi.gagal(gate.pesan!);
  if (terpilih.any((k) => k.id == kandidat.id)) {
    return HasilValidasi.gagal('Kelas ${kandidat.kode} sudah dipilih.');
  }
  if (terpilih.any((k) => k.kodeMk == kandidat.kodeMk)) {
    return HasilValidasi.gagal(
      'MK ${kandidat.namaMk} sudah ada di KRS (tidak boleh ganda).',
    );
  }
  if (kandidat.penuh) {
    return HasilValidasi.gagal(
      'Kelas ${kandidat.kode} penuh '
      '(${kandidat.jumlahTerdaftar}/${kandidat.kapasitas}).',
    );
  }
  if (sksTerpilih + kandidat.sks > plafonSks) {
    return HasilValidasi.gagal(
      'Melebihi plafon $plafonSks SKS '
      '(terpakai $sksTerpilih + ${kandidat.sks}).',
    );
  }
  for (final k in terpilih) {
    for (final j1 in kandidat.jadwal) {
      for (final j2 in k.jadwal) {
        if (jadwalBentrok(j1, j2)) {
          return HasilValidasi.gagal(
            'Bentrok jadwal dengan ${k.namaMk} '
            '(${hariLabel(j1.hari)} ${j1.jamMulai}).',
          );
        }
      }
    }
  }
  return const HasilValidasi.ok();
}
