import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/widgets/bezel_card.dart';
import '../../admin/widgets/empty_state.dart';
import '../../admin/widgets/section_header.dart';
import '../../admin/widgets/status_badge.dart';
import '../../app/formatters.dart';
import '../../features/mahasiswa/models/mahasiswa_layanan_models.dart';
import '../../features/mahasiswa/models/mahasiswa_models.dart';
import '../../features/mahasiswa/providers/mahasiswa_providers.dart';
import '../widgets/page_body.dart';

/// Info akademik read-only: periode, countdown, kalender, pengumuman (`09`).
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
    final belumDibaca = repo.jumlahPengumumanBelumDibaca;
    final berikutnya = repo.eventBerikutnya();
    final mendatang = repo.eventMendatang(batas: 6);

    return PageBody(
      maxWidth: 1000,
      children: [
        SectionHeader(
          eyebrow: 'Akademik',
          title: 'Info Akademik',
          subtitle: 'Periode aktif, kalender, dan pengumuman resmi kampus.',
          action: belumDibaca == 0
              ? null
              : TextButton.icon(
                  onPressed: repo.tandaiSemuaPengumumanDibaca,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: Text('Tandai dibaca ($belumDibaca)'),
                ),
        ),
        if (berikutnya != null)
          _CountdownCard(event: berikutnya)
        else
          const StatusBannerFallback(),
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
          eyebrow: 'Kalender',
          title: 'Agenda mendatang',
          subtitle: '${mendatang.length} agenda terdekat',
        ),
        if (mendatang.isEmpty)
          const BezelCard(child: Text('Tidak ada agenda mendatang.'))
        else
          BezelCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [for (final e in mendatang) _KalenderTile(event: e)],
            ),
          ),
        SectionHeader(
          eyebrow: 'Pengumuman',
          title: 'Pengumuman kampus',
          subtitle:
              '${pengumuman.length} pengumuman · $belumDibaca belum dibaca',
        ),
        if (pengumuman.isEmpty)
          const BezelCard(child: Text('Belum ada pengumuman.'))
        else
          for (final p in pengumuman)
            _PengumumanCard(
              pengumuman: p,
              sudahDibaca: repo.pengumumanSudahDibaca(p.id),
              onBaca: () => repo.tandaiPengumumanDibaca(p.id),
            ),
      ],
    );
  }
}

/// Cadangan bila tidak ada agenda (mis. semua periode sudah lewat).
class StatusBannerFallback extends StatelessWidget {
  const StatusBannerFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const BezelCard(
      child: Text('Belum ada periode akademik aktif pada kalender.'),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final KalenderEvent event;

  const _CountdownCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sisa = event.sisaHari(DateTime.now());
    return BezelCard(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final teks = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusBadge(
                    label: event.kategori.label,
                    tone: BadgeTone.info,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      event.judul,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${formatTanggalPanjang(event.tanggal)}'
                '${event.keterangan == null ? '' : ' · ${event.keterangan}'}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          );
          final angka = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sisa',
                style: Theme.of(context).textTheme.displaySmall
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
              ),
              Text('hari lagi', style: Theme.of(context).textTheme.labelMedium),
            ],
          );
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [teks, const SizedBox(height: 12), angka],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: teks),
              const SizedBox(width: 16),
              angka,
            ],
          );
        },
      ),
    );
  }
}

class _KalenderTile extends StatelessWidget {
  final KalenderEvent event;

  const _KalenderTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sisa = event.sisaHari(DateTime.now());
    return ListTile(
      dense: true,
      leading: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${event.tanggal.day}',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(event.judul),
      subtitle: Text(
        '${formatTanggal(event.tanggal)} · ${event.kategori.label}'
        '${sisa == 0 ? ' · Hari ini' : ' · $sisa hari lagi'}',
      ),
      trailing: event.kategori == KategoriKalender.uas
          ? const StatusBadge(label: 'UAS', tone: BadgeTone.pending)
          : null,
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
  final bool sudahDibaca;
  final VoidCallback onBaca;

  const _PengumumanCard({
    required this.pengumuman,
    required this.sudahDibaca,
    required this.onBaca,
  });

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
                if (!sudahDibaca)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatTanggal(pengumuman.tanggal),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                if (!sudahDibaca)
                  TextButton(
                    onPressed: onBaca,
                    child: const Text('Tandai dibaca'),
                  )
                else
                  Text(
                    'Sudah dibaca',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
