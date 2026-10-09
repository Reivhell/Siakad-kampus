import 'package:flutter/material.dart';

/// Entry reveal GPU-safe: hanya transform + opacity.
/// Kurva massa-pegas: Cubic(0.32, 0.72, 0, 1), 700ms.
/// Jangan pakai untuk list panjang > 20 item sekaligus.
class Reveal extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const Reveal({super.key, required this.child, this.delayMs = 0});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  static const _curve = Cubic(0.32, 0.72, 0, 1);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = CurvedAnimation(parent: _c, curve: _curve);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: _curve));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Apple §14: reduced-motion → tampil statis, tanpa slide/spring.
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
