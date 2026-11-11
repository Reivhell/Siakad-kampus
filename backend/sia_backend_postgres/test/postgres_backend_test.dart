import 'dart:io';

import 'package:sia_backend_core/sia_backend_core.dart';
import 'package:sia_backend_postgres/sia_backend_postgres.dart';
import 'package:test/test.dart';

void main() {
  final url = Platform.environment['SIAKAD_TEST_DATABASE_URL'];
  final skip = url == null ? 'Set SIAKAD_TEST_DATABASE_URL to run.' : false;

  group('PostgresBackend', () {
    late PostgresBackend backend;

    setUpAll(() {
      backend = PostgresBackend(url ?? 'postgresql://postgres@127.0.0.1:5432/siakad_test');
    });

    tearDownAll(() => backend.close());

    test('authenticates seeded admin and reads roles', () async {
      final user = await backend.authenticate('admin@kampus.ac.id', 'Admin#12345');
      expect(user, isNotNull);
      expect(user!.isAdmin, isTrue);
    }, skip: skip);

    test('rejects wrong password', () async {
      final user = await backend.authenticate('admin@kampus.ac.id', 'wrong');
      expect(user, isNull);
    }, skip: skip);

    test('lists users under RLS as admin', () async {
      final admin = (await backend.authenticate('admin@kampus.ac.id', 'Admin#12345'))!;
      final page = await backend.list(admin, const PageRequest(limit: 5));
      expect(page.total, greaterThan(0));
      expect(page.items, isNotEmpty);
    }, skip: skip);

    test('student cannot see other students', () async {
      final student = (await backend.authenticate('2510100001', 'Mhs#12345'))!;
      final page = await backend.listMahasiswa(student, const PageRequest());
      expect(page.items.map((e) => e.npm), contains('2510100001'));
      expect(page.items.length, 1);
    }, skip: skip);
  });
}
