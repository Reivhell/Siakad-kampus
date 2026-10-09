import 'package:flutter/material.dart';

import '../models/fase5b_seed.dart';
import '../models/letters.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/bezel_card.dart';
import '../widgets/feedback.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Persuratan (spec 15): antrean + pre-flight + nomor otomatis + QR.
class LettersPage extends StatefulWidget {
  const LettersPage({super.key});

  @override
  State<LettersPage> createState() => _LettersPageState();
}

class _LettersPageState extends State<LettersPage> {
  final _search = TextEditingController();
  late List<LetterReq> _reqs;
  String _status = 'SEMUA';

  @override
  void initState() {
    super.initState();
    _reqs = seedLetters();
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

  Future<void> _terbitkan(LetterReq r) async {
    // Pre-flight: demo anggap AKTIF kecuali Dimas (CUTI di seed civitas).
    final err = letterEligible(r.npm == '2510010045' ? 'CUTI' : 'AKTIF');
    if (err != null) {
      _snack(err, error: true);
      return;
    }
    final pejabat = TextEditingController(text: 'Dekan FTI — Dr. Ir. Suyanto');
    final ok = await showAdminForm<bool>(
      context: context,
      title: 'Terbitkan ${r.jenis}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('[${r.npm}] ${r.nama} • ${r.tujuan}'),
          const Text('✓ AKTIF ✓ KRS 22 SKS ✓ UKT lunas'),
          const SizedBox(height: 8),
          TextField(
            controller: pejabat,
            decoration: const InputDecoration(
              labelText: 'Pejabat penandatangan',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tolak'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Setujui & Terbitkan'),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok == null) return;
    if (!ok) {
      setState(() => r.status = 'DITOLAK');
      _snack('Permohonan ditolak + alasan tercatat.');
      return;
    }
    final now = DateTime.now();
    final seq = nextLetterSeq(
      now.year,
      [
        for (final x in _reqs)
          if (x.nomor != null)
            (
              int.tryParse(x.nomor!.split('/').first) ?? 0,
              now.year,
            ),
      ],
    );
    setState(() {
      r.nomor = letterNumber(
        seq: seq,
        kode: r.kode,
        month: now.month,
        year: now.year,
      );
      r.status = 'SELESAI';
    });
    _snack('${r.nomor} terbit + QR aktif (90 hari).');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final q = _search.text.toLowerCase();
    final list = _reqs.where((r) {
      if (q.isNotEmpty &&
          !r.nama.toLowerCase().contains(q) &&
          !r.npm.contains(q) &&
          !(r.nomor ?? '').toLowerCase().contains(q)) {
        return false;
      }
      if (_status != 'SEMUA' && r.status != _status) return false;
      return true;
    }).toList();

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
                  eyebrow: 'Admin / Surat',
                  title: 'Persuratan Akademik',
                  subtitle: 'UUU/KODE/FTI-SIAKAD/ROMAWI/TTTT • QR publik • 90 hari',
                ),
              ),
              const SizedBox(height: 16),
              Reveal(
                child: BezelCard(
                  child: FilterBar(
                    searchController: _search,
                    searchHint: 'Cari NPM / nama / no surat…',
                    onSearchChanged: (_) => setState(() {}),
                    filters: [
                      FilterOption(
                        label: 'Status',
                        value: _status,
                        options: const [
                          'SEMUA',
                          'MENUNGGU_VERIFIKASI',
                          'SELESAI',
                          'DITOLAK',
                        ],
                        onSelected: (v) => setState(() => _status = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const Reveal(
                  child: BezelCard(
                    child: EmptyState(
                      icon: Icons.mail_outlined,
                      title: 'Antrean kosong',
                      subtitle: 'Tidak ada permohonan cocok.',
                    ),
                  ),
                )
              else
                for (var i = 0; i < list.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Reveal(
                      delayMs: (i * 40).clamp(0, 200),
                      child: BezelCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '[${list[i].npm}] ${list[i].nama}',
                          ),
                          subtitle: Text(
                            '${list[i].jenis} • ${list[i].tujuan}${list[i].nomor != null ? '\n${list[i].nomor}' : ''}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              StatusBadge(
                                label: list[i].status,
                                tone: switch (list[i].status) {
                                  'SELESAI' => BadgeTone.success,
                                  'DITOLAK' => BadgeTone.danger,
                                  _ => BadgeTone.pending,
                                },
                              ),
                              if (list[i].status == 'MENUNGGU_VERIFIKASI')
                                FilledButton.tonal(
                                  onPressed: () => _terbitkan(list[i]),
                                  child: const Text('Periksa'),
                                )
                              else
                                TextButton(
                                  onPressed: () => soon(
                                    context,
                                    'Unduh PDF ${list[i].nomor ?? ''}',
                                  ),
                                  child: const Text('Unduh'),
                                ),
                            ],
                          ),
                        ),
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
