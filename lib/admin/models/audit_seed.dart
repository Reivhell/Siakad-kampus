import 'audit.dart';

/// Seed 8 entri kronologis mundur — rantai hash konsisten via verifyChain.
List<AuditEntry> seedAudit() {
  final raw = [
    AuditEntry(
      id: '8f12a840-0001',
      waktu: DateTime(2026, 9, 28, 10, 45),
      aktor: 'Dr. Aris Munandar',
      aksi: 'DOSEN_FINALISASI_NILAI',
      entitas: 'kelas',
      ip: '10.10.2.14',
      before: {'sudah_final': 'false', 'huruf_nilai': 'D (58.00)'},
      after: {'sudah_final': 'true (FINAL)', 'huruf_nilai': 'B (78.50)'},
    ),
    AuditEntry(
      id: '8f12a840-0002',
      waktu: DateTime(2026, 9, 28, 10, 30),
      aktor: 'Administrator Pusat',
      aksi: 'ADMIN_FORCE_ADD_KRS',
      entitas: 'krs',
      ip: '192.168.1.50',
      before: {'kuota': '40/40'},
      after: {'kuota': '41/40 (override)'},
    ),
    AuditEntry(
      id: '8f12a840-0003',
      waktu: DateTime(2026, 9, 28, 9, 15),
      aktor: 'Siti Nurhaliza (Mhs)',
      aksi: 'MAHASISWA_AJUKAN_KRS',
      entitas: 'krs',
      ip: '180.252.1.8',
    ),
    AuditEntry(
      id: '8f12a840-0004',
      waktu: DateTime(2026, 9, 28, 3, 12),
      aktor: 'SYSTEM_SECURITY_DAEMON',
      aksi: 'AUTH_BRUTE_FORCE_LOCKOUT',
      entitas: 'user',
      ip: '45.12.89.201',
      before: {'attempts': '4'},
      after: {'attempts': '5 → LOCKED 30 mnt'},
    ),
    AuditEntry(
      id: '8f12a840-0005',
      waktu: DateTime(2026, 9, 27, 16, 0),
      aktor: 'Administrator Pusat',
      aksi: 'ADMIN_BUKA_KUNCI_NILAI',
      entitas: 'nilai',
      ip: '192.168.1.50',
      before: {'sudah_final': 'true'},
      after: {'sudah_final': 'false (48 jam)'},
    ),
    AuditEntry(
      id: '8f12a840-0006',
      waktu: DateTime(2026, 9, 27, 2, 40),
      aktor: 'oknum.operator@kampus.ac.id',
      aksi: 'SECURITY_UNAUTHORIZED_TRY',
      entitas: 'nilai',
      ip: '36.81.44.10',
    ),
  ];
  var prev = '';
  final out = <AuditEntry>[];
  for (final e in raw) {
    final h = chainHash(e.id, prev);
    out.add(
      AuditEntry(
        id: e.id,
        waktu: e.waktu,
        aktor: e.aktor,
        aksi: e.aksi,
        entitas: e.entitas,
        ip: e.ip,
        before: e.before,
        after: e.after,
        hashPrev: prev,
        hash: h,
      ),
    );
    prev = h;
  }
  return out;
}
