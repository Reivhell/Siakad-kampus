import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/admin_shell.dart';
import 'package:siakad_kampus/app/theme/siakad_theme.dart';

Future<void> _mobile(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
  tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    MaterialApp(theme: SiakadTheme.light, home: const AdminShell()),
  );
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tab Menu buka drawer, bukan pindah page', (tester) async {
    await _mobile(tester);
    expect(find.text('Mahasiswa Aktif'), findsOneWidget); // dashboard
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    // Drawer terbuka + masih di dashboard (tidak nyasar ke Audit Log)
    expect(find.text('Audit Log'), findsWidgets);
    expect(find.text('Mahasiswa Aktif'), findsOneWidget);
  });

  testWidgets('drawer navigasi sinkron + bottom ikut', (tester) async {
    await _mobile(tester);
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Nilai'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Monitoring Nilai'), findsOneWidget);
    // Drawer item lain di luar 4 tab → bottom tetap di Menu
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Pengguna & Role'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Manajemen Pengguna & Peran'), findsOneWidget);
  });

  testWidgets('bottom tab Kelas/KRS/Nilai pindah langsung', (tester) async {
    await _mobile(tester);
    final bar = find.byType(NavigationBar);
    await tester.tap(find.descendant(of: bar, matching: find.text('KRS')));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Administrasi KRS'), findsOneWidget);
    await tester.tap(find.descendant(of: bar, matching: find.text('Nilai')));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Monitoring Nilai'), findsOneWidget);
  });
}
