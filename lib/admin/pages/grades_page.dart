import 'package:flutter/material.dart';

import '../models/grades_seed.dart';
import '../models/grading.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/bezel_card.dart';
import '../widgets/filter_bar.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Monitoring Nilai (spec 08): rekap finalisasi + unlock BA + referensi konversi.
class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  final _search = TextEditingController();
  late List<KelasNilai> _kelas;
  String _status = 'SEMUA';

  @override
  void initState() {
    super.initState();
    _kelas = seedKelasNilai();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _unlock(KelasNilai k) async {
    final ba = TextEditingController();
    int jam = 48;
    final ok = await showAdminForm<bool>(
      context: context,
      title: 'Buka Kunci ${k.kode}',
      child: StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${k.mkNama} • ${k.dosen}'),
            const SizedBox(height: 8),
            TextField(
              controller: ba,
              decoration: const InputDecoration(
                labelText: 'Nomor Berita Acara *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownMenu<int>(
              initialSelection: jam,
              label: const Text('Jendela'),
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 24, label: '24 jam'),
                DropdownMenuEntry(value: 48, label: '48 jam (standar)'),
                DropdownMenuEntry(value: 72, label: '72 jam'),
              ],
              onSelected: (v) => setS(() => jam = v ?? jam),
            ),
            const Text(
              'Kunci kembali otomatis saat jendela berakhir (cron).',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batalkan'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Setujui & Buka'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (ba.text.trim().isEmpty) {
      _snack('Berita Acara wajib.', error: true);
      return;
    }
    final now = DateTime.now();
    setState(() {
      k.finalisasi = false;
      k.unlockHingga = unlockExpiry(now, jam);
    });
    _snack('${k.kode} terbuka $jam jam hingga ${k.unlockHingga}.');
  }

  void _relock(KelasNilai k) {
    setState(() {
      k.unlockHingga = null;
    });
    _snack('${k.kode} dipantau revisi — kunci manual bila dosen selesai.');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final q = _search.text.toLowerCase();
    final list = _kelas.where((k) {
      if (q.isNotEmpty &&
          !k.mkNama.toLowerCase().contains(q) &&
          !k.kode.toLowerCase().contains(q) &&
          !k.dosen.toLowerCase().contains(q)) {
        return false;
      }
      if (_status != 'SEMUA' && k.status != _status) return false;
      return true;
    }).toList();
    final finalCount = _kelas.where((k) => k.finalisasi).length;
    final frac = _kelas.isEmpty ? 0.0 : finalCount / _kelas.length;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: width >= 1024 ? 24 : 16,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Reveal(
                child: SectionHeader(
                  eyebrow: 'Admin / Nilai',
                  title: 'Monitoring Nilai',
                  subtitle:
                      'Batas finalisasi 28 Jan 2026 • reminder otomatis H-7/H-3',
                ),
              ),
              const SizedBox(height: 16),
              Reveal(
                child: BezelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keterisian kampus ${(frac * 100).toStringAsFixed(1)}% final',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Reveal(
                child: BezelCard(
                  child: FilterBar(
                    searchController: _search,
                    searchHint: 'Cari MK / dosen…',
                    onSearchChanged: (_) => setState(() {}),
                    filters: [
                      FilterOption(
                        label: 'Status',
                        value: _status,
                        options: const [
                          'SEMUA',
                          'FINAL',
                          'DRAFT',
                          'KOSONG',
                          'TERBUKA',
                        ],
                        onSelected: (v) => setState(() => _status = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Reveal(
                    delayMs: (i * 40).clamp(0, 240),
                    child: BezelCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('[${list[i].kode}] ${list[i].mkNama}'),
                        subtitle: Text(
                          '${list[i].dosen} • ${list[i].terisi}/${list[i].peserta} terisi${list[i].unlockHingga != null ? ' • terbuka hingga ${list[i].unlockHingga}' : ''}',
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusBadge(
                              label: list[i].status,
                              tone: switch (list[i].status) {
                                'FINAL' => BadgeTone.success,
                                'DRAFT' => BadgeTone.pending,
                                'TERBUKA' => BadgeTone.info,
                                _ => BadgeTone.danger,
                              },
                            ),
                            if (list[i].finalisasi)
                              FilledButton.tonal(
                                onPressed: () => _unlock(list[i]),
                                child: const Text('Buka Kunci'),
                              )
                            else
                              FilledButton.tonal(
                                onPressed: () => _relock(list[i]),
                                child: const Text('Pantau'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const Reveal(
                child: SectionHeader(
                  eyebrow: 'Referensi',
                  title: 'Skala Konversi 7-Tier',
                  subtitle: 'A 85+ • AB 80+ • B 75+ • BC 70+ • C 65+ • D 50+ • E <50',
                ),
              ),
              const SizedBox(height: 8),
              Reveal(
                child: BezelCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in [85.0, 82.0, 77.0, 72.0, 67.0, 55.0, 30.0])
                        Builder(
                          builder: (_) {
                            final g = convertScore(s);
                            return Chip(
                              label: Text(
                                '${s.toInt()} → ${g.huruf} (${g.bobot})',
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
