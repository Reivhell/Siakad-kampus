import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/models/app_user.dart';
import 'package:siakad_kampus/admin/models/users_seed.dart';

void main() {
  group('Password policy (02 §3.4)', () {
    test('tolak pendek / tanpa besar / tanpa angka', () {
      expect(validatePassword('Ab1!'), isNotNull);
      expect(validatePassword('kampus-unggul-782'), isNotNull); // tanpa besar
      expect(validatePassword('KampusUnggulxxx'), isNotNull); // tanpa angka/simbol
    });
    test('terima format generator', () {
      expect(validatePassword('Kampus-Unggul-782!'), isNull);
    });
    test('generator selalu penuhi policy (seeded)', () {
      final rng = Random(42);
      for (var i = 0; i < 50; i++) {
        expect(validatePassword(generateTempPassword(rng)), isNull);
      }
    });
  });

  group('Email unik case-insensitive', () {
    test('duplikat ditolak, milik sendiri boleh', () {
      final all = seedUsers();
      expect(
        validateUserEmail('ADMIN@kampus.ac.id', all),
        contains('telah digunakan'),
      );
      expect(
        validateUserEmail('admin@kampus.ac.id', all, selfId: 'u-admin-1'),
        isNull,
      );
      expect(validateUserEmail('bukan-email', all), isNotNull);
    });
  });

  group('Guard self-lockout + admin-terakhir (02 §4.2)', () {
    test('tidak bisa nonaktifkan diri sendiri', () {
      final all = seedUsers();
      final v = validateUserAction(
        targetUserId: currentAdminId,
        currentAdminId: currentAdminId,
        actionType: 'DEACTIVATE',
        all: all,
      );
      expect(v.ok, isFalse);
    });
    test('admin terakhir diproteksi', () {
      final solo = [
        AppUser(
          id: 'solo',
          nama: 'Solo',
          email: 'solo@kampus.ac.id',
          roles: {UserRole.admin},
        ),
      ];
      final v = validateUserAction(
        targetUserId: 'solo',
        currentAdminId: 'other',
        actionType: 'REVOKE_ADMIN',
        all: solo,
      );
      expect(v.ok, isFalse);
    });
    test('admin kedua boleh dicabut', () {
      final all = seedUsers();
      final v = validateUserAction(
        targetUserId: 'u-admin-2',
        currentAdminId: currentAdminId,
        actionType: 'REVOKE_ADMIN',
        all: all,
      );
      expect(v.ok, isTrue);
    });
  });

  group('Filter role/status', () {
    test('multi-role + terkunci', () {
      final all = seedUsers();
      expect(filterUsers(all, role: 'MULTI-ROLE').length, 1);
      expect(filterUsers(all, status: 'TERKUNCI').length, 1);
      expect(filterUsers(all, query: 'siti').length, 1);
    });
  });
}
