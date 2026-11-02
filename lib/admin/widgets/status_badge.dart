import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Badge pill AA — fill TIDAK pernah jadi teks (design.md §2.2).
/// Light: ink di atas surface. Dark: jewel di atas elevated + border.
enum BadgeTone { success, pending, danger, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final IconData icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon = Icons.fiber_manual_record,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    late Color bg;
    late Color fg;
    late Color border;
    switch (tone) {
      case BadgeTone.success:
        bg = dark ? AppColors.darkPassSurface : AppColors.passSurface;
        fg = dark ? AppColors.darkPass : AppColors.passInk;
        border = dark ? AppColors.darkPassBorder : const Color(0xFFBBF7D0);
      case BadgeTone.pending:
        bg = dark ? AppColors.darkAlertSurface : AppColors.alertSurface;
        fg = dark ? AppColors.darkAlert : AppColors.alertInk;
        border = dark ? AppColors.darkAlertBorder : const Color(0xFFFDE68A);
      case BadgeTone.danger:
        bg = dark ? AppColors.darkDangerSurface : AppColors.warningSurface;
        fg = dark ? AppColors.darkDanger : AppColors.dangerInk;
        border = dark ? AppColors.darkDangerBorder : const Color(0xFFFECACA);
      case BadgeTone.info:
        bg = dark ? AppColors.darkInfoSurface : AppColors.infoSurface;
        fg = dark ? AppColors.darkInfo : AppColors.infoInk;
        border = dark ? AppColors.darkInfoBorder : const Color(0xFFBAE6FD);
      case BadgeTone.neutral:
        bg = dark ? AppColors.darkSurfaceInteractive : AppColors.lightSurfaceRaised;
        fg = dark ? AppColors.darkTextSecondary : AppColors.neutralInk;
        border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    }
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
