import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/rules/admin_rules.dart';

void main() {
  group('positiveCapacity (06 §3 + 03 §7)', () {
    test('1 lolos, 0/-3 ditolak dengan pesan', () {
      expect(AdminRules.positiveCapacity(40).ok, isTrue);
      final nol = AdminRules.positiveCapacity(0);
      expect(nol.ok, isFalse);
      expect(nol.message, 'Kapasitas harus > 0.');
      expect(AdminRules.positiveCapacity(-3).ok, isFalse);
    });
  });

  group('isOverCapacity tepi (01 §3.3)', () {
    test('sama-dengan = penuh; kapasitas 0 tak pernah penuh', () {
      expect(AdminRules.isOverCapacity(40, 40), isTrue);
      expect(AdminRules.isOverCapacity(41, 40), isTrue);
      expect(AdminRules.isOverCapacity(39, 40), isFalse);
      expect(AdminRules.isOverCapacity(0, 0), isFalse);
      expect(AdminRules.isOverCapacity(5, 0), isFalse);
    });
  });

  group('classHealth prioritas tile kelas (01 §3.3)', () {
    test('tanpaDosen menang atas penuh (paritas tampilan lama)', () {
      expect(
        AdminRules.classHealth(
          terdaftar: 40,
          kapasitas: 40,
          hasDosen: false,
          hasRuang: true,
        ),
        ClassHealth.tanpaDosen,
      );
      expect(
        AdminRules.classHealth(
          terdaftar: 40,
          kapasitas: 40,
          hasDosen: true,
          hasRuang: true,
        ),
        ClassHealth.penuh,
      );
      expect(
        AdminRules.classHealth(
          terdaftar: 20,
          kapasitas: 40,
          hasDosen: true,
          hasRuang: false,
        ),
        ClassHealth.tanpaRuang,
      );
      expect(
        AdminRules.classHealth(
          terdaftar: 20,
          kapasitas: 40,
          hasDosen: true,
          hasRuang: true,
        ),
        ClassHealth.sehat,
      );
    });
  });

  group('Ambang subtitle PA ikut thresholds', () {
    test('asuhanOverload = 45 di satu sumber', () {
      expect(AdminThresholds.asuhanOverload, 45);
      expect(AdminRules.asuhan(45).ok, isTrue);
      expect(AdminRules.asuhan(46).ok, isFalse);
    });
  });
}
