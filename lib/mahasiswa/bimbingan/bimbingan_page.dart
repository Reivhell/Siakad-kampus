import 'package:flutter/material.dart';
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

/// Bimbingan akademik / dosen wali (`08_bimbingan_dan_dosen_wali.md`).
class BimbinganPage extends ConsumerWidget {
  const BimbinganPage({super.key});

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
    final profile = repo.profile(npm);
    if (profile == null) {
      return const EmptyState(
        icon: Icons.person_off_outlined,
        title: 'Profil tidak ditemukan',
        subtitle: 'Hubungi administrator.',
      );
    }

    final rows = repo.bimbinganMahasiswa(npm);
    final berikutnya = repo.bimbinganBerikutnya(npm);
    final selesai = rows
        .where((b) => b.status == StatusBimbingan.selesai)
        .length;
    final menunggu = rows
        .where((b) => b.status == StatusBimbingan.diajukan)
        .length;
    final punyaPa = profile.dosenWali.trim().isNotEmpty;

    return PageBody(
      maxWidth: 1000,
      children: [
        SectionHeader(
          eyebrow: 'Pembimbingan',
          title: 'Bimbingan & Dosen Wali',
          subtitle:
              'Konsultasi akademik dengan dosen pembimbing akademik (PA).',
          action: FilledButton.tonalIcon(
            onPressed: punyaPa
                ? () => _dialogBimbingan(context, ref, profile.dosenWali)
                : null,
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Ajukan konsultasi'),
          ),
        ),
        if (!punyaPa)
          const StatusBanner(
            tone: StatusBannerTone.warning,
            icon: Icons.person_search_outlined,
            message:
                'Dosen wali belum ditetapkan. Hubungi admin akademik agar '
                'plotting PA dapat dilakukan.',
          ),
        BezelCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                child: Text(
                  punyaPa
                      ? profile.dosenWali.substring(0, 1).toUpperCase()
                      : '?',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      punyaPa ? profile.dosenWali : 'Belum ada dosen wali',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Pembimbing akademik · ${profile.prodi}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: punyaPa ? 'PA AKTIF' : 'BELUM ADA PA',
                tone: punyaPa ? BadgeTone.success : BadgeTone.danger,
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Stat(label: 'Total sesi', value: '${rows.length}'),
            _Stat(label: 'Selesai', value: '$selesai'),
            _Stat(label: 'Menunggu', value: '$menunggu'),
          ],
        ),
        if (berikutnya != null)
          StatusBanner(
            tone: StatusBannerTone.info,
            icon: Icons.event_note_outlined,
            message:
                'Sesi berikutnya: "${berikutnya.topik}" pada '
                '${formatTanggal(berikutnya.tanggal)} '
                '(${berikutnya.status.label}).',
          ),
        SectionHeader(
          eyebrow: 'Riwayat',
          title: 'Log konsultasi',
          subtitle: '${rows.length} catatan bimbingan',
        ),
        if (rows.isEmpty)
          const BezelCard(
            child: Text(
              'Belum ada sesi bimbingan. Ajukan konsultasi pertama Anda.',
            ),
          )
        else
          for (final b in rows) _BimbinganCard(entry: b),
        BezelCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jika PA berhalangan lebih dari 7 hari, eskalasi ke admin '
                  'akademik atau Ketua Program Studi. Setiap sesi dicatat '
                  'pada log aktivitas (MAHASISWA_KONSULTASI).',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _dialogBimbingan(
    BuildContext context,
    WidgetRef ref,
    String dosen,
  ) async {
    final topik = TextEditingController();
    final catatan = TextEditingController();
    String? error;
    final hasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Ajukan konsultasi'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dosen wali: $dosen',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topik,
                  autofocus: true,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Topik konsultasi',
                    hintText: 'Contoh: rencana KRS dan beban SKS',
                  ),
                ),
                TextField(
                  controller: catatan,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Catatan tambahan (opsional)',
                    alignLabelWithHint: true,
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
                final err = validasiTopikBimbingan(topik.text);
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
        .ajukanBimbingan(
          ref.read(currentNpmProvider)!,
          topik.text,
          catatan: catatan.text,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Pengajuan konsultasi terkirim.'),
        backgroundColor: err == null
            ? null
            : Theme.of(context).colorScheme.error,
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

class _BimbinganCard extends StatelessWidget {
  final BimbinganEntry entry;

  const _BimbinganCard({required this.entry});

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
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.forum_outlined, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.topik,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: entry.status.label,
                        tone: toneBimbingan(entry.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatTanggal(entry.tanggal)} · ${entry.dosen}',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (entry.catatan != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.catatan!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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
