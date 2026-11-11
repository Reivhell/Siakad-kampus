import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/master_data.dart';
import 'package:siakad_kampus/admin/models/master_seed.dart';
import 'package:siakad_kampus/admin/rules/admin_rules.dart';

Periode _p(String id, bool aktif) => Periode(
      id: id,
      nama: id,
      tahun: '2025/2026',
      semester: 'GANJIL',
      mulai: DateTime(2025, 9, 1),
      selesai: DateTime(2026, 1, 24),
      aktif: aktif,
    );

void main() {
  group('Periode aktif satu sumber (03 §3.2 + 06 §3)', () {
    test('seed demo: aktif = per-2526-ganjil', () {
      expect(
        AdminRules.activePeriod(seedPeriode()).id,
        'per-2526-ganjil',
      );
    });

    test('throw bila 0 atau 2 aktif', () {
      expect(() => AdminRules.activePeriod([_p('a', false)]),
          throwsA(isA<StateError>()));
      expect(
        () => AdminRules.activePeriod([_p('a', true), _p('b', true)]),
        throwsA(isA<StateError>()),
      );
      expect(
        () => AdminRules.activePeriod([_p('a', true), _p('b', true)]),
        throwsA(predicate((e) =>
            e is StateError && e.message.contains('tepat 1 (dapat 2)'))),
      );
    });

    test('canOpenKrs sepakat dengan singleActive', () {
      final ok = AdminRules.canOpenKrs(periode: seedPeriode(), kelasSiap: 2);
      expect(ok.ok, isTrue);
      final bobrok = AdminRules.canOpenKrs(
        periode: [_p('a', true), _p('b', true)],
        kelasSiap: 2,
      );
      expect(bobrok.ok, isFalse);
      expect(bobrok.message, contains('tepat 1 (dapat 2)'));
    });
  });
}
