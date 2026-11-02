import 'package:flutter/foundation.dart';

import '../models/mahasiswa_models.dart';
import '../seed/mahasiswa_seed.dart';

/// Repository seed-lokal untuk seluruh data mahasiswa.
///
/// Kontrak method sengaja menyerupai service kanonis (`krs_service`,
/// `nilai_service`, `jadwal_service`, `presensi_service`) supaya bisa
/// ditukar dengan implementasi Supabase tanpa mengubah halaman.
class MahasiswaRepository extends ChangeNotifier {
  final List<PeriodeAkademik> periode;
  final List<MahasiswaProfile> profiles;
  final List<Kelas> kelas;
  final List<KrsEntry> krs;
  final List<NilaiRecord> nilai;
  final List<PresensiRecord> presensi;
  final List<Tagihan> tagihan;
  final List<Pengumuman> pengumuman;

  /// Flag dispensasi UKT yang diberikan admin (fitur_admin/07).
  final Map<String, bool> dispensasi;

  int _seq = 0;

  MahasiswaRepository({
    required this.periode,
    required this.profiles,
    required this.kelas,
    required this.krs,
    required this.nilai,
    required this.presensi,
    required this.tagihan,
    required this.pengumuman,
    Map<String, bool>? dispensasi,
  }) : dispensasi = dispensasi ?? {};

  factory MahasiswaRepository.seed() => MahasiswaRepository(
    periode: seedPeriode(),
    profiles: seedProfiles(),
    kelas: seedKelas(),
    krs: seedKrs(),
    nilai: seedNilai(),
    presensi: seedPresensi(),
    tagihan: seedTagihan(),
    pengumuman: seedPengumuman(),
  );

  // -------------------------------------------------------------------------
  // Master
  // -------------------------------------------------------------------------

  PeriodeAkademik get periodeAktif =>
      periode.firstWhere((p) => p.aktif, orElse: () => periode.last);

  List<MahasiswaProfile> get semuaMahasiswa => List.unmodifiable(profiles);

  MahasiswaProfile? profile(String npm) {
    for (final p in profiles) {
      if (p.npm == npm) return p;
    }
    return null;
  }

  Kelas? kelasById(String id) {
    for (final k in kelas) {
      if (k.id == id) return k;
    }
    return null;
  }

  List<Kelas> kelasPeriode(String periodeId) =>
      kelas.where((k) => k.periodeId == periodeId).toList();

  // -------------------------------------------------------------------------
  // KRS
  // -------------------------------------------------------------------------

  List<KrsEntry> krsMahasiswa(String npm, {String? periodeId}) {
    final target = periodeId ?? periodeAktif.id;
    return krs
        .where((e) => e.npm == npm && e.periodeId == target)
        .toList();
  }

  /// KRS yang masih berlaku (draft / menunggu / aktif) pada periode aktif.
  List<Kelas> kelasDipilih(String npm) => krsMahasiswa(npm)
      .where((e) => e.status != StatusKrs.batal)
      .map((e) => kelasById(e.kelasId))
      .whereType<Kelas>()
      .toList();

  int sksDipilih(String npm) =>
      kelasDipilih(npm).fold(0, (acc, k) => acc + k.sks);

  StatusKrs? statusKrs(String npm) {
    final rows = krsMahasiswa(npm).where((e) => e.status != StatusKrs.batal);
    if (rows.isEmpty) return null;
    if (rows.any((e) => e.status == StatusKrs.aktif)) return StatusKrs.aktif;
    if (rows.any((e) => e.status == StatusKrs.menungguApproval)) {
      return StatusKrs.menungguApproval;
    }
    return StatusKrs.draft;
  }

  List<Kelas> get kelasTersedia => kelasPeriode(periodeAktif.id);

  /// Gate UKT/SPP: status mahasiswa + tagihan periode aktif.
  /// Dispensasi admin (force-add) membuka blokir meski belum lunas.
  GateKrs gate(String npm) {
    final p = profile(npm);
    if (p == null) {
      return const GateKrs.blokir('Profil mahasiswa tidak ditemukan.');
    }
    if (!p.status.bisaAmbilKrs) {
      return GateKrs.blokir(
        'Status ${p.status.label} — pengambilan KRS dikunci.',
      );
    }
    final belumLunas = tagihan
        .where(
          (t) =>
              t.npm == npm &&
              t.periodeId == periodeAktif.id &&
              t.status == TagihanStatus.belum,
        )
        .toList();
    if (belumLunas.isNotEmpty && !(dispensasi[npm] ?? false)) {
      return const GateKrs.blokir(
        'UKT/SPP periode ini belum lunas. KRS terkunci sampai pembayaran '
        'diverifikasi atau admin memberi dispensasi.',
      );
    }
    return const GateKrs.lolos();
  }

