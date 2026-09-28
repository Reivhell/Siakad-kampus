/// Model + logika murni master data (spec 03 §3–§4).
class Prodi {
  final String id;
  String kode; // 2 digit, lock bila ada mahasiswa
  String nama;
  String jenjang; // D3/S1/S2/S3
  String? gelar;
  int studentCount;
  Prodi({
    required this.id,
    required this.kode,
    required this.nama,
    required this.jenjang,
    this.gelar,
    this.studentCount = 0,
  });
}

class Periode {
  final String id;
  String nama;
  String tahun; // 2025/2026
  String semester; // GANJIL/GENAP/PENDEK
  DateTime mulai;
  DateTime selesai;
  bool aktif;
  Periode({
    required this.id,
    required this.nama,
    required this.tahun,
    required this.semester,
    required this.mulai,
    required this.selesai,
    this.aktif = false,
  });
}

class Ruangan {
  final String id;
  String kode;
  String nama;
  int kapasitas;
  String gedung;
  String tipe;
  bool tersedia;
  Ruangan({
    required this.id,
    required this.kode,
    required this.nama,
    required this.kapasitas,
    required this.gedung,
    this.tipe = 'RUANG_TEORI',
    this.tersedia = true,
  });
}

final _tahunRe = RegExp(r'^\d{4}/\d{4}$');

String? validateTahunAkademik(String v) {
  if (!_tahunRe.hasMatch(v.trim())) {
    return 'Format tahun harus 2025/2026.';
  }
  final parts = v.trim().split('/');
  if (int.parse(parts[1]) != int.parse(parts[0]) + 1) {
    return 'Tahun kedua harus tahun pertama + 1.';
  }
  return null;
}

/// Validasi 03 §4.2: selesai > mulai, 60–210 hari.
String? validatePeriodDates(DateTime start, DateTime end) {
  if (end.isBefore(start)) {
    return 'Tanggal selesai tidak boleh mendahului tanggal mulai.';
  }
  final days = end.difference(start).inDays;
  if (days < 60) return 'Durasi semester minimal 60 hari kalender.';
  if (days > 210) return 'Durasi semester maksimal 210 hari (7 bulan).';
  return null;
}

/// Switch atomik single-active (03 §3.2 + §4.1): tepat satu aktif.
List<Periode> switchActivePeriod(List<Periode> all, String targetId) {
  var found = false;
  final out = [
    for (final p in all)
      Periode(
        id: p.id,
        nama: p.nama,
        tahun: p.tahun,
        semester: p.semester,
        mulai: p.mulai,
        selesai: p.selesai,
        aktif: p.id == targetId,
      ),
  ];
  for (final p in out) {
    if (p.aktif) found = true;
  }
  if (!found) throw StateError('Periode target tidak ditemukan.');
  return out;
}

/// Kode prodi di-lock bila sudah ada mahasiswa (03 §7).
bool prodiKodeLocked(Prodi p) => p.studentCount > 0;

/// Kelas valid bila muat di ruangan (03 §7).
bool ruangMuatiKelas(Ruangan r, int kapasitasKelas) =>
    r.tersedia && r.kapasitas >= kapasitasKelas;
