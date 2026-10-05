/// Logika penilaian (spec 08): konversi 7-tier, NA, IPS/IPK, unlock.
class GradeResult {
  final String huruf;
  final double bobot;
  final String predikat;
  const GradeResult(this.huruf, this.bobot, this.predikat);
}

/// Konversi 08 §4.1 — batas inklusif bawah tiap tier.
GradeResult convertScore(double s) {
  if (s < 0 || s > 100) throw ArgumentError('Skor 0–100.');
  if (s >= 85) return const GradeResult('A', 4.0, 'Sangat Baik');
  if (s >= 80) return const GradeResult('AB', 3.5, 'Antara Sangat Baik dan Baik');
  if (s >= 75) return const GradeResult('B', 3.0, 'Baik');
  if (s >= 70) return const GradeResult('BC', 2.5, 'Cukup Baik');
  if (s >= 65) return const GradeResult('C', 2.0, 'Cukup');
  if (s >= 50) return const GradeResult('D', 1.0, 'Kurang');
  return const GradeResult('E', 0.0, 'Tidak Lulus');
}

/// NA 08 §3.2 — bobot wajib total 100%.
double weightedFinal(Map<String, double> weights, Map<String, double> scores) {
  final total = weights.values.fold(0.0, (a, b) => a + b);
  if ((total - 100).abs() > 0.001) {
    throw ArgumentError('Total bobot harus 100% (dapat $total).');
  }
  var na = 0.0;
  weights.forEach((k, w) {
    final s = scores[k] ?? 0;
    if (s < 0 || s > 100) throw ArgumentError('Skor $k 0–100.');
    na += w / 100 * s;
  });
  return double.parse(na.toStringAsFixed(2));
}

class GradeEntry {
  final String mkId;
  final int sks;
  final double bobot;
  const GradeEntry(this.mkId, this.sks, this.bobot);
}

/// IPS = Σ(sks×bobot)/Σsks (08 §3.3).
double calcIps(List<GradeEntry> entries) {
  if (entries.isEmpty) return 0;
  var num = 0.0;
  var den = 0;
  for (final e in entries) {
    num += e.sks * e.bobot;
    den += e.sks;
  }
  return double.parse((num / den).toStringAsFixed(2));
}

/// IPK best-grade: tiap mkId hanya bobot tertinggi (08 §7 retake).
double calcIpk(List<GradeEntry> entries) {
  final best = <String, GradeEntry>{};
  for (final e in entries) {
    final cur = best[e.mkId];
    if (cur == null || e.bobot > cur.bobot) best[e.mkId] = e;
  }
  return calcIps(best.values.toList());
}

/// Unlock 08 §3.4: kedaluwarsa = now + durasi jam.
DateTime unlockExpiry(DateTime now, int hours) =>
    now.add(Duration(hours: hours));

bool isUnlockExpired(DateTime now, DateTime expiry) =>
    !now.isBefore(expiry);
