/// Satu sumber ambang batas seluruh role Admin.
///
/// Sebelumnya angka tersebar sebagai literal di 15 model
/// (75% di attendance, 144 di graduation + curriculum, 20 di krs +
/// curriculum + transfer, dst). Mengubah kebijakan berarti berburu
/// literal — dan pasti ada yang terlewat. Kini ubah di sini saja.
///
/// File ini tanpa import agar seluruh model bisa memakainya
/// tanpa circular-import ke [AdminRules].
abstract final class AdminThresholds {
  // ── Presensi (spec 09) ──
  static const uasMinPct = 75.0;
  static const meetingsTarget = 16;
  static const behindWeek = 10;
  static const behindRealization = 8;

  // ── Kelulusan & SKS (spec 12, 07, 04) ──
  static const sksLulusMin = 144;
  static const sksMabaPaket = 20;
  static const sksMbkmPaketMax = 20;
  static const sksTransferMax = 100;
  static const sksDMaxToleransi = 6;
  static const ipkLulusMin = 2.0;

  // ── Plafon IPS → SKS (spec 07 §4.1) ──
  static const plafonCumlaude = 24;
  static const plafonBaik = 21;
  static const plafonCukup = 18;
  static const plafonKurang = 15;
  static const plafonMin = 12;
  static const ipsCumlaude = 3.0;
  static const ipsBaik = 2.5;
  static const ipsCukup = 2.0;
  static const ipsKurang = 1.5;

  // ── Periode (spec 03 §4.2) ──
  static const periodMinDays = 60;
  static const periodMaxDays = 210;

  // ── Penjadwalan (spec 06) ──
  static const sksMinutes = 50;
  static const fridayBlackoutStart = 11 * 60 + 30;
  static const fridayBlackoutEnd = 13 * 60;

  // ── Dosen & asuhan (spec 05, 11) ──
  static const bkdMin = 12;
  static const bkdMax = 16;
  static const asuhanOverload = 45;

  // ── Civitas (spec 05) ──
  static const npmSeqMax = 999;
  static const bypassMaxHours = 24.0;
  static const bypassMinReminders = 2;

  // ── Predikat (spec 12 §3.2) ──
  static const cumlaudeIpk = 3.51;
  static const cumlaudeMaxSemester = 8;
  static const sangatMemuaskanIpk = 3.01;
  static const memuaskanIpk = 2.76;

  // ── Dashboard early-warning (spec 01 §3.3) ──
  /// Kelas < N mahasiswa = kurang peminat (evaluasi merger/batal).
  static const lowEnrollmentMax = 5;

  /// Deadline pengingat finalisasi nilai (H-7 dan H-3).
  static const gradeReminderH7 = 7;
  static const gradeReminderH3 = 3;

  /// IPS < ini = butuh bimbingan PA.
  static const atRiskIps = 2.0;

  /// Semester batas masa studi S1 (peringatan 12–14).
  static const masaStudiWarn = 12;
  static const masaStudiMax = 14;

  // ── Unlock nilai (spec 08 §3.4) ──
  static const unlockMinHours = 1;
  static const unlockMaxHours = 72;

  // ── Penilaian (spec 08 §4.1) ──
  static const scoreMin = 0.0;
  static const scoreMax = 100.0;

  /// Bobot C — ambang lulus per-MK (dipakai yudisium, prasyarat,
  /// transfer). Beda makna dengan [ipkLulusMin] (rerata kelulusan):
  /// jangan digabung meski angkanya sama — kebijakan berbeda.
  static const bobotLulusMin = 2.0;

  // ── Peringatan studi / SP (spec 11 §3.3) ──
  /// Checkpoint tengah studi: smt 6 dengan SKS < 80 → SP-2.
  static const spTengahSemester = 6;
  static const spTengahSks = 80;

  // ── Anomali audit (spec 10 §3) ──
  /// Aksi kritis di luar 06:00–22:00 = anomali jam kerja.
  static const anomaliMalamDari = 22;
  static const anomaliMalamSampai = 6;
}
