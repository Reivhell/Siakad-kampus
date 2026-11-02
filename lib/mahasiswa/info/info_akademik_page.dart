import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/widgets/bezel_card.dart';
import '../../admin/widgets/empty_state.dart';
import '../../admin/widgets/section_header.dart';
import '../../admin/widgets/status_badge.dart';
import '../../app/formatters.dart';
import '../../features/mahasiswa/models/mahasiswa_models.dart';
import '../../features/mahasiswa/providers/mahasiswa_providers.dart';
import '../widgets/page_body.dart';

/// Info akademik read-only: periode aktif + pengumuman (`09`).
class InfoAkademikPage extends ConsumerWidget {
  const InfoAkademikPage({super.key});

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

    final periode = repo.periodeAktif;
    final pengumuman = repo.pengumuman;

    return PageBody(
      maxWidth: 900,
      children: [
        SectionHeader(
          eyebrow: 'Akademik',
          title: 'Info Akademik',
          subtitle: 'Periode aktif dan pengumuman resmi kampus.',
        ),
        BezelCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      periode.nama,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const StatusBadge(
                    label: 'PERIODE AKTIF',
                    tone: BadgeTone.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Baris(
                icon: Icons.edit_calendar_outlined,
                label: 'Jendela KRS',
                value:
                    '${formatTanggalPanjang(periode.krsMulai)} – '
                    '${formatTanggalPanjang(periode.krsSelesai)}',
              ),
              _Baris(
                icon: Icons.assignment_outlined,
                label: 'Ujian Tengah Semester',
                value: 'Mulai ${formatTanggalPanjang(periode.utsMulai)}',
              ),
              _Baris(
                icon: Icons.fact_check_outlined,
                label: 'Ujian Akhir Semester',
                value: 'Mulai ${formatTanggalPanjang(periode.uasMulai)}',
              ),
            ],
          ),
        ),
        SectionHeader(
          eyebrow: 'Pengumuman',
          title: 'Pengumuman kampus',
          subtitle: '${pengumuman.length} pengumuman',
        ),
        if (pengumuman.isEmpty)
          const BezelCard(child: Text('Belum ada pengumuman.'))
        else
          for (final p in pengumuman) _PengumumanCard(pengumuman: p),
      ],
    );
  }
}

class _Baris extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Baris({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PengumumanCard extends StatelessWidget {
  final Pengumuman pengumuman;

  const _PengumumanCard({required this.pengumuman});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BezelCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  pengumuman.penting ? Icons.campaign : Icons.push_pin_outlined,
                  color: cs.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pengumuman.judul,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (pengumuman.penting)
                  const StatusBadge(label: 'PENTING', tone: BadgeTone.pending),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              pengumuman.isi,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              formatTanggal(pengumuman.tanggal),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
