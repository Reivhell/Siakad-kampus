import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/app_user.dart';
import 'package:siakad_kampus/admin/models/curriculum.dart';
import 'package:siakad_kampus/admin/models/krs.dart';
import 'package:siakad_kampus/admin/models/master_data.dart';
import 'package:siakad_kampus/admin/models/scheduling.dart';
import 'package:siakad_kampus/admin/rules/admin_rules.dart';

List<AppUser> _users() => [
      AppUser(
        id: 'a1',
        nama: 'Admin Satu',
        email: 'a1@kampus.ac.id',
        roles: {UserRole.admin},
      ),
      AppUser(
        id: 'a2',
        nama: 'Admin Dua',
        email: 'a2@kampus.ac.id',
        roles: {UserRole.admin},
      ),
      AppUser(
        id: 'm1',
        nama: 'Mhs',
        email: 'm@kampus.ac.id',
        roles: {UserRole.mahasiswa},
      ),
    ];

void main() {
  group('Thresholds dipakai model (DRY)', () {
    test('plafon IPS konsisten via fasade', () {
      expect(AdminRules.maxSks(semester: 5, ips: 3.5), 24);
      expect(AdminRules.maxSks(semester: 5, ips: 1.0), 12);
      expect(calculateMaxSks(semester: 1, ips: null), 20);
    });

    test('unlock 1-72, 0 dan 73 ditolak', () {
      expect(AdminRules.unlockWindow(1).ok, isTrue);
      expect(AdminRules.unlockWindow(72).ok, isTrue);
      expect(AdminRules.unlockWindow(0).ok, isFalse);
      expect(AdminRules.unlockWindow(73).ok, isFalse);
    });
  });

  group('RuleCheck.all', () {
    test('gagal pertama menang', () {
      final c = RuleCheck.all([
        const RuleCheck.pass(),
        const RuleCheck.fail('E1'),
        const RuleCheck.fail('E2'),
      ]);
      expect(c.ok, isFalse);
      expect(c.message, 'E1');
      expect(
        RuleCheck.failures([
          const RuleCheck.pass(),
          const RuleCheck.fail('E1'),
          const RuleCheck.fail('E2'),
        ]),
        ['E1', 'E2'],
      );
    });
  });

  group('Master baru', () {
    test('switchPeriod: target tak ada ditolak', () {
      final all = [
        Periode(
          id: 'p1',
          nama: 'Ganjil',
          tahun: '2025/2026',
          semester: 'GANJIL',
          mulai: DateTime(2025, 9, 1),
          selesai: DateTime(2026, 1, 24),
          aktif: true,
        ),
      ];
      expect(AdminRules.switchPeriod(all, 'pX').ok, isFalse);
      expect(AdminRules.switchPeriod(all, 'p1').ok, isTrue);
      expect(AdminRules.singleActive(all).ok, isTrue);
      expect(
        AdminRules.singleActive([
          ...all,
          Periode(
            id: 'p2',
            nama: 'Genap',
            tahun: '2025/2026',
            semester: 'GENAP',
            mulai: DateTime(2026, 2, 1),
            selesai: DateTime(2026, 6, 30),
            aktif: true,
          ),
        ]).ok,
        isFalse,
      );
    });

    test('prodiKode terkunci bila ada mahasiswa', () {
      final p = Prodi(
        id: 'pr',
        kode: '01',
        nama: 'TI',
        jenjang: 'S1',
        studentCount: 3,
      );
      expect(AdminRules.prodiKode(p, '02').ok, isFalse);
      expect(AdminRules.prodiKode(p, '01').ok, isTrue);
    });
  });

  group('Civitas baru', () {
    test('npm format + duplikat', () {
      expect(AdminRules.npm('2410010901').ok, isTrue);
      expect(AdminRules.npm('123').ok, isFalse);
      expect(AdminRules.npmBaru('2410010901', ['2410010901']).ok, isFalse);
      expect(AdminRules.npmBaru('2410010902', ['2410010901']).ok, isTrue);
      expect(AdminRules.npmSequence(1000).ok, isFalse);
    });
  });

  group('Kurikulum baru', () {
    test('total + siklus', () {
      expect(AdminRules.curriculumTotal(144).ok, isTrue);
      expect(AdminRules.curriculumTotal(100).ok, isFalse);
      expect(
        AdminRules.prereqCycle(const [
          PrereqRule(kurikulumId: 'k', mkId: 'a', syaratMkId: 'b'),
          PrereqRule(kurikulumId: 'k', mkId: 'b', syaratMkId: 'a'),
        ]).ok,
        isFalse,
      );
      expect(
        AdminRules.prereqCycle(const [
          PrereqRule(kurikulumId: 'k', mkId: 'a', syaratMkId: 'b'),
        ]).ok,
        isTrue,
      );
    });
  });

  group('Scheduling baru', () {
    test('ruang renovasi ditolak + shrink + openClass', () {
      final cand = JadwalSlot(
        id: 's2',
        kelasId: 'k2',
        ruangId: 'r1',
        hari: 2,
        mulai: 500,
        selesai: 590,
      );
      final c = AdminRules.scheduleSlot(
        candidate: cand,
        existing: const [],
        candidateDosen: const ['d1'],
        dosenByKelas: const {},
        sks: 1,
        kapasitasKelas: 30,
        kapasitasRuang: 40,
        ruangTersedia: false,
      );
      expect(c.ok, isFalse);
      expect(AdminRules.shrinkCapacity(10, 20).ok, isFalse);
      expect(
        AdminRules.openClass(
          kapasitas: 0,
          terdaftar: 0,
          kapasitasRuang: 40,
        ).ok,
        isFalse,
      );
      expect(
        AdminRules.openClass(
          kapasitas: 40,
          terdaftar: 0,
          kapasitasRuang: 40,
        ).ok,
        isTrue,
      );
      expect(AdminRules.scheduleBlackout(5, 700, 750), isTrue);
      expect(AdminRules.scheduleBlackout(1, 700, 750), isFalse);
    });
  });

  group('KRS baru', () {
    test('jendela + switchGuard', () {
      final w = KrsWindow(
        id: 'w',
        nama: 'Gel.1',
        minSemester: 3,
        maxSemester: 8,
        buka: DateTime(2026, 9, 1),
        tutup: DateTime(2026, 9, 30),
      );
      expect(
        AdminRules.krsWindow(w, 5, DateTime(2026, 9, 10)).ok,
        isTrue,
      );
      expect(
        AdminRules.krsWindow(w, 1, DateTime(2026, 9, 10)).ok,
        isFalse,
      );
      final entries = [
        KrsEntry(id: 'e1', npm: 'N1', kelasId: 'k1', status: 'AKTIF'),
      ];
      final ok = AdminRules.switchGuard(
        npm: 'N1',
        toKelasId: 'k2',
        mkByKelas: {'k1': 'mk-a', 'k2': 'mk-b'},
        kelasPeriode: {'k1': 'p', 'k2': 'p'},
        existing: entries,
        movingEntryId: 'e1',
        statusMhs: 'AKTIF',
      );
      expect(ok.ok, isTrue);
      final cuti = AdminRules.switchGuard(
        npm: 'N1',
        toKelasId: 'k2',
        mkByKelas: {'k1': 'mk-a', 'k2': 'mk-b'},
        kelasPeriode: {'k1': 'p', 'k2': 'p'},
        existing: entries,
        movingEntryId: 'e1',
        statusMhs: 'CUTI',
      );
      expect(cuti.ok, isFalse);
    });
  });

  group('Nilai baru', () {
    test('bobot 100 lolos, 90 gagal; skor liar gagal', () {
      expect(
        AdminRules.nilaiAkhir(
          {'uts': 50, 'uas': 50},
          {'uts': 80, 'uas': 80},
        ).ok,
        isTrue,
      );
      expect(
        AdminRules.nilaiAkhir(
          {'uts': 50, 'uas': 40},
          {'uts': 80, 'uas': 80},
        ).ok,
        isFalse,
      );
      expect(AdminRules.skor(101).ok, isFalse);
      expect(AdminRules.skor(85).ok, isTrue);
      expect(
        AdminRules.unlockActive(
          DateTime(2026, 1, 1, 10),
          DateTime(2026, 1, 1, 12),
        ).ok,
        isTrue,
      );
      expect(
        AdminRules.unlockActive(
          DateTime(2026, 1, 1, 13),
          DateTime(2026, 1, 1, 12),
        ).ok,
        isFalse,
      );
      expect(AdminRules.gradeDeadlineSoon(7), isTrue);
      expect(AdminRules.gradeDeadlineSoon(5), isFalse);
    });
  });

  group('User baru', () {
    test('assign duplikat ditolak; temp password lolos policy', () {
      final all = _users();
      expect(
        AdminRules.assignRole(
          targetUserId: 'a1',
          currentAdminId: 'a2',
          role: UserRole.admin,
          all: all,
        ).ok,
        isFalse,
      );
      expect(
        AdminRules.assignRole(
          targetUserId: 'm1',
          currentAdminId: 'a1',
          role: UserRole.admin,
          all: all,
        ).ok,
        isTrue,
      );
      expect(AdminRules.tempPassword('Kampus-Merdeka-123!').ok, isTrue);
      expect(AdminRules.tempPassword('pendek').ok, isFalse);
    });
  });

  group('Dashboard engine', () {
    test('classHealth prioritas: dosen > ruang > penuh > sepi', () {
      expect(
        AdminRules.classHealth(
          terdaftar: 40,
          kapasitas: 40,
          hasDosen: false,
          hasRuang: true,
        ),
        ClassHealth.tanpaDosen,
      );
      expect(
        AdminRules.classHealth(
          terdaftar: 40,
          kapasitas: 40,
          hasDosen: true,
          hasRuang: true,
        ),
        ClassHealth.penuh,
      );
      expect(
        AdminRules.classHealth(
          terdaftar: 3,
          kapasitas: 40,
          hasDosen: true,
          hasRuang: true,
        ),
        ClassHealth.sepi,
      );
      expect(
        AdminRules.classHealth(
          terdaftar: 20,
          kapasitas: 40,
          hasDosen: true,
          hasRuang: true,
        ),
        ClassHealth.sehat,
      );
    });

    test('partisipasi + okupansi + progres + atRisk', () {
      expect(AdminRules.krsParticipation(94, 100), 94.0);
      expect(AdminRules.krsParticipation(0, 0), 0);
      expect(AdminRules.roomOccupancy(76, 100), 76.0);
      expect(AdminRules.semesterProgress(8), 50.0);
      expect(
        AdminRules.isAtRisk(presensiPct: 70, ips: 3.0, semester: 4),
        isTrue,
      );
      expect(
        AdminRules.isAtRisk(presensiPct: 90, ips: 1.9, semester: 4),
        isTrue,
      );
      expect(
        AdminRules.isAtRisk(presensiPct: 90, ips: 3.0, semester: 12),
        isTrue,
      );
      expect(
        AdminRules.isAtRisk(presensiPct: 90, ips: 3.0, semester: 4),
        isFalse,
      );
    });
  });

  group('Surat + feeder + yudisium baru', () {
    test('letterNumber format + masaStudi + readiness', () {
      expect(
        AdminRules.letterNumber(seq: 41, kode: 'S.Aktif', month: 9, year: 2026),
        '041/S.Aktif/FTI-SIAKAD/IX/2026',
      );
      expect(AdminRules.masaStudi(15).ok, isFalse);
      expect(AdminRules.masaStudi(4).ok, isTrue);
      expect(AdminRules.readiness(10, 10), 100.0);
      expect(AdminRules.readinessLevel(10, 10), FeederLevel.siap);
      expect(AdminRules.readinessLevel(0, 10), FeederLevel.belum);
      expect(AdminRules.motherName('-').ok, isFalse);
      expect(AdminRules.meetingBehind(5, 12).ok, isFalse);
      expect(AdminRules.projectedUas(
        total: 16,
        hadir: 11,
        dispensasiNow: 0,
        tambahan: 1,
      ), 75.0);
    });
  });
}
