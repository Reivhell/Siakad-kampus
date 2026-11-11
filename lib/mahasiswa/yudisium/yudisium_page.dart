import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/widgets/bezel_card.dart';
import '../../admin/widgets/empty_state.dart';
import '../../admin/widgets/section_header.dart';
import '../../admin/widgets/status_badge.dart';
import '../../app/formatters.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/status_banner.dart';
import '../../features/mahasiswa/models/mahasiswa_layanan_models.dart';
import '../../features/mahasiswa/models/mahasiswa_models.dart';
import '../../features/mahasiswa/providers/mahasiswa_providers.dart';
import '../widgets/layanan_widgets.dart';
import '../widgets/page_body.dart';

/// Yudisium / kelulusan (`11_yudisium_dan_kelulusan.md`, EKSTENSI P2).
class YudisiumPage extends ConsumerWidget {
  const YudisiumPage({super.key});

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

    final cek = repo.cekYudisium(npm);
    final pengajuan = repo.yudisiumMahasiswa(npm);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final warna = cek.semuaTercapai
        ? (dark ? AppColors.darkPass : AppColors.passInk)
        : (dark ? AppColors.darkAlert : AppColors.alertInk);

    return PageBody(
      maxWidth: 1000,
      children: [
        SectionHeader(
          eyebrow: 'Kelulusan',
          title: 'Yudisium',
          subtitle:
              'Verifikasi syarat kelulusan dan ajukan yudisium secara mandiri.',
        ),
        if (pengajuan != null)
          StatusBanner(
            tone: pengajuan.status == StatusPengajuan.ditolak
                ? StatusBannerTone.danger
                : StatusBannerTone.info,
            icon: Icons.assignment_turned_in_outlined,
            message:
                'Pengajuan yudisium ${formatTanggal(pengajuan.diajukan)} '
                'berstatus ${pengajuan.status.label}. '
                '${pengajuan.status == StatusPengajuan.pengajuan ? 'Admin akademik akan memverifikasi berkas Anda.' : ''}',
          )
        else if (cek.semuaTercapai)
          const StatusBanner(
            tone: StatusBannerTone.success,
            icon: Icons.celebration_outlined,
            message:
                'Seluruh syarat kelulusan terpenuhi. Anda dapat mengajukan '
                'yudisium sekarang.',
          )
        else
          StatusBanner(
            tone: StatusBannerTone.warning,
            icon: Icons.rule,
            message:
                'Belum memenuhi syarat yudisium: ${cek.kekurangan.join(', ')}.',
          ),
        BezelCard(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ringkasan = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress SKS lulus',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cek.sksLulus} / ${cek.sksTarget}',
                    style: Theme.of(context).textTheme.displaySmall
                        ?.copyWith(color: warna),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: cek.progressSks,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kurang ${(cek.sksTarget - cek.sksLulus).clamp(0, 999)} SKS '
                    'menuju syarat kelulusan.',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              );
              final metrik = Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _Metrik(
                    label: 'IPK',
                    value: formatDesimal(cek.ipk),
                    lulus: cek.ipkCukup,
                  ),
                  _Metrik(
                    label: 'Nilai E',
                    value: cek.adaNilaiE ? 'Ada' : 'Tidak ada',
                    lulus: cek.tanpaE,
                  ),
                  _Metrik(
                    label: 'Status',
                    value: profile.status.label,
                    lulus: cek.statusAktif,
                  ),
                  _Metrik(
                    label: 'Tanggungan',
                    value: cek.bebasTanggungan ? 'Bebas' : 'Ada',
                    lulus: cek.bebasTanggungan,
                  ),
                ],
              );
              if (constraints.maxWidth < 680) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [ringkasan, const SizedBox(height: 18), metrik],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: ringkasan),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: metrik),
                ],
              );
            },
          ),
        ),
        SectionHeader(
          eyebrow: 'Syarat',
          title: 'Checklist kelulusan',
          subtitle: 'Mengacu kurikulum aktif dan status akademik terkini.',
        ),
        _SyaratTile(
          label: 'SKS lulus minimal ${cek.sksTarget}',
          detail: 'Tercapai ${cek.sksLulus} SKS',
          lulus: cek.sksCukup,
        ),
        _SyaratTile(
          label: 'IPK minimal 2.00',
          detail: 'IPK saat ini ${formatDesimal(cek.ipk)}',
          lulus: cek.ipkCukup,
        ),
        _SyaratTile(
          label: 'Tidak ada nilai E',
          detail: cek.adaNilaiE ? 'Masih ada nilai E' : 'Tidak ada nilai E',
          lulus: cek.tanpaE,
        ),
        _SyaratTile(
          label: 'Status mahasiswa AKTIF',
          detail: 'Status ${profile.status.label}',
          lulus: cek.statusAktif,
        ),
        _SyaratTile(
          label: 'Bebas tanggungan keuangan',
          detail: cek.bebasTanggungan
              ? 'Tidak ada tunggakan'
              : 'Masih ada tunggakan UKT/SPP',
          lulus: cek.bebasTanggungan,
        ),
        const SizedBox(height: 4),
        if (pengajuan == null)
          FilledButton.icon(
            onPressed: cek.bisaAjukan ? () => _ajukan(context, ref, npm) : null,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Ajukan Yudisium'),
          )
        else
          BezelCard(
            child: Row(
              children: [
                const Icon(Icons.hourglass_top),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pengajuan yudisium sudah dikirim. Pantau status di halaman '
                    'ini; SK kelulusan dan PIN ijazah diterbitkan admin.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                StatusBadge(
                  label: pengajuan.status.label,
                  tone: tonePengajuan(pengajuan.status),
                ),
              ],
            ),
          ),
        BezelCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nilai DRAFT tidak dihitung dalam audit kelulusan. Kurikulum '
                  'acuan mengikuti versi yang berlaku saat angkatan masuk. '
                  'Pengajuan hanya dapat dilakukan satu kali.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _ajukan(BuildContext context, WidgetRef ref, String npm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajukan yudisium?'),
        content: const Text(
          'Pastikan seluruh data akademik sudah benar. Setelah diajukan, '
          'perubahan hanya dapat dilakukan admin akademik.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, ajukan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = ref.read(mahasiswaRepositoryProvider).ajukanYudisium(npm);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Pengajuan yudisium terkirim.'),
        backgroundColor: err == null
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _Metrik extends StatelessWidget {
  final String label;
  final String value;
  final bool lulus;

  const _Metrik({
    required this.label,
    required this.value,
    required this.lulus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          lulus ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: lulus
              ? (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkPass
                    : AppColors.passInk)
              : Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ],
    );
  }
}

class _SyaratTile extends StatelessWidget {
  final String label;
  final String detail;
  final bool lulus;

  const _SyaratTile({
    required this.label,
    required this.detail,
    required this.lulus,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final warna = lulus
        ? (dark ? AppColors.darkPass : AppColors.passInk)
        : Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BezelCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              lulus ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: warna,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(
              label: lulus ? 'TERPENUHI' : 'BELUM',
              tone: lulus ? BadgeTone.success : BadgeTone.danger,
            ),
          ],
        ),
      ),
    );
  }
}
