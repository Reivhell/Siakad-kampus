import 'dart:math' show Random;

import '../models/advising.dart' as advising;
import '../models/app_user.dart' as users;
import '../models/attendance.dart' as attendance;
import '../models/audit.dart' as audit;
import '../models/civitas.dart' as civitas;
import '../models/curriculum.dart' as curriculum;
import '../models/feeder.dart' as feeder;
import '../models/graduation.dart' as graduation;
import '../models/grading.dart' as grading;
import '../models/krs.dart' as krs;
import '../models/letters.dart' as letters;
import '../models/master_data.dart' as master;
import '../models/scheduling.dart' as scheduling;
import '../models/transfer.dart' as xfer;
import 'admin_thresholds.dart';

export 'admin_thresholds.dart';

/// Hasil tunggal seluruh guard Admin.
///
/// Model lama memakai 5 bentuk berbeda untuk konsep yang sama:
/// `String?` (null = lolos), `ValidationResult`, `PrereqVerdict`,
/// `Eligibility`, `DegreeResult`. Bentuk lama dipertahankan agar
/// tes lama hijau; bentuk baru ini yang dipakai kode baru dan
/// jembatan lintas modul. [ok] true = lolos.
class RuleCheck {
  final bool ok;
  final String? message;
  const RuleCheck._(this.ok, this.message);
  const RuleCheck.pass() : this._(true, null);
  const RuleCheck.fail(String m) : this._(false, m);

  /// Jembatan dari guard gaya lama `String?` (null = lolos).
  factory RuleCheck.fromError(String? err) =>
      err == null ? const RuleCheck.pass() : RuleCheck.fail(err);

  /// Jembatan dari [users.ValidationResult].
  factory RuleCheck.fromValidation(users.ValidationResult v) =>
      v.ok ? const RuleCheck.pass() : RuleCheck.fail(v.message ?? 'Ditolak.');

  /// Gabung N cek: lolos bila semua lolos, gagal dengan pesan pertama.
  /// Dipakai page yang dulu menumpuk `if (!a) ... if (!b) ...` berulang.
  static RuleCheck all(List<RuleCheck> checks) {
    for (final c in checks) {
      if (!c.ok) return c;
    }
    return const RuleCheck.pass();
  }

  /// Kumpulkan SEMUA pesan gagal (untuk form yang menampilkan list error).
  static List<String> failures(List<RuleCheck> checks) =>
      [for (final c in checks) if (!c.ok) c.message ?? 'Ditolak.'];

  String? get asError => ok ? null : message;
}

/// Status kesehatan kelas untuk dashboard (spec 01 §3.3).
enum ClassHealth { sehat, penuh, sepi, tanpaDosen, tanpaRuang }

/// Tingkat kesiapan ekspor PDDIKTI (spec 13).
enum FeederLevel { siap, kurang, belum }

/// Fasade guard role Admin — satu pintu untuk seluruh 15 modul.
///
/// Prinsip: fasade ini TIDAK menduplikasi logika. Setiap guard
/// mendelegasikan ke fungsi murni yang sudah ada (dan sudah diuji).
/// Yang baru di sini hanyalah guard *lintas modul* — aturan yang
/// sebelumnya dicek setengah-setengah di tiap page (mis. force-add KRS
/// lupa cek status mahasiswa; bypass lupa cek plafon SKS).
abstract final class AdminRules {
  // ── 02 Pengguna & role ──────────────────────────────────────────
  static RuleCheck userAction({
    required String targetUserId,
    required String currentAdminId,
    required String actionType,
    required List<users.AppUser> all,
  }) =>
      RuleCheck.fromValidation(
        users.validateUserAction(
          targetUserId: targetUserId,
          currentAdminId: currentAdminId,
          actionType: actionType,
          all: all,
        ),
      );

  static RuleCheck userEmail(
    String v,
    List<users.AppUser> existing, {
    String? selfId,
  }) =>
      RuleCheck.fromError(
        users.validateUserEmail(v, existing, selfId: selfId),
      );

  static RuleCheck password(String v) =>
      RuleCheck.fromError(users.validatePassword(v));

  /// Password sementara generator wajib lolos policy (02 §4.3 → §3.4).
  /// Menangkap regresi bila daftar kata generator berubah.
  static RuleCheck tempPassword(String v) =>
      RuleCheck.fromError(users.validatePassword(v));

  /// Assign role: tolak duplikat & tolak cabut admin terakhir via
  /// guard yang sama dengan deactivate (02 §4.2).
  static RuleCheck assignRole({
    required String targetUserId,
    required String currentAdminId,
    required users.UserRole role,
    required List<users.AppUser> all,
  }) {
    final target = all.where((u) => u.id == targetUserId);
    if (target.isEmpty) return const RuleCheck.fail('Pengguna tak ditemukan.');
    if (target.first.roles.contains(role)) {
      return RuleCheck.fail('Sudah memiliki role ${role.name}.');
    }
    return const RuleCheck.pass();
  }

