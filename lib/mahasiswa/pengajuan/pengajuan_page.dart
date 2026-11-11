import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/widgets/bezel_card.dart';
import '../../admin/widgets/empty_state.dart';
import '../../admin/widgets/section_header.dart';
import '../../admin/widgets/status_badge.dart';
import '../../app/formatters.dart';
import '../../app/widgets/status_banner.dart';
import '../../features/mahasiswa/models/mahasiswa_layanan_models.dart';
import '../../features/mahasiswa/models/mahasiswa_models.dart';
import '../../features/mahasiswa/providers/mahasiswa_providers.dart';
import '../widgets/layanan_widgets.dart';
import '../widgets/page_body.dart';

/// Layanan pengajuan: cuti, banding nilai, konversi/MBKM
/// (`12_layanan_pengajuan.md`, EKSTENSI P2).
class PengajuanPage extends ConsumerStatefulWidget {
  const PengajuanPage({super.key});

  @override
  ConsumerState<PengajuanPage> createState() => _PengajuanPageState();
}

class _PengajuanPageState extends ConsumerState<PengajuanPage> {
  int _tab = 0;

  static const _labels = ['Cuti', 'Banding Nilai', 'Konversi / MBKM'];
  static const _icons = [
    Icons.pause_circle_outline,
    Icons.rate_review_outlined,
    Icons.swap_horiz_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(mahasiswaRepositoryProvider);
    final npm = ref.watch(currentNpmProvider);
    if (npm == null) {
      return const EmptyState(
        icon: Icons.person_off_outlined,
        title: 'Sesi tidak ditemukan',
        subtitle: 'Silakan masuk kembali.',
      );
    }
    if (repo.profile(npm) == null) {
      return const EmptyState(
        icon: Icons.person_off_outlined,
        title: 'Profil tidak ditemukan',
        subtitle: 'Hubungi administrator.',
      );
    }

    final cuti = repo.cutiMahasiswa(npm);
    final banding = repo.bandingMahasiswa(npm);
    final konversi = repo.konversiMahasiswa(npm);

    return PageBody(
      maxWidth: 1000,
      children: [
        SectionHeader(
          eyebrow: 'Layanan',
          title: 'Pengajuan Akademik',
          subtitle: 'Cuti, banding nilai, dan konversi kredit/MBKM dalam satu portal.',
          action: FilledButton.tonalIcon(
            onPressed: () => _bukaForm(context, ref),
            icon: const Icon(Icons.add),
            label: Text('Ajukan ${_labels[_tab]}'),
          ),
        ),
        const StatusBanner(
          tone: StatusBannerTone.info,
          icon: Icons.fact_check_outlined,
          message:
              'Semua pengajuan bersifat read-own dan diproses admin/dosen. '
              'Anda dapat membatalkan pengajuan selama status masih PENGAJUAN.',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            segments: [
              for (var i = 0; i < _labels.length; i++)
                ButtonSegment(
                  value: i,
                  icon: Icon(_icons[i]),
                  label: Text(_labels[i]),
                ),
            ],
            selected: {_tab},
            onSelectionChanged: (v) => setState(() => _tab = v.first),
          ),
        ),
        if (_tab == 0)
          ..._cutiSection(context, npm, cuti)
        else if (_tab == 1)
          ..._bandingSection(context, npm, banding)
        else
          ..._konversiSection(context, npm, konversi),
      ],
    );
  }

  List<Widget> _cutiSection(
    BuildContext context,
    String npm,
    List<PengajuanCuti> rows,
  ) {
    return [
      SectionHeader(
        eyebrow: 'Cuti',
        title: 'Pengajuan cuti akademik',
        subtitle: '${rows.length} pengajuan',
      ),
      if (rows.isEmpty)
        const BezelCard(
          child: Text(
            'Belum ada pengajuan cuti. Cuti hanya dapat diajukan saat status '
            'mahasiswa AKTIF.',
          ),
        )
      else
        for (final c in rows)
          _PengajuanCard(
            icon: Icons.pause_circle_outline,
            title: 'Cuti ${_namaPeriode(c.periodeId)}',
            body: c.alasan,
            tanggal: c.diajukan,
            status: c.status,
            onBatalkan: c.status.menunggu
                ? () => _batalkanCuti(context, c)
                : null,
          ),
    ];
  }

  List<Widget> _bandingSection(
    BuildContext context,
    String npm,
    List<BandingNilai> rows,
  ) {
    return [
      SectionHeader(
        eyebrow: 'Banding',
        title: 'Banding nilai',
        subtitle: '${rows.length} pengajuan',
      ),
      if (rows.isEmpty)
        const BezelCard(
          child: Text(
            'Belum ada banding nilai. Banding hanya untuk MK dengan nilai '
            'final, maksimal 7 hari setelah nilai disahkan.',
          ),
        )
      else
        for (final b in rows)
          _PengajuanCard(
            icon: Icons.rate_review_outlined,
            title: '${b.kodeMk} · ${b.namaMk}',
            body: b.alasan,
            tanggal: b.diajukan,
            status: b.status,
            jawaban: b.jawabanDosen,
          ),
    ];
  }

  List<Widget> _konversiSection(
    BuildContext context,
    String npm,
    List<PengajuanKonversi> rows,
  ) {
    return [
      SectionHeader(
        eyebrow: 'Konversi',
        title: 'Konversi & transfer kredit',
        subtitle: '${rows.length} pengajuan',
      ),
      if (rows.isEmpty)
        const BezelCard(
          child: Text(
            'Belum ada pengajuan konversi. Gunakan untuk mahasiswa pindahan, '
            'alih jenjang, atau kegiatan MBKM.',
          ),
        )
      else
        for (final k in rows)
          _PengajuanCard(
            icon: Icons.swap_horiz_outlined,
            title: k.jenis.label,
            body: '${k.institusiAsal} · ${k.sksDimohonkan} SKS. ${k.catatan}',
            tanggal: k.diajukan,
            status: k.status,
            jawaban: k.hasilPemetaan,
          ),
    ];
  }

  String _namaPeriode(String id) {
    final repo = ref.read(mahasiswaRepositoryProvider);
    for (final p in repo.periode) {
      if (p.id == id) return p.nama;
    }
    return id;
  }

  Future<void> _batalkanCuti(BuildContext context, PengajuanCuti cuti) async {
    final err = ref
        .read(mahasiswaRepositoryProvider)
        .batalkanCuti(cuti.npm, cuti.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Pengajuan cuti dibatalkan.'),
        backgroundColor: err == null
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _bukaForm(BuildContext context, WidgetRef ref) async {
    final npm = ref.read(currentNpmProvider)!;
    switch (_tab) {
      case 0:
        await _formCuti(context, npm);
      case 1:
        await _formBanding(context, npm);
      default:
        await _formKonversi(context, npm);
    }
  }

  Future<void> _formCuti(BuildContext context, String npm) async {
    final alasan = TextEditingController();
    String? error;
    final hasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Ajukan cuti akademik'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periode aktif: '
                  '${ref.read(mahasiswaRepositoryProvider).periodeAktif.nama}. '
                  'KRS periode berjalan akan dibekukan setelah disetujui.',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: alasan,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Alasan cuti',
                    alignLabelWithHint: true,
                    hintText: 'Contoh: alasan kesehatan dengan surat keterangan dokter',
                  ),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final err = validasiAlasan(alasan.text);
                if (err != null) {
                  setState(() => error = err);
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
    if (hasil != true) return;
    final err = ref
        .read(mahasiswaRepositoryProvider)
        .ajukanCuti(npm, alasan: alasan.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Pengajuan cuti terkirim.'),
        backgroundColor: err == null
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _formBanding(BuildContext context, String npm) async {
    final repo = ref.read(mahasiswaRepositoryProvider);
    final kandidat = <String, NilaiRecord>{
      for (final n in repo.nilaiMahasiswa(npm))
        if (n.sudahFinal && n.huruf != null) n.kodeMk: n,
    }.values.toList()..sort((a, b) => a.kodeMk.compareTo(b.kodeMk));
    if (kandidat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada nilai final yang dapat dibanding.'),
        ),
      );
      return;
    }
    var pilihan = kandidat.first.kodeMk;
    final alasan = TextEditingController();
    String? error;
    final hasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Ajukan banding nilai'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: pilihan,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mata kuliah (nilai final)',
                  ),
                  items: [
                    for (final n in kandidat)
                      DropdownMenuItem(
                        value: n.kodeMk,
                        child: Text(
                          '${n.kodeMk} · ${n.namaMk} (${n.huruf})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => pilihan = v ?? pilihan),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: alasan,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Alasan banding',
                    alignLabelWithHint: true,
                    hintText:
                        'Sertakan bukti atau komponen nilai yang dipersoalkan',
                  ),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final err = validasiAlasan(alasan.text);
                if (err != null) {
                  setState(() => error = err);
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
    if (hasil != true) return;
    final err = repo.ajukanBanding(npm, pilihan, alasan.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Banding nilai terkirim.'),
        backgroundColor: err == null
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _formKonversi(BuildContext context, String npm) async {
    var jenis = JenisKonversi.mbkm;
    final institusi = TextEditingController();
    final sks = TextEditingController(text: '20');
    final catatan = TextEditingController();
    String? error;
    final hasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Ajukan konversi kredit'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<JenisKonversi>(
                    initialValue: jenis,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Jenis'),
                    items: [
                      for (final j in JenisKonversi.values)
                        DropdownMenuItem(value: j, child: Text(j.label)),
                    ],
                    onChanged: (v) => setState(() => jenis = v ?? jenis),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: institusi,
                    decoration: const InputDecoration(
                      labelText: 'Institusi asal / mitra',
                      hintText: 'Contoh: PT Nusantara Digital',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sks,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'SKS yang dimohonkan',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: catatan,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi kegiatan / MK asal',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final sksValue = int.tryParse(sks.text.trim());
                if (sksValue == null) {
                  setState(() => error = 'SKS harus berupa angka.');
                  return;
                }
                final err =
                    validasiSksKonversi(sksValue) ??
                    validasiAlasan(catatan.text);
                if (err != null) {
                  setState(() => error = err);
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
    if (hasil != true) return;
    final err = ref
        .read(mahasiswaRepositoryProvider)
        .ajukanKonversi(
          npm,
          jenis: jenis,
          institusiAsal: institusi.text,
          sksDimohonkan: int.tryParse(sks.text.trim()) ?? 0,
          catatan: catatan.text,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Pengajuan konversi terkirim.'),
        backgroundColor: err == null
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _PengajuanCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final DateTime tanggal;
  final StatusPengajuan status;
  final String? jawaban;
  final VoidCallback? onBatalkan;

  const _PengajuanCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.tanggal,
    required this.status,
    this.jawaban,
    this.onBatalkan,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BezelCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: status.label,
                        tone: tonePengajuan(status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatTanggal(tanggal),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                  if (jawaban != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Tanggapan: $jawaban',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  if (onBatalkan != null) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: onBatalkan,
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Batalkan pengajuan'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
