import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/pages/civitas_page.dart';
import 'package:siakad_kampus/admin/pages/krs_page.dart';
import 'package:siakad_kampus/admin/pages/scheduling_page.dart';
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
  testWidgets('civitas render mhs + dosen', (tester) async {
    await _surface(tester, const Size(1280, 1600));
    await _pump(tester, const CivitasPage());
    expect(find.text('Civitas Akademika'), findsOneWidget);
    expect(find.textContaining('2610010001'), findsOneWidget);
    await tester.tap(find.text('Dosen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('0412088501'), findsOneWidget);
  });

  testWidgets('scheduling render slot + kelas', (tester) async {
    await _surface(tester, const Size(1280, 2000));
    await _pump(tester, const SchedulingPage());
    expect(find.text('Kelas & Penjadwalan'), findsOneWidget);
    expect(find.textContaining('TI101-A'), findsWidgets);
  });

  testWidgets('krs render antrean + plafon', (tester) async {
    await _surface(tester, const Size(1280, 2000));
    await _pump(tester, const KrsPage());
    expect(find.text('Administrasi KRS'), findsOneWidget);
    expect(find.textContaining('2410010050'), findsOneWidget);
    expect(find.text('Force-Add'), findsWidgets);
  });
}
