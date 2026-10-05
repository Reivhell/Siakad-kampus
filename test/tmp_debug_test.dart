import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/auth/login_page.dart';

void main() {
  testWidgets('debug tree', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(MaterialApp(
      home: LoginPage(onSuccess: (_) {}),
    ));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    final tf = find.byType(TextFormField).first;
    final el = tester.element(tf);
    final chain = <String>[];
    el.visitAncestorElements((a) {
      chain.add(a.widget.runtimeType.toString());
      return chain.length < 40;
    });
    debugPrint('CHAIN: ${chain.join(' > ')}');
    debugPrint('SCAFFOLD: ${find.byType(Scaffold).evaluate().length}');
    final e = tester.takeException();
    debugPrint('EX: $e');
  });
}