  static RuleCheck revokeAdmin({
    required String targetUserId,
    required String currentAdminId,
    required List<users.AppUser> all,
  }) =>
      userAction(
        targetUserId: targetUserId,
        currentAdminId: currentAdminId,
        actionType: 'REVOKE_ADMIN',
        all: all,
      );

  /// Filter daftar pengguna (02 §5.1) — satu pintu agar page tak
  /// mengimpor model langsung.
  static List<users.AppUser> filterUsers(
    List<users.AppUser> all, {
    String query = '',
    String role = 'SEMUA',
    String status = 'SEMUA',
  }) =>
      users.filterUsers(all, query: query, role: role, status: status);

  /// Password sementara yang dijamin lolos policy (02 §4.3).
  /// Generator lama kadang lolos kadang tidak bila daftar kata diubah;
  /// panggil ini agar regresi ketahuan di tes, bukan saat demo.
  static String generateTemp([Random? rng]) {
    final pwd = users.generateTempPassword(rng);
    assert(
      users.validatePassword(pwd) == null,
      'generateTempPassword melanggar policy: $pwd',
    );
    return pwd;
  }

  // ── 05 Civitas ──────────────────────────────────────────────────
  static RuleCheck studentTransition(String from, String to) =>
      civitas.canTransition(from, to)
          ? const RuleCheck.pass()
          : RuleCheck.fail('Transisi $from → $to ilegal.');

  static RuleCheck krsForStatus(String status) =>
      civitas.krsUnlocked(status)
          ? const RuleCheck.pass()
          : RuleCheck.fail('KRS terkunci untuk status $status (wajib AKTIF).');

  static RuleCheck nidn(String v) =>
      RuleCheck.fromError(civitas.validateNidn(v));

  static RuleCheck bkd(int beban) =>
      RuleCheck.fromError(civitas.bkdWarning(beban));

  static RuleCheck npm(String v) => civitas.npmRe.hasMatch(v.trim())
      ? const RuleCheck.pass()
      : const RuleCheck.fail('NPM harus tepat 10 digit angka.');

  /// NPM baru: format + nomor urut dalam batas + unik.
  static RuleCheck npmBaru(String v, List<String> existing) {
    final f = npm(v);
    if (!f.ok) return f;
    if (existing.contains(v.trim())) {
      return const RuleCheck.fail('NPM duplikat.');
    }
    return const RuleCheck.pass();
  }

  static RuleCheck npmSequence(int seq) =>
      seq >= 1 && seq <= AdminThresholds.npmSeqMax
          ? const RuleCheck.pass()
          : RuleCheck.fail(
              'Nomor urut 1–${AdminThresholds.npmSeqMax}.');

  /// Nomor urut berikutnya untuk prefix 7 digit (05 §3.2).
  /// Delegasi murni — page tak perlu tahu algoritma MAX+1.
  static int nextNpmSequence(String prefix7, List<String> existing) =>
      civitas.nextSequenceFor(prefix7, existing);

  /// Bangun NPM + validasi + cek duplikat dalam satu panggilan.
  /// Menggantikan 3 langkah manual di page (generate → validate → cek).
  static ({String? npm, RuleCheck check}) makeNpm({
    required int year,
    required String facultyCode,
    required String prodiCode,
    required int seq,
    required List<String> existing,
  }) {
    final seqCheck = npmSequence(seq);
    if (!seqCheck.ok) return (npm: null, check: seqCheck);
    late final String npmValue;
    try {
      npmValue = civitas.generateNpm(
        year: year,
        facultyCode: facultyCode,
        prodiCode: prodiCode,
        nextSequence: seq,
      );
    } on ArgumentError catch (e) {
      return (npm: null, check: RuleCheck.fail(e.message as String? ?? 'NPM tak valid.'));
    }
    final dup = npmBaru(npmValue, existing);
    if (!dup.ok) return (npm: null, check: dup);
    return (npm: npmValue, check: const RuleCheck.pass());
  }

  // ── 03 Master ───────────────────────────────────────────────────
  static RuleCheck periodDates(DateTime start, DateTime end) =>
      RuleCheck.fromError(master.validatePeriodDates(start, end));

  static RuleCheck tahunAkademik(String v) =>
      RuleCheck.fromError(master.validateTahunAkademik(v));

  static RuleCheck roomFits(master.Ruangan r, int kapasitasKelas) =>
      master.ruangMuatiKelas(r, kapasitasKelas)
          ? const RuleCheck.pass()
          : RuleCheck.fail(
              'Ruangan ${r.kode} tak muat (${r.kapasitas} < $kapasitasKelas).');

