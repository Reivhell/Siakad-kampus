import 'package:flutter/material.dart';

import '../models/fase5b_seed.dart';
import '../models/feeder.dart';
import '../rules/admin_rules.dart';
import '../widgets/admin_page.dart';
import '../widgets/bezel_card.dart';
import '../widgets/feedback.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';
import '../widgets/admin_dialog.dart';

/// PDDIKTI (spec 13): skor kesiapan + 7 paket + anomali + preview CSV.
class FeederPage extends StatefulWidget {
  const FeederPage({super.key});

  @override
  State<FeederPage> createState() => _FeederPageState();
}

class _FeederPageState extends State<FeederPage> {
  late List<FeederIssue> _issues;
  bool _ran = true;

  @override
  void initState() {
    super.initState();
    _issues = seedFeederIssues();
  }

  void _exportCsv() {
    final preview = AdminRules.csvRow(['npm', 'nama', 'nik', 'status']);
    showAdminForm<void>(
      context: context,
      title: 'Ekspor CSV Neo Feeder',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Paket AKM + Biodata — separator ; • UTF-8 • quote-escape.'),
          const SizedBox(height: 12),
          SelectableText('$preview\n${AdminRules.csvRow(['2210010001', 'Aditya Pratama', '3501000100000001', 'A'])}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: FilledButton.tonalIcon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.check, size: 18), label: const Text('Tutup'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    const total = 1420;
    final valid = total - _issues.length;
    final score = AdminRules.readiness(valid, total);
    const pakets = [
      ('Biodata Maba', 1.0, '350 data'),
      ('Kurikulum & MK', 1.0, '52 MK'),
      ('Kelas & Dosen', 0.99, '112 kelas'),
      ('KRS & Peserta', 1.0, '4.210 relasi'),
      ('Nilai', 0.91, '12 belum final'),
      ('AKM', 0.985, 'lengkap'),
      ('Lulus & DO', 1.0, '38 yudisium'),
    ];
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
                  eyebrow: 'Admin / PDDIKTI',
                  title: 'Pelaporan Neo Feeder',
                  subtitle: 'Tenggat 31 Mar 2026 • separator ; • UTF-8 • quote-escape',
                  action: FilledButton.icon(
                    onPressed: () => setState(() => _ran = true),
                    icon: const Icon(Icons.play_arrow_outlined, size: 18),
                    label: const Text('Diagnostik'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Reveal(
                child: BezelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skor kesiapan $score% SIAP LAPOR',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (nama, f, sub) in pakets)
                            Chip(
                              avatar: Icon(
                                f >= 1
                                    ? Icons.check_circle
                                    : Icons.warning_amber,
                                size: 16,
                              ),
                              label: Text('$nama • $sub'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Reveal(
                child: SectionHeader(
                  eyebrow: 'Anomali',
                  title: 'Wajib Diperbaiki',
                  subtitle: 'One-click navigation ke modul pemilik data',
                ),
              ),
              const SizedBox(height: 8),
              if (!_ran || _issues.isEmpty)
                const Reveal(
                  child: BezelCard(
                    child: Text('Bersih — siap ekspor ZIP CSV.'),
                  ),
                )
              else
                for (var i = 0; i < _issues.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Reveal(
                      delayMs: (i * 40).clamp(0, 200),
                      child: BezelCard(
                        child: AdminListRow(
                          title: Text(
                            '[${_issues[i].category}] ${_issues[i].name}',
                          ),
                          subtitle: Text(_issues[i].issue),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              const StatusBadge(
                                label: 'PERBAIKI',
                                tone: BadgeTone.pending,
                              ),
                              TextButton(
                                onPressed: () => soon(
                                  context,
                                  'Perbaiki di ${_issues[i].action}',
                                ),
                                child: Text(_issues[i].action),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              const Reveal(
                child: SectionHeader(
                  eyebrow: 'Preview',
                  title: 'Contoh Baris CSV',
                  subtitle:
                      'akm.csv: id_reg;npm;periode;ips;ipk;sks;total;status',
                ),
              ),
              const SizedBox(height: 8),
              Reveal(
                child: BezelCard(
                  child: SelectableText(
                    AdminRules.csvRow([
                      'REG-001',
                      '2610010001',
                      'Ganjil 2025/2026',
                      '3,85',
                      '3,80',
                      '20',
                      '20',
                      'A',
                    ]),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Reveal(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: _exportCsv,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Ekspor CSV'),
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
