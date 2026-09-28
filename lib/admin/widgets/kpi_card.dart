import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'bezel_card.dart';

/// Metric KPI — icon lembut + angka tabular besar + sub-keterangan.
/// Star emas hanya untuk IPK cumlaude (design.md §6.1).
class KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final bool starGold;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.starGold = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return BezelCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: cs.primary),
              ),
              const Spacer(),
              if (starGold)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: dark
                        ? AppColors.darkGold.withValues(alpha: 0.14)
                        : const Color(0xFFFFF9C4),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: dark
                          ? AppColors.darkGold.withValues(alpha: 0.4)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: dark
                            ? AppColors.darkGold
                            : const Color(0xFFA16207),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cumlaude',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(
                              color: dark
                                  ? AppColors.darkGold
                                  : const Color(0xFF854D0E),
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
