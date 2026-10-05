import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/master_data.dart';
import 'package:siakad_kampus/admin/models/master_seed.dart';

void main() {
  group('Validasi tanggal periode (03 §4.2)', () {
    test('selesai < mulai ditolak', () {
      expect(
        validatePeriodDates(DateTime(2026, 1, 1), DateTime(2025, 9, 1)),
        isNotNull,
      );
    });
    test('< 60 hari ditolak, > 210 hari ditolak', () {
      expect(
        validatePeriodDates(DateTime(2025, 9, 1), DateTime(2025, 9, 30)),
        contains('60'),
      );
      expect(
        validatePeriodDates(DateTime(2025, 9, 1), DateTime(2026, 9, 1)),
        contains('210'),
      );
    });
    test('rentang normal lolos', () {
      expect(
        validatePeriodDates(DateTime(2025, 9, 1), DateTime(2026, 1, 24)),
        isNull,
      );
    });
  });

  group('Tahun akademik', () {
    test('format + sekuens', () {
      expect(validateTahunAkademik('2025/2026'), isNull);
      expect(validateTahunAkademik('2025-2026'), isNotNull);
      expect(validateTahunAkademik('2025/2027'), isNotNull);
    });
  });

  group('Single-active invariant (03 §3.2)', () {
    test('switch hasilkan tepat satu aktif', () {
      final out = switchActivePeriod(seedPeriode(), 'per-2425-genap');
      expect(out.where((p) => p.aktif).length, 1);
      expect(
        out.firstWhere((p) => p.aktif).id,
        'per-2425-genap',
      );
    });
    test('target tak dikenal lempar', () {
      expect(
        () => switchActivePeriod(seedPeriode(), 'tak-ada'),
        throwsStateError,
      );
    });
  });

  group('Guard relasional', () {
    test('kode prodi terkunci bila ada mahasiswa', () {
      final prodi = seedProdi();
      expect(prodiKodeLocked(prodi.first), isTrue);
      expect(prodiKodeLocked(prodi.last), isFalse);
    });
    test('ruangan renovasi / kekecilan ditolak', () {
      final ruang = seedRuangan();
      final lab = ruang.firstWhere((r) => r.id == 'r-lab1');
      final renov = ruang.firstWhere((r) => r.id == 'r-renov');
      expect(ruangMuatiKelas(lab, 40), isTrue);
      expect(ruangMuatiKelas(lab, 41), isFalse);
      expect(ruangMuatiKelas(renov, 10), isFalse);
    });
  });
}