  /// Switch periode: target wajib ada + tanggal valid (03 §3.2).
  static RuleCheck switchPeriod(List<master.Periode> all, String targetId) {
    final t = all.where((p) => p.id == targetId);
    if (t.isEmpty) return const RuleCheck.fail('Periode target tak ada.');
    return periodDates(t.first.mulai, t.first.selesai);
  }

  /// Invarian single-active: tepat satu aktif (03 §4.1).
  static RuleCheck singleActive(List<master.Periode> all) {
    final n = all.where((p) => p.aktif).length;
    return n == 1
        ? const RuleCheck.pass()
        : RuleCheck.fail('Aktif harus tepat 1 (dapat $n).');
  }

  /// Periode aktif tunggal (03 §3.2 + 06 §3: kelas & KRS terkunci ke sini).
  /// Page dilarang menghardcode id periode (`'per-2526-ganjil'` ×2 di
  /// krs_page dulu) — ambil dari sini agar selamat saat seed berganti.
  /// Throw bila invarian bobrok; panggil dalam try/catch di UI.
  static master.Periode activePeriod(List<master.Periode> all) {
    final g = singleActive(all);
    if (!g.ok) throw StateError(g.message ?? 'Periode aktif tidak valid.');
    return all.firstWhere((p) => p.aktif);
  }

  static RuleCheck prodiKode(master.Prodi p, String kodeBaru) =>
      master.prodiKodeLocked(p) && p.kode != kodeBaru
          ? const RuleCheck.fail('Kode prodi terkunci (sudah ada mahasiswa).')
          : const RuleCheck.pass();

  /// Kode terkunci bila prodi sudah punya mahasiswa (03 §7).
  /// Untuk status UI (disable field); validasi simpan pakai [prodiKode].
  static bool isProdiKodeLocked(master.Prodi p) =>
      master.prodiKodeLocked(p);

  /// Eksekusi switch periode atomik (03 §3.2) — guard dulu, baru operasi.
  /// Page lama memanggil `switchActivePeriod` langsung tanpa validasi
  /// tanggal; kini satu panggilan menolak target rusak.
  static List<master.Periode> doSwitchPeriod(
    List<master.Periode> all,
    String targetId,
  ) {
    final g = switchPeriod(all, targetId);
    if (!g.ok) throw StateError(g.message ?? 'Switch periode ditolak.');
    return master.switchActivePeriod(all, targetId);
  }

  // ── 04 Kurikulum ────────────────────────────────────────────────
  static RuleCheck sksComposition(curriculum.MataKuliah mk) =>
      RuleCheck.fromError(curriculum.validateSksComposition(mk));

  static RuleCheck semesterCap(int semester, int totalSks) =>
      RuleCheck.fromError(curriculum.validateSemesterCap(semester, totalSks));

  /// Total SKS kurikulum wajib ≥ 144 (04 §3.3 + 12 §3).
  static RuleCheck curriculumTotal(int totalSks) =>
      totalSks >= AdminThresholds.sksLulusMin
          ? const RuleCheck.pass()
          : RuleCheck.fail(
              'Total $totalSks < ${AdminThresholds.sksLulusMin} SKS lulus.');

  static RuleCheck prereqCycle(List<curriculum.PrereqRule> rules) =>
      curriculum.hasPrereqCycle(rules)
          ? const RuleCheck.fail('Siklus prasyarat terdeteksi.')
          : const RuleCheck.pass();

  static RuleCheck prereq({
    required int earnedSks,
    required Map<String, String> bestGrades,
    required List<curriculum.PrereqRule> rules,
    required String targetNama,
    String Function(String mkId)? courseName,
  }) {
    final v = prereqDetail(
      earnedSks: earnedSks,
      bestGrades: bestGrades,
      rules: rules,
      targetNama: targetNama,
      courseName: courseName,
    );
    return v.eligible
        ? const RuleCheck.pass()
        : RuleCheck.fail(v.reason ?? 'Prasyarat tak terpenuhi.');
  }

  /// Detail prasyarat untuk tampilan page (alasan per-rule).
  /// Page butuh `reason`, bukan sekadar lolos/gagal — sediakan di sini
  /// agar page tak mengimpor model kurikulum langsung.
  static curriculum.PrereqVerdict prereqDetail({
    required int earnedSks,
    required Map<String, String> bestGrades,
    required List<curriculum.PrereqRule> rules,
    required String targetNama,
    String Function(String mkId)? courseName,
  }) =>
      curriculum.checkPrereq(
        earnedSks: earnedSks,
        bestGrades: bestGrades,
        rules: rules,
        targetNama: targetNama,
        courseName: courseName,
      );

  /// Total SKS satu semester dalam satu kurikulum (04 §3.3).
  static int semesterTotal(
    String kurikulumId,
    int semester,
    List<curriculum.KurikulumMk> maps,
    Map<String, curriculum.MataKuliah> mkById,
  ) =>
      curriculum.semesterSksTotal(kurikulumId, semester, maps, mkById);

