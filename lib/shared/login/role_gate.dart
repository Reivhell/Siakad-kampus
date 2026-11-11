import 'package:flutter/material.dart';

import '../../admin/admin_shell.dart';
import '../../mahasiswa/mahasiswa_router.dart';
import '../../shared/api_client.dart';
import '../../shared/app_session.dart';
import '../../shared/auth_service.dart';
import 'login_page.dart';

/// Gerbang peran: belum login → [LoginPage], sudah → shell per peran.
///
/// [AuthService] memulihkan sesi dari penyimpanan saat pertama kali dibangun,
/// sehingga pengguna yang masih memiliki token valid langsung dialihkan ke
/// shell tanpa memasukkan ulang kredensial.
class RoleGate extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService auth;

  const RoleGate({super.key, required this.apiClient, required this.auth});

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    // Sesi sudah dipulihkan oleh AuthService.init() di main.dart. Tunggu satu
    // frame agar build pertama konsisten.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _initializing = false);
    });
  }

  void _logout() {
    setState(() => _initializing = true);
    widget.auth.logout().then((_) {
      if (mounted) setState(() => _initializing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const _Splash();
    }
    final session = widget.auth.session;
    if (session == null) {
      return LoginPage(
        onSuccess: (session) {
          widget.auth.setSession(session);
          if (mounted) setState(() {});
        },
        apiClient: widget.apiClient,
      );
    }
    return _shellFor(session);
  }

  Widget _shellFor(AppSession session) {
    final label = session.displayName.isNotEmpty ? session.displayName : session.npm;
    final short = label.length > 18 ? '${label.substring(0, 18)}…' : label;
    switch (session.role) {
      case AppRole.admin:
        return AdminShell(
          userLabel: short,
          onLogout: _logout,
          apiClient: widget.apiClient,
          auth: widget.auth,
        );
      case AppRole.dosen:
        return _RolePlaceholder(
          title: 'Dasbor Dosen',
          subtitle: 'Kelas, nilai, dan presensi menyusul di modul dosen.',
          userLabel: session.npm,
          onLogout: _logout,
        );
      case AppRole.mahasiswa:
        final npm = session.user['npm'] is String
            ? session.user['npm'] as String
            : session.npm;
        return MahasiswaRouter(npm: npm, onLogout: _logout);
    }
  }
}

/// Layar sambutan saat memulihkan sesi dari penyimpanan.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Layar tunggu per peran — diganti shell asli saat modulnya dibangun.
class _RolePlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  final String userLabel;
  final VoidCallback onLogout;

  const _RolePlaceholder({
    required this.title,
    required this.subtitle,
    required this.userLabel,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIAKAD'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(child: Text(userLabel)),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onLogout,
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
