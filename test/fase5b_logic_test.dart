import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/feeder.dart';
import 'package:siakad_kampus/admin/models/letters.dart';
import 'package:siakad_kampus/admin/models/transfer.dart';

void main() {
  group('Pre-flight (13 §3.1)', () {
    test('NIK 16 digit + ibu valid', () {
      expect(validateNik('3201234567890001'), isNull);
      expect(validateNik('12345'), isNotNull);
      expect(validateNik(null), isNotNull);
      expect(validateMotherName('Siti Aminah'), isNull);
      expect(validateMotherName('-'), isNotNull);
      expect(validateMotherName(''), isNotNull);
    });
    test('CSV ; + quote escape', () {
      expect(csvRow(['a;b', 'c"d']), '"a;b";"c""d"');
    });
    test('readiness', () {
      expect(readinessScore(1346, 1420), 94.8);
      expect(readinessScore(0, 0), 100);
    });
  });

  group('Konversi (14)', () {
    test('pola mapping', () {
      expect(mappingPattern(nAsal: 1, nLokal: 1), '1-to-1');
      expect(mappingPattern(nAsal: 2, nLokal: 1), 'N-to-1');
      expect(mappingPattern(nAsal: 1, nLokal: 4), contains('MBKM'));
    });
    test('asal D/E ditolak, cap 100 & MBKM 20', () {
      expect(guardAsalHuruf('B'), isNull);
      expect(guardAsalHuruf('D'), isNotNull);
      expect(guardAsalHuruf('E'), isNotNull);
      expect(transferCapCheck(101), isNotNull);
      expect(transferCapCheck(68), isNull);
      expect(mbkmCapCheck(21), isNotNull);
      expect(mbkmCapCheck(20), isNull);
    });
    test('merger N-to-1 rata-rata tertimbang', () {
      // B(3.0)×2 + A(4.0)×2 → 3.5
      expect(
        mergedBobot([(3.0, 2), (4.0, 2)]),
        3.5,
      );
    });
  });

  group('Surat (15)', () {
    test('format UUU/KODE/FTI/ROMAWI/TTTT', () {
      expect(
        letterNumber(seq: 42, kode: 'S.Ket-Aktif', month: 9, year: 2026),
        '042/S.Ket-Aktif/FTI-SIAKAD/IX/2026',
      );
      expect(
        letterNumber(seq: 1, kode: 'SKL', month: 1, year: 2026),
        '001/SKL/FTI-SIAKAD/I/2026',
      );
    });
    test('seq reset per tahun', () {
      expect(
        nextLetterSeq(2026, [(41, 2026), (200, 2025)]),
        42,
      );
      expect(nextLetterSeq(2027, [(41, 2026)]), 1);
    });
    test('verifikasi revoke > expiry > terbit', () {
      final t = DateTime(2026, 9, 28);
      final exp = DateTime(2026, 12, 27);
      expect(
        verifyDoc(now: t, terbit: t, berlakuHingga: exp, revoked: false),
        DocStatus.valid,
      );
      expect(
        verifyDoc(
          now: DateTime(2027, 1, 1),
          terbit: t,
          berlakuHingga: exp,
          revoked: false,
        ),
        DocStatus.kadaluwarsa,
      );
      expect(
        verifyDoc(now: t, terbit: t, berlakuHingga: exp, revoked: true),
        DocStatus.dicabut,
      );
      expect(letterEligible('CUTI'), isNotNull);
      expect(letterEligible('AKTIF'), isNull);
    });
  });
}