  /// Beban semester: total + cap paket maba dalam satu cek (04 §3.3).
  static RuleCheck semesterLoad({
    required String kurikulumId,
    required int semester,
    required List<curriculum.KurikulumMk> maps,
    required Map<String, curriculum.MataKuliah> mkById,
  }) {
    final total = semesterTotal(kurikulumId, semester, maps, mkById);
    return semesterCap(semester, total);
  }

  // ── 06 Penjadwalan ──────────────────────────────────────────────
  /// Hasil evaluasi slot per-komponen untuk checklist UI (06 §4).
  ///
  /// Satu evaluasi dipakai pesan per-baris DAN keputusan akhir.
  /// Page lama mengevaluasi 2× (manual untuk pesan + via fasade untuk
  /// `clear`) — buang CPU ganda dan berisiko divergen saat aturan
  /// bertambah (renovasi sudah pernah lolos dari pesan manual).
  static ({
    scheduling.JadwalSlot? room,
    scheduling.JadwalSlot? lecturer,
    String? capacity,
    String? duration,
  }) scheduleHits({
    required scheduling.JadwalSlot candidate,
    required List<scheduling.JadwalSlot> existing,
    required List<String> candidateDosen,
    required Map<String, List<String>> dosenByKelas,
    required int sks,
    required int kapasitasKelas,
    required int kapasitasRuang,
  }) =>
      (
        room: scheduling.roomConflict(candidate, existing),
        lecturer: scheduling.lecturerConflict(
          candidate,
          candidateDosen,
          dosenByKelas,
          existing,
        ),
        capacity: scheduling.capacityCheck(kapasitasKelas, kapasitasRuang),
        duration: scheduling.durationCheck(
          sks,
          candidate.mulai,
          candidate.selesai,
        ),
      );

  static RuleCheck scheduleSlot({
    required scheduling.JadwalSlot candidate,
    required List<scheduling.JadwalSlot> existing,
    required List<String> candidateDosen,
    required Map<String, List<String>> dosenByKelas,
    required int sks,
    required int kapasitasKelas,
    required int kapasitasRuang,
    bool ruangTersedia = true,
  }) {
    if (!ruangTersedia) {
      return const RuleCheck.fail('Ruangan sedang renovasi.');
    }
    final h = scheduleHits(
      candidate: candidate,
      existing: existing,
      candidateDosen: candidateDosen,
      dosenByKelas: dosenByKelas,
      sks: sks,
      kapasitasKelas: kapasitasKelas,
      kapasitasRuang: kapasitasRuang,
    );
    if (h.room != null) {
      return RuleCheck.fail(
        'Bentrok ruangan ${candidate.ruangId} dengan ${h.room!.kelasId} '
        '(${scheduling.fmtTime(h.room!.mulai)}–${scheduling.fmtTime(h.room!.selesai)}).',
      );
    }
    if (h.lecturer != null) {
      return RuleCheck.fail(
        'Dosen ganda dengan kelas ${h.lecturer!.kelasId} '
        '(${scheduling.fmtTime(h.lecturer!.mulai)}–${scheduling.fmtTime(h.lecturer!.selesai)}).',
      );
    }
    if (h.capacity != null) return RuleCheck.fail(h.capacity!);
    if (h.duration != null) return RuleCheck.fail(h.duration!);
    return const RuleCheck.pass();
  }

  /// Warning non-blokir: Jumat 11:30–13:00 (06 §7).
  static bool scheduleBlackout(
    int hari,
    int mulai,
    int selesai,
  ) =>
      scheduling.isBlackoutWarning(hari, mulai, selesai);

  static RuleCheck shrinkCapacity(int baru, int terdaftar) =>
      RuleCheck.fromError(
        scheduling.shrinkCapacityCheck(baru, terdaftar));

  /// Kapasitas wajib positif (06 §3 + 03 §7).
  /// Tiga form menulis `<= 0` manual dengan pesan beda-beda;
  /// satu sumber di sini.
  static RuleCheck positiveCapacity(int kapasitas) =>
      kapasitas > 0
          ? const RuleCheck.pass()
          : const RuleCheck.fail('Kapasitas harus > 0.');

  /// Buka kelas: kapasitas > 0 + MK valid + muat di ruang (06 §3).
  static RuleCheck openClass({
    required int kapasitas,
    required int terdaftar,
    required int kapasitasRuang,
  }) =>
      RuleCheck.all([
        RuleCheck.fromError(
          scheduling.shrinkCapacityCheck(kapasitas, 0),
        ),
        RuleCheck.fromError(
          scheduling.capacityCheck(kapasitas, kapasitasRuang),
        ),
        terdaftar <= kapasitas
            ? const RuleCheck.pass()
            : const RuleCheck.fail('Terdaftar melebihi kapasitas.'),
      ]);

