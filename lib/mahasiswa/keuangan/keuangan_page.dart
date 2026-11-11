import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// Keuangan: status tagihan UKT/SPP + gate KRS (keputusan produk: status saja).
class KeuanganPage extends ConsumerWidget {
  const KeuanganPage({super.key});

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

    final tagihan = repo.tagihanMahasiswa(npm);
    final tunggakan = repo.totalTunggakan(npm);
    final gate = repo.gate(npm);
    final dispensasi = repo.dispensasiAktif(npm);
    final tagihanAktif = repo.tagihanPeriodeAktif(npm);
    final lunas = tagihanAktif?.status == TagihanStatus.lunas || dispensasi;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final warnaTunggakan = tunggakan == 0
        ? (dark ? AppColors.darkPass : AppColors.passInk)
        : (dark ? AppColors.darkDanger : AppColors.dangerInk);

    return PageBody(
      maxWidth: 900,
      children: [
        SectionHeader(
          eyebrow: 'Keuangan',
          title: 'Tagihan UKT/SPP',
          subtitle: 'Status pembayaran dan pengaruhnya terhadap KRS.',
          action: StatusBadge(
            label: lunas ? 'KRS TERBUKA' : 'KRS TERKUNCI',
            tone: lunas ? BadgeTone.success : BadgeTone.danger,
            icon: lunas ? Icons.lock_open : Icons.lock_outline,
          ),
        ),
        BezelCard(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final total = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total tunggakan',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatRupiah(tunggakan),
                      style: Theme.of(context).textTheme.displaySmall
                          ?.copyWith(color: warnaTunggakan),
                    ),
                  ),
                ],
              );
              final periode = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tagihan periode aktif',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tagihanAktif == null
                        ? 'Tidak ada tagihan'
                        : '${tagihanAktif.jenis} · '
                              '${formatRupiah(tagihanAktif.nominal)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              );
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [total, const SizedBox(height: 16), periode],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: total),
                  const SizedBox(width: 16),
                  periode,
                ],
              );
            },
          ),
        ),
        if (!gate.lolos)
          StatusBanner(
            tone: StatusBannerTone.danger,
            icon: Icons.lock_outline,
            message: gate.pesan!,
          ),
        if (dispensasi)
          const StatusBanner(
            tone: StatusBannerTone.success,
            icon: Icons.verified_outlined,
            message:
                'Admin akademik memberi dispensasi UKT. KRS tetap dapat '
                'diajukan meskipun tagihan belum lunas.',
          ),
        SectionHeader(eyebrow: 'Riwayat', title: 'Daftar tagihan'),
        if (tagihan.isEmpty)
          const BezelCard(child: Text('Belum ada tagihan tercatat.'))
        else
          for (final t in tagihan)
            _TagihanCard(
              tagihan: t,
              namaPeriode: repo.periode
                  .firstWhere(
                    (p) => p.id == t.periodeId,
                    orElse: () => repo.periodeAktif,
                  )
                  .nama,
            ),
        BezelCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pembayaran diverifikasi oleh bagian keuangan. Bila sudah '
                  'membayar tetapi status belum berubah, hubungi admin '
                  'akademik agar KRS dapat dibuka atau diberi dispensasi.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/mahasiswa/krs'),
                child: const Text('Buka KRS'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagihanCard extends StatelessWidget {
  final Tagihan tagihan;
  final String namaPeriode;

  const _TagihanCard({required this.tagihan, required this.namaPeriode});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final lunas = tagihan.status == TagihanStatus.lunas;
    final warna = lunas
        ? (dark ? AppColors.darkPass : AppColors.passInk)
        : (dark ? AppColors.darkAlert : AppColors.alertInk);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BezelCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                lunas
                    ? Icons.check_circle_outline
                    : Icons.receipt_long_outlined,
                color: warna,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tagihan.jenis} · $namaPeriode',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    lunas
                        ? 'Dibayar ${tagihan.tanggalBayar ?? '—'}'
                        : 'Belum dibayar',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRupiah(tagihan.nominal),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                StatusBadge(
                  label: lunas ? 'LUNAS' : 'BELUM',
                  tone: lunas ? BadgeTone.success : BadgeTone.danger,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
