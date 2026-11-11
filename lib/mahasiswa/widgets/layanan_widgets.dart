import 'package:flutter/material.dart';

import '../../admin/widgets/status_badge.dart';
import '../../features/mahasiswa/models/mahasiswa_layanan_models.dart';

BadgeTone tonePengajuan(StatusPengajuan status) => switch (status) {
  StatusPengajuan.pengajuan => BadgeTone.pending,
  StatusPengajuan.disetujui => BadgeTone.info,
  StatusPengajuan.selesai => BadgeTone.success,
  StatusPengajuan.ditolak => BadgeTone.danger,
  StatusPengajuan.dibatalkan => BadgeTone.neutral,
};

BadgeTone toneSurat(StatusSurat status) => switch (status) {
  StatusSurat.pengajuan => BadgeTone.pending,
  StatusSurat.terbit => BadgeTone.success,
  StatusSurat.ditolak => BadgeTone.danger,
  StatusSurat.dibatalkan => BadgeTone.neutral,
};

BadgeTone toneBimbingan(StatusBimbingan status) => switch (status) {
  StatusBimbingan.diajukan => BadgeTone.pending,
  StatusBimbingan.disetujui => BadgeTone.info,
  StatusBimbingan.selesai => BadgeTone.success,
  StatusBimbingan.ditolak => BadgeTone.danger,
};

BadgeTone toneKurikulum(StatusKurikulum status) => switch (status) {
  StatusKurikulum.lulus => BadgeTone.success,
  StatusKurikulum.berjalan => BadgeTone.info,
  StatusKurikulum.belum => BadgeTone.neutral,
};

/// QR verifikasi surat tiruan (deterministik dari token).
///
/// Hanya representasi visual untuk demo frontend; pada fase backend QR
/// dihasilkan dari URL verifikasi resmi. Tidak butuh dependensi tambahan.
class QrPlaceholder extends StatelessWidget {
  final String token;
  final double size;

  const QrPlaceholder({super.key, required this.token, this.size = 132});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'QR verifikasi surat $token',
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dark ? Colors.white : const Color(0xFFE2E8F0),
          ),
        ),
        child: CustomPaint(painter: _QrPainter(token)),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final String token;

  _QrPainter(this.token);

  static const _grid = 21;

  bool _sel(int x, int y) {
    if (x < 0 || y < 0 || x >= _grid || y >= _grid) return false;
    // Finder pattern 7x7 di tiga sudut.
    bool finder(int ox, int oy) {
      final dx = x - ox;
      final dy = y - oy;
      if (dx < 0 || dy < 0 || dx > 6 || dy > 6) return false;
      final border = dx == 0 || dy == 0 || dx == 6 || dy == 6;
      final core = dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4;
      return border || core;
    }

    if (finder(0, 0) || finder(_grid - 7, 0) || finder(0, _grid - 7)) {
      return true;
    }
    if ((x < 8 && y < 8) ||
        (x >= _grid - 8 && y < 8) ||
        (x < 8 && y >= _grid - 8)) {
      return false;
    }
    final h = token.codeUnits.fold<int>(
      17,
      (acc, c) => (acc * 31 + c) & 0x7fffffff,
    );
    final v = (h ^ (x * 73856093) ^ (y * 19349663)) & 0x7fffffff;
    return v % 3 == 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _grid;
    final paint = Paint()..color = const Color(0xFF0F172A);
    for (var y = 0; y < _grid; y++) {
      for (var x = 0; x < _grid; x++) {
        if (!_sel(x, y)) continue;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.2, cell + 0.2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.token != token;
}

/// Baris metrik ringkas untuk kartu ringkasan.
class MetricLine extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const MetricLine({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
