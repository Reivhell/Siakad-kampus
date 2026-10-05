import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/pages/admin_dashboard_page.dart';
import 'package:siakad_kampus/admin/pages/users_page.dart';
import 'package:siakad_kampus/app/theme/siakad_theme.dart';

Future<void> qcDark(WidgetTester t, Widget p) async {
  t.view.physicalSize = const Size(1280, 1800);
  t.view.devicePixelRatio = 1.0;
  t.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.platformDispatcher.clearPlatformBrightnessTestValue();
  });
  await t.pumpWidget(
    MaterialApp(
      theme: SiakadTheme.light,
      darkTheme: SiakadTheme.dark,
      themeMode: ThemeMode.dark,
      home: Scaffold(body: p),
    ),
  );
  await t.pump(const Duration(milliseconds: 800));
  await t.pumpAndSettle();
  final errs = <Object>[];
  Object? e = t.takeException();
  while (e != null) {
    errs.add(e);
    e = t.takeException();
  }
  expect(errs, isEmpty, reason: 'dark: $errs');
}

void main() {
  testWidgets('QC dark dashboard', (t) async => qcDark(t, const AdminDashboardPage()));
  testWidgets('QC dark users', (t) async => qcDark(t, const UsersPage()));
}
