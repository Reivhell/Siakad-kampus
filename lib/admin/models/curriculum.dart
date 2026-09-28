/// Model + prereq engine kurikulum (spec 04 §3–§4).
class MataKuliah {
  final String id;
  String kode;
  String nama;
  int sks;
  int sksTeori;
  int sksPraktikum;
  int semesterDefault;
  String jenis; // WAJIB_PRODI, PILIHAN, TUGAS_AKHIR, MBKM, ...
  MataKuliah({
    required this.id,
    required this.kode,
    required this.nama,
    required this.sks,
    required this.sksTeori,
    required this.sksPraktikum,
    required this.semesterDefault,
    this.jenis = 'WAJIB_PRODI',
  });
}

class Kurikulum {
  final String id;
  String nama;
  String prodiId;
  int tahun;
  int totalSksLulus;
  bool aktif;
  Kurikulum({
    required this.id,
    required this.nama,
    required this.prodiId,
    required this.tahun,
    this.totalSksLulus = 144,
    this.aktif = false,
  });
}

class KurikulumMk {
  final String kurikulumId;
  final String mkId;
  int semester; // 1..8
  String sifat; // WAJIB | PILIHAN
  KurikulumMk({
    required this.kurikulumId,
    required this.mkId,
    required this.semester,
    this.sifat = 'WAJIB',
  });
}

class PrereqRule {
  final String kurikulumId;
  final String mkId;
  final String? syaratMkId; // null bila hanya threshold SKS
  final String tipe; // HARD_PREREQUISITE | CO_REQUISITE | CREDIT_THRESHOLD
  final String minHuruf;
  final int minSks;
  const PrereqRule({
    required this.kurikulumId,
    required this.mkId,
    this.syaratMkId,
    this.tipe = 'HARD_PREREQUISITE',
    this.minHuruf = 'C',
    this.minSks = 0,
  });
}

/// CHECK sks = teori + praktikum (04 §3.1).
String? validateSksComposition(MataKuliah mk) {
  if (mk.sks < 1 || mk.sks > 10) return 'SKS harus 1–10.';
  if (mk.sks != mk.sksTeori + mk.sksPraktikum) {
    return 'SKS (${mk.sks}) harus = teori (${mk.sksTeori}) + praktikum (${mk.sksPraktikum}).';
  }
  return null;
}

/// Paket smt 1–2 maks 20 SKS (04 §3.3).
String? validateSemesterCap(int semester, int totalSks) {
  if ((semester == 1 || semester == 2) && totalSks > 20) {
    return 'Semester $semester maksimal 20 SKS paket maba.';
  }
  return null;
}

int semesterSksTotal(
  String kurikulumId,
  int semester,
  List<KurikulumMk> maps,
  Map<String, MataKuliah> mkById,
) {
  var total = 0;
  for (final m in maps) {
    if (m.kurikulumId == kurikulumId && m.semester == semester) {
      total += mkById[m.mkId]?.sks ?? 0;
    }
  }
  return total;
}

const _bobot = {'A': 4.0, 'B': 3.0, 'C': 2.0, 'D': 1.0, 'E': 0.0};

class PrereqVerdict {
  final bool eligible;
  final String? reason;
  const PrereqVerdict._(this.eligible, this.reason);
  const PrereqVerdict.eligible() : this._(true, null);
  const PrereqVerdict.ineligible(String r) : this._(false, r);
}

/// Evaluator 04 §4.2: threshold SKS + hard prereq nilai minimal.
PrereqVerdict checkPrereq({
  required int earnedSks,
  required Map<String, String> bestGrades, // mkId -> huruf
  required List<PrereqRule> rules,
  required String targetNama,
  String Function(String mkId)? courseName,
}) {
  for (final rule in rules) {
    if (rule.minSks > 0 && earnedSks < rule.minSks) {
      return PrereqVerdict.ineligible(
        'SKS kumulatif ($earnedSks) belum memenuhi minimal ${rule.minSks} untuk $targetNama.',
      );
    }
    if (rule.tipe == 'CO_REQUISITE') continue; // boleh bersamaan
    final sid = rule.syaratMkId;
    if (sid == null) continue;
    final got = bestGrades[sid];
    if (got == null) {
      final name = courseName?.call(sid) ?? sid;
      return PrereqVerdict.ineligible(
        'Belum menempuh prasyarat: $name.',
      );
    }
    final need = _bobot[rule.minHuruf] ?? 2.0;
    final have = _bobot[got] ?? 0.0;
    if (have < need) {
      final name = courseName?.call(sid) ?? sid;
      return PrereqVerdict.ineligible(
        'Nilai $name ($got) belum memenuhi minimal ${rule.minHuruf}.',
      );
    }
  }
  return const PrereqVerdict.eligible();
}

/// Deteksi siklus prasyarat (DFS) — 04 §7 circular prerequisite.
bool hasPrereqCycle(List<PrereqRule> rules) {
  final adj = <String, List<String>>{};
  for (final r in rules) {
    if (r.syaratMkId == null || r.tipe == 'CREDIT_THRESHOLD') continue;
    adj.putIfAbsent(r.mkId, () => []).add(r.syaratMkId!);
  }
  final visiting = <String>{};
  final done = <String>{};
  bool dfs(String n) {
    if (done.contains(n)) return false;
    if (!visiting.add(n)) return true;
    for (final m in adj[n] ?? const []) {
      if (dfs(m)) return true;
    }
    visiting.remove(n);
    done.add(n);
    return false;
  }

  for (final n in adj.keys) {
    if (dfs(n)) return true;
  }
  return false;
}
