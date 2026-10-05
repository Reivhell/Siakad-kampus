import 'package:flutter/material.dart';

import '../models/advising.dart';
import '../models/fase5_seed.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/bezel_card.dart';
import '../widgets/feedback.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Dosen Wali (spec 11): beban + round-robin wizard + bypass + SP.
class AdvisorPage extends StatefulWidget {
  const AdvisorPage({super.key});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage> {
  late List<AdvisorLoad> _loads;

  @override
  void initState() {
    super.initState();
    _loads = seedAdvisor();
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _wizard() async {
    final picked = _loads.map((e) => e.nidn).toSet();
    final res = await showAdminForm<Map<String, List<String>>>(
      context: context,
      title: 'Alokasi Batch 120 Maba',
      child: StatefulBuilder(
        builder: (ctx, setS) {
          final n = picked.length;
          final each = n == 0 ? 0 : 120 ~/ n;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final d in _loads)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(d.nama),
                  subtitle: Text('Asuhan kini ${d.asuhan}'),
                  value: picked.contains(d.nidn),
                  onChanged: (v) => setS(
                    () => v == true
                        ? picked.add(d.nidn)
                        : picked.remove(d.nidn),
                  ),
                ),
              Text(
                n < 2
                    ? 'Centang minimal 2 dosen.'
                    : 'Simulasi: 120 → $n dosen @ $each mhs (round-robin NPM).',
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batalkan'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: n < 2
                        ? null
                        : () => Navigator.pop(
                            ctx,
                            distributeRoundRobin(
                              studentNpms: List.generate(
                                120,
                                (i) =>
                                    '2610010${(i + 1).toString().padLeft(3, '0')}',
                              ),
                              lecturerNidns: picked.toList(),
                            ),
                          ),
                    child: const Text('Jalankan'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    if (res == null) return;
    setState(() {
      for (final d in _loads) {
        d.asuhan += res[d.nidn]?.length ?? 0;
      }
    });
    _snack('120 maba teralokasikan atomik. Audit tercatat.');
  }

  Future<void> _bypass(AdvisorLoad d) async {
    final catatan = TextEditingController();
    final ok = await showAdminForm<bool>(
      context: context,
      title: 'Bypass ${d.nama}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Syarat: ≤24 jam + ≥2 reminder + SKS ok + no bentrok.'),
          const SizedBox(height: 8),
          TextField(
            controller: catatan,
            decoration: const InputDecoration(
              labelText: 'Catatan Kaprodi *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sahkan'),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = bypassEligible(
      deadlineHoursLeft: 12,
      remindersSent: 2,
      sksOk: true,
      noConflict: true,
      catatan: catatan.text,
    );
    if (err != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }
    setState(() => d.approved = d.asuhan);
    _snack('KRS asuhan ${d.nama} disahkan darurat.');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
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
              Reveal(
                child: SectionHeader(
                  eyebrow: 'Admin / Dosen Wali',
                  title: 'Dosen Wali & Bimbingan',
                  subtitle: 'Kuota ideal 30–40 • overload > 45 merah',
                  action: FilledButton.icon(
                    onPressed: _wizard,
                    icon: const Icon(Icons.casino_outlined, size: 18),
                    label: const Text('Alokasi Batch'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _loads.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Reveal(
                    delayMs: (i * 40).clamp(0, 200),
                    child: BezelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_loads[i].nama} (${_loads[i].nidn})',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              if (overloadAsuhan(_loads[i].asuhan))
                                const StatusBadge(
                                  label: 'OVERLOAD',
                                  tone: BadgeTone.danger,
                                )
                              else
                                StatusBadge(
                                  label:
                                      '${_loads[i].approved}/${_loads[i].asuhan} KRS',
                                  tone: _loads[i].approved < _loads[i].asuhan
                                      ? BadgeTone.pending
                                      : BadgeTone.success,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: _loads[i].asuhan == 0
                                  ? 0
                                  : _loads[i].approved / _loads[i].asuhan,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.tonal(
                                onPressed: () => soon(
                                  context,
                                  'Kelola mahasiswa ${_loads[i].nama}',
                                ),
                                child: const Text('Kelola Mhs'),
                              ),
                              if (_loads[i].approved < _loads[i].asuhan)
                                FilledButton.tonal(
                                  onPressed: () => _bypass(_loads[i]),
                                  child: const Text('Bypass Darurat'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const Reveal(
                child: SectionHeader(
                  eyebrow: 'Early warning',
                  title: 'Contoh SP Otomatis',
                  subtitle: 'SP-1 IPS<2 • SP-2 beruntun/smt6 SKS<80 • SP-3 smt≥12 tanpa proposal',
                ),
              ),
              const SizedBox(height: 8),
              const Reveal(
                child: BezelCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusBadge(
                        label: 'Dimas SP-2 (1.95, 1.88)',
                        tone: BadgeTone.pending,
                      ),
                      StatusBadge(
                        label: 'Rina SP-1 (1.90)',
                        tone: BadgeTone.info,
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
