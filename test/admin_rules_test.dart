import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/advising.dart';
import 'package:siakad_kampus/admin/models/curriculum.dart';
import 'package:siakad_kampus/admin/models/graduation.dart';
import 'package:siakad_kampus/admin/models/krs.dart';
import 'package:siakad_kampus/admin/models/scheduling.dart';
import 'package:siakad_kampus/admin/models/users_seed.dart';
import 'package:siakad_kampus/admin/rules/admin_rules.dart';
import 'package:siakad_kampus/admin/rules/grade_scale.dart';

void main() {
  group('GradeScale tunggal', () {
    test('7 tier + AB/BC lolos prasyarat (bug lama: AB dinilai 0.0)', () {
      expect(bobotOf('AB'), 3.5);
      expect(bobotOf('BC'), 2.5);
      final v = checkPrereq(
        earnedSks: 40,
        bestGrades: {'mk-a': 'AB'},
        rules: const [
          PrereqRule(kurikulumId: 'k', mkId: 'mk-b', syaratMkId: 'mk-a'),
        ],
        targetNama: 'MK-B',
      );
      expect(v.eligible, isTrue);
    });

    test('yudisium konsisten dengan skala tunggal', () {
      final r = degreeAudit(
        grades: const [
          AuditGrade(mkId: 'm1', sks: 72, huruf: 'AB', wajib: true),
          AuditGrade(mkId: 'm2', sks: 72, huruf: 'BC', wajib: true),
        ],
        semesters: 8,
        libraryClear: true,
        financeClear: true,
      );
      expect(r.pass, isTrue);
      expect(r.ipk, 3.0);
    });
  });

  group('RuleCheck jembatan', () {
    test('fromError null = lolos', () {
      expect(RuleCheck.fromError(null).ok, isTrue);
      expect(RuleCheck.fromError('x').ok, isFalse);
      expect(RuleCheck.fromError('x').asError, 'x');
    });

    test('userAction: self + admin-terakhir ditolak', () {
      final all = seedUsers();
      expect(
        AdminRules.userAction(
          targetUserId: currentAdminId,
          currentAdminId: currentAdminId,
          actionType: 'DEACTIVATE',
          all: all,
        ).ok,
        isFalse,
      );
      expect(
        AdminRules.userAction(
          targetUserId: 'u-admin-2',
          currentAdminId: currentAdminId,
          actionType: 'REVOKE_ADMIN',
          all: all,
        ).ok,
        isTrue,
      );
    });
  });

  group('KRS force-add lengkap', () {
    List<KrsEntry> entries() => [
      KrsEntry(id: 'e1', npm: 'N1', kelasId: 'k1', status: 'AKTIF'),
    ];

    test('tolak status non-AKTIF (cek yang dulu lupa)', () {
      final c = AdminRules.forceAdd(
        npm: 'N2',
        targetKelasId: 'k2',
        mkByKelas: {'k1': 'mk-a', 'k2': 'mk-b'},
        kelasPeriode: {'k1': 'p', 'k2': 'p'},
        existing: entries(),
        kapasitasRuang: 40,
        statusMhs: 'CUTI',
        diambilSks: 10,
        plafonSks: 24,
      );
      expect(c.ok, isFalse);
      expect(c.message, contains('terkunci'));
    });

    test('tolak beban melebihi plafon', () {
      final c = AdminRules.forceAdd(
        npm: 'N2',
        targetKelasId: 'k2',
        mkByKelas: {'k1': 'mk-a', 'k2': 'mk-b'},
        kelasPeriode: {'k1': 'p', 'k2': 'p'},
        existing: entries(),
        kapasitasRuang: 40,
        statusMhs: 'AKTIF',
        diambilSks: 25,
        plafonSks: 24,
      );
      expect(c.ok, isFalse);
      expect(c.message, contains('plafon'));
    });

    test('tolak duplikat MK + lolos bersih', () {
      final dup = AdminRules.forceAdd(
        npm: 'N1',
        targetKelasId: 'k2',
        mkByKelas: {'k1': 'mk-a', 'k2': 'mk-a'},
        kelasPeriode: {'k1': 'p', 'k2': 'p'},
        existing: entries(),
        kapasitasRuang: 40,
        statusMhs: 'AKTIF',
        diambilSks: 10,
        plafonSks: 24,
      );
      expect(dup.ok, isFalse);

      final ok = AdminRules.forceAdd(
        npm: 'N2',
        targetKelasId: 'k2',
        mkByKelas: {'k1': 'mk-a', 'k2': 'mk-b'},
        kelasPeriode: {'k1': 'p', 'k2': 'p'},
        existing: entries(),
        kapasitasRuang: 40,
        statusMhs: 'AKTIF',
        diambilSks: 10,
        plafonSks: 24,
      );
      expect(ok.ok, isTrue);
    });

    test('plafon konsisten dengan fungsi lama', () {
      expect(AdminRules.maxSks(semester: 1, ips: null), 20);
      expect(AdminRules.maxSks(semester: 5, ips: 3.5), 24);
    });
  });

  group('Penjadwalan satu pintu', () {
    final existing = [
      JadwalSlot(
        id: 's1',
        kelasId: 'k1',
        ruangId: 'r1',
        hari: 1,
        mulai: 480,
        selesai: 570,
      ),
    ];

    test('bentrok ruang terdeteksi', () {
      final c = AdminRules.scheduleSlot(
        candidate: JadwalSlot(
          id: 's2',
          kelasId: 'k2',
          ruangId: 'r1',
          hari: 1,
          mulai: 500,
          selesai: 590,
        ),
        existing: existing,
        candidateDosen: const ['d2'],
        dosenByKelas: const {
          'k1': ['d1'],
        },
        sks: 1,
        kapasitasKelas: 30,
        kapasitasRuang: 40,
      );
      expect(c.ok, isFalse);
      expect(c.message, contains('Bentrok ruangan'));
    });

    test('slot bersih lolos', () {
      final c = AdminRules.scheduleSlot(
        candidate: JadwalSlot(
          id: 's2',
          kelasId: 'k2',
          ruangId: 'r1',
          hari: 2,
          mulai: 500,
          selesai: 590,
        ),
        existing: existing,
        candidateDosen: const ['d2'],
        dosenByKelas: const {
          'k1': ['d1'],
        },
        sks: 1,
        kapasitasKelas: 30,
        kapasitasRuang: 40,
      );
      expect(c.ok, isTrue);
    });
  });

  group('Lintas modul', () {
    test('UAS 75%: 74% gagal, dispensasi menolong', () {
      expect(
        AdminRules.uas(total: 16, hadir: 11, dispensasi: 0).ok,
        isFalse,
      );
      expect(
        AdminRules.uas(total: 16, hadir: 11, dispensasi: 1).ok,
        isTrue,
      );
    });

    test('transfer: D ditolak, >100 ditolak, MBKM >20 ditolak', () {
      expect(
        AdminRules.transfer(
          asalHuruf: 'D',
          totalDiakui: 60,
          paketSks: 10,
          isMbkm: false,
        ).ok,
        isFalse,
      );
      expect(
        AdminRules.transfer(
          asalHuruf: 'B',
          totalDiakui: 101,
          paketSks: 10,
          isMbkm: false,
        ).ok,
        isFalse,
      );
      expect(
        AdminRules.transfer(
          asalHuruf: 'B',
          totalDiakui: 60,
          paketSks: 21,
          isMbkm: true,
        ).ok,
        isFalse,
      );
      expect(
        AdminRules.transfer(
          asalHuruf: 'B',
          totalDiakui: 60,
          paketSks: 20,
          isMbkm: true,
        ).ok,
        isTrue,
      );
    });

    test('bypass butuh catatan + reminder + jendela 24 jam', () {
      expect(
        AdminRules.bypass(
          deadlineHoursLeft: 12,
          remindersSent: 2,
          sksOk: true,
          noConflict: true,
          catatan: 'PA cuti sakit.',
        ).ok,
        isTrue,
      );
      expect(
        AdminRules.bypass(
          deadlineHoursLeft: 48,
          remindersSent: 2,
          sksOk: true,
          noConflict: true,
          catatan: 'x',
        ).ok,
        isFalse,
      );
    });

    test('round-robin tetap seimbang via fasade tak langsung', () {
      final out = distributeRoundRobin(
        studentNpms: const ['a', 'b', 'c'],
        lecturerNidns: const ['d1', 'd2'],
      );
      expect(out['d1'], hasLength(2));
      expect(out['d2'], hasLength(1));
    });
  });
}
