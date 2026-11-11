import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/advising.dart';
import 'package:siakad_kampus/admin/models/audit.dart';
import 'package:siakad_kampus/admin/models/curriculum.dart';
import 'package:siakad_kampus/admin/models/graduation.dart';
import 'package:siakad_kampus/admin/models/master_data.dart';
import 'package:siakad_kampus/admin/rules/admin_rules.dart';
import 'package:siakad_kampus/admin/rules/grade_scale.dart';

AuditEntry _log(String aksi, int hour) => AuditEntry(
      id: 't-$aksi-$hour',
      waktu: DateTime(2026, 9, 28, hour, 0),
      aktor: 'admin@kampus.ac.id',
      aksi: aksi,
      entitas: 'nilai',
      ip: '10.0.0.1',
    );

void main() {
  group('SP tunduk thresholds (11 §3.3)', () {
    test('SP-3 smt 12 tanpa proposal; aman bila ada proposal', () {
      expect(
        spLevel(
          ipsHistory: const [3.0],
          semester: 12,
          totalSks: 130,
          hasProposal: false,
        ),
        'SP-3',
      );
      expect(
        spLevel(
          ipsHistory: const [3.0],
          semester: 12,
          totalSks: 130,
          hasProposal: true,
        ),
        isNull,
      );
      expect(
        AdminRules.spLevel(
          ipsHistory: const [3.0],
          semester: 12,
          totalSks: 130,
          hasProposal: false,
        ),
        'SP-3',
      );
    });

    test('SP-2 dua smt < 2.0 + smt 6 & sks < 80', () {
      expect(
        spLevel(
          ipsHistory: const [3.0, 1.9, 1.8],
          semester: 4,
          totalSks: 60,
          hasProposal: false,
        ),
        'SP-2',
      );
      expect(
        spLevel(
          ipsHistory: const [3.0],
          semester: 6,
          totalSks: 79,
          hasProposal: false,
        ),
        'SP-2',
      );
      expect(
        spLevel(
          ipsHistory: const [3.0],
          semester: 6,
          totalSks: 80,
          hasProposal: false,
        ),
        isNull,
      );
    });

    test('SP-1 ips terakhir < 2.0 sekali', () {
      expect(
        spLevel(
          ipsHistory: const [3.0, 1.9],
          semester: 3,
          totalSks: 40,
          hasProposal: false,
        ),
        'SP-1',
      );
      expect(
        spLevel(
          ipsHistory: const [3.0, 2.5],
          semester: 3,
          totalSks: 40,
          hasProposal: false,
        ),
        isNull,
      );
    });
  });

  group('bobotLulusMin konsisten (C = 2.0 di semua modul)', () {
    test('skala tunggal: C lolos, D gagal', () {
      expect(isPassingGrade('C'), isTrue);
      expect(isPassingGrade('BC'), isTrue);
      expect(isPassingGrade('D'), isFalse);
      expect(isPassingGrade('E'), isFalse);
    });

    test('yudisium + prasyarat sepakat soal D', () {
      final r = degreeAudit(
        grades: const [
          AuditGrade(mkId: 'w', sks: 144, huruf: 'D', wajib: true),
        ],
        semesters: 8,
        libraryClear: true,
        financeClear: true,
      );
      expect(r.pass, isFalse);
      expect(r.reasons.join(' '), contains('MK wajib'));

      final v = checkPrereq(
        earnedSks: 100,
        bestGrades: const {'mk-a': 'D'},
        rules: const [
          PrereqRule(kurikulumId: 'k', mkId: 'mk-b', syaratMkId: 'mk-a'),
        ],
        targetNama: 'MK-B',
      );
      expect(v.eligible, isFalse);
      expect(v.reason, contains('minimal C'));
    });
  });

  group('Anomali malam tunduk thresholds (10 §3)', () {
    test('NILAI jam 23 anomali, jam 10 bukan; non-kritis malam bukan', () {
      expect(isAnomaly(_log('DOSEN_FINALISASI_NILAI', 23)), isTrue);
      expect(isAnomaly(_log('DOSEN_FINALISASI_NILAI', 10)), isFalse);
      expect(isAnomaly(_log('ADMIN_BUAT_KELAS', 23)), isFalse);
      expect(AdminRules.isAnomaly(_log('ADMIN_YUDISIUM', 3)), isTrue);
      expect(AdminRules.isAnomaly(_log('ADMIN_YUDISIUM', 9)), isFalse);
    });
  });

  group('Prodi lock satu pintu (03 §7)', () {
    test('isProdiKodeLocked + prodiKode sepakat', () {
      final ramai = Prodi(
        id: 'p',
        kode: '01',
        nama: 'TI',
        jenjang: 'S1',
        studentCount: 5,
      );
      final kosong = Prodi(id: 'q', kode: '02', nama: 'SI', jenjang: 'S1');
      expect(AdminRules.isProdiKodeLocked(ramai), isTrue);
      expect(AdminRules.isProdiKodeLocked(kosong), isFalse);
      expect(AdminRules.prodiKode(ramai, '01').ok, isTrue); // tak berubah
      expect(AdminRules.prodiKode(ramai, '09').ok, isFalse);
      expect(AdminRules.prodiKode(kosong, '09').ok, isTrue);
    });
  });

  group('Advisor + users via fasade', () {
    test('asuhan overload + distribute via fasade', () {
      expect(AdminRules.asuhan(45).ok, isTrue);
      expect(AdminRules.asuhan(46).ok, isFalse);
      final out = AdminRules.distribute(
        studentNpms: const ['a', 'b'],
        lecturerNidns: const ['d1'],
      );
      expect(out['d1'], ['a', 'b']);
    });
  });
}
