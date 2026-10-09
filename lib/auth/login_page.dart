import 'package:flutter/material.dart';

import '../admin/widgets/bezel_card.dart';
import '../admin/widgets/feedback.dart';
import '../admin/widgets/reveal.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_typography.dart';
import 'auth_validators.dart';

class LoginPage extends StatefulWidget {
  final ValueChanged<String> onSuccess;

  const LoginPage({super.key, required this.onSuccess});

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
  bool _done = false;
  String? _serverError;

  late final AnimationController _shakeCtl;
  late final Animation<double> _shake;

  static final _shakeSeq = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 22),
    TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 7.0, end: -4.0), weight: 20),
    TweenSequenceItem(tween: Tween(begin: -4.0, end: 3.0), weight: 18),
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
    final error = await fakeSignIn(_npm.text, _password.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _serverError = error;
      });
      _shakeForm();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onSuccess(_npm.text.trim());
      return;
    }
    setState(() {
      _busy = false;
      _done = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    widget.onSuccess(_npm.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    if (wide) return _wide(context);
    return SafeArea(child: _mobile(context));
  }

  Widget _wide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 6, child: const _BrandPanel()),
        Container(width: 1, color: _hairline(context)),
        Expanded(flex: 5, child: _formSide(context)),
      ],
    );
  }

  Widget _mobile(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BrandPanel(compact: true),
          Transform.translate(
            offset: const Offset(0, -32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Reveal(delayMs: 140, child: _formCard(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formSide(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
          child: Reveal(delayMs: 140, child: _formCard(context)),
        ),
      ),
    );
  }

  Color _hairline(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? AppColors.darkBorder : AppColors.lightBorder;
  }

  Widget _formCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final body = Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EyebrowTag(label: 'MASUK'),
          const SizedBox(height: 12),
          Text('Masuk ke SIAKAD',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 24),
          TextFormField(
            controller: _npm,
            validator: validateNpm,
            keyboardType: TextInputType.number,
            maxLength: 10,
            style: AppTypography.identifier(15),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'NPM',
              hintText: 'cth. 2610010042',
              prefixIcon: Icon(Icons.badge_outlined),
              counterText: '',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          _NpmMeter(count: _npm.text.length),
          const SizedBox(height: 20),
          TextFormField(
            controller: _password,
            validator: (v) => validateLoginPassword(v ?? ''),
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Kata sandi',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Tampilkan sandi' : 'Sembunyikan sandi',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _serverError == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outlined,
                            size: 18, color: cs.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _serverError!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: cs.error),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _remember,
                visualDensity: VisualDensity.compact,
                onChanged: (v) => setState(() => _remember = v ?? false),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _remember = !_remember),
                  child: const Text('Ingat saya'),
                ),
              ),
              TextButton(
                onPressed: () => soon(context, 'Reset kata sandi'),
                child: const Text('Lupa sandi?'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _IslandButton(
            onTap: _busy || _done ? null : _submit,
            child: FilledButton(
              onPressed: _busy || _done ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : _done
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Berhasil'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Masuk'),
                            SizedBox(width: 12),
                            _ButtonArrow(),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: BezelCard(
        padding: const EdgeInsets.all(24),
        child: AnimatedBuilder(
          animation: _shake,
          child: body,
          builder: (context, child) => Transform.translate(
            offset: Offset(_shake.value, 0),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _EyebrowTag extends StatelessWidget {
  final String label;

  const _EyebrowTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.primary.withValues(alpha: 0.1),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.identifier(10).copyWith(
              color: cs.primary,
              letterSpacing: 2,
            ),
      ),
    );
  }
}

class _ButtonArrow extends StatelessWidget {
  const _ButtonArrow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.onPrimary.withValues(alpha: 0.18),
      ),
      child: Icon(Icons.arrow_forward_rounded, size: 16, color: cs.onPrimary),
    );
  }
}

class _IslandButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _IslandButton({required this.child, this.onTap});

  @override
  State<_IslandButton> createState() => _IslandButtonState();
}

class _IslandButtonState extends State<_IslandButton> {
  double _scale = 1.0;

  void _set(bool down) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(() => _scale = down ? 0.97 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: const Cubic(0.32, 0.72, 0, 1),
        child: widget.child,
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final bool compact;

  const _BrandPanel({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.darkBg : AppColors.elegantNavy;
    final fg = dark ? AppColors.darkTextPrimary : Colors.white;
    final accent = dark ? AppColors.darkGold : AppColors.goldAccent;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: 0.6)],
                  ),
                ),
                child: Icon(Icons.school_rounded, color: bg, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sistem Informasi Akademik',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: fg),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SIAKAD KAMPUS',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            letterSpacing: 2.4,
                            color: fg.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DrawRule(color: accent),
          SizedBox(height: compact ? 28 : 48),
          Text.rich(
            TextSpan(
              text: 'Satu pintu.\nSemua peran.',
              style: TextStyle(color: fg),
              children: [
                TextSpan(
                  text: '.',
                  style: TextStyle(color: accent),
                ),
              ],
            ),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: compact ? 34 : 72,
                  height: 1.02,
                  letterSpacing: -0.03 * (compact ? 34 : 72),
                  color: fg,
                ),
          ),
          if (!compact) ...[
            const SizedBox(height: 20),
            Text(
              'Mahasiswa, dosen, dan admin masuk lewat pintu yang sama — hak akses dibedakan setelah autentikasi.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: fg.withValues(alpha: 0.65),
                    height: 1.6,
                  ),
            ),
          ],
        ],
      ),
    );

    final animated = _rise(context, child: content);

    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bg, bg.withValues(alpha: 0.95)],
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(36),
          ),
        ),
        child: animated,
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg, bg.withValues(alpha: 0.92)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(64, 64, 56, 64),
          child: animated,
        ),
      ),
    );
  }

  Widget _rise(BuildContext context, {required Widget child}) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: const Cubic(0.32, 0.72, 0, 1),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 24),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _DrawRule extends StatelessWidget {
  final Color color;

  const _DrawRule({required this.color});

  @override
  Widget build(BuildContext context) {
    final line = SizedBox(
      width: double.infinity,
      height: 2,
      child: ColoredBox(color: color),
    );
    if (MediaQuery.disableAnimationsOf(context)) return line;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: const Cubic(0.32, 0.72, 0, 1),
      builder: (context, t, _) => Transform.scale(
        alignment: Alignment.centerLeft,
        scaleX: t.clamp(0.0, 1.0),
        child: line,
      ),
    );
  }
}

class _NpmMeter extends StatelessWidget {
  final int count;

  const _NpmMeter({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final done = count >= 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < 10; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: const Cubic(0.32, 0.72, 0, 1),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < count
                        ? (done ? AppColors.goldAccent : cs.primary)
                        : cs.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$count/10',
            style: AppTypography.identifier(11).copyWith(
              color: done ? AppColors.goldAccent : cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
