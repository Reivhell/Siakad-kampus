import 'package:flutter/material.dart';

/// Eyebrow pill mikroskopis + judul. Spatial rhythm lega.
class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
          ),
          child: Text(
            eyebrow.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    final act = action;
    // Aksi rapat (tombol "Ekspor Snapshot" dll) memakan kolom Expanded
    // sampai 30px di 360px. Di bawah [_wideWithAction] aksi turun ke
    // baris sendiri dan judul dapat lebar penuh.
    if (act != null && MediaQuery.sizeOf(context).width < _wideWithAction) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [text, const SizedBox(height: 12), act],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: text),
        if (act != null) ...[const SizedBox(width: 16), act],
      ],
    );
  }

  /// Lebar saat aksi masih muat sebaris dengan judul.
  static const _wideWithAction = 700.0;
}
