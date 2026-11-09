import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:siakad_kampus/shared/api_client.dart';
import 'package:siakad_kampus/shared/app_session.dart';
import 'package:siakad_kampus/shared/login/login_page.dart';

void main() {
  testWidgets('debug tree', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(MaterialApp(
      home: LoginPage(
        onSuccess: (session) {},
        apiClient: ApiClient(baseUrl: 'http://test', client: _FakeHttpClient()),
      ),
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

class _FakeHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = '{}';
    final bytes = utf8.encode(body);
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
