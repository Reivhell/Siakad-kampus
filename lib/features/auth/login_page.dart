import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/widgets/bezel_card.dart';
import '../../app/widgets/status_banner.dart';
import 'auth_providers.dart';

/// Login §14 + §27 (Login → Dashboard). Guard role ditangani router.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _identitas = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _memproses = false;
  String? _error;

  @override
  void dispose() {
    _identitas.dispose();
    _password.dispose();
    super.dispose();
  }

  void _isiDemo(String identitas, String password) {
    setState(() {
      _identitas.text = identitas;
      _password.text = password;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_memproses) return;
    setState(() {
      _memproses = true;
      _error = null;
    });
    final hasil = ref
        .read(authRepositoryProvider)
        .signIn(_identitas.text, _password.text);
    if (!mounted) return;
    if (!hasil.sukses) {
      setState(() {
        _memproses = false;
        _error = hasil.error;
      });
      return;
    }
    ref.read(authSessionProvider).signIn(hasil.account!);
    if (mounted) setState(() => _memproses = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SIAKAD KAMPUS',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(letterSpacing: 1.5),
                          ),
                          Text(
                            'Sistem Informasi Akademik',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Masuk ke akun Anda',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gunakan email atau NPM terdaftar.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  BezelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: const Key('login-identifier'),
                          controller: _identitas,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email atau NPM',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          key: const Key('login-password'),
                          controller: _password,
                          obscureText: _obscure,
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? 'Tampilkan password'
                                  : 'Sembunyikan password',
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          StatusBanner(
                            tone: StatusBannerTone.danger,
                            icon: Icons.error_outline,
                            message: _error!,
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          key: const Key('login-submit'),
                          onPressed: _memproses ? null : _submit,
                          icon: _memproses
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(
                            _memproses ? 'Memproses…' : 'Masuk',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'AKUN DEMO',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 2,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        key: const Key('demo-admin'),
                        avatar: const Icon(Icons.admin_panel_settings, size: 18),
                        label: const Text('Admin'),
                        onPressed: () =>
                            _isiDemo('admin@kampus.ac.id', 'Admin123!'),
                      ),
                      ActionChip(
                        key: const Key('demo-siti'),
                        avatar: const Icon(Icons.school_outlined, size: 18),
                        label: const Text('Mahasiswa · Siti'),
                        onPressed: () => _isiDemo(
                          'siti.261001@mhs.kampus.ac.id',
                          'Mahasiswa123!',
                        ),
                      ),
                      ActionChip(
                        key: const Key('demo-reza'),
                        avatar: const Icon(Icons.receipt_long_outlined, size: 18),
                        label: const Text('Mahasiswa · Reza (UKT belum)'),
                        onPressed: () => _isiDemo(
                          'reza.241016@mhs.kampus.ac.id',
                          'Mahasiswa123!',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Akun terkunci (uji validasi): rendy.251002@mhs.kampus.ac.id',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