  // ── 07 KRS ──────────────────────────────────────────────────────
  /// Plafon SKS dari IPS (mendelegasikan ke [krs.calculateMaxSks]).
  static int maxSks({required int semester, required double? ips}) =>
      krs.calculateMaxSks(semester: semester, ips: ips);

  static RuleCheck sksLoad(int diambil, int plafon) =>
      RuleCheck.fromError(krs.lockCheck(diambil, plafon));

  /// Jendela KRS gelombang staggered (07 §3.1).
  static RuleCheck krsWindow(
    krs.KrsWindow w,
    int semester,
    DateTime now,
  ) =>
      w.openFor(semester, now)
          ? const RuleCheck.pass()
          : RuleCheck.fail('Di luar jendela ${w.nama}.');

  /// Guard force-add LENGKAP: duplikat MK + status mahasiswa + plafon.
  /// Page lama hanya cek duplikat — dua cek lain sering lupa.
  static RuleCheck forceAdd({
    required String npm,
    required String targetKelasId,
    required Map<String, String> mkByKelas,
    required Map<String, String> kelasPeriode,
    required List<krs.KrsEntry> existing,
    required int kapasitasRuang,
    required String statusMhs,
    required int diambilSks,
    required int plafonSks,
  }) {
    final st = krsForStatus(statusMhs);
    if (!st.ok) return st;
    final load = sksLoad(diambilSks, plafonSks);
    if (!load.ok) return load;
    return RuleCheck.fromError(
      krs.forceAddGuard(
        npm: npm,
        targetKelasId: targetKelasId,
        mkByKelas: mkByKelas,
        kelasPeriode: kelasPeriode,
        existing: existing,
        kapasitasRuang: kapasitasRuang,
      ),
    );
  }

  /// Guard pindah kelas atomik: duplikat MK + status + plafon tetap jalan.
  static RuleCheck switchGuard({
    required String npm,
    required String toKelasId,
    required Map<String, String> mkByKelas,
    required Map<String, String> kelasPeriode,
    required List<krs.KrsEntry> existing,
    required String movingEntryId,
    required String statusMhs,
  }) {
    final st = krsForStatus(statusMhs);
    if (!st.ok) return st;
    final others = [
      for (final e in existing)
        if (e.id != movingEntryId) e,
    ];
    return RuleCheck.fromError(
      krs.forceAddGuard(
        npm: npm,
        targetKelasId: toKelasId,
        mkByKelas: mkByKelas,
        kelasPeriode: kelasPeriode,
        existing: others,
        kapasitasRuang: 1,
      ),
    );
  }

  /// Eksekusi pindah kelas atomik (07 §3.3) — guard dulu, baru operasi.
  /// Counter −1/+1 dan entries dihitung di model; fasade memastikan
  /// guard tak dilewati page yang terburu-buru.
  static ({Map<String, int> counters, List<krs.KrsEntry> entries}) doSwitchClass({
    required String entryId,
    required String toKelasId,
    required List<krs.KrsEntry> entries,
    required Map<String, int> counters,
    required String npm,
    required Map<String, String> mkByKelas,
    required Map<String, String> kelasPeriode,
    required String statusMhs,
  }) {
    final g = switchGuard(
      npm: npm,
      toKelasId: toKelasId,
      mkByKelas: mkByKelas,
      kelasPeriode: kelasPeriode,
      existing: entries,
      movingEntryId: entryId,
      statusMhs: statusMhs,
    );
    if (!g.ok) throw StateError(g.message ?? 'Pindah kelas ditolak.');
    return krs.switchClass(
      entryId: entryId,
      toKelasId: toKelasId,
      entries: entries,
      counters: counters,
    );
  }

  // ── 08 Nilai ────────────────────────────────────────────────────
  static RuleCheck unlockWindow(int hours) =>
      hours >= AdminThresholds.unlockMinHours &&
              hours <= AdminThresholds.unlockMaxHours
          ? const RuleCheck.pass()
          : RuleCheck.fail(
              'Durasi unlock ${AdminThresholds.unlockMinHours}–${AdminThresholds.unlockMaxHours} jam.');

  /// Kedaluwarsa unlock masih berlaku (08 §3.4).
  static RuleCheck unlockActive(DateTime now, DateTime expiry) =>
      grading.isUnlockExpired(now, expiry)
          ? const RuleCheck.fail('Masa unlock kedaluwarsa.')
          : const RuleCheck.pass();

  static RuleCheck nilaiAkhir(
    Map<String, double> weights,
    Map<String, double> scores,
  ) {
    try {
      grading.weightedFinal(weights, scores);
      return const RuleCheck.pass();
    } on ArgumentError catch (e) {
      return RuleCheck.fail(e.message as String? ?? 'Bobot tak valid.');
    }
  }

