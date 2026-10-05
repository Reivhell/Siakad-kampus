import 'package:flutter/material.dart';

import '../models/fase5b_seed.dart';
import '../models/transfer.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
    );
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '[${c.npm}] ${c.nama}',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium,
                              ),
                            ),
                            StatusBadge(
                              label: c.status,
                              tone: c.status == 'DISAHKAN'
                                  ? BadgeTone.success
                                  : BadgeTone.pending,
                            ),
                          ],
                        ),
                        Text(
                          '${c.jalur} ${footnoteFor[c.jalur] ?? ''} • ${c.asal}',
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
                                    '${m.lokalMkId} → ${m.diakuiHuruf} (${m.diakuiBobot})\n${mappingPattern(nAsal: 1, nLokal: 1)}',
                                    style: const TextStyle(
                                      fontFeatures: [
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
                                for (final m in c.maps) {
                                  final err = guardAsalHuruf(m.asalHuruf);
                                  if (err != null) {
                                    _snack(err);
                                    return;
                                  }
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
