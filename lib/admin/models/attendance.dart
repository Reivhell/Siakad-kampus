/// Logika presensi (spec 09): eligibility 75%, status pertemuan, proyeksi.
class Eligibility {
  final bool eligible;
  final double percentage;
  final String reason;
  const Eligibility(this.eligible, this.percentage, this.reason);
}

/// Evaluator 09 §4.1 — 0 sesi = eligible 100%.
Eligibility evaluateUas({
  required int total,
  required int hadir,
  required int dispensasi,
}) {
  if (total == 0) {
    return const Eligibility(true, 100, 'Belum ada sesi — dianggap memenuhi.');
  }
  final pct = (hadir + dispensasi) / total * 100;
  final rounded = double.parse(pct.toStringAsFixed(2));
  return Eligibility(
    rounded >= 75,
    rounded,
    rounded >= 75
        ? 'Memenuhi syarat UAS (≥ 75%)'
        : 'Hanya ${pct.toStringAsFixed(1)}% — tidak berhak UAS!',
  );
}

/// Flag TERTINGGAL 09 §3.1: minggu ≥ 10 tapi realisasi < 8.
bool isBehindSchedule(int realisasi, int mingguBerjalan) =>
    mingguBerjalan >= 10 && realisasi < 8;

/// Status progres vs target linear (realisasi/16 vs minggu/16).
String meetingTrack(int realisasi, int minggu) {
  if (isBehindSchedule(realisasi, minggu)) return 'TERTINGGAL';
  if (realisasi >= minggu) return 'ON-TRACK';
  if (realisasi >= minggu - 2) return 'TERLAMBAT 1–2';
  return 'TERTINGGAL';
}

/// Proyeksi % bila dispensasi disahkan.
double projectedPct({
  required int total,
  required int hadir,
  required int dispensasiNow,
  required int tambahan,
}) {
  if (total == 0) return 100;
  return double.parse(
    ((hadir + dispensasiNow + tambahan) / total * 100).toStringAsFixed(1),
  );
}

class KelasPresensi {
  final String kelasId;
  final String kode;
  final String mkNama;
  final String dosen;
  final int realisasi; // /16
  const KelasPresensi({
    required this.kelasId,
    required this.kode,
    required this.mkNama,
    required this.dosen,
    required this.realisasi,
  });
}

class SkriningMhs {
  final String npm;
  final String nama;
  final String kelasId;
  final int total;
  final int hadir;
  int dispensasi;
  SkriningMhs({
    required this.npm,
    required this.nama,
    required this.kelasId,
    required this.total,
    required this.hadir,
    this.dispensasi = 0,
  });
}