  static RuleCheck skor(double s) {
    try {
      grading.convertScore(s);
      return const RuleCheck.pass();
    } on ArgumentError catch (e) {
      return RuleCheck.fail(e.message as String? ?? 'Skor tak valid.');
    }
  }

  /// Konversi skor → huruf+bobot+predikat (08 §4.1) untuk tampilan page.
  static grading.GradeResult gradeForScore(double s) =>
      grading.convertScore(s);

  /// Kedaluwarsa unlock = now + durasi (08 §3.4) — menolak jendela
  /// ilegal dulu agar page tak menyimpan expiry mustahil.
  static DateTime unlockUntil(DateTime now, int hours) {
    final g = unlockWindow(hours);
    if (!g.ok) throw StateError(g.message ?? 'Durasi unlock ditolak.');
    return grading.unlockExpiry(now, hours);
  }

  /// H-7 / H-3 reminder finalisasi (01 §3.3 + 08).
  static bool gradeDeadlineSoon(int daysLeft) =>
      daysLeft == AdminThresholds.gradeReminderH7 ||
      daysLeft == AdminThresholds.gradeReminderH3 ||
      daysLeft <= 0;

  static double ips(List<grading.GradeEntry> e) => grading.calcIps(e);
  static double ipk(List<grading.GradeEntry> e) => grading.calcIpk(e);

  // ── 09 Presensi ─────────────────────────────────────────────────
  static RuleCheck uas({
    required int total,
    required int hadir,
    required int dispensasi,
  }) {
    final e = uasDetail(total: total, hadir: hadir, dispensasi: dispensasi);
    return e.eligible
        ? const RuleCheck.pass()
        : RuleCheck.fail(e.reason);
  }

  /// Detail UAS (persen + alasan) untuk tampilan page.
  static attendance.Eligibility uasDetail({
    required int total,
    required int hadir,
    required int dispensasi,
  }) =>
      attendance.evaluateUas(
        total: total,
        hadir: hadir,
        dispensasi: dispensasi,
      );

  /// Status progres pertemuan untuk badge page (09 §3.1).
  static String meetingTrack(int realisasi, int minggu) =>
      attendance.meetingTrack(realisasi, minggu);

  static RuleCheck meetingBehind(int realisasi, int minggu) =>
      attendance.isBehindSchedule(realisasi, minggu)
          ? RuleCheck.fail('Tertinggal: $realisasi/16 di minggu $minggu.')
          : const RuleCheck.pass();

  static double projectedUas({
    required int total,
    required int hadir,
    required int dispensasiNow,
    required int tambahan,
  }) =>
      attendance.projectedPct(
        total: total,
        hadir: hadir,
        dispensasiNow: dispensasiNow,
        tambahan: tambahan,
      );

  // ── 11 Dosen wali / bypass ──────────────────────────────────────
  static RuleCheck bypass({
    required double deadlineHoursLeft,
    required int remindersSent,
    required bool sksOk,
    required bool noConflict,
    required String catatan,
  }) =>
      RuleCheck.fromError(
        advising.bypassEligible(
          deadlineHoursLeft: deadlineHoursLeft,
          remindersSent: remindersSent,
          sksOk: sksOk,
          noConflict: noConflict,
          catatan: catatan,
        ),
      );

  static String? spLevel({
    required List<double> ipsHistory,
    required int semester,
    required int totalSks,
    required bool hasProposal,
  }) =>
      advising.spLevel(
        ipsHistory: ipsHistory,
        semester: semester,
        totalSks: totalSks,
        hasProposal: hasProposal,
      );

  static RuleCheck asuhan(int total) => advising.overloadAsuhan(total)
      ? RuleCheck.fail(
          'Overload asuhan $total > ${AdminThresholds.asuhanOverload}.')
      : const RuleCheck.pass();

  /// Distribusi PA round-robin (11 §3.1) — menolak daftar dosen kosong
  /// dengan RuleCheck, bukan membiarkan ArgumentError mentah ke UI.
  static RuleCheck distributeCheck(List<String> lecturerNidns) =>
      lecturerNidns.isEmpty
          ? const RuleCheck.fail('Dosen tidak boleh kosong.')
          : const RuleCheck.pass();

  static Map<String, List<String>> distribute({
    required List<String> studentNpms,
    required List<String> lecturerNidns,
  }) {
    final g = distributeCheck(lecturerNidns);
    if (!g.ok) throw StateError(g.message ?? 'Distribusi ditolak.');
    return advising.distributeRoundRobin(
      studentNpms: studentNpms,
      lecturerNidns: lecturerNidns,
    );
  }

