import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/widgets/bezel_card.dart';
import '../../admin/widgets/empty_state.dart';
import '../../admin/widgets/section_header.dart';
import '../../admin/widgets/status_badge.dart';
import '../../app/formatters.dart';
import '../../app/widgets/status_banner.dart';
import '../../features/mahasiswa/models/mahasiswa_models.dart';
import '../../features/mahasiswa/providers/mahasiswa_providers.dart';
import '../widgets/page_body.dart';

/// KRS: lihat + ambil sesuai periode (`03_krs.md`) dengan gate UKT/SPP.
class KrsPage extends ConsumerWidget {
  const KrsPage({super.key});

  void _pesan(BuildContext context, String? error, {String sukses = ''}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? sukses),
        backgroundColor: error == null
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

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

    final gate = repo.gate(npm);
    final status = repo.statusKrs(npm);
    final dipilih = repo.kelasDipilih(npm);
    final sks = repo.sksDipilih(npm);
    final plafon = repo.plafonSks(npm);
    final tersedia = repo.kelasTersedia;
    final bisaEdit = status == null || status == StatusKrs.draft;
    final bisaAjukan = status == StatusKrs.draft && dipilih.isNotEmpty;

    return PageBody(
      children: [
        SectionHeader(
          eyebrow: 'Registrasi',
          title: 'Kartu Rencana Studi',
          subtitle:
              '${repo.periodeAktif.nama} · '
              'KRS ${formatTanggal(repo.periodeAktif.krsMulai)}–'
              '${formatTanggal(repo.periodeAktif.krsSelesai)}',
          action: _StatusBadge(status: status),
        ),
        _RingkasanSks(sks: sks, plafon: plafon, ipsLalu: repo.ipsLalu(npm)),
        if (!gate.lolos)
          StatusBanner(
            tone: StatusBannerTone.danger,
            icon: Icons.lock_outline,
            message: repo.dispensasiAktif(npm)
                ? '${gate.pesan!} (Dispensasi admin aktif.)'
                : gate.pesan!,
          ),
        if (status == StatusKrs.aktif)
          const StatusBanner(
            tone: StatusBannerTone.success,
            icon: Icons.verified_outlined,
            message:
                'KRS periode ini sudah disahkan. Perubahan hanya dapat '
                'dilakukan oleh admin akademik.',
          ),
        if (status == StatusKrs.menungguApproval)
          const StatusBanner(
            tone: StatusBannerTone.warning,
            icon: Icons.hourglass_top,
            message: 'KRS menunggu persetujuan dosen wali / admin akademik.',
          ),
        SectionHeader(
          eyebrow: 'Terdaftar',
          title: 'Mata kuliah dipilih',
          subtitle: '${dipilih.length} MK · $sks SKS',
        ),
        if (dipilih.isEmpty)
          BezelCard(
            child: Row(
              children: [
                const Icon(Icons.playlist_add),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Belum ada MK di KRS. Pilih kelas pada daftar di bawah.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          for (final k in dipilih)
            _KelasDipilihCard(
              kelas: k,
              editable: bisaEdit,
              onHapus: () {
                final entry = repo
                    .krsMahasiswa(npm)
                    .where((e) => e.kelasId == k.id)
                    .first;
                final err = repo.hapusKrs(npm, entry.id);
                _pesan(context, err, sukses: '${k.namaMk} dihapus dari KRS.');
              },
            ),
        if (bisaEdit) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final ajukan = FilledButton.icon(
                onPressed: bisaAjukan && gate.lolos
                    ? () {
                        final err = repo.ajukanKrs(npm);
                        _pesan(
                          context,
                          err,
                          sukses: 'KRS diajukan dan menunggu approval.',
                        );
                      }
                    : null,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Ajukan KRS'),
              );
              final batal = OutlinedButton.icon(
                onPressed: dipilih.isEmpty
                    ? null
                    : () => _konfirmasiBatal(context, ref, npm),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Batalkan'),
              );
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [ajukan, const SizedBox(height: 8), batal],
                );
              }
              return Row(
                children: [
                  Expanded(child: ajukan),
                  const SizedBox(width: 12),
                  batal,
                ],
              );
            },
          ),
        ],
        SectionHeader(
          eyebrow: 'Katalog',
          title: 'Kelas tersedia',
          subtitle: '${tersedia.length} kelas pada periode aktif',
        ),
        for (final k in tersedia)
          _KelasTersediaCard(
            kelas: k,
            sudahDipilih: dipilih.any((d) => d.id == k.id),
            bisaTambah: bisaEdit && gate.lolos,
            onTambah: () {
              final err = repo.tambahKrs(npm, k.id);
              _pesan(context, err, sukses: '${k.namaMk} ditambahkan ke KRS.');
            },
          ),
      ],
    );
  }

  Future<void> _konfirmasiBatal(
    BuildContext context,
    WidgetRef ref,
    String npm,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan KRS?'),
        content: const Text(
          'Seluruh MK pada KRS periode ini akan dibatalkan. '
          'Tindakan ini tidak dapat diurungkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = ref.read(mahasiswaRepositoryProvider).batalkanKrs(npm);
    if (context.mounted) {
      _pesan(context, err, sukses: 'KRS dibatalkan.');
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final StatusKrs? status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return const StatusBadge(label: 'Belum ada', tone: BadgeTone.neutral);
    }
    final tone = switch (status!) {
      StatusKrs.aktif => BadgeTone.success,
      StatusKrs.menungguApproval => BadgeTone.pending,
      StatusKrs.draft => BadgeTone.info,
      StatusKrs.batal => BadgeTone.danger,
    };
    return StatusBadge(label: status!.label, tone: tone);
  }
}

