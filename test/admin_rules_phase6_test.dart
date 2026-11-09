import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/scheduling.dart';
import 'package:siakad_kampus/admin/rules/admin_rules.dart';

JadwalSlot _slot(
  String id,
  String kelas,
  String ruang,
  int hari,
  int mulai,
  int selesai,
) =>
    JadwalSlot(
      id: id,
      kelasId: kelas,
      ruangId: ruang,
      hari: hari,
      mulai: mulai,
      selesai: selesai,
    );

RuleCheck _verdict({
  required JadwalSlot cand,
  required List<JadwalSlot> existing,
  List<String> dosen = const ['d1'],
  Map<String, List<String>> byKelas = const {},
  int sks = 2,
  int kapKelas = 30,
  int kapRuang = 40,
  bool tersedia = true,
}) =>
    AdminRules.scheduleSlot(
      candidate: cand,
      existing: existing,
      candidateDosen: dosen,
      dosenByKelas: byKelas,
      sks: sks,
      kapasitasKelas: kapKelas,
      kapasitasRuang: kapRuang,
      ruangTersedia: tersedia,
    );

void main() {
  group('scheduleHits paritas dengan scheduleSlot', () {
    test('slot bersih: hits nol + verdict lolos', () {
      final cand = _slot('c', 'k2', 'r1', 2, 480, 580);
      final h = AdminRules.scheduleHits(
        candidate: cand,
        existing: [_slot('s', 'k1', 'r1', 1, 480, 580)],
        candidateDosen: const ['d2'],
        dosenByKelas: const {'k1': ['d1']},
        sks: 2,
        kapasitasKelas: 30,
        kapasitasRuang: 40,
      );
      expect(h.room, isNull);
      expect(h.lecturer, isNull);
      expect(h.capacity, isNull);
      expect(h.duration, isNull);
      expect(_verdict(cand: cand, existing: [_slot('s', 'k1', 'r1', 1, 480, 580)]).ok,
          isTrue);
    });

    test('bentrok ruang: hit terisi + verdict sebut ruangan', () {
      final existing = [_slot('s', 'k1', 'r1', 1, 480, 580)];
      final cand = _slot('c', 'k2', 'r1', 1, 500, 600);
      final h = AdminRules.scheduleHits(
        candidate: cand,
        existing: existing,
        candidateDosen: const ['d2'],
        dosenByKelas: const {'k1': ['d1']},
        sks: 2,
        kapasitasKelas: 30,
        kapasitasRuang: 40,
      );
      expect(h.room?.kelasId, 'k1');
      final v = _verdict(cand: cand, existing: existing);
      expect(v.ok, isFalse);
      expect(v.message, contains('Bentrok ruangan'));
    });

    test('dosen ganda: hit terisi + verdict sebut dosen', () {
      final existing = [_slot('s', 'k1', 'r9', 1, 480, 580)];
      final cand = _slot('c', 'k2', 'r1', 1, 500, 600);
      final h = AdminRules.scheduleHits(
        candidate: cand,
        existing: existing,
        candidateDosen: const ['d1'],
        dosenByKelas: const {'k1': ['d1']},
        sks: 2,
        kapasitasKelas: 30,
        kapasitasRuang: 40,
      );
      expect(h.room, isNull);
      expect(h.lecturer?.kelasId, 'k1');
      final v = _verdict(
        cand: cand,
        existing: existing,
        dosen: const ['d1'],
        byKelas: const {'k1': ['d1']},
      );
      expect(v.ok, isFalse);
      expect(v.message, contains('Dosen ganda'));
    });

    test('kapasitas + durasi: pesan model utuh lewat fasade', () {
      final cand = _slot('c', 'k2', 'r1', 3, 480, 500);
      final h = AdminRules.scheduleHits(
        candidate: cand,
        existing: const [],
        candidateDosen: const ['d9'],
        dosenByKelas: const {},
        sks: 3, // butuh 150 mnt, dapat 20
        kapasitasKelas: 99,
        kapasitasRuang: 40,
      );
      expect(h.capacity, contains('melebihi ruangan'));
      expect(h.duration, contains('minimal 150 mnt'));
      // kapasitas didahulukan dari durasi (urutan lama dipertahankan)
      final v = _verdict(
        cand: cand,
        existing: const [],
        dosen: const ['d9'],
        sks: 3,
        kapKelas: 99,
      );
      expect(v.ok, isFalse);
      expect(v.message, contains('melebihi ruangan'));
    });

    test('renovasi ditolak verdict; hits murni konflik', () {
      final cand = _slot('c', 'k2', 'r1', 3, 480, 580);
      final h = AdminRules.scheduleHits(
        candidate: cand,
        existing: const [],
        candidateDosen: const ['d9'],
        dosenByKelas: const {},
        sks: 2,
        kapasitasKelas: 30,
        kapasitasRuang: 40,
      );
      expect(h.room, isNull);
      final v = _verdict(cand: cand, existing: const [], tersedia: false);
      expect(v.ok, isFalse);
      expect(v.message, contains('renovasi'));
    });
  });

  group('curriculumTotal verdict header (04 §3.3)', () {
    test('144 lolos, 100 gagal dengan pesan', () {
      expect(AdminRules.curriculumTotal(144).ok, isTrue);
      final c = AdminRules.curriculumTotal(100);
      expect(c.ok, isFalse);
      expect(c.message, contains('100 < 144'));
    });
  });
}