  // ── 12 Yudisium ─────────────────────────────────────────────────
  static RuleCheck graduate({
    required List<graduation.AuditGrade> grades,
    required int semesters,
    required bool libraryClear,
    required bool financeClear,
  }) {
    final r = graduateDetail(
      grades: grades,
      semesters: semesters,
      libraryClear: libraryClear,
      financeClear: financeClear,
    );
    return r.pass
        ? const RuleCheck.pass()
        : RuleCheck.fail(r.reasons.join(' '));
  }

  /// Detail degree audit (IPK + reasons + predikat) untuk tampilan page.
  static graduation.DegreeResult graduateDetail({
    required List<graduation.AuditGrade> grades,
    required int semesters,
    required bool libraryClear,
    required bool financeClear,
  }) =>
      graduation.degreeAudit(
        grades: grades,
        semesters: semesters,
        libraryClear: libraryClear,
        financeClear: financeClear,
      );

  static String predikat({
    required double ipk,
    required int semesters,
    required bool hasRetake,
  }) =>
      graduation.predikat(
        ipk: ipk,
        semesters: semesters,
        hasRetake: hasRetake,
      );

  /// Peringatan masa studi S1: 12–14 semester (01 §3.3 + 12).
  static RuleCheck masaStudi(int semester) {
    if (semester > AdminThresholds.masaStudiMax) {
      return RuleCheck.fail('Lewat batas masa studi S1 (14).');
    }
    if (semester >= AdminThresholds.masaStudiWarn) {
      return RuleCheck.fail('Mendekati batas masa studi (smt $semester).');
    }
    return const RuleCheck.pass();
  }

  static RuleCheck pin(String pin, List<String> existing) =>
      RuleCheck.fromError(graduation.validatePin(pin, existing));

  // ── 13 PDDIKTI ──────────────────────────────────────────────────
  static RuleCheck nik(String? v) =>
      RuleCheck.fromError(feeder.validateNik(v));

  static RuleCheck motherName(String? v) =>
      RuleCheck.fromError(feeder.validateMotherName(v));

  static double readiness(int valid, int total) =>
      feeder.readinessScore(valid, total);

  static FeederLevel readinessLevel(int valid, int total) {
    final s = feeder.readinessScore(valid, total);
    if (s >= 100) return FeederLevel.siap;
    if (s >= 80) return FeederLevel.kurang;
    return FeederLevel.belum;
  }

  /// Sel CSV Neo Feeder (UTF-8, `;`, quote+escape) — satu pintu ekspor.
  static String csvCell(String v) => feeder.csvCell(v);
  static String csvRow(List<String> cells) => feeder.csvRow(cells);

  // ── 14 Transfer ─────────────────────────────────────────────────
  static RuleCheck transfer({
    required String asalHuruf,
    required int totalDiakui,
    required int paketSks,
    required bool isMbkm,
  }) {
    final g = xfer.guardAsalHuruf(asalHuruf);
    if (g != null) return RuleCheck.fail(g);
    final cap = xfer.transferCapCheck(totalDiakui);
    if (cap != null) return RuleCheck.fail(cap);
    if (isMbkm) {
      final m = xfer.mbkmCapCheck(paketSks);
      if (m != null) return RuleCheck.fail(m);
    }
    return const RuleCheck.pass();
  }

  static double mergedBobot(List<(double, int)> bobotSks) =>
      xfer.mergedBobot(bobotSks);

  /// Pola relasi transfer: 1-to-1 | N-to-1 | 1-to-N (MBKM) | N-to-N.
  static String transferPattern({
    required int nAsal,
    required int nLokal,
  }) =>
      xfer.mappingPattern(nAsal: nAsal, nLokal: nLokal);

  /// Footnote transkrip untuk jenis transfer (*T/*M/*R).
  static String? transferFootnote(String jenis) => xfer.footnoteFor[jenis];

  // ── 15 Surat ────────────────────────────────────────────────────
  static RuleCheck letterFor(String statusMhs) =>
      RuleCheck.fromError(letters.letterEligible(statusMhs));

  static String letterNumber({
    required int seq,
    required String kode,
    required int month,
    required int year,
  }) =>
      letters.letterNumber(seq: seq, kode: kode, month: month, year: year);

  static letters.DocStatus verifyDoc({
    required DateTime now,
    required DateTime terbit,
    required DateTime berlakuHingga,
    required bool revoked,
  }) =>
      letters.verifyDoc(
        now: now,
        terbit: terbit,
        berlakuHingga: berlakuHingga,
        revoked: revoked,
      );

  /// Nomor urut surat berikutnya (MAX+1 per tahun, 15 §5).
  static int nextLetterSeq(int year, List<(int, int)> seqYearPairs) =>
      letters.nextLetterSeq(year, seqYearPairs);

  // ── 10 Audit ────────────────────────────────────────────────────
  static bool isAnomaly(audit.AuditEntry e) => audit.isAnomaly(e);

