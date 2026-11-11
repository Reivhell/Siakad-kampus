import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/shared/api_client.dart';
import 'package:siakad_kampus/shared/app_session.dart';
import 'package:siakad_kampus/shared/auth_service.dart';
import 'package:siakad_kampus/shared/login/login_page.dart';
import 'package:siakad_kampus/shared/login/role_gate.dart';

void main() {
  test('resolveRole menggunakan klaim roles dari backend', () {
    expect(
      resolveRole('u', user: {'roles': ['ADMIN']}),
      AppRole.admin,
    );
    expect(
      resolveRole('u', user: {'roles': ['DOSEN']}),
      AppRole.dosen,
    );
    expect(
      resolveRole('u', user: {'roles': ['MAHASISWA']}),
      AppRole.mahasiswa,
    );
    expect(resolveRole('2610010042'), AppRole.mahasiswa);
  });
  testWidgets('RoleGate awal tampilkan LoginPage', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final apiClient = ApiClient(baseUrl: 'http://test');
    final auth = AuthService(apiClient: apiClient);
    await tester.pumpWidget(
      MaterialApp(home: RoleGate(apiClient: apiClient, auth: auth)),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Masuk ke SIAKAD'), findsOneWidget);
    expect(find.textContaining('Satu pintu'), findsOneWidget);
    expect(find.textContaining('Semua peran'), findsOneWidget);
  });
}
