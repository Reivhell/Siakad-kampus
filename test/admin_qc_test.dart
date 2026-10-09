import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/pages/admin_dashboard_page.dart';
import 'package:siakad_kampus/admin/pages/advisor_page.dart';
import 'package:siakad_kampus/admin/pages/attendance_page.dart';
import 'package:siakad_kampus/admin/pages/audit_page.dart';
import 'package:siakad_kampus/admin/pages/civitas_page.dart';
import 'package:siakad_kampus/admin/pages/curriculum_page.dart';
import 'package:siakad_kampus/admin/pages/feeder_page.dart';
import 'package:siakad_kampus/admin/pages/grades_page.dart';
import 'package:siakad_kampus/admin/pages/graduation_page.dart';
import 'package:siakad_kampus/admin/pages/krs_page.dart';
import 'package:siakad_kampus/admin/pages/letters_page.dart';
import 'package:siakad_kampus/admin/pages/master_page.dart';
import 'package:siakad_kampus/admin/pages/scheduling_page.dart';
import 'package:siakad_kampus/admin/pages/transfer_page.dart';
import 'package:siakad_kampus/admin/pages/users_page.dart';
import 'package:siakad_kampus/app/theme/siakad_theme.dart';

const _pages = <String, Widget>{
  'dashboard': AdminDashboardPage(),
  'users': UsersPage(),
  'master': MasterPage(),
  'curriculum': CurriculumPage(),
  'civitas': CivitasPage(),
  'scheduling': SchedulingPage(),
  'krs': KrsPage(),
  'grades': GradesPage(),
  'attendance': AttendancePage(),
  'advisor': AdvisorPage(),
  'graduation': GraduationPage(),
  'transfer': TransferPage(),
  'feeder': FeederPage(),
  'letters': LettersPage(),
  'audit': AuditPage(),
};

Future<void> _qcPump(
  WidgetTester tester,
  Widget page,
  Size surface,
  String tag,
) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
  await tester.pumpWidget(
    MaterialApp(theme: SiakadTheme.light, home: Scaffold(body: page)),
  );
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
  // Gulir semua scrollable sampai bawah agar item lazy ikut ke-render.
  for (final v in find.byType(Scrollable).evaluate()) {
    final s = v.widget as Scrollable;
    if (s.axis == Axis.vertical) {
      await tester.drag(find.byWidget(s), const Offset(0, -3000));
      await tester.pumpAndSettle();
    }
  }
  final errors = <Object>[];
  Object? e = tester.takeException();
  while (e != null) {
    errors.add(e);
    e = tester.takeException();
  }
  expect(errors, isEmpty, reason: '$tag @ $surface: $errors');
}

void main() {
  for (final entry in _pages.entries) {
    testWidgets('QC mobile 390x844 — ${entry.key}', (tester) async {
      await _qcPump(tester, entry.value, const Size(390, 844), entry.key);
    });
  }
  for (final entry in _pages.entries) {
    testWidgets('QC tablet 800x1280 — ${entry.key}', (tester) async {
      await _qcPump(tester, entry.value, const Size(800, 1280), entry.key);
    });
  }
  for (final entry in _pages.entries) {
    testWidgets('QC desktop 1440x900 — ${entry.key}', (tester) async {
      await _qcPump(tester, entry.value, const Size(1440, 900), entry.key);
    });
  }
}
