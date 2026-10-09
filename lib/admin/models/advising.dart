/// Logika Dosen Wali (spec 11): round-robin, SP levels, bypass guard.
Map<String, List<String>> distributeRoundRobin({
  required List<String> studentNpms,
  required List<String> lecturerNidns,
}) {
  if (lecturerNidns.isEmpty) throw ArgumentError('Dosen tidak boleh kosong.');
  final out = {for (final n in lecturerNidns) n: <String>[]};
  for (var i = 0; i < studentNpms.length; i++) {
    out[lecturerNidns[i % lecturerNidns.length]]!.add(studentNpms[i]);
  }
  return out;
}

/// SP-1: ips < 2 pertama kali. SP-2: dua smt beruntun < 2 ATAU smt6 & sks<80.
/// SP-3: smt ≥ 12 tanpa proposal. (11 §3.3)
String? spLevel({
  required List<double> ipsHistory, // urut semester
  required int semester,
  required int totalSks,
  required bool hasProposal,
}) {
  if (semester >= 12 && !hasProposal) return 'SP-3';
  if (ipsHistory.length >= 2 &&
      ipsHistory[ipsHistory.length - 1] < 2.0 &&
      ipsHistory[ipsHistory.length - 2] < 2.0) {
    return 'SP-2';
  }
  if (semester == 6 && totalSks < 80) return 'SP-2';
  if (ipsHistory.isNotEmpty && ipsHistory.last < 2.0) return 'SP-1';
  return null;
}

/// Syarat bypass 11 §3.2: ≤24 jam + ≥2 reminder + SKS ok + no bentrok.
String? bypassEligible({
  required double deadlineHoursLeft,
  required int remindersSent,
  required bool sksOk,
  required bool noConflict,
  required String catatan,
}) {
  if (deadlineHoursLeft > 24) {
    return 'Bypass hanya bila portal tersisa ≤ 24 jam.';
  }
  if (remindersSent < 2) return 'Kirim minimal 2 reminder ke PA dulu.';
  if (!sksOk) return 'Pelanggaran plafon SKS — selesaikan dulu.';
  if (!noConflict) return 'Jadwal bentrok — selesaikan dulu.';
  if (catatan.trim().isEmpty) return 'Catatan administratif wajib.';
  return null;
}

/// Warning beban asuhan > 45 (11 §7).
bool overloadAsuhan(int total) => total > 45;
