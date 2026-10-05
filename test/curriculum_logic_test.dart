import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/curriculum.dart';
import 'package:siakad_kampus/admin/models/curriculum_seed.dart';

void main() {
  group('Validasi SKS (04 §3.1, §3.3)', () {
    test('komposisi teori+praktikum', () {
      final ok = seedMk().first;
      expect(validateSksComposition(ok), isNull);
      final bad = MataKuliah(
        id: 'x',
        kode: 'X001',
        nama: 'Rusak',
        sks: 3,
        sksTeori: 3,
        sksPraktikum: 3,
        semesterDefault: 1,
      );
      expect(validateSksComposition(bad), isNotNull);
    });
    test('paket smt 1–2 maks 20 SKS', () {
      expect(validateSemesterCap(1, 21), isNotNull);
      expect(validateSemesterCap(1, 20), isNull);
      expect(validateSemesterCap(3, 30), isNull);
    });
    test('rekap seed konsisten', () {
      final mk = {for (final m in seedMk()) m.id: m};
      expect(semesterSksTotal('k-2024', 1, seedMapping(), mk), 6);
    });
  });

  group('Prereq engine (04 §4.2)', () {
    test('SKS kurang → ineligible', () {
      final v = checkPrereq(
        earnedSks: 100,
        bestGrades: const {'mk-ti601': 'B'},
        rules: seedPrereq().where((r) => r.mkId == 'mk-ti801').toList(),
        targetNama: 'Skripsi',
      );
      expect(v.eligible, isFalse);
      expect(v.reason, contains('120'));
    });
    test('prasyarat belum ditempuh → ineligible', () {
      final v = checkPrereq(
        earnedSks: 130,
        bestGrades: const {},
        rules: const [
          PrereqRule(
            kurikulumId: 'k',
            mkId: 't',
            syaratMkId: 'mk-ti101',
            minHuruf: 'C',
          ),
        ],
        targetNama: 'Struktur Data',
        courseName: (_) => 'Algoritma',
      );
      expect(v.eligible, isFalse);
      expect(v.reason, contains('Algoritma'));
    });
    test('nilai di bawah minimal → ineligible; co-req dilewati', () {
      final low = checkPrereq(
        earnedSks: 130,
        bestGrades: const {'mk-ti101': 'D'},
        rules: const [
          PrereqRule(
            kurikulumId: 'k',
            mkId: 't',
            syaratMkId: 'mk-ti101',
            minHuruf: 'C',
          ),
        ],
        targetNama: 'X',
      );
      expect(low.eligible, isFalse);
      final co = checkPrereq(
        earnedSks: 0,
        bestGrades: const {},
        rules: const [
          PrereqRule(
            kurikulumId: 'k',
            mkId: 't',
            syaratMkId: 'mk-x',
            tipe: 'CO_REQUISITE',
          ),
        ],
        targetNama: 'X',
      );
      expect(co.eligible, isTrue);
    });
    test('lengkap → eligible', () {
      final v = checkPrereq(
        earnedSks: 130,
        bestGrades: const {'mk-ti601': 'B'},
        rules: seedPrereq().where((r) => r.mkId == 'mk-ti801').toList(),
        targetNama: 'Skripsi',
      );
      expect(v.eligible, isTrue);
    });
  });

  group('Cycle detection (04 §7)', () {
    test('rantai lurus aman, siklus tertangkap', () {
      expect(hasPrereqCycle(seedPrereq()), isFalse);
      const cyc = [
        PrereqRule(kurikulumId: 'k', mkId: 'a', syaratMkId: 'b'),
        PrereqRule(kurikulumId: 'k', mkId: 'b', syaratMkId: 'a'),
      ];
      expect(hasPrereqCycle(cyc), isTrue);
    });
  });
}