class _RingkasanSks extends StatelessWidget {
  final int sks;
  final int plafon;
  final double? ipsLalu;

  const _RingkasanSks({
    required this.sks,
    required this.plafon,
    required this.ipsLalu,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final metrik = Wrap(
      runSpacing: 8,
      children: [
        _Metric(label: 'SKS dipilih', value: '$sks'),
        _Metric(label: 'Plafon SKS', value: '$plafon'),
        _Metric(label: 'IPS lalu', value: formatDesimal(ipsLalu)),
      ],
    );
    final catatan = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Plafon mengikuti IPS semester lalu '
            '(E>12, D>15, C>18, B>21, A>24; maba 20).',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
    return BezelCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [metrik, const SizedBox(height: 12), catatan],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: metrik),
              const SizedBox(width: 16),
              Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: Text(
                  'Plafon mengikuti IPS semester lalu '
                  '(E>12, D>15, C>18, B>21, A>24; maba 20).',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _KelasDipilihCard extends StatelessWidget {
  final Kelas kelas;
  final bool editable;
  final VoidCallback onHapus;

  const _KelasDipilihCard({
    required this.kelas,
    required this.editable,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final j = kelas.jadwal.isEmpty ? null : kelas.jadwal.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BezelCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${kelas.sks}',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: cs.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kelas.namaMk,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${kelas.kode} · ${j == null ? 'Jadwal menyusul' : '${hariLabel(j.hari)} ${j.jamMulai} · ${j.ruanganTampil} · ${kelas.sks} SKS'}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  Text(
                    kelas.dosen,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            if (editable)
              IconButton(
                tooltip: 'Hapus dari KRS',
                onPressed: onHapus,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ),
    );
  }
}

class _KelasTersediaCard extends StatelessWidget {
  final Kelas kelas;
  final bool sudahDipilih;
  final bool bisaTambah;
  final VoidCallback onTambah;

  const _KelasTersediaCard({
    required this.kelas,
    required this.sudahDipilih,
    required this.bisaTambah,
    required this.onTambah,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final j = kelas.jadwal.isEmpty ? null : kelas.jadwal.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BezelCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          kelas.namaMk,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: kelas.penuh
                            ? 'PENUH ${kelas.jumlahTerdaftar}/${kelas.kapasitas}'
                            : '${kelas.jumlahTerdaftar}/${kelas.kapasitas}',
                        tone: kelas.penuh
                            ? BadgeTone.danger
                            : BadgeTone.neutral,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${kelas.kode} · ${j == null ? 'Jadwal menyusul' : '${hariLabel(j.hari)} ${j.jamMulai}–${j.jamSelesai} · ${j.ruanganTampil}'}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  Text(
                    '${kelas.dosen} · ${kelas.sks} SKS',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (sudahDipilih)
              const StatusBadge(label: 'Terdaftar', tone: BadgeTone.success)
            else
              IconButton.filledTonal(
                tooltip: 'Tambahkan ke KRS',
                onPressed: bisaTambah && !kelas.penuh ? onTambah : null,
                icon: const Icon(Icons.add),
              ),
          ],
        ),
      ),
    );
  }
}
