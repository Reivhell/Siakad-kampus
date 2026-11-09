import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/audit.dart';
import 'package:siakad_kampus/admin/models/curriculum.dart';
import 'package:siakad_kampus/admin/models/krs.dart';
import 'package:siakad_kampus/admin/models/master_data.dart';
import 'package:siakad_kampus/admin/models/users_seed.dart';
import 'package:siakad_kampus/admin/rules/admin_rules.dart';

List<Periode> _periode({bool aktif = true}) => [
      Periode(
        id: 'p1',
        nama: 'Ganjil 2025/2026',
        tahun: '2025/2026',
        semester: 'GANJIL',
        mulai: DateTime(2025, 9, 1),
        selesai: DateTime(2026, 1, 24),
        aktif: aktif,
      ),
    ];

void main() {
  group('Users satu pintu', () {
    test('filter + generateTemp lolos policy 100x', () {
      final all = seedUsers();
      expect(AdminRules.filterUsers(all, role: 'ADMIN').length, 2);
      expect(AdminRules.filterUsers(all, query: 'tidak-ada').length, 0);
      final rng = Random(42);
      for (var i = 0; i < 100; i++) {
        final pwd = AdminRules.generateTemp(Random(rng.nextInt(1 << 32)));
        expect(AdminRules.tempPassword(pwd).ok, isTrue);
      }
      expect(AdminRules.generateTemp().length, greaterThan(8));
    });
  });

  group('NPM satu panggilan', () {
    test('makeNpm sukses + duplikat ditolak + seq liar ditolak', () {
      final ok = AdminRules.makeNpm(
        year: 2024,
        facultyCode: '100',
        prodiCode: '10',
        seq: 45,
        existing: const [],
      );
      expect(ok.check.ok, isTrue);
      expect(ok.npm, '2410010045');

      final dup = AdminRules.makeNpm(
        year: 2024,
        facultyCode: '100',
        prodiCode: '10',
        seq: 45,
        existing: const ['2410010045'],
      );
      expect(dup.check.ok, isFalse);
      expect(dup.npm, isNull);

      final liar = AdminRules.makeNpm(
        year: 2024,
        facultyCode: '100',
        prodiCode: '10',
        seq: 1000,
        existing: const [],
      );
      expect(liar.check.ok, isFalse);
      expect(AdminRules.nextNpmSequence('2410010', ['2410010045']), 46);
    });
  });

  group('Master operasi terjaga', () {
    test('doSwitchPeriod sukses + target tak ada throw', () {
      final out = AdminRules.doSwitchPeriod(_periode(aktif: true), 'p1');
      expect(out.where((p) => p.aktif).length, 1);
      expect(() => AdminRules.doSwitchPeriod(_periode(), 'pX'),
          throwsA(isA<StateError>()));
    });
  });

  group('Kurikulum semester load', () {
    test('total + cap paket maba', () {
      final mk = {
        'a': MataKuliah(
          id: 'a',
          kode: 'TI101',
          nama: 'A',
          sks: 12,
          sksTeori: 12,
          sksPraktikum: 0,
          semesterDefault: 1,
        ),
        'b': MataKuliah(
          id: 'b',
          kode: 'TI102',
          nama: 'B',
          sks: 10,
          sksTeori: 10,
          sksPraktikum: 0,
          semesterDefault: 1,
        ),
      };
      final maps = [
        KurikulumMk(kurikulumId: 'k', mkId: 'a', semester: 1),
        KurikulumMk(kurikulumId: 'k', mkId: 'b', semester: 1),
      ];
      expect(AdminRules.semesterTotal('k', 1, maps, mk), 22);
      expect(
        AdminRules.semesterLoad(
          kurikulumId: 'k',
          semester: 1,
          maps: maps,
          mkById: mk,
        ).ok,
        isFalse,
      );
      expect(
        AdminRules.semesterLoad(
          kurikulumId: 'k',
          semester: 3,
          maps: maps,
          mkById: mk,
        ).ok,
        isTrue,
      );
      // detail prasyarat tetap tersedia untuk UI
      final v = AdminRules.prereqDetail(
        earnedSks: 0,
        bestGrades: const {},
        rules: const [],
        targetNama: 'X',
      );
      expect(v.eligible, isTrue);
    });
  });

  group('KRS switch terjaga', () {
    test('doSwitchClass sukses + status CUTI throw', () {
      final entries = [
        KrsEntry(id: 'e1', npm: 'N1', kelasId: 'k1', status: 'AKTIF'),
      ];
      final ok = AdminRules.doSwitchClass(
        entryId: 'e1',
        toKelasId: 'k2',
        entries: entries,
        counters: const {'k1': 5, 'k2': 3},
        npm: 'N1',
        mkByKelas: const {'k1': 'mk-a', 'k2': 'mk-b'},
        kelasPeriode: const {'k1': 'p', 'k2': 'p'},
        statusMhs: 'AKTIF',
      );
      expect(ok.entries.first.kelasId, 'k2');
      expect(ok.counters['k1'], 4);
      expect(ok.counters['k2'], 4);
      expect(
        () => AdminRules.doSwitchClass(
          entryId: 'e1',
          toKelasId: 'k2',
          entries: entries,
          counters: const {'k1': 5},
          npm: 'N1',
          mkByKelas: const {'k1': 'mk-a', 'k2': 'mk-b'},
          kelasPeriode: const {'k1': 'p', 'k2': 'p'},
          statusMhs: 'CUTI',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Nilai detail + expiry terjaga', () {
    test('gradeForScore + unlockUntil', () {
      expect(AdminRules.gradeForScore(85).huruf, 'A');
      expect(AdminRules.gradeForScore(82).huruf, 'AB');
      final now = DateTime(2026, 1, 1, 10);
      expect(
        AdminRules.unlockUntil(now, 48),
        DateTime(2026, 1, 3, 10),
      );
      expect(() => AdminRules.unlockUntil(now, 0), throwsA(isA<StateError>()));
      expect(() => AdminRules.unlockUntil(now, 99), throwsA(isA<StateError>()));
    });
  });

  group('Presensi + yudisium detail', () {
    test('uasDetail + track + graduateDetail', () {
      final el = AdminRules.uasDetail(total: 16, hadir: 11, dispensasi: 1);
      expect(el.eligible, isTrue);
      expect(el.percentage, 75.0);
      expect(AdminRules.meetingTrack(5, 12), 'TERTINGGAL');
      expect(AdminRules.meetingTrack(12, 12), 'ON-TRACK');
      final r = AdminRules.graduateDetail(
        grades: const [],
        semesters: 8,
        libraryClear: true,
        financeClear: true,
      );
      expect(r.pass, isFalse); // 0 SKS
      expect(r.ipk, 0.0);
    });
  });

  group(' Wali distribusi terjaga', () {
    test('distribute seimbang + kosong throw', () {
      final out = AdminRules.distribute(
        studentNpms: const ['a', 'b', 'c'],
        lecturerNidns: const ['d1', 'd2'],
      );
      expect(out['d1'], ['a', 'c']);
      expect(out['d2'], ['b']);
      expect(() => AdminRules.distribute(
            studentNpms: const ['a'],
            lecturerNidns: const [],
          ), throwsA(isA<StateError>()));
    });
  });

  group('Ekspor + transfer + surat', () {
    test('csv quote-escape + pattern + footnote + nextSeq', () {
      expect(AdminRules.csvCell('a"b'), '"a""b"');
      expect(AdminRules.csvRow(['a', 'b']), '"a";"b"');
      expect(
        AdminRules.transferPattern(nAsal: 2, nLokal: 1),
        'N-to-1',
      );
      expect(AdminRules.transferFootnote('MBKM_MAGANG'), '*M');
      expect(AdminRules.transferFootnote('ANeh'), isNull);
      expect(AdminRules.nextLetterSeq(2026, [(41, 2026), (10, 2025)]), 42);
      expect(AdminRules.nextLetterSeq(2027, [(41, 2026)]), 1);
    });
  });

  group('Audit satu pintu', () {
    test('filterLog + diffLog', () {
      final all = [
        AuditEntry(
          id: '1',
          waktu: DateTime(2026, 9, 28, 10, 45),
          aktor: 'admin@kampus.ac.id',
          aksi: 'ADMIN_BUAT_KELAS',
          entitas: 'kelas',
          ip: '10.0.0.1',
          before: const {'kapasitas': '30'},
          after: const {'kapasitas': '40', 'ruang': 'A201'},
        ),
      ];
      expect(AdminRules.filterLog(all, query: 'buat').length, 1);
      expect(AdminRules.filterLog(all, query: 'tak-ada').length, 0);
      final rows = AdminRules.diffLog(all.first.before, all.first.after);
      expect(rows.length, 2); // union keys
      expect(rows.where((r) => r.changed).length, 2);
    });
  });

  group('Lifecycle semester', () {
    test('canOpenKrs: butuh single-active + kelas siap', () {
      expect(
        AdminRules.canOpenKrs(periode: _periode(), kelasSiap: 3).ok,
        isTrue,
      );
      expect(
        AdminRules.canOpenKrs(periode: _periode(), kelasSiap: 0).ok,
        isFalse,
      );
      expect(
        AdminRules.canOpenKrs(
          periode: [..._periode(), ..._periode()],
          kelasSiap: 3,
        ).ok,
        isFalse,
      );
    });

    test('canCloseSemester + taskWeight', () {
      expect(
        AdminRules.canCloseSemester(kelasBelumFinal: 0, kelasTertinggal: 0).ok,
        isTrue,
      );
      final c = AdminRules.canCloseSemester(
          kelasBelumFinal: 2, kelasTertinggal: 1);
      expect(c.ok, isFalse);
      expect(c.message, contains('2 kelas belum final'));
      expect(
        AdminRules.taskWeight(unlock: 2, forceAdd: 5, cuti: 1),
        2 * 3 + 5 * 2 + 1,
      );
    });
  });
}
