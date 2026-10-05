import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/auth/auth_validators.dart';

void main() {
  group('validateNpm', () {
    test('menerima 10 digit angka', () {
      expect(validateNpm('2610010042'), isNull);
      expect(validateNpm('  2610010042  '), isNull);
    });

    test('menolak kosong, huruf, dan panjang salah', () {
      expect(validateNpm(''), isNotNull);
      expect(validateNpm('   '), isNotNull);
      expect(validateNpm('261001004A'), contains('angka'));
      expect(validateNpm('12345'), contains('10 digit'));
      expect(validateNpm('123456789012'), contains('10 digit'));
    });
  });

  group('validateLoginPassword', () {
    test('menerima non-kosong, menolak kosong', () {
      expect(validateLoginPassword('x'), isNull);
      expect(validateLoginPassword(''), isNotNull);
    });
  });

  group('fakeSignIn (stub)', () {
    test('sukses untuk NPM valid + sandi non-kosong', () async {
      expect(await fakeSignIn('2610010042', 'rahasia'), isNull);
    });

    test('gagal untuk NPM / sandi invalid', () async {
      expect(await fakeSignIn('123', 'rahasia'), isNotNull);
      expect(await fakeSignIn('2610010042', ''), isNotNull);
    });
  });
}
