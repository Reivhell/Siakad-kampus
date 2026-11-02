import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/widgets/bezel_card.dart';
import '../../admin/widgets/empty_state.dart';
import '../../admin/widgets/section_header.dart';
import '../../admin/widgets/status_badge.dart';
import '../../app/formatters.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/status_banner.dart';
import '../../features/mahasiswa/models/mahasiswa_models.dart';
import '../../features/mahasiswa/providers/mahasiswa_providers.dart';
import '../widgets/page_body.dart';

/// Presensi per pertemuan (`06_presensi_saya.md`).
class PresensiPage extends ConsumerWidget {
  const PresensiPage({super.key});

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

    final kelas = repo.kelasDipilih(npm);
    final kritis = repo.kelasPresensiKritis(npm);

    return PageBody(
      children: [
        SectionHeader(
          eyebrow: 'Kehadiran',
          title: 'Presensi Saya',
          subtitle:
              'Persentase = HADIR / pertemuan tercatat. '
              'Belum dicatat dosen tidak dihitung ALPHA.',
        ),
        if (kritis.isNotEmpty)
          StatusBanner(
            tone: StatusBannerTone.danger,
            icon: Icons.gpp_maybe_outlined,
            message:
                'Kehadiran di bawah 75% berisiko tidak memenuhi syarat UAS: '
                '${kritis.map((k) => k.namaMk).join(', ')}.',
          ),
        if (kelas.isEmpty)
          const BezelCard(child: Text('Belum ada kelas pada KRS periode ini.'))
        else
          for (final k in kelas)
            _KelasPresensiCard(
              kelas: k,
              rekap: rekapPresensi(k.id, repo.presensiKelas(npm, k.id)),
              rows: repo.presensiKelas(npm, k.id),
            ),
      ],
    );
  }
}

class _KelasPresensiCard extends StatelessWidget {
  final Kelas kelas;
  final RekapPresensi rekap;
  final List<PresensiRecord> rows;

  const _KelasPresensiCard({
    required this.kelas,
    required this.rekap,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final persen = rekap.persen;
    final tone = rekap.kritis
        ? BadgeTone.danger
        : rekap.perhatian
        ? BadgeTone.pending
        : BadgeTone.success;
    final warna = rekap.kritis
        ? (Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkDanger
              : AppColors.dangerInk)
        : rekap.perhatian
        ? (Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkAlert
              : AppColors.alertInk)
        : (Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkPass
              : AppColors.passInk);

    final hadir = rows.where((r) => r.status == 'HADIR').length;
    final izin = rows.where((r) => r.status == 'IZIN').length;
    final sakit = rows.where((r) => r.status == 'SAKIT').length;
    final alpha = rows.where((r) => r.status == 'ALPHA').length;
    final belum = rows.where((r) => r.status == null).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BezelCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kelas.namaMk,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${kelas.kode} · ${kelas.sks} SKS · ${kelas.dosen}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatPersen(persen),
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: warna, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  label: rekap.kritis
                      ? 'Kritis'
                      : rekap.perhatian
                      ? 'Perhatian'
                      : 'Aman',
                  tone: tone,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (persen ?? 0) / 100,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                color: warna,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Count(label: 'Hadir', value: hadir),
                _Count(label: 'Izin', value: izin),
                _Count(label: 'Sakit', value: sakit),
                _Count(label: 'Alpha', value: alpha),
                _Count(label: 'Belum dicatat', value: belum),
              ],
            ),
            const SizedBox(height: 4),
            Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(
                  'Detail pertemuan (${rows.length})',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                children: [
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${r.pertemuanKe}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                          SizedBox(
                            width: 92,
                            child: Text(
                              r.tanggal,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              r.topik ?? '—',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: r.status ?? 'Belum dicatat',
                            tone: switch (r.status) {
                              'HADIR' => BadgeTone.success,
                              'IZIN' => BadgeTone.info,
                              'SAKIT' => BadgeTone.pending,
                              'ALPHA' => BadgeTone.danger,
                              _ => BadgeTone.neutral,
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final String label;
  final int value;

  const _Count({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
