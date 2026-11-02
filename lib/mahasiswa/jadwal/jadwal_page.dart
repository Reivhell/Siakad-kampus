import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/widgets/bezel_card.dart';
import '../../admin/widgets/empty_state.dart';
import '../../admin/widgets/section_header.dart';
import '../../features/mahasiswa/models/mahasiswa_models.dart';
import '../../features/mahasiswa/providers/mahasiswa_providers.dart';
import '../widgets/page_body.dart';

/// Jadwal mingguan read-only dari KRS AKTIF (`04_jadwal_kuliah.md`).
class JadwalPage extends ConsumerWidget {
  const JadwalPage({super.key});

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

    final minggu = repo.jadwalMinggu(npm);

    return PageBody(
      children: [
        SectionHeader(
          eyebrow: 'Perkuliahan',
          title: 'Jadwal Kuliah',
          subtitle:
              '${repo.periodeAktif.nama} · '
              '${minggu.length} kelas dari KRS AKTIF',
        ),
        if (minggu.isEmpty)
          const BezelCard(
            child: Text(
              'Belum ada jadwal. Jadwal muncul setelah KRS periode ini '
              'disahkan.',
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return _Board(minggu: minggu);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var hari = 1; hari <= 7; hari++)
                    ..._seksiHari(hari, minggu),
                ],
              );
            },
          ),
      ],
    );
  }

  List<Widget> _seksiHari(int hari, List<Kelas> minggu) {
    final items = minggu.where((k) => k.jadwal.any((j) => j.hari == hari));
    if (items.isEmpty) return const [];
    return [
      _HariHeader(hari: hari, jumlah: items.length),
      for (final k in items)
        _JadwalCard(
          kelas: k,
          jadwal: k.jadwal.firstWhere((j) => j.hari == hari),
        ),
      const SizedBox(height: 8),
    ];
  }
}

class _Board extends StatelessWidget {
  final List<Kelas> minggu;

  const _Board({required this.minggu});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var hari = 1; hari <= 7; hari++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: hari == 7 ? 0 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HariHeader(
                    hari: hari,
                    jumlah: minggu
                        .where((k) => k.jadwal.any((j) => j.hari == hari))
                        .length,
                    compact: true,
                  ),
                  for (final k in minggu.where(
                    (k) => k.jadwal.any((j) => j.hari == hari),
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _JadwalCard(
                        kelas: k,
                        jadwal: k.jadwal.firstWhere((j) => j.hari == hari),
                        compact: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HariHeader extends StatelessWidget {
  final int hari;
  final int jumlah;
  final bool compact;

  const _HariHeader({
    required this.hari,
    required this.jumlah,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isToday = DateTime.now().weekday == hari;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hariLabel(hari),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: isToday ? cs.primary : null),
            ),
          ),
          if (isToday && !compact) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Hari ini',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: cs.primary),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Text('$jumlah', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _JadwalCard extends StatelessWidget {
  final Kelas kelas;
  final JadwalSlot jadwal;
  final bool compact;

  const _JadwalCard({
    required this.kelas,
    required this.jadwal,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BezelCard(
      padding: EdgeInsets.all(compact ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  jadwal.jamMulai,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: cs.primary),
                ),
                Text(
                  '–${jadwal.jamSelesai}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            kelas.namaMk,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontSize: compact ? 13 : null),
          ),
          Text(
            '${kelas.kode} · ${kelas.sks} SKS',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.meeting_room_outlined,
                size: 12,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  jadwal.ruanganTampil,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              kelas.dosen,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
