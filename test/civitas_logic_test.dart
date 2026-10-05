import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/civitas.dart';

void main() {
  group('NPM generator (05 §3.1, §4.1)', () {
    test('format AA+FFF+PP+UUU tepat 10 digit', () {
      expect(
        generateNpm(
          year: 2026,
          facultyCode: '100',
          prodiCode: '10',
          nextSequence: 42,
        ),
        '2610010042',
      );
      expect(
        generateNpm(
          year: 2024,
          facultyCode: '100',
          prodiCode: '20',
          nextSequence: 1,
        ),
        '2410020001',
      );
    });
    test('seq di luar 1–999 / hasil non-numerik lempar', () {
      expect(
        () => generateNpm(
          year: 2026,
          facultyCode: '100',
          prodiCode: '10',
          nextSequence: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => generateNpm(
          year: 2026,
          facultyCode: '100',
          prodiCode: '10',
          nextSequence: 1000,
        ),
        throwsArgumentError,
      );
    });
    test('nextSequence MAX+1 per prefix, penuh lempar', () {
      expect(
        nextSequenceFor('2610010', ['2610010001', '2610010041']),
        42,
      );
      expect(nextSequenceFor('2610010', []), 1);
      expect(
        () => nextSequenceFor(
          '2610010',
          ['2610010999'],
        ),
        throwsStateError,
      );
    });
  });

  group('Status machine (05 §3.3)', () {
    test('transisi legal vs ilegal vs terminal', () {
      expect(canTransition('AKTIF', 'CUTI'), isTrue);
      expect(canTransition('CUTI', 'AKTIF'), isTrue);
      expect(canTransition('AKTIF', 'AKTIF'), isFalse);
      expect(canTransition('LULUS', 'AKTIF'), isFalse);
      expect(canTransition('DO', 'AKTIF'), isFalse);
    });
    test('KRS hanya terbuka saat AKTIF', () {
      expect(krsUnlocked('AKTIF'), isTrue);
      expect(krsUnlocked('CUTI'), isFalse);
      expect(krsUnlocked('NON_AKTIF'), isFalse);
    });
  });

  group('NIDN + BKD (05 §3.4)', () {
    test('nidn numerik', () {
      expect(validateNidn('0412088501'), isNull);
      expect(validateNidn('NIDN-01'), isNotNull);
    });
    test('bkd 12–16 ideal', () {
      expect(bkdWarning(14), isNull);
      expect(bkdWarning(8), isNotNull);
      expect(bkdWarning(18), isNotNull);
    });
  });
}