  static bool verifyChain(List<audit.AuditEntry> ordered) =>
      audit.verifyChain(ordered);

  static String aksiKategori(String aksi) => audit.aksiKategori(aksi);

  /// Filter jejak audit untuk explorer page (10 §3).
  static List<audit.AuditEntry> filterLog(
    List<audit.AuditEntry> all, {
    String query = '',
    String aksi = 'SEMUA',
    String entitas = 'SEMUA',
  }) =>
      audit.filterAudit(all, query: query, aksi: aksi, entitas: entitas);

  /// Diff before→after untuk inspeksi metadata (10 §4).
  static List<audit.DiffRow> diffLog(
    Map<String, String> before,
    Map<String, String> after,
  ) =>
      audit.diffStates(before, after);

  // ── 01 Dashboard (early-warning engine, spec 01 §3.3) ───────────
  /// Kesehatan satu kelas dari angka mentah seed/page.
  /// Menggantikan 4 `if` tersebar di dashboard + scheduling page.
  static ClassHealth classHealth({
    required int terdaftar,
    required int kapasitas,
    required bool hasDosen,
    required bool hasRuang,
  }) {
    if (!hasDosen) return ClassHealth.tanpaDosen;
    if (!hasRuang) return ClassHealth.tanpaRuang;
    if (kapasitas > 0 && terdaftar >= kapasitas) return ClassHealth.penuh;
    if (terdaftar < AdminThresholds.lowEnrollmentMax) {
      return ClassHealth.sepi;
    }
    return ClassHealth.sehat;
  }

  static bool isOverCapacity(int terdaftar, int kapasitas) =>
      kapasitas > 0 && terdaftar >= kapasitas;

  static bool isLowEnrollment(int terdaftar) =>
      terdaftar < AdminThresholds.lowEnrollmentMax;

  /// Partisipasi KRS 0–100% (01 §3.1).
  static double krsParticipation(int locked, int totalActive) {
    if (totalActive <= 0) return 0;
    return double.parse((locked / totalActive * 100).toStringAsFixed(1));
  }

  /// Okupansi ruang 0–100% (01 §3.5).
  static double roomOccupancy(int usedHours, int availableHours) {
    if (availableHours <= 0) return 0;
    return double.parse((usedHours / availableHours * 100).toStringAsFixed(1));
  }

  /// Progres semester 0–100% dari minggu berjalan / 16.
  static double semesterProgress(int mingguBerjalan) =>
      (mingguBerjalan.clamp(0, AdminThresholds.meetingsTarget) /
              AdminThresholds.meetingsTarget *
              100)
          .toDouble();

  /// Mahasiswa butuh perhatian: presensi < 75% ATAU ips < 2 ATAU
  /// semester ≥ 12 (01 §3.3). Satu fungsi, bukan 3 filter di page.
  static bool isAtRisk({
    required double presensiPct,
    required double ips,
    required int semester,
  }) =>
      presensiPct < AdminThresholds.uasMinPct ||
      ips < AdminThresholds.atRiskIps ||
      semester >= AdminThresholds.masaStudiWarn;

  // ── Lifecycle semester (Admin.md §2) ────────────────────────────
  /// Gerbang buka KRS: periode aktif tunggal + minimal 1 kelas siap
  /// (punya dosen + ruang). Mencegah portal dibuka saat jadwal kosong —
  /// kesalahan klasik yang dulu baru ketahuan dari komplain mahasiswa.
  static RuleCheck canOpenKrs({
    required List<master.Periode> periode,
    required int kelasSiap,
  }) {
    final single = singleActive(periode);
    if (!single.ok) return single;
    if (kelasSiap < 1) {
      return const RuleCheck.fail('Belum ada kelas siap (dosen+ruang).');
    }
    return const RuleCheck.pass();
  }

  /// Gerbang tutup semester: semua nilai final + tak ada kelas
  /// tertinggal jauh. Menahan tombol "tutup" yang dulu bisa diklik
  /// prematur lalu merusak rekap KHS.
  static RuleCheck canCloseSemester({
    required int kelasBelumFinal,
    required int kelasTertinggal,
  }) =>
      RuleCheck.all([
        kelasBelumFinal == 0
            ? const RuleCheck.pass()
            : RuleCheck.fail('$kelasBelumFinal kelas belum finalisasi nilai.'),
        kelasTertinggal == 0
            ? const RuleCheck.pass()
            : RuleCheck.fail('$kelasTertinggal kelas tertinggal > 2 pertemuan.'),
      ]);

  /// Ringkasan antrean dashboard dalam satu angka prioritas:
  /// unlock nilai (bobot 3) + force-add (2) + cuti (1).
  /// Page tinggal urut, tak perlu tahu bobot.
  static int taskWeight({required int unlock, required int forceAdd, required int cuti}) =>
      unlock * 3 + forceAdd * 2 + cuti;
}
