import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/pages/transfer_page.dart';
import 'package:siakad_kampus/admin/pages/feeder_page.dart';
import 'package:siakad_kampus/admin/pages/letters_page.dart';
import 'package:siakad_kampus/admin/pages/advisor_page.dart';
import 'package:siakad_kampus/admin/pages/graduation_page.dart';
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
  testWidgets('wali render beban + wizard', (tester) async {
    await _surface(tester, const Size(1280, 1800));
    await _pump(tester, const AdvisorPage());
    expect(find.text('Dosen Wali & Bimbingan'), findsOneWidget);
    expect(find.textContaining('Aris Munandar'), findsOneWidget);
  });

  testWidgets('yudisium render calon + predikat', (tester) async {
    await _surface(tester, const Size(1280, 1800));
    await _pump(tester, const GraduationPage());
    expect(find.text('Kelulusan & Yudisium'), findsOneWidget);
    expect(find.text('MEMENUHI'), findsWidgets);
  });

  testWidgets('pddikti render skor + anomali', (tester) async {
    await _surface(tester, const Size(1280, 2000));
    await _pump(tester, const FeederPage());
    expect(find.text('Pelaporan Neo Feeder'), findsOneWidget);
    expect(find.textContaining('SIAP LAPOR'), findsOneWidget);
  });

  testWidgets('konversi render matriks', (tester) async {
    await _surface(tester, const Size(1280, 1800));
    await _pump(tester, const TransferPage());
    expect(find.text('Transfer & MBKM'), findsOneWidget);
    expect(find.textContaining('Bagus Prasetyo'), findsOneWidget);
  });

  testWidgets('surat render antrean', (tester) async {
    await _surface(tester, const Size(1280, 1800));
    await _pump(tester, const LettersPage());
    expect(find.text('Persuratan Akademik'), findsOneWidget);
    expect(find.text('Periksa'), findsWidgets);
  });
}
