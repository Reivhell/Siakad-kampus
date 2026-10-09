import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/attendance.dart';

void main() {
  group('Eligibility 75% (09 §4.1)', () {
    test('0 sesi = eligible 100', () {
      final e = evaluateUas(total: 0, hadir: 0, dispensasi: 0);
      expect(e.eligible, isTrue);
      expect(e.percentage, 100);
    });
    test('batas 75 pas lolos, di bawah gugur', () {
      expect(
        evaluateUas(total: 12, hadir: 9, dispensasi: 0).eligible,
        isTrue,
      );
      final gugur = evaluateUas(total: 11, hadir: 7, dispensasi: 0);
      expect(gugur.eligible, isFalse);
      expect(gugur.percentage, closeTo(63.64, 0.01));
    });
    test('dispensasi menaikkan efektif', () {
      final e = evaluateUas(total: 11, hadir: 7, dispensasi: 2);
      expect(e.percentage, closeTo(81.82, 0.01));
      expect(e.eligible, isTrue);
    });
  });

  group('Status pertemuan (09 §3.1)', () {
    test('flag tertinggal minggu ≥10 & <8 sesi', () {
      expect(isBehindSchedule(6, 11), isTrue);
      expect(isBehindSchedule(11, 11), isFalse);
      expect(isBehindSchedule(6, 9), isFalse);
    });
    test('track on-time vs terlambat', () {
      expect(meetingTrack(11, 11), 'ON-TRACK');
      expect(meetingTrack(10, 11), 'TERLAMBAT 1–2');
      expect(meetingTrack(6, 11), 'TERTINGGAL');
    });
    test('proyeksi dispensasi', () {
      expect(
        projectedPct(total: 11, hadir: 7, dispensasiNow: 0, tambahan: 2),
        81.8,
      );
      expect(
        projectedPct(total: 0, hadir: 0, dispensasiNow: 0, tambahan: 0),
        100,
      );
    });
  });
}
