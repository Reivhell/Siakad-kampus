import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Double-Bezel (Doppelrand) — outer shell + inner core.
/// Spec visual: high-end-visual-design §4A, token: design.md §4.
/// Light: outer #F1F5F9 + border #E2E8F0, inner white.
/// Dark (Nocturne): outer #16233B, inner #0E172B, border #1E2E4A.
class BezelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? onTapHint;

  const BezelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.semanticLabel,
    this.onTapHint,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final outer = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceRaised,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: dark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: dark
                ? AppColors.darkBorder
                : AppColors.lightBorder.withValues(alpha: 0.7),
          ),
          gradient: dark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.darkBezelTop, AppColors.darkSurface],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.lightSurface, AppColors.lightBg],
                ),
          boxShadow: [
            if (!dark)
              const BoxShadow(
                color: AppColors.bezelShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: child,
      ),
    );
    if (onTap == null) return outer;
    return Semantics(
      button: true,
      label: semanticLabel,
      hint: onTapHint,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          autofocus: false,
          child: outer,
        ),
      ),
    );
  }
}
