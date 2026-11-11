import 'package:flutter/material.dart';

import '../widgets/admin_page.dart';

import '../models/fase5b_seed.dart';
import '../rules/admin_rules.dart';
import '../widgets/bezel_card.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Konversi (spec 14): matriks 2 sisi + pola + cap + footnote.
class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  late List<TransferCase> _cases;

  @override
  void initState() {
    super.initState();
    _cases = seedTransfer();
  }

  void _snack(String m) {
    showAdminSnack(context, m);
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
              const Reveal(
                child: SectionHeader(
                  eyebrow: 'Admin / Konversi',
                  title: 'Transfer & MBKM',
                  subtitle: '1-to-1 • N-to-1 merger • 1-to-N MBKM 20 SKS',
                ),
              ),
              const SizedBox(height: 16),
              for (final c in _cases)
                Reveal(
                  child: BezelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdminListRow(
                          title: Text(
                            '[${c.npm}] ${c.nama}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          trailing: StatusBadge(
                            label: c.status,
                            tone: c.status == 'DISAHKAN'
                                ? BadgeTone.success
                                : BadgeTone.pending,
                          ),
                        ),
                        Text(
                          '${c.jalur} ${AdminRules.transferFootnote(c.jalur) ?? ''} • ${c.asal}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Divider(height: 24),
                        for (final m in c.maps)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    '[${m.asalKode}] ${m.asalNama}\n${m.asalSks} SKS • asal ${m.asalHuruf}',
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.arrow_forward, size: 18),
                                ),
                                Expanded(
                                  child: Text(
                                    '${m.lokalMkId} → ${m.diakuiHuruf} (${m.diakuiBobot})\n${AdminRules.transferPattern(nAsal: m.asalKode.split('+').length, nLokal: 1)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilledButton.tonal(
                              onPressed: () {
                                // Total dihitung sekali (dulu fold 2× per baris).
                                final totalSks = c.maps.fold(
                                  0,
                                  (a, x) => a + x.asalSks,
                                );
                                final g = RuleCheck.all([
                                  for (final m in c.maps)
                                    AdminRules.transfer(
                                      asalHuruf: m.asalHuruf,
                                      totalDiakui: totalSks,
                                      paketSks: totalSks,
                                      isMbkm: c.jalur.startsWith('MBKM'),
                                    ),
                                ]);
                                if (!g.ok) {
                                  _snack(g.message ?? 'Ditolak.');
                                  return;
                                }
                                setState(() => c.status = 'DISAHKAN');
                                _snack(
                                  'SK SK-KONV/FTI/2026/015 terbit • nilai diinjeksi.',
                                );
                              },
                              child: const Text('Sahkan + Injeksi'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Reveal(
                child: BezelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Guard regulasi'),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusBadge(
                            label: 'Asal min C (D/E ditolak)',
                            tone: BadgeTone.info,
                          ),
                          StatusBadge(
                            label: 'Cap total 100 SKS S1',
                            tone: BadgeTone.info,
                          ),
                          StatusBadge(
                            label: 'MBKM ≤ 20/semester',
                            tone: BadgeTone.info,
                          ),
                          StatusBadge(
                            label: 'Footnote *T/*M/*R',
                            tone: BadgeTone.neutral,
                          ),
                        ],
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
