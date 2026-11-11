import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../widgets/page_body.dart';

/// Agregat read-only 5 service kanonis (`01_dashboard.md`).
class BerandaPage extends ConsumerWidget {
  const BerandaPage({super.key});

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
        subtitle: 'Hubungi administrator untuk menautkan akun mahasiswa.',
      );
    }

    final ipk = repo.ipk(npm);
    final sksLulus = repo.sksLulusMahasiswa(npm);
    final sksTempuh = repo.sksTempuh(npm);
    final ipsTerakhir =
        repo.ipsPeriode(npm, repo.periodeAktif.id) ?? repo.ipsLalu(npm);
    final statusKrs = repo.statusKrs(npm);
    final kritis = repo.kelasPresensiKritis(npm);
    final rekap = repo.rekapSemua(npm).where((r) => r.persen != null).toList()
      ..sort((a, b) => a.persen!.compareTo(b.persen!));
    final terendah = rekap.isEmpty ? null : rekap.first;
    final namaTerendah = terendah == null
        ? ''
        : (repo.kelasById(terendah.kelasId)?.namaMk ?? '');
    final jadwalHariIni = repo.jadwalHari(npm, DateTime.now().weekday);
    final tagihan = repo.tagihanPeriodeAktif(npm);
    final gate = repo.gate(npm);
    final pengumuman = repo.pengumuman.take(2).toList();
    final belumDibaca = repo.jumlahPengumumanBelumDibaca;
    final cekYudisium = repo.cekYudisium(npm);
    final agenda = repo.eventBerikutnya();

    return PageBody(
      children: [
        _GreetingCard(profile: profile),
        _KpiGrid(
          items: [
            (
              icon: Icons.workspace_premium_outlined,
              label: 'IPK',
              value: formatDesimal(ipk),
              sub: 'Kumulatif $sksTempuh SKS ditempuh',
            ),
            (
              icon: Icons.checklist_rtl,
              label: 'SKS Lulus',
              value: '$sksLulus/${repo.totalSksKurikulum}',
              sub: 'Sisa ${repo.totalSksKurikulum - sksLulus} SKS',
            ),
            (
              icon: Icons.trending_up,
              label: 'IPS Terakhir',
              value: formatDesimal(ipsTerakhir),
              sub: 'Semester ${profile.semester}',
            ),
            (
              icon: Icons.how_to_reg_outlined,
              label: 'Kehadiran Terendah',
              value: terendah == null ? '—' : formatPersen(terendah.persen),
              sub: namaTerendah.isEmpty ? 'Belum ada data' : namaTerendah,
            ),
          ],
        ),
        if (kritis.isNotEmpty)
          StatusBanner(
            tone: StatusBannerTone.danger,
            icon: Icons.warning_amber_rounded,
            message:
                'Presensi kritis (<75%): '
                '${kritis.map((k) => k.namaMk).join(', ')}. '
                'Segera konsultasikan ke dosen pengampu.',
            actionLabel: 'Detail',
            onAction: () => context.go('/mahasiswa/presensi'),
          ),
        if (tagihan != null && tagihan.status == TagihanStatus.belum)
          StatusBanner(
            tone: StatusBannerTone.warning,
            icon: Icons.receipt_long_outlined,
            message:
                '${tagihan.jenis} ${formatRupiah(tagihan.nominal)} belum lunas. '
                '${gate.lolos ? 'Dispensasi admin aktif.' : 'KRS terkunci.'}',
            actionLabel: 'Bayar',
            onAction: () => context.go('/mahasiswa/keuangan'),
          ),
        if (cekYudisium.semuaTercapai && cekYudisium.pengajuan == null)
          StatusBanner(
            tone: StatusBannerTone.success,
            icon: Icons.celebration_outlined,
            message:
                'Selamat! Seluruh syarat kelulusan terpenuhi '
                '(${cekYudisium.sksLulus}/${cekYudisium.sksTarget} SKS). '
                'Ajukan yudisium sekarang.',
            actionLabel: 'Yudisium',
            onAction: () => context.go('/mahasiswa/yudisium'),
          ),
        if (agenda != null) _AgendaCard(event: agenda),
        SectionHeader(
          eyebrow: 'Jadwal',
          title: 'Hari ini',
          subtitle: hariLabel(DateTime.now().weekday),
          action: TextButton(
            onPressed: () => context.go('/mahasiswa/jadwal'),
            child: const Text('Lihat semua'),
          ),
        ),
        if (jadwalHariIni.isEmpty)
          BezelCard(
            child: Row(
              children: [
                const Icon(Icons.free_breakfast_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tidak ada kelas hari ini.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          ...jadwalHariIni.map((k) => _KelasHariIni(kelas: k)),
        SectionHeader(
          eyebrow: 'Registrasi',
          title: 'Status KRS',
          action: TextButton(
            onPressed: () => context.go('/mahasiswa/krs'),
            child: const Text('Buka KRS'),
          ),
        ),
        BezelCard(
          child: Row(
            children: [
              _StatusKrsBadge(status: statusKrs),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusKrs == null
                      ? 'Belum ada KRS pada periode ini.'
                      : '${repo.sksDipilih(npm)} SKS terdaftar · '
                            'plafon ${repo.plafonSks(npm)} SKS',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        SectionHeader(
          eyebrow: 'Pintasan',
          title: 'Layanan mahasiswa',
          subtitle: 'Akses cepat modul akademik pendukung.',
        ),
        const _QuickActions(),
        SectionHeader(
          eyebrow: 'Akademik',
          title: belumDibaca == 0
              ? 'Info akademik'
              : 'Info akademik · $belumDibaca baru',
          action: TextButton(
            onPressed: () => context.go('/mahasiswa/info'),
            child: const Text('Semua info'),
          ),
        ),
        for (final p in pengumuman) _PengumumanTile(pengumuman: p),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return BezelCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          _Aksi(
            icon: Icons.workspace_premium_outlined,
            label: 'Transkrip',
            path: '/mahasiswa/transkrip',
          ),
          _Aksi(
            icon: Icons.forum_outlined,
            label: 'Bimbingan',
            path: '/mahasiswa/bimbingan',
          ),
          _Aksi(
            icon: Icons.description_outlined,
            label: 'Surat Akademik',
            path: '/mahasiswa/surat',
          ),
          _Aksi(
            icon: Icons.celebration_outlined,
            label: 'Yudisium',
            path: '/mahasiswa/yudisium',
          ),
          _Aksi(
            icon: Icons.dynamic_feed_outlined,
            label: 'Pengajuan',
            path: '/mahasiswa/pengajuan',
          ),
          _Aksi(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Keuangan',
            path: '/mahasiswa/keuangan',
          ),
        ],
      ),
    );
  }
}

class _Aksi extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;

  const _Aksi({required this.icon, required this.label, required this.path});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => context.go(path),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  final KalenderEvent event;

  const _AgendaCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sisa = event.sisaHari(DateTime.now());
    return BezelCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$sisa',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('hari', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.judul,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  formatTanggalPanjang(event.tanggal),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go('/mahasiswa/info'),
            child: const Text('Kalender'),
          ),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final MahasiswaProfile profile;

  const _GreetingCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BezelCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Text(
              profile.nama.substring(0, 1).toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: cs.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${profile.nama}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${profile.npm} · ${profile.prodi} · Semester '
                  '${profile.semester}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              StatusBadge(
                label: profile.status.label,
                tone: profile.status == StatusMahasiswa.aktif
                    ? BadgeTone.success
                    : BadgeTone.danger,
              ),
              if (!profile.npmValid)
                const StatusBadge(
                  label: 'NPM tidak valid',
                  tone: BadgeTone.danger,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final List<({IconData icon, String label, String value, String sub})> items;

  const _KpiGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    icon: items[i].icon,
                    label: items[i].label,
                    value: items[i].value,
                    sub: items[i].sub,
                  ),
                ),
              ],
            ],
          );
        }
        return SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 210,
              child: KpiCard(
                icon: items[i].icon,
                label: items[i].label,
                value: items[i].value,
                sub: items[i].sub,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KelasHariIni extends StatelessWidget {
  final Kelas kelas;

  const _KelasHariIni({required this.kelas});

  @override
  Widget build(BuildContext context) {
    final jadwal = kelas.jadwal.first;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BezelCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  jadwal.jamMulai,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: cs.primary),
                ),
                Text(
                  jadwal.jamSelesai,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 36, color: cs.outline),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kelas.namaMk,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${kelas.kode} · ${jadwal.ruanganTampil}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            StatusBadge(label: '${kelas.sks} SKS', tone: BadgeTone.neutral),
          ],
        ),
      ),
    );
  }
}

class _StatusKrsBadge extends StatelessWidget {
  final StatusKrs? status;

  const _StatusKrsBadge({required this.status});

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

class _PengumumanTile extends StatelessWidget {
  final Pengumuman pengumuman;

  const _PengumumanTile({required this.pengumuman});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BezelCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              pengumuman.penting ? Icons.campaign : Icons.push_pin_outlined,
              color: cs.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pengumuman.judul,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pengumuman.isi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
