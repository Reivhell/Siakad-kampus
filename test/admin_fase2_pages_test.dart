import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/pages/curriculum_page.dart';
import 'package:siakad_kampus/admin/pages/master_page.dart';
import 'package:siakad_kampus/admin/pages/users_page.dart';
import 'package:siakad_kampus/app/theme/siakad_theme.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: SiakadTheme.light, home: Scaffold(body: child));

Future<void> _surface(WidgetTester tester, Size s) async {
  tester.view.physicalSize = s;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(_wrap(page));
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('users page render tabel + filter', (tester) async {
    await _surface(tester, const Size(1280, 1800));
    await _pump(tester, const UsersPage());
    expect(find.text('Manajemen Pengguna & Peran'), findsOneWidget);
    expect(find.text('Dr. Aris Munandar'), findsOneWidget);
  });

  testWidgets('master page 3 tab + periode aktif', (tester) async {
    await _surface(tester, const Size(1280, 1600));
    await _pump(tester, const MasterPage());
    expect(find.text('Master Data Akademik'), findsOneWidget);
    expect(find.textContaining('Ganjil 2025/2026'), findsWidgets);
    await tester.tap(find.text('Periode'));
    await tester.pumpAndSettle();
    expect(find.text('Aktifkan'), findsWidgets);
  });

  testWidgets('kurikulum matriks + bank MK', (tester) async {
    await _surface(tester, const Size(1280, 2000));
    await _pump(tester, const CurriculumPage());
    expect(find.text('Kurikulum & Mata Kuliah'), findsOneWidget);
    expect(find.text('Matriks Semester 1–8'), findsOneWidget);
    expect(find.textContaining('Skripsi'), findsWidgets);
  });
}
