/// Konversi & transfer kredit (spec 14): pola, guard, cap.
class TransferMap {
  final String asalKode;
  final String asalNama;
  final int asalSks;
  final String asalHuruf;
  final String lokalMkId;
  final String diakuiHuruf;
  final double diakuiBobot;
  const TransferMap({
    required this.asalKode,
    required this.asalNama,
    required this.asalSks,
    required this.asalHuruf,
    required this.lokalMkId,
    required this.diakuiHuruf,
    required this.diakuiBobot,
  });
}

/// Pola relasi: 1-1 | N-1 (merger) | 1-N (MBKM split).
String mappingPattern({
  required int nAsal,
  required int nLokal,
}) {
  if (nAsal == 1 && nLokal == 1) return '1-to-1';
  if (nAsal > 1 && nLokal == 1) return 'N-to-1';
  if (nAsal == 1 && nLokal > 1) return '1-to-N (MBKM)';
  return 'N-to-N';
}

/// Nilai asal D/E tidak layak diakui (14 §7).
String? guardAsalHuruf(String huruf) {
  if (huruf == 'D' || huruf == 'E') {
    return 'Nilai asal $huruf tidak layak dikonversi (min C).';
  }
  return null;
}

/// Cap regulasi: total ≤ 100 SKS S1; paket MBKM ≤ 20/semester.
String? transferCapCheck(int totalDiakui) {
  if (totalDiakui > 100) {
    return 'Total $totalDiakui SKS > 100 — wajib ≥36 SKS lokal.';
  }
  return null;
}

String? mbkmCapCheck(int paketSks) {
  if (paketSks > 20) return 'Paket MBKM $paketSks > plafon 20 SKS.';
  return null;
}

/// Rata-rata tertimbang merger N-to-1 (bobot × sks).
double mergedBobot(List<(double, int)> bobotSks) {
  var num = 0.0;
  var den = 0;
  for (final (b, s) in bobotSks) {
    num += b * s;
    den += s;
  }
  return double.parse((num / den).toStringAsFixed(2));
}

const footnoteFor = {
  'PINDAHAN': '*T',
  'ALIH_JENJANG': '*T',
  'MBKM_MAGANG': '*M',
  'MBKM_PERTUKARAN': '*M',
  'RPL': '*R',
};
