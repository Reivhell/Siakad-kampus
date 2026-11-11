import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/widgets/bezel_card.dart';
import '../../admin/widgets/empty_state.dart';
import '../../admin/widgets/section_header.dart';
import '../../admin/widgets/status_badge.dart';
import '../../app/widgets/status_banner.dart';
import '../../features/mahasiswa/models/mahasiswa_models.dart';
import '../../features/mahasiswa/providers/mahasiswa_providers.dart';
import '../widgets/page_body.dart';

/// Profil & status (`02_profil_dan_status.md`). Edit terbatas telepon/avatar.
class ProfilPage extends ConsumerWidget {
  const ProfilPage({super.key});

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
    final p = repo.profile(npm);
    if (p == null) {
      return const EmptyState(
        icon: Icons.person_off_outlined,
        title: 'Profil tidak ditemukan',
        subtitle:
            'Akun belum tertaut ke data mahasiswa. Hubungi administrator.',
      );
    }

    return PageBody(
      maxWidth: 900,
      children: [
        SectionHeader(
          eyebrow: 'Akun',
          title: 'Profil Mahasiswa',
          subtitle: 'Data akademik hanya dapat diubah oleh admin akademik.',
        ),
        BezelCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.12),
                child: Text(
                  p.nama.substring(0, 1).toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nama,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${p.npm} · ${p.prodi}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: p.status.label,
                tone: p.status == StatusMahasiswa.aktif
                    ? BadgeTone.success
                    : BadgeTone.danger,
              ),
            ],
          ),
        ),
        if (!p.status.bisaAmbilKrs)
          StatusBanner(
            tone: StatusBannerTone.danger,
            icon: Icons.lock_outline,
            message:
                'Status ${p.status.label} — menu KRS dikunci. '
                'Hubungi admin akademik untuk informasi lebih lanjut.',
          ),
        BezelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identitas akademik',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              InfoLine(label: 'NPM', value: p.npm),
              InfoLine(label: 'Nama lengkap', value: p.nama),
              InfoLine(label: 'Program studi', value: p.prodi),
              InfoLine(label: 'Jenjang', value: p.jenjang),
              InfoLine(label: 'Tahun masuk', value: '${p.tahunMasuk}'),
              InfoLine(label: 'Semester', value: '${p.semester}'),
              InfoLine(label: 'Dosen wali', value: p.dosenWali),
            ],
          ),
        ),
        BezelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kontak', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              InfoLine(label: 'Email', value: p.email),
              InfoLine(
                label: 'Telepon',
                value: p.telepon,
                trailing: IconButton(
                  tooltip: 'Ubah telepon',
                  onPressed: () => _editTelepon(context, ref, p),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              ),
              InfoLine(
                label: 'Avatar URL',
                value: p.avatarUrl ?? 'Belum diatur',
                trailing: IconButton(
                  tooltip: 'Ubah avatar',
                  onPressed: () => _editAvatar(context, ref, p),
                  icon: const Icon(Icons.image_outlined, size: 18),
                ),
              ),
            ],
          ),
        ),
        Text(
          'Setiap perubahan profil dicatat pada log aktivitas '
          '(MAHASISWA_UBAH_PROFIL).',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Future<void> _editTelepon(
    BuildContext context,
    WidgetRef ref,
    MahasiswaProfile p,
  ) async {
    final controller = TextEditingController(text: p.telepon);
    final hasil = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah nomor telepon'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nomor telepon',
            hintText: '+62 812-xxxx-xxxx',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (hasil == null) return;
    final err = ref
        .read(mahasiswaRepositoryProvider)
        .updateProfil(p.npm, telepon: hasil);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Nomor telepon diperbarui.'),
        backgroundColor: err == null
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _editAvatar(
    BuildContext context,
    WidgetRef ref,
    MahasiswaProfile p,
  ) async {
    final controller = TextEditingController(text: p.avatarUrl ?? '');
    final hasil = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah URL avatar'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'URL gambar',
            hintText: 'https://…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (hasil == null) return;
    final err = ref
        .read(mahasiswaRepositoryProvider)
        .updateProfil(p.npm, avatarUrl: hasil);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Avatar diperbarui.'),
        backgroundColor: err == null
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }
}
