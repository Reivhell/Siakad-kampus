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
        bg = dark ? AppColors.darkSuccessSurface : AppColors.passSurface;
        fg = dark ? AppColors.darkPass : AppColors.passInk;
        border = dark ? AppColors.darkSuccessBorder : AppColors.passBorder;
      case BadgeTone.pending:
        bg = dark ? AppColors.darkWarningSurface : AppColors.alertSurface;
        fg = dark ? AppColors.darkAlert : AppColors.alertInk;
        border = dark ? AppColors.darkWarningBorder : AppColors.alertBorder;
      case BadgeTone.danger:
        bg = dark ? AppColors.darkDangerSurface : AppColors.warningSurface;
        fg = dark ? AppColors.darkDanger : AppColors.dangerInk;
        border = dark ? AppColors.darkDangerBorder : AppColors.dangerBorder;
      case BadgeTone.info:
        bg = dark ? AppColors.darkInfoSurface : AppColors.infoSurface;
        fg = dark ? AppColors.darkInfo : AppColors.infoInk;
        border = dark ? AppColors.darkInfoBorder : AppColors.infoBorder;
      case BadgeTone.neutral:
        bg = dark
            ? AppColors.darkSurfaceInteractive
            : AppColors.lightSurfaceRaised;
        fg = dark ? AppColors.darkTextSecondary : AppColors.neutralInk;
        border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    }
    // Badge tidak boleh jadi pencuri ruang: di HP label panjang
    // ("Minggu 8/16", "MENUNGGU_APPROVAL") mengklaim lebih dari separuh
    // layar dan menyisakan 30px untuk judul di sebelahnya. Cap ikut viewport.
    final screen = MediaQuery.sizeOf(context).width;
    final cap = screen * 0.45 < 260 ? screen * 0.45 : 260.0;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cap),
          child: Wrap(
            // Wrap, bukan Row: Row meledak saat label lebih lebar dari
            // ruang sisa (HP 360px), Wrap memindah label ke baris berikut.
            // Intrinsic-safe juga — DataTable/Row mengukur tanpa batas,
            // di sana semua anak tetap satu baris.
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(icon, size: 10, color: fg),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