  String? tambahKrs(String npm, String kelasId) {
    final p = profile(npm);
    final kandidat = kelasById(kelasId);
    if (p == null || kandidat == null) return 'Data tidak ditemukan.';
    final hasil = validasiTambahKrs(
      kandidat: kandidat,
      terpilih: kelasDipilih(npm),
      sksTerpilih: sksDipilih(npm),
      plafonSks: plafonSks(npm),
      gate: gate(npm),
      statusMahasiswa: p.status,
    );
    if (!hasil.ok) return hasil.pesan;
    _seq++;
    kandidat.jumlahTerdaftar++;
    krs.add(
      KrsEntry(
        id: 'KRS-$npm-$_seq',
        npm: npm,
        kelasId: kelasId,
        periodeId: kandidat.periodeId,
      ),
    );
    notifyListeners();
    return null;
  }

  String? hapusKrs(String npm, String krsId) {
    KrsEntry? entry;
    for (final e in krs) {
      if (e.id == krsId) {
        entry = e;
        break;
      }
    }
    if (entry == null) return 'Baris KRS tidak ditemukan.';
    if (entry.status != StatusKrs.draft) {
      return 'Hanya baris DRAFT yang dapat dihapus.';
    }
    final k = kelasById(entry.kelasId);
    if (k != null && k.jumlahTerdaftar > 0) k.jumlahTerdaftar--;
    krs.remove(entry);
    notifyListeners();
    return null;
  }

  String? ajukanKrs(String npm) {
    final rows = krsMahasiswa(
      npm,
    ).where((e) => e.status == StatusKrs.draft).toList();
    if (rows.isEmpty) return 'Belum ada MK di draft KRS.';
    final g = gate(npm);
    if (!g.lolos) return g.pesan;
    for (final e in rows) {
      e.status = StatusKrs.menungguApproval;
    }
    notifyListeners();
    return null;
  }

  String? batalkanKrs(String npm) {
    final rows = krsMahasiswa(
      npm,
    ).where((e) => e.status != StatusKrs.batal).toList();
    if (rows.isEmpty) return 'Tidak ada KRS untuk dibatalkan.';
    for (final e in rows) {
      e.status = StatusKrs.batal;
      final k = kelasById(e.kelasId);
      if (k != null && k.jumlahTerdaftar > 0) k.jumlahTerdaftar--;
    }
    notifyListeners();
    return null;
  }

  /// Aksi admin: sahkan KRS yang menunggu approval PA.
  void setujuiKrs(String npm) {
    for (final e in krsMahasiswa(npm)) {
      if (e.status == StatusKrs.menungguApproval) {
        e.status = StatusKrs.aktif;
      }
    }
    notifyListeners();
  }

  void setDispensasi(String npm, bool value) {
    dispensasi[npm] = value;
    notifyListeners();
  }

  bool dispensasiAktif(String npm) => dispensasi[npm] ?? false;

  // -------------------------------------------------------------------------
  // Nilai & IPK
  // -------------------------------------------------------------------------

  List<NilaiRecord> nilaiMahasiswa(String npm) =>
      nilai.where((n) => n.npm == npm).toList();

  List<NilaiRecord> nilaiPeriode(String npm, String periodeId) => nilai
      .where((n) => n.npm == npm && n.periodeId == periodeId)
      .toList()
    ..sort((a, b) => a.kodeMk.compareTo(b.kodeMk));

  double? ipsPeriode(String npm, String periodeId) =>
      ipsDari(nilaiPeriode(npm, periodeId));

  /// IPS periode terakhir sebelum periode aktif (dasar plafon SKS).
  double? ipsLalu(String npm) {
    for (var i = periode.length - 1; i >= 0; i--) {
      final p = periode[i];
      if (p.id == periodeAktif.id) continue;
      final rows = nilaiPeriode(npm, p.id);
      if (rows.any((r) => r.huruf != null)) return ipsDari(rows);
    }
    return null;
  }

  double? ipk(String npm) => ipkDari(nilaiMahasiswa(npm));

  int get totalSksKurikulum => 144;

  int sksLulusMahasiswa(String npm) => sksLulus(nilaiMahasiswa(npm));

  /// SKS tempuh = seluruh MK yang tercatat nilai/terdaftar pada periode aktif.
  int sksTempuh(String npm) {
    final rows = nilaiMahasiswa(npm);
    final kunci = {for (final r in rows) '${r.periodeId}|${r.kodeMk}'};
    final tanpaNilai = kelasDipilih(
      npm,
    ).where((k) => !kunci.contains('${periodeAktif.id}|${k.kodeMk}'));
    return rows.fold(0, (acc, r) => acc + r.sks) +
        tanpaNilai.fold(0, (acc, k) => acc + k.sks);
  }

