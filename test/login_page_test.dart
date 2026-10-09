import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/admin_shell.dart';
import 'package:siakad_kampus/app/theme/app_colors.dart';
import 'package:siakad_kampus/auth/auth_gate.dart';
import 'package:siakad_kampus/auth/login_page.dart';
import 'package:siakad_kampus/main.dart';

Future<void> _surface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
}

Future<void> _pumpGate(WidgetTester tester) async {
  await tester.pumpWidget(const SiakadApp());
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

Future<void> _loginAs(
  WidgetTester tester,
  String npm,
  String password,
) async {
  await tester.enterText(find.byType(TextFormField).at(0), npm);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
  await tester.pump(); // loading
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 500)); // success beat
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app memakai SiakadTheme light di kanvas terang', (tester) async {
    await _surface(tester, const Size(1440, 1600));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const SiakadApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(LoginPage));
    final theme = Theme.of(ctx);

    expect(theme.colorScheme.primary, AppColors.indigoBlue);
    expect(theme.scaffoldBackgroundColor, AppColors.lightBg);
  });

  testWidgets('dark mode memakai lapisan Nocturne Academic', (tester) async {
    await _surface(tester, const Size(1440, 1600));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const SiakadApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.byType(LoginPage)));

    expect(theme.colorScheme.primary, AppColors.darkPrimary);
    expect(theme.scaffoldBackgroundColor, AppColors.darkBg);
  });

  testWidgets('login page tampil + toggle sandi', (tester) async {
    await _surface(tester, const Size(390, 844));
    await _pumpGate(tester);

    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('NPM'), findsOneWidget);

    // Toggle tampil/sembunyi sandi.
    await tester.tap(find.byTooltip('Tampilkan sandi'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Sembunyikan sandi'), findsOneWidget);
  });

  testWidgets('NPM invalid tampilkan error, tidak masuk shell', (tester) async {
    await _surface(tester, const Size(390, 844));
    await _pumpGate(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '123');
    await tester.enterText(find.byType(TextFormField).at(1), 'rahasia');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('NPM harus tepat 10 digit.'), findsOneWidget);
    expect(find.byType(AdminShell), findsNothing);
  });

  testWidgets('login valid → shell + keluar kembali ke login', (tester) async {
    await _surface(tester, const Size(390, 844));
    await _pumpGate(tester);
    await _loginAs(tester, '2610010042', 'rahasia');

    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);

    // Keluar via menu akun.
    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(AdminShell), findsNothing);
  });

  testWidgets('AuthGate desktop tampil panel merek', (tester) async {
    await _surface(tester, const Size(1440, 1000));
    await tester.pumpWidget(
      const MaterialApp(home: AuthGate()),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.textContaining('SIAKAD'), findsWidgets);
    expect(find.text('Masuk'), findsWidgets);
  });

  testWidgets('login render bersih di dark mode', (tester) async {
    await _surface(tester, const Size(390, 844));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpGate(tester);

    expect(find.text('Masuk'), findsWidgets);
  });
}
