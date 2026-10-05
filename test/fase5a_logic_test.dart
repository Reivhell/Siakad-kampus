import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/advising.dart';
import 'package:siakad_kampus/admin/models/graduation.dart';

void main() {
  group('Round-robin (11 §4.1)', () {
    test('120 → 4 dosen @ 30 bergilir', () {
      final d = distributeRoundRobin(
        studentNpms: List.generate(120, (i) => 'N$i'),
        lecturerNidns: const ['A', 'B', 'C', 'D'],
      );
      expect(d.values.every((v) => v.length == 30), isTrue);
      expect(d['A']!.first, 'N0');
      expect(d['B']!.first, 'N1');
      expect(d['D']!.last, 'N119');
    });
    test('dosen kosong lempar', () {
      expect(
        () => distributeRoundRobin(studentNpms: ['N1'], lecturerNidns: []),
        throwsArgumentError,
      );
    });
    test('overload > 45', () {
      expect(overloadAsuhan(46), isTrue);
      expect(overloadAsuhan(45), isFalse);
    });
  });

  group('SP levels (11 §3.3)', () {
    test('SP-1 / SP-2 beruntun / SP-2 smt6 / SP-3', () {
      expect(
        spLevel(ipsHistory: [1.9], semester: 3, totalSks: 40, hasProposal: false),
        'SP-1',
      );
      expect(
        spLevel(
          ipsHistory: [1.9, 1.8],
          semester: 4,
          totalSks: 60,
          hasProposal: false,
        ),
        'SP-2',
      );
      expect(
        spLevel(
          ipsHistory: [3.0],
          semester: 6,
          totalSks: 70,
          hasProposal: false,
        ),
        'SP-2',
      );
      expect(
        spLevel(
          ipsHistory: [3.2],
          semester: 12,
          totalSks: 130,
          hasProposal: false,
        ),
        'SP-3',
      );
      expect(
        spLevel(
          ipsHistory: [3.2],
          semester: 5,
          totalSks: 100,
          hasProposal: true,
        ),
        isNull,
      );
    });
  });

  group('Bypass guard (11 §3.2)', () {
    test('tolak bila >24 jam / reminder kurang / tanpa catatan', () {
      expect(
        bypassEligible(
          deadlineHoursLeft: 48,
          remindersSent: 2,
          sksOk: true,
          noConflict: true,
          catatan: 'x',
        ),
        isNotNull,
      );
      expect(
        bypassEligible(
          deadlineHoursLeft: 12,
          remindersSent: 1,
          sksOk: true,
          noConflict: true,
          catatan: 'x',
        ),
        isNotNull,
      );
      expect(
        bypassEligible(
          deadlineHoursLeft: 12,
          remindersSent: 2,
          sksOk: true,
          noConflict: true,
          catatan: ' ',
        ),
        isNotNull,
      );
      expect(
        bypassEligible(
          deadlineHoursLeft: 12,
          remindersSent: 2,
          sksOk: true,
          noConflict: true,
          catatan: 'Izin Kaprodi',
        ),
        isNull,
      );
    });
  });

  group('Degree audit (12 §4.1)', () {
    List<AuditGrade> okGrades() => [
      const AuditGrade(mkId: 'm1', sks: 3, huruf: 'A', wajib: true),
      const AuditGrade(mkId: 'm2', sks: 3, huruf: 'B', wajib: true),
      const AuditGrade(mkId: 'm3', sks: 138, huruf: 'A'),
    ];
    test('lolos + cumlaude tepat waktu', () {
      final r = degreeAudit(
        grades: okGrades(),
        semesters: 8,
        libraryClear: true,
        financeClear: true,
      );
      expect(r.pass, isTrue);
      expect(r.predikat, contains('PUJIAN'));
    });
    test('kurang SKS / ada E / D > 6 / wajib < C / ipk / clearance', () {
      expect(
        degreeAudit(
          grades: [const AuditGrade(mkId: 'm', sks: 140, huruf: 'B')],
          semesters: 10,
          libraryClear: true,
          financeClear: true,
        ).pass,
        isFalse,
      );
      expect(
        degreeAudit(
          grades: [
            const AuditGrade(mkId: 'm1', sks: 144, huruf: 'E'),
          ],
          semesters: 8,
          libraryClear: true,
          financeClear: true,
        ).pass,
        isFalse,
      );
      expect(
        degreeAudit(
          grades: [
            const AuditGrade(mkId: 'm1', sks: 9, huruf: 'D'),
            const AuditGrade(mkId: 'm2', sks: 135, huruf: 'B'),
          ],
          semesters: 8,
          libraryClear: true,
          financeClear: true,
        ).pass,
        isFalse,
      );
      expect(
        degreeAudit(
          grades: [
            const AuditGrade(
              mkId: 'agama',
              sks: 2,
              huruf: 'D',
              wajibNasional: true,
            ),
            const AuditGrade(mkId: 'm2', sks: 142, huruf: 'B'),
          ],
          semesters: 8,
          libraryClear: true,
          financeClear: true,
        ).pass,
        isFalse,
      );
      expect(
        degreeAudit(
          grades: okGrades(),
          semesters: 8,
          libraryClear: false,
          financeClear: true,
        ).pass,
        isFalse,
      );
    });
    test('predikat matrix', () {
      expect(
        predikat(ipk: 3.88, semesters: 8, hasRetake: false),
        contains('PUJIAN'),
      );
      expect(
        predikat(ipk: 3.88, semesters: 10, hasRetake: false),
        'SANGAT MEMUASKAN',
      );
      expect(predikat(ipk: 3.2, semesters: 8, hasRetake: true), 'SANGAT MEMUASKAN');
      expect(predikat(ipk: 2.8, semesters: 8, hasRetake: false), 'MEMUASKAN');
      expect(predikat(ipk: 2.5, semesters: 8, hasRetake: false), 'CUKUP');
    });
    test('PIN unik numerik', () {
      expect(validatePin('132012026000145', ['x']), isNull);
      expect(validatePin('PIN-X', []), isNotNull);
      expect(validatePin('132012026000145', ['132012026000145']), isNotNull);
    });
  });
}
