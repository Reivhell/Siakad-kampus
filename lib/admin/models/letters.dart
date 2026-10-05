/// Penomoran surat + verifikasi QR (spec 15).
const romanMonths = [
  'I',
  'II',
  'III',
  'IV',
  'V',
  'VI',
  'VII',
  'VIII',
  'IX',
  'X',
  'XI',
  'XII',
];

/// Format: UUU/KODE/FTI-SIAKAD/ROMAWI/TTTT — reset tiap tahun.
String letterNumber({
  required int seq,
  required String kode,
  required int month,
  required int year,
}) {
  final uuu = seq.toString().padLeft(3, '0');
  return '$uuu/$kode/FTI-SIAKAD/${romanMonths[month - 1]}/$year';
}

/// MAX+1 per tahun terbit.
int nextLetterSeq(int year, List<(int, int)> seqYearPairs) {
  var max = 0;
  for (final (seq, y) in seqYearPairs) {
    if (y == year && seq > max) max = seq;
  }
  return max + 1;
}

enum DocStatus { valid, kadaluwarsa, dicabut, belumBerlaku }

/// Verifikasi publik: revoke > expiry > terbit.
DocStatus verifyDoc({
  required DateTime now,
  required DateTime terbit,
  required DateTime berlakuHingga,
  required bool revoked,
}) {
  if (revoked) return DocStatus.dicabut;
  if (now.isBefore(terbit)) return DocStatus.belumBerlaku;
  if (now.isAfter(berlakuHingga)) return DocStatus.kadaluwarsa;
  return DocStatus.valid;
}

/// Pre-flight: surat aktif hanya untuk mhs AKTIF (15 §7).
String? letterEligible(String statusMhs) {
  if (statusMhs != 'AKTIF') {
    return 'Penerbitan ditolak: status $statusMhs (wajib AKTIF).';
  }
  return null;
}
