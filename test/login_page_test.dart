import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:siakad_kampus/admin/admin_shell.dart';
import 'package:siakad_kampus/app/theme/app_colors.dart';
import 'package:siakad_kampus/auth/auth_gate.dart';
import 'package:siakad_kampus/auth/login_page.dart';
import 'package:siakad_kampus/main.dart';
import 'package:siakad_kampus/shared/api_client.dart';
import 'package:siakad_kampus/shared/auth_service.dart';
import 'package:siakad_kampus/shared/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _surface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
}

ApiClient _testApiClient() => ApiClient(baseUrl: 'http://test', client: _FakeHttpClient());
AuthService _testAuth() => AuthService(apiClient: _testApiClient());

Future<void> _pumpGate(WidgetTester tester) async {
  await tester.pumpWidget(
    SiakadApp(apiClient: _testApiClient(), auth: _testAuth()),
  );
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

class _FakeHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isLogin = request.url.path.contains('/auth/login');
    final body = isLogin
        ? jsonEncode({
            'access_token': 'fake-jwt-token',
            'expires_at':
                DateTime.now().add(const Duration(hours: 12)).toUtc().toIso8601String(),
            'user': {
              'id': 'user-1',
              'email': '2610010042@kampus.ac.id',
              'nama_lengkap': 'Test User',
              'roles': ['ADMIN'],
            },
          })
        : '{}';
    final bytes = utf8.encode(body);
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<void> _loginAs(
  WidgetTester tester,
  String npm,
  String password,
) async {
  await tester.enterText(find.byType(TextFormField).at(0), npm);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  final masuk = find.widgetWithText(FilledButton, 'Masuk');
  await tester.ensureVisible(masuk);
  await tester.pumpAndSettle();
  await tester.tap(masuk);
  await tester.pump(); // loading
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 500)); // success beat
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 1500)); // penyimpanan sesi async
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SecureStorage.init();
  });

  testWidgets('app memakai SiakadTheme light di kanvas terang', (tester) async {
    await _surface(tester, const Size(1440, 1600));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      SiakadApp(apiClient: _testApiClient(), auth: _testAuth()),
    );
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

    await tester.pumpWidget(
      SiakadApp(apiClient: _testApiClient(), auth: _testAuth()),
    );
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
    final masuk = find.widgetWithText(FilledButton, 'Masuk');
    await tester.ensureVisible(masuk);
    await tester.pumpAndSettle();
    await tester.tap(masuk);
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
      MaterialApp(home: AuthGate(apiClient: _testApiClient(), auth: _testAuth())),
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
