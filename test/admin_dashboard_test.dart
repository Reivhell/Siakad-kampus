import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/pages/admin_dashboard_page.dart';
import 'package:siakad_kampus/app/theme/siakad_theme.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: SiakadTheme.light, home: Scaffold(body: child));

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
}

void main() {
  testWidgets('dashboard render KPI + warning + antrean (desktop)', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 2200));
    await tester.pumpWidget(_wrap(const AdminDashboardPage()));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('Mahasiswa Aktif'), findsOneWidget);
    expect(find.text('Pusat Peringatan Dini'), findsOneWidget);
    expect(find.text('Antrean Persetujuan'), findsOneWidget);
    expect(find.text('Jejak Aktivitas Live'), findsOneWidget);
    expect(find.text('Kesehatan Sistem'), findsOneWidget);
  });

  testWidgets('mobile <600 pakai carousel KPI horizontal', (tester) async {
    await _setSurface(tester, const Size(390, 1600));
    await tester.pumpWidget(_wrap(const AdminDashboardPage()));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('Mahasiswa Aktif'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.horizontal,
      ),
      findsOneWidget,
    );
  });

  testWidgets('presentation mode samarkan angka sensitif', (tester) async {
    await _setSurface(tester, const Size(1280, 2200));
    await tester.pumpWidget(_wrap(const AdminDashboardPage()));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Presentasi: OFF'));
    await tester.pumpAndSettle();
    expect(find.text('1.4xx'), findsOneWidget);
  });
}
