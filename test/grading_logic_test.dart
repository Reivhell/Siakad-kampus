import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/grading.dart';

void main() {
  group('Konversi 7-tier (08 §4.1)', () {
    test('batas inklusif tiap tier', () {
      expect(convertScore(100).huruf, 'A');
      expect(convertScore(85).huruf, 'A');
      expect(convertScore(84.99).huruf, 'AB');
      expect(convertScore(80).huruf, 'AB');
      expect(convertScore(79.99).huruf, 'B');
      expect(convertScore(75).huruf, 'B');
      expect(convertScore(74.99).huruf, 'BC');
      expect(convertScore(70).huruf, 'BC');
      expect(convertScore(69.99).huruf, 'C');
      expect(convertScore(65).huruf, 'C');
      expect(convertScore(64.99).huruf, 'D');
      expect(convertScore(50).huruf, 'D');
      expect(convertScore(49.99).huruf, 'E');
      expect(convertScore(0).huruf, 'E');
    });
    test('di luar 0–100 lempar', () {
      expect(() => convertScore(-1), throwsArgumentError);
      expect(() => convertScore(101), throwsArgumentError);
    });
  });

  group('NA berbobot (08 §3.2)', () {
    test('contoh umum 20/30/40/10', () {
      const w = {'Tugas': 20.0, 'UTS': 30.0, 'UAS': 40.0, 'Presensi': 10.0};
      const s = {'Tugas': 80.0, 'UTS': 70.0, 'UAS': 90.0, 'Presensi': 100.0};
      expect(weightedFinal(w, s), 83.0);
    });
    test('total bobot ≠ 100 ditolak', () {
      expect(
        () => weightedFinal(const {'A': 50.0}, const {'A': 80.0}),
        throwsArgumentError,
      );
    });
  });

  group('IPS & IPK best-grade (08 §3.3)', () {
    test('IPS rata-rata berbobot SKS', () {
      expect(
        calcIps(const [GradeEntry('m1', 3, 4.0), GradeEntry('m2', 3, 2.0)]),
        3.0,
      );
      expect(calcIps(const []), 0);
    });
    test('IPK ambil nilai tertinggi per MK', () {
      final entries = const [
        GradeEntry('mk1', 3, 1.0), // mengulang
        GradeEntry('mk1', 3, 3.0), // terbaik
        GradeEntry('mk2', 2, 4.0),
      ];
      // (3*3 + 2*4) / 5 = 3.4
      expect(calcIpk(entries), 3.4);
    });
  });

  group('Unlock window (08 §3.4)', () {
    test('kedaluwarsa 48 jam', () {
      final now = DateTime(2026, 9, 28, 12);
      final exp = unlockExpiry(now, 48);
      expect(exp, DateTime(2026, 9, 30, 12));
      expect(isUnlockExpired(now, exp), isFalse);
      expect(isUnlockExpired(exp.add(const Duration(seconds: 1)), exp), isTrue);
    });
  });
}
