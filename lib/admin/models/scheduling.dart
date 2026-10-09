/// Conflict engine penjadwalan (spec 06 §4): overlap interval + kapasitas.
class KelasKuliah {
  final String id;
  String mkId;
  String kode;
  int kapasitas;
  int terdaftar;
  List<String> dosenIds;
  String leadDosenId;
  KelasKuliah({
    required this.id,
    required this.mkId,
    required this.kode,
    required this.kapasitas,
    this.terdaftar = 0,
    required this.dosenIds,
    required this.leadDosenId,
  });
}

class JadwalSlot {
  final String id;
  String kelasId;
  String ruangId;
  int hari; // 1 Senin .. 7 Minggu
  int mulai; // menit sejak 00:00
  int selesai;
  JadwalSlot({
    required this.id,
    required this.kelasId,
    required this.ruangId,
    required this.hari,
    required this.mulai,
    required this.selesai,
  });
}

/// Overlap 06 §4.1: (A.mulai < B.selesai) && (A.selesai > B.mulai).
/// Tepi bersentuhan (selesai == mulai) TIDAK bentrok.
bool intervalsOverlap(int aStart, int aEnd, int bStart, int bEnd) =>
    aStart < bEnd && aEnd > bStart;

bool sameDayOverlap(JadwalSlot a, JadwalSlot b) =>
    a.hari == b.hari &&
    intervalsOverlap(a.mulai, a.selesai, b.mulai, b.selesai);

/// Bentrok ruangan: ruang sama + hari sama + irisan waktu.
JadwalSlot? roomConflict(JadwalSlot candidate, List<JadwalSlot> existing) {
  for (final s in existing) {
    if (s.id == candidate.id) continue;
    if (s.ruangId == candidate.ruangId && sameDayOverlap(s, candidate)) {
      return s;
    }
  }
  return null;
}

/// Double-booking dosen: irisan waktu di kelas lain yg berbagi dosen.
JadwalSlot? lecturerConflict(
  JadwalSlot candidate,
  List<String> candidateDosen,
  Map<String, List<String>> dosenByKelas,
  List<JadwalSlot> existing,
) {
  for (final s in existing) {
    if (s.id == candidate.id || s.kelasId == candidate.kelasId) continue;
    if (!sameDayOverlap(s, candidate)) continue;
    final other = dosenByKelas[s.kelasId] ?? const [];
    if (candidateDosen.any(other.contains)) return s;
  }
  return null;
}

String? capacityCheck(int kapasitasKelas, int kapasitasRuang) {
  if (kapasitasKelas > kapasitasRuang) {
    return 'Kapasitas kelas ($kapasitasKelas) melebihi ruangan ($kapasitasRuang).';
  }
  return null;
}

/// Durasi minimal = SKS × 50 mnt (06 §3.3).
String? durationCheck(int sks, int mulai, int selesai) {
  final need = sks * 50;
  if (selesai - mulai < need) {
    return 'Durasi ${selesai - mulai} mnt < minimal $need mnt ($sks SKS).';
  }
  return null;
}

/// Blackout Jumat 11:30–13:00 (06 §7): warning, bukan blokir.
bool isBlackoutWarning(int hari, int mulai, int selesai) {
  if (hari != 5) return false;
  const bStart = 11 * 60 + 30;
  const bEnd = 13 * 60;
  return intervalsOverlap(mulai, selesai, bStart, bEnd);
}

/// Turunkan kapasitas ditolak bila < terdaftar (06 §7).
String? shrinkCapacityCheck(int baru, int terdaftar) {
  if (baru < terdaftar) {
    return 'Kapasitas baru ($baru) < terdaftar ($terdaftar). Pindahkan mhs dulu.';
  }
  if (baru <= 0) return 'Kapasitas harus > 0.';
  return null;
}

int toMinutes(int h, int m) => h * 60 + m;

String fmtTime(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

const dayNames = {
  1: 'Senin',
  2: 'Selasa',
  3: 'Rabu',
  4: 'Kamis',
  5: 'Jumat',
  6: 'Sabtu',
  7: 'Minggu',
};
