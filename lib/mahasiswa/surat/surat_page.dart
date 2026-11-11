import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/widgets/bezel_card.dart';
import '../../admin/widgets/empty_state.dart';
import '../../admin/widgets/section_header.dart';
import '../../admin/widgets/status_badge.dart';
import '../../app/formatters.dart';
import '../../app/widgets/status_banner.dart';
import '../../features/mahasiswa/models/mahasiswa_layanan_models.dart';
import '../../features/mahasiswa/providers/mahasiswa_providers.dart';
import '../widgets/layanan_widgets.dart';
import '../widgets/page_body.dart';

/// Surat akademik + QR verifikasi (`10_surat_akademik.md`, EKSTENSI P2).
class SuratPage extends ConsumerWidget {
  const SuratPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(mahasiswaRepositoryProvider);
    final npm = ref.watch(currentNpmProvider);
    if (npm == null) {
      return const EmptyState(
        icon: Icons.person_off_outlined,
        title: 'Sesi tidak ditemukan',
        subtitle: 'Silakan masuk kembali.',
      );
    }
    if (repo.profile(npm) == null) {
      return const EmptyState(
        icon: Icons.person_off_outlined,
        title: 'Profil tidak ditemukan',
        subtitle: 'Hubungi administrator.',
      );
    }

    final rows = repo.suratMahasiswa(npm);
    final terbit = rows.where((s) => s.status == StatusSurat.terbit).length;
    final proses = rows.where((s) => s.status == StatusSurat.pengajuan).length;

    return PageBody(
      maxWidth: 1000,
      children: [
        SectionHeader(
          eyebrow: 'Layanan',
          title: 'Surat Akademik',
          subtitle:
              'Ajukan surat resmi kampus dan verifikasi keasliannya via QR.',
          action: FilledButton.tonalIcon(
            onPressed: () => _dialogAjukan(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Ajukan surat'),
          ),
        ),
        const StatusBanner(
          tone: StatusBannerTone.info,
          icon: Icons.qr_code_2,
          message:
              'Surat diterbitkan admin akademik. Nomor surat dan QR verifikasi '
              'muncul otomatis setelah status TERBIT.',
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Stat(label: 'Total pengajuan', value: '${rows.length}'),
            _Stat(label: 'Terbit', value: '$terbit'),
            _Stat(label: 'Diproses', value: '$proses'),
          ],
        ),
        SectionHeader(
          eyebrow: 'Riwayat',
          title: 'Daftar surat',
          subtitle: '${rows.length} pengajuan',
        ),
        if (rows.isEmpty)
          const BezelCard(child: Text('Belum ada pengajuan surat akademik.'))
        else
          for (final s in rows)
            _SuratCard(
              surat: s,
              onLihatQr: s.status == StatusSurat.terbit
                  ? () => _dialogQr(context, s)
                  : null,
              onBatalkan: s.status.bisaDibatalkan
                  ? () => _batalkan(context, ref, s)
                  : null,
            ),
        BezelCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.gavel_outlined, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Waktu proses normal 2–3 hari kerja. Surat yang sudah TERBIT '
                  'tidak dapat dibatalkan; ajukan surat baru bila ada '
                  'perubahan keperluan.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _dialogAjukan(BuildContext context, WidgetRef ref) async {
    var jenis = JenisSurat.keteranganAktif;
    final keperluan = TextEditingController();
    String? error;
    final hasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Ajukan surat akademik'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<JenisSurat>(
                  initialValue: jenis,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Jenis surat'),
                  items: [
                    for (final j in JenisSurat.values)
                      DropdownMenuItem(value: j, child: Text(j.label)),
                  ],
                  onChanged: (v) => setState(() => jenis = v ?? jenis),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keperluan,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Keperluan',
                    alignLabelWithHint: true,
                    hintText: 'Jelaskan tujuan penggunaan surat',
                  ),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final err = validasiKeperluanSurat(keperluan.text);
                if (err != null) {
                  setState(() => error = err);
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
    if (hasil != true) return;
    final err = ref
        .read(mahasiswaRepositoryProvider)
        .ajukanSurat(ref.read(currentNpmProvider)!, jenis, keperluan.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Pengajuan surat terkirim.'),
        backgroundColor: err == null
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _batalkan(
    BuildContext context,
    WidgetRef ref,
    SuratAkademik surat,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan pengajuan?'),
        content: Text('${surat.jenis.label} akan dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = ref
        .read(mahasiswaRepositoryProvider)
        .batalkanSurat(ref.read(currentNpmProvider)!, surat.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Pengajuan surat dibatalkan.'),
        backgroundColor: err == null
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _dialogQr(BuildContext context, SuratAkademik surat) async {
    final token = surat.verifikasiToken ?? surat.nomor ?? surat.id;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(surat.jenis.label),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrPlaceholder(token: token, size: 168),
              const SizedBox(height: 12),
              Text(
                surat.nomor ?? 'Nomor menyusul',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Pindai QR untuk memverifikasi keaslian surat. '
                'Halaman verifikasi dapat diakses tanpa login.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(
                surat.verifikasiUrl,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: surat.verifikasiUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tautan verifikasi disalin.')),
              );
            },
            child: const Text('Salin tautan'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return BezelCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _SuratCard extends StatelessWidget {
  final SuratAkademik surat;
  final VoidCallback? onLihatQr;
  final VoidCallback? onBatalkan;

  const _SuratCard({required this.surat, this.onLihatQr, this.onBatalkan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BezelCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                surat.status == StatusSurat.terbit
                    ? Icons.verified_outlined
                    : Icons.description_outlined,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          surat.jenis.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: surat.status.label,
                        tone: toneSurat(surat.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    surat.keperluan,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Diajukan ${formatTanggal(surat.diajukan)}'
                    '${surat.nomor != null ? ' · Nomor ${surat.nomor}' : ''}'
                    '${surat.terbit != null ? ' · Terbit ${formatTanggal(surat.terbit!)}' : ''}',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (onLihatQr != null || onBatalkan != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (onLihatQr != null)
                          TextButton.icon(
                            onPressed: onLihatQr,
                            icon: const Icon(Icons.qr_code_2, size: 16),
                            label: const Text('Lihat QR'),
                          ),
                        if (onBatalkan != null)
                          TextButton.icon(
                            onPressed: onBatalkan,
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('Batalkan'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
