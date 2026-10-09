import 'package:flutter/material.dart';

import '../admin/admin_shell.dart';
import 'login_page.dart';

/// Gerbang sesi demo: belum login → LoginPage, sudah → AdminShell.
/// State in-memory; ganti Riverpod + Supabase session saat backend wiring.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _npm;

  @override
  Widget build(BuildContext context) {
    final npm = _npm;
    if (npm == null) {
      return LoginPage(
        onSuccess: (signedInNpm) => setState(() => _npm = signedInNpm),
      );
    }
    return AdminShell(
      userLabel: npm.length >= 4 ? npm.substring(npm.length - 4) : npm,
      onLogout: () => setState(() => _npm = null),
    );
  }
}
