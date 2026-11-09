import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../auth/auth_validators.dart';
import '../../shared/api_client.dart';
import '../../shared/app_session.dart';
import '../widgets/siakad_adaptive.dart';

/// Gerbang masuk bersama seluruh peran — `lib/shared/login/`.
///
/// Satu pintu (referensi: `fitur_admin/login.png`): mahasiswa, dosen,
/// admin login di sini; [RoleGate] membedakan hak akses setelah
/// autentikasi. Halaman ini disengaja gelap penuh di kedua mode
/// terang/gelap; token yang dipakai tetap milik [AppColors].
class LoginPage extends StatefulWidget {
  final ValueChanged<AppSession> onSuccess;
  final ApiClient apiClient;

  const LoginPage({
    super.key,
    required this.onSuccess,
    required this.apiClient,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _npm = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = false;
  bool _busy = false;
  final bool _done = false;
  String? _serverError;

  late final AnimationController _shakeCtl;
  late final Animation<double> _shake;

  static final _shakeSeq = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 22),
    TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 7.0, end: -4.0), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 4.0, end: -3.0), weight: 18),
    TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 20),
  ]);

  @override
  void initState() {
    super.initState();
    _shakeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _shake = _shakeSeq.animate(
      CurvedAnimation(parent: _shakeCtl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _shakeCtl.dispose();
    _npm.dispose();
    _password.dispose();
    super.dispose();
  }

  void _shakeForm() {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    _shakeCtl.forward(from: 0);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      _shakeForm();
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await widget.apiClient.login(
        _npm.text.trim(),
        _password.text,
      );
      if (!mounted) return;
      widget.onSuccess(
        AppSession(
          npm: result.npm,
          role: resolveRole(result.npm, user: result.user),
          token: result.token,
          user: result.user,
        ),
      );
      return;
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _serverError = e.toString();
      });
      _shakeForm();
      return;
    }
  }

  void _soon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature segera hadir.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024) return _wide(context);
          return _mobile(context);
        },
      ),
    );
  }

  Widget _wide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(flex: 11, child: _CampusPanel()),
        Expanded(
          flex: 9,
          child: ColoredBox(
            color: AppColors.darkBg,
            child: Stack(
              children: [
                const Positioned(top: 28, right: 40, child: _Wordmark()),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(48, 96, 48, 48),
                    child: _LoginCard(
                      formKey: _formKey,
                      npm: _npm,
                      password: _password,
                      obscure: _obscure,
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                      remember: _remember,
                      onToggleRemember: (v) =>
                          setState(() => _remember = v ?? false),
                      busy: _busy,
                      done: _done,
                      serverError: _serverError,
                      shake: _shake,
                      onSubmit: _submit,
                      onForgot: () => _soon('Reset kata sandi'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobile(BuildContext context) {
    return ColoredBox(
      color: AppColors.darkBg,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 300, child: _CampusPanel(compact: true)),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
                child: _LoginCard(
                  formKey: _formKey,
                  npm: _npm,
                  password: _password,
                  obscure: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  remember: _remember,
                  onToggleRemember: (v) =>
                      setState(() => _remember = v ?? false),
                  busy: _busy,
                  done: _done,
                  serverError: _serverError,
                  shake: _shake,
                  onSubmit: _submit,
                  onForgot: () => _soon('Reset kata sandi'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel kampus senja: merek + headline. Foto dari
/// `assets/images/login_campus.jpg` bila ada; gradasi senja bila belum.
class _CampusPanel extends StatelessWidget {
  final bool compact;

  const _CampusPanel({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayStyle =
        (compact ? textTheme.displaySmall : textTheme.displayLarge)?.copyWith(
          height: 1.15,
          letterSpacing: -0.5,
        );
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A1328), Color(0xFF16264A), Color(0xFF3D3428)],
            ),
          ),
        ),
        Image.asset(
          'assets/images/login_campus.jpg',
          fit: BoxFit.cover,
          semanticLabel: 'Gedung kampus saat senja',
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x59060A17), Color(0x00060A17), Color(0xCC060A17)],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 24 : 48,
            compact ? 24 : 44,
            compact ? 24 : 48,
            compact ? 20 : 56,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandRow(),
              const Spacer(),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Satu pintu.\n',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: 'Semua peran.',
                      style: TextStyle(color: AppColors.darkGold),
                    ),
                  ],
                  style: displayStyle,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 16),
                Text(
                  'Mahasiswa, dosen, dan admin masuk lewat pintu yang sama — hak akses dibedakan setelah autentikasi.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoTile(size: 44),
        SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sistem Informasi Akademik',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'SIAKAD KAMPUS',
                style: TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 11,
                  letterSpacing: 2.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ubin logo emas: gradasi + ikon topi toga. Tanpa custom painter.
class _LogoTile extends StatelessWidget {
  final double size;

  const _LogoTile({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkGold,
            AppColors.darkGold.withValues(alpha: 0.62),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 8),
            blurRadius: 24,
            color: Color(0x40000000),
          ),
        ],
      ),
      child: Icon(
        Icons.school_rounded,
        color: AppColors.darkBg,
        size: size * 0.52,
      ),
    );
  }
}

