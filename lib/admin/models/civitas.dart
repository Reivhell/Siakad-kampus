/// Model + logika civitas (spec 05): NPM 10 digit, status machine, NIDN, BKD.
class Mahasiswa {
  final String npm;
  String nama;
  String prodiId;
  int angkatan;
  String status; // AKTIF, CUTI, LULUS, DO, NON_AKTIF, MENINGGAL
  int sks;
  double ipk;
  String? dosenWali;
  Mahasiswa({
    required this.npm,
    required this.nama,
    required this.prodiId,
    required this.angkatan,
    this.status = 'AKTIF',
    this.sks = 0,
    this.ipk = 0,
    this.dosenWali,
  });
}

class Dosen {
  final String nidn;
  String nama;
  String prodiId;
  String status; // AKTIF, TIDAK_AKTIF, TUGAS_BELAJAR
  int bebanSks;
  Dosen({
    required this.nidn,
    required this.nama,
    required this.prodiId,
    this.status = 'AKTIF',
    this.bebanSks = 0,
  });
}

final npmRe = RegExp(r'^[0-9]{10}$');
final nidnRe = RegExp(r'^[0-9]+$');

/// Generator 05 §4.1: AA + FFF + PP + UUU.
String generateNpm({
  required int year,
  required String facultyCode,
  required String prodiCode,
  required int nextSequence,
}) {
  final aa = (year % 100).toString().padLeft(2, '0');
  final fff = facultyCode.padLeft(3, '0');
  final pp = prodiCode.padLeft(2, '0');
  final uuu = nextSequence.toString().padLeft(3, '0');
  final npm = '$aa$fff$pp$uuu';
  if (!npmRe.hasMatch(npm)) {
    throw ArgumentError('NPM harus tepat 10 digit angka: $npm');
  }
  if (nextSequence < 1 || nextSequence > 999) {
    throw ArgumentError('Nomor urut 1–999.');
  }
  return npm;
}

/// MAX+1 per prefix 7 digit (05 §3.2).
int nextSequenceFor(String prefix7, List<String> existingNpms) {
  var max = 0;
  for (final n in existingNpms) {
    if (n.startsWith(prefix7) && npmRe.hasMatch(n)) {
      final seq = int.tryParse(n.substring(7)) ?? 0;
      if (seq > max) max = seq;
    }
  }
  if (max >= 999) throw StateError('Kuota urut penuh (maks 999).');
  return max + 1;
}

/// State machine 05 §3.3 — transisi legal dari tiap status.
const statusTransitions = {
  'CALON': ['AKTIF'],
  'AKTIF': ['CUTI', 'NON_AKTIF', 'LULUS', 'DO', 'MENINGGAL'],
  'CUTI': ['AKTIF'],
  'NON_AKTIF': ['AKTIF'],
  'LULUS': <String>[],
  'DO': <String>[],
  'MENINGGAL': <String>[],
};

bool canTransition(String from, String to) =>
    statusTransitions[from]?.contains(to) ?? false;

/// KRS terkunci kecuali AKTIF (05 §7).
bool krsUnlocked(String status) => status == 'AKTIF';

/// BKD 05 §3.4: ideal 12–16 SKS.
String? bkdWarning(int beban) {
  if (beban < 12) return 'Kurang beban (< 12 SKS).';
  if (beban > 16) return 'Kelebihan beban (> 16 SKS).';
  return null;
}

String? validateNidn(String v) {
  if (!nidnRe.hasMatch(v.trim())) return 'NIDN harus numerik.';
  return null;
}
