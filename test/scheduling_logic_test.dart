import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/scheduling.dart';

JadwalSlot _s({
  String id = 'x',
  String kelas = 'k1',
  String ruang = 'r1',
  int hari = 2,
  int mulai = 480,
  int selesai = 580,
}) => JadwalSlot(
  id: id,
  kelasId: kelas,
  ruangId: ruang,
  hari: hari,
  mulai: mulai,
  selesai: selesai,
);

void main() {
  group('Overlap interval (06 §4.1)', () {
    test('irisan terdeteksi, tepi bersentuhan aman', () {
      expect(intervalsOverlap(480, 580, 540, 640), isTrue);
      expect(intervalsOverlap(480, 540, 540, 600), isFalse);
      expect(intervalsOverlap(480, 580, 480, 580), isTrue);
    });
    test('beda hari tidak bentrok', () {
      expect(sameDayOverlap(_s(hari: 1), _s(hari: 2)), isFalse);
    });
  });

  group('Bentrok ruangan & dosen (06 §4.2)', () {
    test('ruang sama + overlap → hit', () {
      final hit = roomConflict(_s(ruang: 'r1'), [_s(id: 'a', ruang: 'r1')]);
      expect(hit, isNotNull);
      expect(roomConflict(_s(ruang: 'r2'), [_s(id: 'a', ruang: 'r1')]), isNull);
    });
    test('dosen ganda di slot irisan → hit; kelas sama dilewati', () {
      final byKelas = {
        'k1': ['N1'],
        'k2': ['N1'],
      };
      final other = [_s(id: 'a', kelas: 'k2', ruang: 'r2')];
      expect(
        lecturerConflict(_s(kelas: 'k1'), ['N1'], byKelas, other),
        isNotNull,
      );
      expect(
        lecturerConflict(_s(kelas: 'k1'), ['N9'], byKelas, other),
        isNull,
      );
    });
  });

  group('Kapasitas, durasi, blackout, shrink', () {
    test('kelas > ruang ditolak', () {
      expect(capacityCheck(40, 30), isNotNull);
      expect(capacityCheck(40, 40), isNull);
    });
    test('durasi minimal SKS×50', () {
      expect(durationCheck(3, 480, 630), isNull); // 150 mnt pas
      expect(durationCheck(3, 480, 600), isNotNull);
    });
    test('blackout Jumat 11:30–13:00', () {
      expect(isBlackoutWarning(5, 690, 750), isTrue);
      expect(isBlackoutWarning(5, 480, 580), isFalse);
      expect(isBlackoutWarning(1, 690, 750), isFalse);
    });
    test('shrink di bawah terdaftar ditolak', () {
      expect(shrinkCapacityCheck(30, 38), isNotNull);
      expect(shrinkCapacityCheck(40, 38), isNull);
    });
  });
}
