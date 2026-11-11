import '../rules/admin_thresholds.dart';
import '../rules/grade_scale.dart';

/// Degree audit + predikat (spec 12 §3–§4).
class AuditGrade {
  final String mkId;
  final int sks;
  final String huruf; // A..E
  final bool wajibNasional;
  final bool wajib;
  final bool isRetake;
  const AuditGrade({
    required this.mkId,
    required this.sks,
    required this.huruf,
    this.wajibNasional = false,
    this.wajib = false,
    this.isRetake = false,
  });
}

/// Bobot nilai: tabel tunggal [gradeBobot] (dulu salinan lokal 7-tier).
const _bobotAudit = gradeBobot;

class DegreeResult {
  final bool pass;
  final List<String> reasons;
  final double ipk;
  final String predikat;
  const DegreeResult(this.pass, this.reasons, this.ipk, this.predikat);
}

/// Predikat 12 §3.2 deterministik.
String predikat({
  required double ipk,
  required int semesters,
  required bool hasRetake,
}) {
  if (ipk >= AdminThresholds.cumlaudeIpk &&
      semesters <= AdminThresholds.cumlaudeMaxSemester &&
      !hasRetake) {
    return 'DENGAN PUJIAN (CUM LAUDE)';
  }
  if (ipk >= AdminThresholds.sangatMemuaskanIpk ||
      (ipk >= AdminThresholds.cumlaudeIpk &&
          semesters > AdminThresholds.cumlaudeMaxSemester)) {
    return 'SANGAT MEMUASKAN';
  }
  if (ipk >= AdminThresholds.memuaskanIpk) return 'MEMUASKAN';
  return 'CUKUP';
}

DegreeResult degreeAudit({
  required List<AuditGrade> grades,
  required int semesters,
  required bool libraryClear,
  required bool financeClear,
  int minSks = AdminThresholds.sksLulusMin,
}) {
  final reasons = <String>[];
  final lulus = grades.where((g) => g.huruf != 'E').toList();
  final sks = lulus.fold(0, (a, g) => a + g.sks);
  if (sks < minSks) reasons.add('SKS lulus $sks < $minSks.');
  if (grades.any((g) => g.huruf == 'E')) {
    reasons.add('Masih ada nilai E.');
  }
  final dSks = grades
      .where((g) => g.huruf == 'D')
      .fold(0, (a, g) => a + g.sks);
  if (dSks > AdminThresholds.sksDMaxToleransi) {
    reasons.add(
      'Nilai D $dSks SKS > toleransi ${AdminThresholds.sksDMaxToleransi}.',
    );
  }
  if (grades.any(
    (g) =>
        g.wajibNasional &&
        (_bobotAudit[g.huruf] ?? 0) < AdminThresholds.bobotLulusMin,
  )) {
    reasons.add('MK wajib nasional < C.');
  }
  if (grades.any(
    (g) => (g.wajib) && (_bobotAudit[g.huruf] ?? 0) < AdminThresholds.bobotLulusMin,
  )) {
    reasons.add('MK wajib / TA < C.');
  }
  var num = 0.0;
  var den = 0;
  for (final g in grades) {
    num += g.sks * (_bobotAudit[g.huruf] ?? 0);
    den += g.sks;
  }
  final ipk = den == 0 ? 0.0 : double.parse((num / den).toStringAsFixed(2));
  if (ipk < AdminThresholds.ipkLulusMin) {
    reasons.add('IPK $ipk < ${AdminThresholds.ipkLulusMin.toStringAsFixed(2)}.');
  }
  if (!libraryClear) reasons.add('Belum bebas pustaka.');
  if (!financeClear) reasons.add('Tunggakan keuangan.');
  final retake = grades.any((g) => g.isRetake);
  return DegreeResult(
    reasons.isEmpty,
    reasons,
    ipk,
    predikat(ipk: ipk, semesters: semesters, hasRetake: retake),
  );
}

/// PIN unik + format digit (12 §7).
String? validatePin(String pin, List<String> existing) {
  if (!RegExp(r'^[0-9]+$').hasMatch(pin)) return 'PIN harus numerik.';
  if (existing.contains(pin)) return 'PIN duplikat — cacat hukum.';
  return null;
}
