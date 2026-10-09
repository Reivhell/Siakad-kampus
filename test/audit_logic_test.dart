import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/audit.dart';
import 'package:siakad_kampus/admin/models/audit_seed.dart';

void main() {
  group('Taksonomi + filter (10 §3)', () {
    test('kategori prefix', () {
      expect(aksiKategori('ADMIN_FORCE_ADD_KRS'), 'Administratif');
      expect(aksiKategori('DOSEN_FINALISASI_NILAI'), 'Dosen');
      expect(aksiKategori('MAHASISWA_AJUKAN_KRS'), 'Mahasiswa');
      expect(aksiKategori('AUTH_BRUTE_FORCE_LOCKOUT'), 'Keamanan');
    });
    test('filter query + kategori + entitas', () {
      final all = seedAudit();
      expect(filterAudit(all, query: 'brute').length, 1);
      expect(filterAudit(all, aksi: 'Keamanan').length, 2);
      expect(filterAudit(all, entitas: 'krs').length, 2);
      expect(filterAudit(all, query: 'tak-ada').isEmpty, isTrue);
    });
  });

  group('Anomali (10 §1.4)', () {
    test('brute-force + akses nilai dini hari', () {
      final all = seedAudit();
      final brute = all.firstWhere(
        (e) => e.aksi == 'AUTH_BRUTE_FORCE_LOCKOUT',
      );
      expect(isAnomaly(brute), isTrue);
      final siang = all.firstWhere(
        (e) => e.aksi == 'DOSEN_FINALISASI_NILAI',
      );
      expect(isAnomaly(siang), isFalse);
      final malam = AuditEntry(
        id: 'x',
        waktu: DateTime(2026, 9, 28, 2, 0),
        aktor: 'y',
        aksi: 'ADMIN_BUKA_KUNCI_NILAI',
        entitas: 'nilai',
        ip: '1.1.1.1',
      );
      expect(isAnomaly(malam), isTrue);
    });
  });

  group('Diff + hash chain (10 §4.2, §2.2)', () {
    test('union keys urut, changed flag', () {
      final rows = diffStates(
        {'a': '1', 'b': '2'},
        {'b': '3', 'c': '4'},
      );
      expect(rows.map((r) => r.field).toList(), ['a', 'b', 'c']);
      expect(rows.firstWhere((r) => r.field == 'b').changed, isTrue);
      expect(rows.firstWhere((r) => r.field == 'a').changed, isTrue);
    });
    test('seed chain valid, rusak terdeteksi', () {
      final all = seedAudit();
      expect(verifyChain(all), isTrue);
      final rusak = [
        for (final e in all)
          AuditEntry(
            id: e.id,
            waktu: e.waktu,
            aktor: e.aktor,
            aksi: e.aksi,
            entitas: e.entitas,
            ip: e.ip,
            hashPrev: e.hashPrev,
            hash: 'palsu',
          ),
      ];
      expect(verifyChain(rusak), isFalse);
    });
  });
}
