import 'package:flutter/foundation.dart';

import '../models/mahasiswa_layanan_models.dart';
import '../models/mahasiswa_models.dart';
import '../seed/mahasiswa_layanan_seed.dart';
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

  // Fitur lanjutan (P1/P2).
  final List<KurikulumMk> kurikulum;
  final List<BimbinganEntry> bimbingan;
  final List<SuratAkademik> surat;
  final List<PengajuanCuti> cuti;
  final List<BandingNilai> banding;
  final List<PengajuanKonversi> konversi;
  final Set<String> pengumumanDibaca;
  final Map<String, YudisiumPengajuan> yudisium;

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
    List<KurikulumMk>? kurikulum,
    List<BimbinganEntry>? bimbingan,
    List<SuratAkademik>? surat,
    List<PengajuanCuti>? cuti,
    List<BandingNilai>? banding,
    List<PengajuanKonversi>? konversi,
    Set<String>? pengumumanDibaca,
    Map<String, YudisiumPengajuan>? yudisium,
  }) : dispensasi = dispensasi ?? {},
       kurikulum = kurikulum ?? const [],
       bimbingan = bimbingan ?? [],
       surat = surat ?? [],
       cuti = cuti ?? [],
       banding = banding ?? [],
       konversi = konversi ?? [],
       pengumumanDibaca = pengumumanDibaca ?? <String>{},
       yudisium = yudisium ?? <String, YudisiumPengajuan>{};

  factory MahasiswaRepository.seed() => MahasiswaRepository(
    periode: seedPeriode(),
    profiles: seedProfiles(),
    kelas: seedKelas(),
    krs: seedKrs(),
    nilai: [...seedNilai(), ...seedNilaiAyu()],
    presensi: seedPresensi(),
    tagihan: seedTagihan(),
    pengumuman: seedPengumuman(),
    kurikulum: seedKurikulum(),
    bimbingan: seedBimbingan(),
    surat: seedSurat(),
    cuti: seedCuti(),
    banding: seedBanding(),
    konversi: seedKonversi(),
    pengumumanDibaca: {'PGM-01'},
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
    return krs.where((e) => e.npm == npm && e.periodeId == target).toList();
  }

  /// KRS yang masih berlaku (draft / menunggu / aktif) pada periode aktif.
  List<Kelas> kelasDipilih(String npm) =>
      krsMahasiswa(npm)
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
    final rows = krsMahasiswa(npm)
        .where((e) => e.status == StatusKrs.draft)
        .toList();
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
    final rows = krsMahasiswa(npm)
        .where((e) => e.status != StatusKrs.batal)
        .toList();
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

  List<NilaiRecord> nilaiPeriode(String npm, String periodeId) =>
      nilai.where((n) => n.npm == npm && n.periodeId == periodeId).toList()
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

  int get totalSksKurikulum =>
      kurikulum.isEmpty ? 144 : kurikulum.fold(0, (acc, mk) => acc + mk.sks);

  int sksLulusMahasiswa(String npm) => sksLulus(nilaiMahasiswa(npm));

  /// SKS tempuh = seluruh MK yang tercatat nilai/terdaftar pada periode aktif.
  int sksTempuh(String npm) {
    final rows = nilaiMahasiswa(npm);
    final kunci = {for (final r in rows) '${r.periodeId}|${r.kodeMk}'};
    final tanpaNilai = kelasDipilih(npm)
        .where((k) => !kunci.contains('${periodeAktif.id}|${k.kodeMk}'));
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
    final out = kelasDipilih(npm)
        .where(
          (k) =>
              krsMahasiswa(npm)
                  .any((e) => e.kelasId == k.id && e.status == StatusKrs.aktif),
        )
        .toList();
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

  List<Kelas> jadwalHari(String npm, int weekday) =>
      jadwalMinggu(npm)
          .where((k) => k.jadwal.any((j) => j.hari == weekday))
          .toList();

  List<RekapPresensi> rekapSemua(String npm) {
    final out = <RekapPresensi>[];
    for (final k in kelasDipilih(npm)) {
      final rows = presensi.where((r) => r.npm == npm && r.kelasId == k.id);
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

  List<Tagihan> tagihanMahasiswa(String npm) =>
      tagihan.where((t) => t.npm == npm).toList()
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

  String? updateProfil(String npm, {String? telepon, String? avatarUrl}) {
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

  // -------------------------------------------------------------------------
  // 07 — Transkrip & progress kurikulum
  // -------------------------------------------------------------------------

  /// Status setiap MK kurikulum untuk satu mahasiswa.
  ///
  /// Lulus = nilai final non-E (percobaan terbaik dipakai bila mengulang),
  /// berjalan = sedang terdaftar pada KRS periode aktif, belum = sisanya.
  List<KurikulumProgress> kurikulumProgress(String npm) {
    final terbaik = <String, NilaiRecord>{};
    for (final n in nilai) {
      if (n.npm != npm || n.huruf == null || !n.sudahFinal) continue;
      final lama = terbaik[n.kodeMk];
      if (lama == null || (lama.huruf == 'E' && n.huruf != 'E')) {
        terbaik[n.kodeMk] = n;
      }
    }
    final berjalan = {for (final k in kelasDipilih(npm)) k.kodeMk};
    return [
      for (final mk in kurikulum)
        if (terbaik.containsKey(mk.kode))
          KurikulumProgress(
            mk: mk,
            status: StatusKurikulum.lulus,
            huruf: terbaik[mk.kode]!.huruf,
          )
        else if (berjalan.contains(mk.kode))
          KurikulumProgress(mk: mk, status: StatusKurikulum.berjalan)
        else
          KurikulumProgress(mk: mk, status: StatusKurikulum.belum),
    ];
  }

  int sksKurikulumLulus(String npm) =>
      kurikulumProgress(npm)
          .where((p) => p.status == StatusKurikulum.lulus)
          .fold(0, (acc, p) => acc + p.mk.sks);

  /// Riwayat nilai per periode, terbaru dulu.
  List<TranskripPeriode> transkripPeriode(String npm) {
    final hasil = <TranskripPeriode>[];
    for (var i = 0; i < periode.length; i++) {
      final p = periode[i];
      final rows = nilaiPeriode(npm, p.id);
      if (rows.isEmpty) continue;
      hasil.add(
        TranskripPeriode(
          periodeId: p.id,
          namaPeriode: p.nama,
          semester: i + 1,
          rows: rows,
          ips: ipsDari(rows),
          sks: rows.fold(0, (acc, r) => acc + r.sks),
        ),
      );
    }
    return hasil.reversed.toList();
  }

  // -------------------------------------------------------------------------
  // 08 — Bimbingan / dosen wali
  // -------------------------------------------------------------------------

  List<BimbinganEntry> bimbinganMahasiswa(String npm) {
    final rows = bimbingan.where((b) => b.npm == npm).toList();
    rows.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return rows;
  }

  BimbinganEntry? bimbinganBerikutnya(String npm) {
    for (final b in bimbinganMahasiswa(npm)) {
      if (b.status == StatusBimbingan.diajukan ||
          b.status == StatusBimbingan.disetujui) {
        return b;
      }
    }
    return null;
  }

  String? ajukanBimbingan(String npm, String topik, {String? catatan}) {
    final p = profile(npm);
    if (p == null) return 'Profil tidak ditemukan.';
    if (p.dosenWali.trim().isEmpty) {
      return 'Dosen wali belum ditetapkan. Hubungi admin akademik.';
    }
    final err = validasiTopikBimbingan(topik);
    if (err != null) return err;
    _seq++;
    bimbingan.add(
      BimbinganEntry(
        id: 'BIM-$npm-$_seq',
        npm: npm,
        dosen: p.dosenWali,
        tanggal: DateTime.now(),
        topik: topik.trim(),
        catatan: (catatan == null || catatan.trim().isEmpty)
            ? null
            : catatan.trim(),
      ),
    );
    notifyListeners();
    return null;
  }

  // -------------------------------------------------------------------------
  // 09 — Pengumuman & kalender
  // -------------------------------------------------------------------------

  bool pengumumanSudahDibaca(String id) => pengumumanDibaca.contains(id);

  int get jumlahPengumumanBelumDibaca =>
      pengumuman.where((p) => !pengumumanDibaca.contains(p.id)).length;

  void tandaiPengumumanDibaca(String id) {
    if (pengumumanDibaca.add(id)) notifyListeners();
  }

  void tandaiSemuaPengumumanDibaca() {
    if (pengumuman.isEmpty) return;
    pengumumanDibaca.addAll(pengumuman.map((p) => p.id));
    notifyListeners();
  }

  List<KalenderEvent> get kalenderAkademik => kalenderDariPeriode(periode);

  List<KalenderEvent> eventMendatang({DateTime? now, int batas = 4}) {
    final acuan = now ?? DateTime.now();
    return kalenderAkademik
        .where((e) => !e.selesaiPada(acuan))
        .take(batas)
        .toList();
  }

  KalenderEvent? eventBerikutnya({DateTime? now}) {
    final rows = eventMendatang(now: now, batas: 1);
    return rows.isEmpty ? null : rows.first;
  }

  // -------------------------------------------------------------------------
  // 10 — Surat akademik
  // -------------------------------------------------------------------------

  List<SuratAkademik> suratMahasiswa(String npm) {
    final rows = surat.where((s) => s.npm == npm).toList();
    rows.sort((a, b) => b.diajukan.compareTo(a.diajukan));
    return rows;
  }

  String? ajukanSurat(String npm, JenisSurat jenis, String keperluan) {
    if (profile(npm) == null) return 'Profil tidak ditemukan.';
    final err = validasiKeperluanSurat(keperluan);
    if (err != null) return err;
    final duplikat = suratMahasiswa(npm)
        .any((s) => s.jenis == jenis && s.status == StatusSurat.pengajuan);
    if (duplikat) {
      return 'Masih ada pengajuan ${jenis.label} yang sedang diproses.';
    }
    _seq++;
    surat.add(
      SuratAkademik(
        id: 'SRT-$npm-$_seq',
        npm: npm,
        jenis: jenis,
        keperluan: keperluan.trim(),
        diajukan: DateTime.now(),
      ),
    );
    notifyListeners();
    return null;
  }

  String? batalkanSurat(String npm, String suratId) {
    for (final s in surat) {
      if (s.id != suratId || s.npm != npm) continue;
      if (!s.status.bisaDibatalkan) {
        return 'Hanya surat berstatus PENGAJUAN yang dapat dibatalkan.';
      }
      s.status = StatusSurat.dibatalkan;
      notifyListeners();
      return null;
    }
    return 'Surat tidak ditemukan.';
  }

  // -------------------------------------------------------------------------
  // 11 — Yudisium
  // -------------------------------------------------------------------------

  YudisiumPengajuan? yudisiumMahasiswa(String npm) => yudisium[npm];

  YudisiumCek cekYudisium(String npm) {
    final rows = nilai.where((n) => n.npm == npm).toList();
    final finalRows = rows.where((n) => n.sudahFinal && n.huruf != null);
    return YudisiumCek(
      sksLulus: sksLulus(rows),
      sksTarget: totalSksKurikulum,
      ipk: ipkDari(rows),
      adaNilaiE: finalRows.any((n) => n.huruf == 'E'),
      statusAktif: profile(npm)?.status == StatusMahasiswa.aktif,
      adaTanggungan: totalTunggakan(npm) > 0,
      pengajuan: yudisium[npm]?.status,
    );
  }

  String? ajukanYudisium(String npm) {
    final cek = cekYudisium(npm);
    if (cek.pengajuan != null) {
      return 'Pengajuan yudisium sudah ada (${cek.pengajuan!.label}).';
    }
    if (!cek.semuaTercapai) {
      return 'Belum memenuhi syarat: ${cek.kekurangan.join(', ')}.';
    }
    yudisium[npm] = YudisiumPengajuan(npm: npm, diajukan: DateTime.now());
    notifyListeners();
    return null;
  }

  // -------------------------------------------------------------------------
  // 12 — Layanan pengajuan
  // -------------------------------------------------------------------------

  List<PengajuanCuti> cutiMahasiswa(String npm) {
    final rows = cuti.where((c) => c.npm == npm).toList();
    rows.sort((a, b) => b.diajukan.compareTo(a.diajukan));
    return rows;
  }

  String? ajukanCuti(String npm, {String? periodeId, required String alasan}) {
    final p = profile(npm);
    if (p == null) return 'Profil tidak ditemukan.';
    if (p.status != StatusMahasiswa.aktif) {
      return 'Hanya mahasiswa berstatus AKTIF yang dapat mengajukan cuti.';
    }
    if (cutiMahasiswa(npm).any((c) => c.status.menunggu)) {
      return 'Masih ada pengajuan cuti yang sedang diproses.';
    }
    final err = validasiAlasan(alasan);
    if (err != null) return err;
    _seq++;
    cuti.add(
      PengajuanCuti(
        id: 'CUTI-$npm-$_seq',
        npm: npm,
        periodeId: periodeId ?? periodeAktif.id,
        alasan: alasan.trim(),
        diajukan: DateTime.now(),
      ),
    );
    notifyListeners();
    return null;
  }

  String? batalkanCuti(String npm, String cutiId) {
    for (final c in cuti) {
      if (c.id != cutiId || c.npm != npm) continue;
      if (!c.status.menunggu) {
        return 'Hanya pengajuan yang masih menunggu dapat dibatalkan.';
      }
      c.status = StatusPengajuan.dibatalkan;
      notifyListeners();
      return null;
    }
    return 'Pengajuan cuti tidak ditemukan.';
  }

  List<BandingNilai> bandingMahasiswa(String npm) {
    final rows = banding.where((b) => b.npm == npm).toList();
    rows.sort((a, b) => b.diajukan.compareTo(a.diajukan));
    return rows;
  }

  String? ajukanBanding(String npm, String kodeMk, String alasan) {
    final rows = nilai.where((n) => n.npm == npm && n.kodeMk == kodeMk);
    if (rows.isEmpty) return 'Mata kuliah tidak ditemukan pada KHS.';
    final row = rows.reduce(
      (a, b) => a.periodeId.compareTo(b.periodeId) >= 0 ? a : b,
    );
    if (!row.sudahFinal || row.huruf == null) {
      return 'Nilai belum final. Banding hanya untuk nilai yang sudah final.';
    }
    if (bandingMahasiswa(npm)
        .any((b) => b.kodeMk == kodeMk && b.status.menunggu)) {
      return 'Sudah ada banding nilai yang sedang diproses untuk MK ini.';
    }
    final err = validasiAlasan(alasan);
    if (err != null) return err;
    _seq++;
    banding.add(
      BandingNilai(
        id: 'BND-$npm-$_seq',
        npm: npm,
        kodeMk: kodeMk,
        namaMk: row.namaMk,
        alasan: alasan.trim(),
        diajukan: DateTime.now(),
      ),
    );
    notifyListeners();
    return null;
  }

  List<PengajuanKonversi> konversiMahasiswa(String npm) {
    final rows = konversi.where((k) => k.npm == npm).toList();
    rows.sort((a, b) => b.diajukan.compareTo(a.diajukan));
    return rows;
  }

  String? ajukanKonversi(
    String npm, {
    required JenisKonversi jenis,
    required String institusiAsal,
    required int sksDimohonkan,
    required String catatan,
  }) {
    if (profile(npm) == null) return 'Profil tidak ditemukan.';
    if (institusiAsal.trim().length < 3) {
      return 'Nama institusi asal minimal 3 karakter.';
    }
    final sksErr = validasiSksKonversi(sksDimohonkan);
    if (sksErr != null) return sksErr;
    final err = validasiAlasan(catatan);
    if (err != null) return err;
    _seq++;
    konversi.add(
      PengajuanKonversi(
        id: 'KONV-$npm-$_seq',
        npm: npm,
        jenis: jenis,
        institusiAsal: institusiAsal.trim(),
        sksDimohonkan: sksDimohonkan,
        catatan: catatan.trim(),
        diajukan: DateTime.now(),
      ),
    );
    notifyListeners();
    return null;
  }
}
