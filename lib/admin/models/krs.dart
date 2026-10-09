/// Logika KRS admin (spec 07): plafon IPS, force-add, switch, jendela.
class KrsEntry {
  final String id;
  String npm;
  String kelasId;
  String status; // DRAFT, MENUNGGU_APPROVAL, AKTIF, BATAL, MENGUNDURKAN_DIRI
  bool paApproved;
  KrsEntry({
    required this.id,
    required this.npm,
    required this.kelasId,
    this.status = 'DRAFT',
    this.paApproved = false,
  });
}

class KrsWindow {
  final String id;
  String nama;
  int minSemester; // gelombang staggered 07 §3.1
  int maxSemester;
  DateTime buka;
  DateTime tutup;
  KrsWindow({
    required this.id,
    required this.nama,
    required this.minSemester,
    required this.maxSemester,
    required this.buka,
    required this.tutup,
  });

  bool openFor(int semester, DateTime now) =>
      semester >= minSemester &&
      semester <= maxSemester &&
      !now.isBefore(buka) &&
      !now.isAfter(tutup);
}

/// Plafon 07 §4.1: maba (smt ≤ 2 / ips null) paket 20.
int calculateMaxSks({required int semester, required double? ips}) {
  if (semester <= 2 || ips == null) return 20;
  if (ips >= 3.00) return 24;
  if (ips >= 2.50) return 21;
  if (ips >= 2.00) return 18;
  if (ips >= 1.50) return 15;
  return 12;
}

String? lockCheck(int diambil, int plafon) {
  if (diambil > plafon) {
    return 'Total $diambil SKS melebihi plafon $plafon SKS — butuh bypass admin.';
  }
  return null;
}

/// Guard force-add 07 §3.3: tolak duplikat MK di kelas lain periode sama.
/// [mkByKelas]: kelasId -> mkId. [kelasPeriode]: kelasId -> periodeId.
String? forceAddGuard({
  required String npm,
  required String targetKelasId,
  required Map<String, String> mkByKelas,
  required Map<String, String> kelasPeriode,
  required List<KrsEntry> existing,
  required int kapasitasRuang,
}) {
  final mk = mkByKelas[targetKelasId];
  final per = kelasPeriode[targetKelasId];
  for (final e in existing) {
    if (e.npm != npm || e.status == 'BATAL') continue;
    if (mkByKelas[e.kelasId] == mk && kelasPeriode[e.kelasId] == per) {
      return 'Mahasiswa sudah terdaftar di kelas lain untuk MK ini.';
    }
  }
  if (kapasitasRuang <= 0) return 'Kapasitas ruangan tidak valid.';
  return null; // lolos: kuota kelas boleh dilampaui, fisik tidak
}

/// Switch atomik murni: pindah + counter −1/+1 (07 §3.3).
({Map<String, int> counters, List<KrsEntry> entries}) switchClass({
  required String entryId,
  required String toKelasId,
  required List<KrsEntry> entries,
  required Map<String, int> counters,
}) {
  final next = [
    for (final e in entries)
      KrsEntry(
        id: e.id,
        npm: e.npm,
        kelasId: e.id == entryId ? toKelasId : e.kelasId,
        status: e.status,
        paApproved: e.paApproved,
      ),
  ];
  final from = entries.firstWhere((e) => e.id == entryId).kelasId;
  final c = Map<String, int>.of(counters);
  c[from] = (c[from] ?? 1) - 1;
  c[toKelasId] = (c[toKelasId] ?? 0) + 1;
  return (counters: c, entries: next);
}
