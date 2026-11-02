import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/admin_shell.dart';
import 'package:siakad_kampus/features/auth/login_page.dart';
import 'package:siakad_kampus/main.dart';
import 'package:siakad_kampus/mahasiswa/mahasiswa_shell.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());

  await tester.pumpWidget(const ProviderScope(child: SiakadApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login admin mengarah ke AdminShell', (tester) async {
    await _pumpApp(tester);
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.tap(find.byKey(const Key('demo-admin')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byType(AdminShell), findsOneWidget);
  });

  testWidgets('login mahasiswa mengarah ke portal mahasiswa', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('demo-siti')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byType(MahasiswaShell), findsOneWidget);
    expect(find.text('Halo, Siti Nurhaliza'), findsOneWidget);
  });

  testWidgets('akun terkunci ditolak dengan pesan', (tester) async {
    await _pumpApp(tester);

    await tester.enterText(
      find.byKey(const Key('login-identifier')),
      'rendy.251002@mhs.kampus.ac.id',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'Mahasiswa123!',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Akun terkunci.'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('password salah ditolak', (tester) async {
    await _pumpApp(tester);

    await tester.enterText(
      find.byKey(const Key('login-identifier')),
      'admin@kampus.ac.id',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'salah');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Password salah.'), findsOneWidget);
  });
}
