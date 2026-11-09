import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/admin_shell.dart';
import 'package:siakad_kampus/admin/pages/advisor_page.dart';
import 'package:siakad_kampus/admin/pages/admin_dashboard_page.dart';
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

/// QC layout: nol overflow di semua pita lebar × skala teks.
///
/// Pita 360 (HP), 700 (tablet sempit/rail ikon), 1024 (batas desktop)
/// plus teks 1.3 — tiga tempat yang pernah meluber:
/// NavigationRail 15 label, `mainAxisExtent` tetap, dan badge status
/// yang memakan kolom judul.
const _pages = <String, Widget>{
  'admin_dashboard_page': AdminDashboardPage(),
  'advisor_page': AdvisorPage(),
  'attendance_page': AttendancePage(),
  'audit_page': AuditPage(),
  'civitas_page': CivitasPage(),
  'curriculum_page': CurriculumPage(),
  'feeder_page': FeederPage(),
  'grades_page': GradesPage(),
  'graduation_page': GraduationPage(),
  'krs_page': KrsPage(),
  'letters_page': LettersPage(),
  'master_page': MasterPage(),
  'scheduling_page': SchedulingPage(),
  'transfer_page': TransferPage(),
  'users_page': UsersPage(),
};

Future<void> _pumpAt(
  WidgetTester t,
  Widget page, {
  required double width,
  required double scale,
}) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1.0;
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await t.pumpWidget(
    MaterialApp(
      theme: SiakadTheme.light,
      home: Scaffold(body: page),
    ),
  );
  await t.pump(const Duration(milliseconds: 800));
  await t.pumpAndSettle();
  // Gulir ke bawah: baris paling bawah sering yang meluber.
  for (final v in find.byType(Scrollable).evaluate()) {
    if ((v.widget as Scrollable).axis == Axis.vertical) {
      await t.drag(find.byWidget(v.widget), const Offset(0, -3000));
      await t.pumpAndSettle();
    }
  }
}

List<Object> _drain(WidgetTester t) {
  final errs = <Object>[];
  Object? e = t.takeException();
  while (e != null) {
    errs.add(e);
    e = t.takeException();
  }
  return errs;
}

void main() {
  for (final page in _pages.entries) {
    for (final width in const [360.0, 700.0, 1024.0]) {
      for (final scale in const [1.0, 1.3]) {
        final tag = '${page.key} w${width.toInt()} s$scale';
        testWidgets('QC layout $tag', (t) async {
          await _pumpAt(t, page.value, width: width, scale: scale);
          expect(_drain(t), isEmpty, reason: tag);
        });
      }
    }
  }

  // Shell: rail 15 destination + 5 tab bawahacross the whole range.
  for (final size in const [
    Size(320, 640),
    Size(360, 800),
    Size(600, 800),
    Size(768, 1024),
    Size(840, 900),
    Size(1024, 700),
    Size(1440, 900),
  ]) {
    final tag = 'shell ${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('QC layout $tag', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(
        MaterialApp(theme: SiakadTheme.light, home: const AdminShell()),
      );
      await t.pump(const Duration(milliseconds: 800));
      await t.pumpAndSettle();
      expect(_drain(t), isEmpty, reason: tag);
    });
  }
}
