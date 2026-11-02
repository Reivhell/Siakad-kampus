import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/krs/admin_krs_page.dart';
import 'package:siakad_kampus/app/theme/siakad_theme.dart';
import 'package:siakad_kampus/features/mahasiswa/providers/mahasiswa_providers.dart';
import 'package:siakad_kampus/features/mahasiswa/repositories/mahasiswa_repository.dart';
import 'package:siakad_kampus/features/mahasiswa/seed/mahasiswa_seed.dart';

Widget _wrap() {
  return ProviderScope(
    overrides: [
      mahasiswaRepositoryProvider.overrideWith(
        (ref) => MahasiswaRepository.seed(),
      ),
      currentNpmProvider.overrideWithValue(npmSiti),
    ],
    child: MaterialApp(
      theme: SiakadTheme.light,
      home: const Scaffold(body: AdminKrsPage()),
    ),
  );
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
}

void main() {
  testWidgets('admin KRS menampilkan mata kuliah pada KRS mahasiswa', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 3000));
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Mata kuliah KRS (6 MK · 18 SKS)'), findsOneWidget);
    expect(find.textContaining('Basis Data'), findsWidgets);
    expect(
      find.text('Belum ada mata kuliah pada KRS periode ini.'),
      findsWidgets,
    );
  });

  testWidgets('admin KRS: tandai lunas membuka gate mahasiswa', (tester) async {
    await _setSurface(tester, const Size(1280, 3000));
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.textContaining('gate blokir'), findsNWidgets(2));
    expect(find.textContaining('gate lolos'), findsOneWidget);

    final tombol = find.widgetWithText(TextButton, 'Tandai lunas').first;
    await tester.ensureVisible(tombol);
    await tester.tap(tombol);
    await tester.pumpAndSettle();

    expect(find.textContaining('gate blokir'), findsOneWidget);
    expect(find.textContaining('gate lolos'), findsNWidgets(2));
  });
}
