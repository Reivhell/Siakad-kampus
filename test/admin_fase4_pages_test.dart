import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/pages/audit_page.dart';
import 'package:siakad_kampus/admin/pages/grades_page.dart';
import 'package:siakad_kampus/admin/pages/attendance_page.dart';
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
  testWidgets('nilai render rekap + konversi', (tester) async {
    await _surface(tester, const Size(1280, 2000));
    await _pump(tester, const GradesPage());
    expect(find.text('Monitoring Nilai'), findsOneWidget);
    expect(find.textContaining('TI101-A'), findsWidgets);
    expect(find.text('Skala Konversi 7-Tier'), findsOneWidget);
  });

  testWidgets('presensi render kelas + skrining', (tester) async {
    await _surface(tester, const Size(1280, 2000));
    await _pump(tester, const AttendancePage());
    expect(find.text('Monitoring Presensi'), findsOneWidget);
    expect(find.textContaining('Terancam Gugur'), findsOneWidget);
    expect(find.text('Dispensasi'), findsWidgets);
  });

  testWidgets('audit render log + anomali + chain', (tester) async {
    await _surface(tester, const Size(1280, 2000));
    await _pump(tester, const AuditPage());
    expect(find.text('Jejak Audit & Keamanan'), findsOneWidget);
    expect(find.text('RANTAI VALID'), findsOneWidget);
    expect(find.text('ANOMALI'), findsWidgets);
  });
}