  int plafonSks(String npm) {
    final p = profile(npm);
    if (p == null) return 20;
    return maxSks(semester: p.semester, ipsLalu: ipsLalu(npm));
  }

  /// Periode yang punya nilai, terbaru dulu (periode aktif selalu ikut).
  List<PeriodeAkademik> periodeKhs(String npm) => periode.reversed
      .where(
        (p) =>
            p.id == periodeAktif.id ||
            nilai.any((n) => n.npm == npm && n.periodeId == p.id),
      )
      .toList();

  // -------------------------------------------------------------------------
  // Jadwal & presensi
  // -------------------------------------------------------------------------

  List<Kelas> jadwalMinggu(String npm) {
    final out = kelasDipilih(
      npm,
    ).where((k) => krsMahasiswa(npm).any(
      (e) => e.kelasId == k.id && e.status == StatusKrs.aktif,
    )).toList();
    out.sort((a, b) {
      final ja = a.jadwal.isEmpty ? 0 : a.jadwal.first.hari;
      final jb = b.jadwal.isEmpty ? 0 : b.jadwal.first.hari;
      if (ja != jb) return ja.compareTo(jb);
      return (a.jadwal.isEmpty ? '' : a.jadwal.first.jamMulai).compareTo(
        b.jadwal.isEmpty ? '' : b.jadwal.first.jamMulai,
      );
    });
    return out;
  }

  List<Kelas> jadwalHari(String npm, int weekday) => jadwalMinggu(
    npm,
  ).where((k) => k.jadwal.any((j) => j.hari == weekday)).toList();

  List<RekapPresensi> rekapSemua(String npm) {
    final out = <RekapPresensi>[];
    for (final k in kelasDipilih(npm)) {
      final rows = presensi.where(
        (r) => r.npm == npm && r.kelasId == k.id,
      );
      out.add(rekapPresensi(k.id, rows));
    }
    return out;
  }

  List<PresensiRecord> presensiKelas(String npm, String kelasId) {
    final rows = presensi
        .where((r) => r.npm == npm && r.kelasId == kelasId)
        .toList();
    rows.sort((a, b) => a.pertemuanKe.compareTo(b.pertemuanKe));
    return rows;
  }

  /// MK dengan kehadiran <75% — pemicu alert dashboard.
  List<Kelas> kelasPresensiKritis(String npm) {
    final kritis = <String>{};
    for (final r in rekapSemua(npm)) {
      if (r.kritis) kritis.add(r.kelasId);
    }
    return kelasDipilih(npm).where((k) => kritis.contains(k.id)).toList();
  }

  // -------------------------------------------------------------------------
  // Keuangan
  // -------------------------------------------------------------------------

  List<Tagihan> tagihanMahasiswa(String npm) => tagihan
      .where((t) => t.npm == npm)
      .toList()
    ..sort((a, b) => b.periodeId.compareTo(a.periodeId));

  Tagihan? tagihanPeriodeAktif(String npm) {
    for (final t in tagihan) {
      if (t.npm == npm && t.periodeId == periodeAktif.id) return t;
    }
    return null;
  }

  int totalTunggakan(String npm) => tagihan
      .where((t) => t.npm == npm && t.status == TagihanStatus.belum)
      .fold(0, (acc, t) => acc + t.nominal);

  void tandaiLunas(String tagihanId) {
    for (final t in tagihan) {
      if (t.id == tagihanId) {
        t.status = TagihanStatus.lunas;
        t.tanggalBayar = 'Hari ini';
      }
    }
    notifyListeners();
  }

  void tandaiBelumLunas(String tagihanId) {
    for (final t in tagihan) {
      if (t.id == tagihanId) {
        t.status = TagihanStatus.belum;
        t.tanggalBayar = null;
      }
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Profil
  // -------------------------------------------------------------------------

  String? updateProfil(
    String npm, {
    String? telepon,
    String? avatarUrl,
  }) {
    final p = profile(npm);
    if (p == null) return 'Profil tidak ditemukan.';
    if (telepon != null) {
      final t = telepon.trim();
      if (t.length < 8) return 'Nomor telepon minimal 8 karakter.';
      p.telepon = t;
    }
    if (avatarUrl != null) {
      p.avatarUrl = avatarUrl.trim().isEmpty ? null : avatarUrl.trim();
    }
    notifyListeners();
    return null;
  }
}
