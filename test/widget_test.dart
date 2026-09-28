import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/admin/admin_shell.dart';
import 'package:siakad_kampus/app/theme/app_colors.dart';
import 'package:siakad_kampus/main.dart';

Future<void> _setSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
}

void main() {
  testWidgets('app memakai SiakadTheme light di kanvas terang', (tester) async {
    await _setSurface(tester);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const SiakadApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(AdminShell));
    final theme = Theme.of(ctx);

    expect(theme.colorScheme.primary, AppColors.indigoBlue);
    expect(theme.scaffoldBackgroundColor, AppColors.lightBg);
  });

  testWidgets('dark mode memakai lapisan Nocturne Academic', (tester) async {
    await _setSurface(tester);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const SiakadApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.byType(AdminShell)));

    expect(theme.colorScheme.primary, AppColors.darkPrimary);
    expect(theme.scaffoldBackgroundColor, AppColors.darkBg);
  });
}
