import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Nada banner. Pasangan surface/ink/border dijaga di `AppColors` agar
/// kontras terang & gelap konsisten (design.md §2.2).
enum StatusBannerTone { success, warning, danger, info }

/// Banner status bersama untuk seluruh portal (mahasiswa, auth, admin).
///
/// Menggantikan banner inline yang dulu menduplikasi nilai hex gelap di
/// banyak halaman. Teks & aksi selalu memakai warna `ink` yang kontras
/// dengan surface-nya, baik light maupun dark mode.
class StatusBanner extends StatelessWidget {
  final StatusBannerTone tone;
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const StatusBanner({
    super.key,
    required this.tone,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    late final Color bg;
    late final Color fg;
    late final Color border;

    switch (tone) {
      case StatusBannerTone.success:
        bg = dark ? AppColors.darkSuccessSurface : AppColors.passSurface;
        fg = dark ? AppColors.darkPass : AppColors.passInk;
        border = dark ? AppColors.darkSuccessBorder : AppColors.passBorder;
      case StatusBannerTone.warning:
        bg = dark ? AppColors.darkWarningSurface : AppColors.alertSurface;
        fg = dark ? AppColors.darkAlert : AppColors.alertInk;
        border = dark ? AppColors.darkWarningBorder : AppColors.alertBorder;
      case StatusBannerTone.danger:
        bg = dark ? AppColors.darkDangerSurface : AppColors.warningSurface;
        fg = dark ? AppColors.darkDanger : AppColors.dangerInk;
        border = dark ? AppColors.darkDangerBorder : AppColors.dangerBorder;
      case StatusBannerTone.info:
        bg = dark ? AppColors.darkInfoSurface : AppColors.infoSurface;
        fg = dark ? AppColors.darkInfo : AppColors.infoInk;
        border = dark ? AppColors.darkInfoBorder : AppColors.infoBorder;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: fg),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: fg),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
