import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/widgets/bezel_card.dart';
import '../../admin/widgets/empty_state.dart';
import '../../admin/widgets/kpi_card.dart';
import '../../admin/widgets/section_header.dart';
import '../../admin/widgets/status_badge.dart';
import '../../app/formatters.dart';
import '../../app/widgets/status_banner.dart';
import '../../features/mahasiswa/models/mahasiswa_layanan_models.dart';
import '../../features/mahasiswa/models/mahasiswa_models.dart';
import '../../features/mahasiswa/providers/mahasiswa_providers.dart';
import '../widgets/layanan_widgets.dart';
import '../widgets/page_body.dart';

/// Transkrip & progress kurikulum (`07_transkrip_dan_progress.md`).
class TranskripPage extends ConsumerWidget {
  const TranskripPage({super.key});

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

    final progress = repo.kurikulumProgress(npm);
    final transkrip = repo.transkripPeriode(npm);
    final totalSks = repo.totalSksKurikulum;
    final lulus = repo.sksKurikulumLulus(npm);
    final sksLulus = repo.sksLulusMahasiswa(npm);
    final ipk = repo.ipk(npm);
    final jumlahLulus = progress
        .where((p) => p.status == StatusKurikulum.lulus)
        .length;
    final jumlahBerjalan = progress
        .where((p) => p.status == StatusKurikulum.berjalan)
        .length;
    final persen = totalSks == 0
        ? 0.0
        : (lulus / totalSks).clamp(0, 1).toDouble();

    return PageBody(
      children: [
        SectionHeader(
          eyebrow: 'Akademik',
          title: 'Transkrip & Progress',
          subtitle:
              'Rekap seluruh nilai dan ketercapaian kurikulum ${profile.prodi}.',
          action: OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Transkrip PDF masih berwatermark SEMENTARA. '
                  'Unduhan resmi tersedia setelah disahkan admin.',
                ),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Unduh'),
          ),
        ),
        const StatusBanner(
          tone: StatusBannerTone.info,
          icon: Icons.verified_user_outlined,
          message:
              'Dokumen ini berstatus SEMENTARA. Transkrip resmi hanya '
              'diterbitkan setelah disahkan oleh admin akademik.',
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Kpi(
              icon: Icons.workspace_premium_outlined,
              label: 'IPK Kumulatif',
              value: formatDesimal(ipk),
              sub: '$sksLulus SKS lulus',
            ),
            _Kpi(
              icon: Icons.fact_check_outlined,
              label: 'MK Lulus',
              value: '$jumlahLulus',
              sub: '$jumlahBerjalan MK berjalan',
            ),
            _Kpi(
              icon: Icons.donut_large,
              label: 'Progress Kurikulum',
              value: formatPersen(persen * 100),
              sub: '$lulus / $totalSks SKS',
            ),
          ],
        ),
        BezelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ketercapaian kurikulum',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$lulus / $totalSks SKS',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: persen, minHeight: 10),
              ),
              const SizedBox(height: 8),
              Text(
                'Kurikulum acuan: versi aktif saat angkatan ${profile.tahunMasuk}. '
                'Nilai DRAFT tidak dihitung lulus.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SectionHeader(
          eyebrow: 'Kurikulum',
          title: 'Progress per semester',
          subtitle: '${progress.length} mata kuliah dalam kurikulum',
        ),
        for (var semester = 1; semester <= 8; semester++)
          _SemesterCard(
            semester: semester,
            rows: progress.where((p) => p.mk.semester == semester).toList(),
          ),
        SectionHeader(
          eyebrow: 'Riwayat',
          title: 'Transkrip nilai',
          subtitle: '${transkrip.length} periode memiliki nilai',
        ),
        if (transkrip.isEmpty)
          const BezelCard(child: Text('Belum ada nilai tercatat.'))
        else
          for (final t in transkrip) _TranskripCard(transkrip: t),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;

  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: KpiCard(icon: icon, label: label, value: value, sub: sub),
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final int semester;
  final List<KurikulumProgress> rows;

  const _SemesterCard({required this.semester, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final total = rows.fold(0, (acc, r) => acc + r.mk.sks);
    final lulus = rows
        .where((r) => r.status == StatusKurikulum.lulus)
        .fold(0, (acc, r) => acc + r.mk.sks);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BezelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Semester $semester',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  label: '$lulus/$total SKS',
                  tone: lulus == total ? BadgeTone.success : BadgeTone.neutral,
                ),
                const SizedBox(width: 8),
                Text(
                  '${rows.length} MK',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : lulus / total,
                minHeight: 6,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 10),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 74,
                      child: Text(
                        r.mk.kode,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.mk.nama,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${r.mk.sks} SKS',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(width: 8),
                    if (r.huruf != null) ...[
                      Text(
                        r.huruf!,
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                    ],
                    StatusBadge(
                      label: r.status.label,
                      tone: toneKurikulum(r.status),
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

class _TranskripCard extends StatelessWidget {
  final TranskripPeriode transkrip;

  const _TranskripCard({required this.transkrip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BezelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    transkrip.namaPeriode,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  'IPS ${formatDesimal(transkrip.ips)} · '
                  '${transkrip.sks} SKS',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 38,
                dataRowMaxHeight: 44,
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Kode')),
                  DataColumn(label: Text('Mata kuliah')),
                  DataColumn(label: Text('SKS'), numeric: true),
                  DataColumn(label: Text('Huruf')),
                  DataColumn(label: Text('Mutu'), numeric: true),
                  DataColumn(label: Text('Status')),
                ],
                rows: [
                  for (final r in transkrip.rows)
                    DataRow(
                      cells: [
                        DataCell(Text(r.kodeMk)),
                        DataCell(Text(r.namaMk)),
                        DataCell(Text('${r.sks}')),
                        DataCell(
                          Text(
                            r.huruf ?? '—',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: r.huruf == 'E' ? cs.error : null,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            r.huruf == null
                                ? '—'
                                : (bobotHuruf[r.huruf] ?? 0).toStringAsFixed(1),
                          ),
                        ),
                        DataCell(
                          r.huruf == null
                              ? const StatusBadge(
                                  label: 'Belum diinput',
                                  tone: BadgeTone.neutral,
                                )
                              : r.sudahFinal
                              ? const StatusBadge(
                                  label: 'Final',
                                  tone: BadgeTone.success,
                                )
                              : const StatusBadge(
                                  label: 'DRAFT',
                                  tone: BadgeTone.pending,
                                ),
                        ),
                      ],
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
