import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_kampus/admin/pages/advisor_page.dart';
import 'package:siakad_kampus/admin/pages/krs_page.dart';
import 'package:siakad_kampus/admin/pages/transfer_page.dart';
import 'package:siakad_kampus/app/theme/siakad_theme.dart';

Future<void> qc(WidgetTester t, Widget p, String tag) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1.0;
  t.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await t.pumpWidget(
    MaterialApp(theme: SiakadTheme.light, home: Scaffold(body: p)),
  );
  await t.pump(const Duration(milliseconds: 800));
  await t.pumpAndSettle();
  for (final v in find.byType(Scrollable).evaluate()) {
    final s = v.widget as Scrollable;
    if (s.axis == Axis.vertical) {
      await t.drag(find.byWidget(s), const Offset(0, -3000));
      await t.pumpAndSettle();
    }
  }
  final errs = <Object>[];
  Object? e = t.takeException();
  while (e != null) {
    errs.add(e);
    e = t.takeException();
  }
  expect(errs, isEmpty, reason: '$tag: $errs');
}

void main() {
  testWidgets('QC big-text advisor', (t) async => qc(t, const AdvisorPage(), 'advisor'));
  testWidgets('QC big-text krs', (t) async => qc(t, const KrsPage(), 'krs'));
  testWidgets('QC big-text transfer', (t) async => qc(t, const TransferPage(), 'transfer'));
}
