/// Model audit trail (spec 10): taksonomi, filter, anomali, diff, hash chain.
class AuditEntry {
  final String id;
  final DateTime waktu;
  final String aktor;
  final String aksi;
  final String entitas;
  final String ip;
  final Map<String, String> before;
  final Map<String, String> after;
  final String hashPrev;
  final String hash;
  const AuditEntry({
    required this.id,
    required this.waktu,
    required this.aktor,
    required this.aksi,
    required this.entitas,
    required this.ip,
    this.before = const {},
    this.after = const {},
    this.hashPrev = '',
    this.hash = '',
  });
}

/// Kategori taksonomi 10 §3.
String aksiKategori(String aksi) {
  if (aksi.startsWith('ADMIN_')) return 'Administratif';
  if (aksi.startsWith('DOSEN_')) return 'Dosen';
  if (aksi.startsWith('MAHASISWA_')) return 'Mahasiswa';
  if (aksi.startsWith('AUTH_') || aksi.startsWith('SECURITY_')) {
    return 'Keamanan';
  }
  return 'Sistem';
}

/// Anomali: aksi brute-force/unauthorized, atau jam 22–06 (di luar kerja).
bool isAnomaly(AuditEntry e) {
  if (e.aksi.contains('BRUTE_FORCE') ||
      e.aksi.contains('UNAUTHORIZED') ||
      e.aksi.contains('LOCKOUT')) {
    return true;
  }
  final h = e.waktu.hour;
  final kritis = e.aksi.contains('NILAI') ||
      e.aksi.contains('KRS') ||
      e.aksi.contains('YUDISIUM');
  return kritis && (h >= 22 || h < 6);
}

List<AuditEntry> filterAudit(
  List<AuditEntry> all, {
  String query = '',
  String aksi = 'SEMUA',
  String entitas = 'SEMUA',
}) {
  final q = query.trim().toLowerCase();
  return all.where((e) {
    if (q.isNotEmpty &&
        !e.aktor.toLowerCase().contains(q) &&
        !e.aksi.toLowerCase().contains(q) &&
        !e.id.toLowerCase().contains(q)) {
      return false;
    }
    if (aksi != 'SEMUA' && aksiKategori(e.aksi) != aksi) return false;
    if (entitas != 'SEMUA' && e.entitas != entitas) return false;
    return true;
  }).toList();
}

class DiffRow {
  final String field;
  final String before;
  final String after;
  bool get changed => before != after;
  const DiffRow(this.field, this.before, this.after);
}

/// Diff before→after (union keys, urut alfabet).
List<DiffRow> diffStates(
  Map<String, String> before,
  Map<String, String> after,
) {
  final keys = {...before.keys, ...after.keys}.toList()..sort();
  return [
    for (final k in keys)
      DiffRow(k, before[k] ?? '—', after[k] ?? '—'),
  ];
}

/// Pseudo hash chain demo (produksi: SHA-256 di DB, 10 §4.2).
String chainHash(String id, String prev) => '${id.hashCode ^ prev.hashCode}';

bool verifyChain(List<AuditEntry> ordered) {
  for (var i = 0; i < ordered.length; i++) {
    final wantPrev = i == 0 ? '' : ordered[i - 1].hash;
    if (ordered[i].hashPrev != wantPrev) return false;
    if (ordered[i].hash != chainHash(ordered[i].id, ordered[i].hashPrev)) {
      return false;
    }
  }
  return true;
}