/// Wordmark kanan-atas sisi form.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SIAKAD KAMPUS',
          style: TextStyle(
            color: Color(0x8CFFFFFF),
            fontSize: 11,
            letterSpacing: 2.4,
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          width: 44,
          height: 2,
          child: ColoredBox(color: AppColors.darkGold),
        ),
      ],
    );
  }
}

/// Kartu form: field outline standar M3 + tombol emas + baris trust.
class _LoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController npm;
  final TextEditingController password;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool remember;
  final ValueChanged<bool?> onToggleRemember;
  final bool busy;
  final bool done;
  final String? serverError;
  final Animation<double> shake;
  final VoidCallback onSubmit;
  final VoidCallback onForgot;

  const _LoginCard({
    required this.formKey,
    required this.npm,
    required this.password,
    required this.obscure,
    required this.onToggleObscure,
    required this.remember,
    required this.onToggleRemember,
    required this.busy,
    required this.done,
    required this.serverError,
    required this.shake,
    required this.onSubmit,
    required this.onForgot,
  });

  static const _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: AppColors.darkBorder),
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 24),
            blurRadius: 64,
            color: Color(0x80000000),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: shake,
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: _LogoTile(size: 52),
              ),
              const SizedBox(height: 22),
              Text(
                'Masuk ke SIAKAD',
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gunakan akun Anda untuk melanjutkan ke sistem informasi akademik.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkTextSecondary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 26),
              TextFormField(
                controller: npm,
                validator: validateNpm,
                keyboardType: TextInputType.number,
                maxLength: 10,
                style: AppTypography.identifier(15)
                    .copyWith(color: AppColors.darkTextPrimary),
                decoration: const InputDecoration(
                  labelText: 'NPM',
                  hintText: 'cth. 2610010042',
                  floatingLabelStyle: TextStyle(color: AppColors.darkGold),
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: _fieldBorder,
                  enabledBorder: _fieldBorder,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(
                      color: AppColors.darkGold,
                      width: 1.5,
                    ),
                  ),
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: password,
                validator: (v) => validateLoginPassword(v ?? ''),
                obscureText: obscure,
                style: const TextStyle(color: AppColors.darkTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Kata sandi',
                  floatingLabelStyle: const TextStyle(
                    color: AppColors.darkGold,
                  ),
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    tooltip: obscure ? 'Tampilkan sandi' : 'Sembunyikan sandi',
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: _fieldBorder,
                  enabledBorder: _fieldBorder,
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(
                      color: AppColors.darkGold,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onSubmit(),
              ),
              if (serverError != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outlined,
                      size: 18,
                      color: AppColors.darkDanger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        serverError!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkDanger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Checkbox(
                    value: remember,
                    side: const BorderSide(color: AppColors.darkTextSecondary),
                    activeColor: AppColors.darkGold,
                    checkColor: AppColors.darkBg,
                    onChanged: onToggleRemember,
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onToggleRemember(!remember),
                      child: ConstrainedBox(
                        // Target sentuh minimal 44px; teks saja 20px.
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Ingat saya',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.darkTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onForgot,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.darkGold,
                    ),
                    child: const Text('Lupa sandi?'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: busy || done ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.darkGold,
                  foregroundColor: AppColors.darkBg,
                  disabledBackgroundColor: AppColors.darkGold.withValues(
                    alpha: 0.6,
                  ),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: busy
                    ? const SiakadLoading()
                    : done
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Berhasil'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Masuk'),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
              const SizedBox(height: 26),
              const Divider(color: AppColors.darkBorder, height: 1),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.darkGold,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SIAKAD Kampus',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.darkTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Aman • Terpercaya • Terintegrasi',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.darkTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        builder: (context, child) =>
            Transform.translate(offset: Offset(shake.value, 0), child: child),
      ),
    );
  }
}
