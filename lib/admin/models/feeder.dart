/// Pre-flight PDDIKTI + CSV Neo Feeder (spec 13).
class FeederIssue {
  final String category;
  final String id;
  final String name;
  final String issue;
  final String action;
  const FeederIssue(this.category, this.id, this.name, this.issue, this.action);
}

final _nikRe = RegExp(r'^[0-9]{16}$');

String? validateNik(String? nik) {
  if (nik == null || !_nikRe.hasMatch(nik)) {
    return 'NIK wajib 16 digit angka.';
  }
  return null;
}

String? validateMotherName(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty || t == '-' || t == '.') {
    return 'Nama ibu kandung wajib valid.';
  }
  return null;
}

/// CSV Neo Feeder: UTF-8, separator ';', teks di-quote + escape "".
String csvCell(String v) => '"${v.replaceAll('"', '""')}"';

String csvRow(List<String> cells) =>
    cells.map(csvCell).join(';');

double readinessScore(int valid, int total) {
  if (total == 0) return 100;
  return double.parse((valid / total * 100).toStringAsFixed(1));
}
