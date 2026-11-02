import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/formatters.dart';
import '../../features/mahasiswa/models/mahasiswa_models.dart';
import '../../features/mahasiswa/providers/mahasiswa_providers.dart';
import '../widgets/bezel_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Sisi admin untuk gate UKT/SPP (`fitur_admin/07_administrasi_krs.md`):
/// verifikasi pembayaran, dispensasi, dan persetujuan KRS.
class AdminKrsPage extends ConsumerWidget {
  const AdminKrsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(mahasiswaRepositoryProvider);
    final mahasiswa = repo.semuaMahasiswa;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                eyebrow: 'Akademik',
                title: 'KRS & Gerbang UKT/SPP',
                subtitle:
                    'Tandai pembayaran lunas, beri dispensasi, atau sahkan '
                    'KRS yang menunggu approval.',
              ),
              const SizedBox(height: 16),
              for (final m in mahasiswa) ...[
                _MahasiswaGateCard(mahasiswa: m),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MahasiswaGateCard extends ConsumerWidget {
  final MahasiswaProfile mahasiswa;

  const _MahasiswaGateCard({required this.mahasiswa});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(mahasiswaRepositoryProvider);
    final npm = mahasiswa.npm;
    final tagihan = repo.tagihanPeriodeAktif(npm);
    final statusKrs = repo.statusKrs(npm);
    final dispensasi = repo.dispensasiAktif(npm);
    final gate = repo.gate(npm);
    final sks = repo.sksDipilih(npm);

    return BezelCard(
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
                      mahasiswa.nama,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$npm · ${mahasiswa.prodi} · Semester '
                      '${mahasiswa.semester}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: statusKrs?.label ?? 'BELUM ADA KRS',
                tone: switch (statusKrs) {
                  StatusKrs.aktif => BadgeTone.success,
                  StatusKrs.menungguApproval => BadgeTone.pending,
                  StatusKrs.draft => BadgeTone.info,
                  StatusKrs.batal => BadgeTone.danger,
                  null => BadgeTone.neutral,
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tagihan == null
                            ? 'Tidak ada tagihan'
                            : '${tagihan.jenis} ${formatRupiah(tagihan.nominal)}',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: tagihan?.status == TagihanStatus.lunas
                          ? 'LUNAS'
                          : 'BELUM',
                      tone: tagihan?.status == TagihanStatus.lunas
                          ? BadgeTone.success
                          : BadgeTone.danger,
                    ),
                  ],
                ),
              ),
              if (tagihan != null)
                TextButton(
                  onPressed: () {
                    if (tagihan.status == TagihanStatus.lunas) {
                      repo.tandaiBelumLunas(tagihan.id);
                    } else {
                      repo.tandaiLunas(tagihan.id);
                    }
                  },
                  child: Text(
                    tagihan.status == TagihanStatus.lunas
                        ? 'Batalkan verifikasi'
                        : 'Tandai lunas',
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_horiz, size: 18),
                  const SizedBox(width: 6),
                  const Flexible(child: Text('Dispensasi UKT')),
                  Switch(
                    value: dispensasi,
                    onChanged: (v) => repo.setDispensasi(npm, v),
                  ),
                ],
              ),
              Text(
                '$sks SKS · ${gate.lolos ? 'gate lolos' : 'gate blokir'}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (statusKrs == StatusKrs.menungguApproval)
                FilledButton.tonalIcon(
                  onPressed: () => repo.setujuiKrs(npm),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Setujui KRS'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _DaftarMkKrs(npm: npm),
        ],
      ),
    );
  }
}

class _DaftarMkKrs extends ConsumerWidget {
  final String npm;

  const _DaftarMkKrs({required this.npm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(mahasiswaRepositoryProvider);
    final cs = Theme.of(context).colorScheme;
    final mk = repo.kelasDipilih(npm);
    if (mk.isEmpty) {
      return Text(
        'Belum ada mata kuliah pada KRS periode ini.',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: cs.onSurfaceVariant),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mata kuliah KRS (${mk.length} MK · ${repo.sksDipilih(npm)} SKS)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final k in mk) _MkTile(kelas: k)],
        ),
      ],
    );
  }
}

class _MkTile extends StatelessWidget {
  final Kelas kelas;

  const _MkTile({required this.kelas});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final j = kelas.jadwal.isEmpty ? null : kelas.jadwal.first;
    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${kelas.kode} · ${kelas.namaMk}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 2),
          Text(
            '${kelas.sks} SKS · '
            '${j == null ? 'Jadwal menyusul' : '${hariLabel(j.hari)} ${j.jamMulai} · ${j.ruanganTampil}'}',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
