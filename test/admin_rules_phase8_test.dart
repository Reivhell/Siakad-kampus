import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/civitas.dart';
import 'package:siakad_kampus/admin/models/civitas_seed.dart';
import 'package:siakad_kampus/admin/rules/admin_rules.dart';

void main() {
  group('Kode fakultas satu sumber (05 §4.1)', () {
    test('facultyCodeTI = 100 di model civitas', () {
      expect(facultyCodeTI, '100');
    });

    test('seed NPM selaras: FFF = facultyCodeTI + format valid', () {
      for (final m in seedMahasiswa()) {
        expect(m.npm.substring(2, 5), facultyCodeTI);
        expect(AdminRules.npm(m.npm).ok, isTrue);
      }
    });

    test('prefix wizard = komposisi ulang seed pertama', () {
      const prefix = '26${facultyCodeTI}10';
      expect('$prefix${1.toString().padLeft(3, '0')}',
          seedMahasiswa().first.npm);
      final built = AdminRules.makeNpm(
        year: 2026,
        facultyCode: facultyCodeTI,
        prodiCode: '10',
        seq: 45,
        existing: const [],
      );
      expect(built.npm, '2610010045');
    });
  });

  group('Guard batch transfer satu tembak (14 §7)', () {
    RuleCheck batch(List<String> huruf, int totalSks, bool mbkm) =>
        RuleCheck.all([
          for (final h in huruf)
            AdminRules.transfer(
              asalHuruf: h,
              totalDiakui: totalSks,
              paketSks: totalSks,
              isMbkm: mbkm,
            ),
        ]);

    test('semua C lolos; satu D menggagalkan dengan pesannya', () {
      expect(batch(['A', 'B'], 7, false).ok, isTrue);
      final g = batch(['A', 'D'], 7, false);
      expect(g.ok, isFalse);
      expect(g.message, contains('min C'));
    });
  });
}
