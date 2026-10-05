import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/krs.dart';

void main() {
  group('Plafon SKS (07 §4.1)', () {
    test('matriks IPS + paket maba', () {
      expect(calculateMaxSks(semester: 1, ips: null), 20);
      expect(calculateMaxSks(semester: 2, ips: 4.0), 20);
      expect(calculateMaxSks(semester: 5, ips: 3.5), 24);
      expect(calculateMaxSks(semester: 5, ips: 2.7), 21);
      expect(calculateMaxSks(semester: 5, ips: 2.2), 18);
      expect(calculateMaxSks(semester: 5, ips: 1.7), 15);
      expect(calculateMaxSks(semester: 5, ips: 1.0), 12);
    });
    test('batas plafon', () {
      expect(lockCheck(24, 24), isNull);
      expect(lockCheck(25, 24), isNotNull);
    });
  });

  group('Jendela staggered (07 §3.1)', () {
    test('gelombang hanya untuk semesternya', () {
      final w = KrsWindow(
        id: 'w',
        nama: 'Gel.1',
        minSemester: 7,
        maxSemester: 14,
        buka: DateTime(2026, 8, 1),
        tutup: DateTime(2026, 8, 2, 23, 59),
      );
      expect(w.openFor(8, DateTime(2026, 8, 1, 12)), isTrue);
      expect(w.openFor(3, DateTime(2026, 8, 1, 12)), isFalse);
      expect(w.openFor(8, DateTime(2026, 8, 5)), isFalse);
    });
  });

  group('Force-add guard (07 §3.3)', () {
    final mkByKelas = {'kA': 'mk1', 'kB': 'mk1', 'kC': 'mk2'};
    final per = {'kA': 'p1', 'kB': 'p1', 'kC': 'p1'};
    test('duplikat MK periode sama ditolak', () {
      final existing = [
        KrsEntry(id: 'e1', npm: 'N1', kelasId: 'kA', status: 'AKTIF'),
      ];
      expect(
        forceAddGuard(
          npm: 'N1',
          targetKelasId: 'kB',
          mkByKelas: mkByKelas,
          kelasPeriode: per,
          existing: existing,
          kapasitasRuang: 45,
        ),
        isNotNull,
      );
    });
    test('MK beda / batal lolos', () {
      final batal = [
        KrsEntry(id: 'e1', npm: 'N1', kelasId: 'kA', status: 'BATAL'),
      ];
      expect(
        forceAddGuard(
          npm: 'N1',
          targetKelasId: 'kB',
          mkByKelas: mkByKelas,
          kelasPeriode: per,
          existing: batal,
          kapasitasRuang: 45,
        ),
        isNull,
      );
      expect(
        forceAddGuard(
          npm: 'N1',
          targetKelasId: 'kC',
          mkByKelas: mkByKelas,
          kelasPeriode: per,
          existing: [
            KrsEntry(id: 'e1', npm: 'N1', kelasId: 'kA', status: 'AKTIF'),
          ],
          kapasitasRuang: 45,
        ),
        isNull,
      );
    });
  });

  group('Switch atomik (07 §3.3)', () {
    test('pindah + counter −1/+1', () {
      final entries = [
        KrsEntry(id: 'e1', npm: 'N1', kelasId: 'kA', status: 'AKTIF'),
      ];
      final r = switchClass(
        entryId: 'e1',
        toKelasId: 'kB',
        entries: entries,
        counters: {'kA': 40, 'kB': 10},
      );
      expect(r.entries.first.kelasId, 'kB');
      expect(r.counters['kA'], 39);
      expect(r.counters['kB'], 11);
    });
  });
}
