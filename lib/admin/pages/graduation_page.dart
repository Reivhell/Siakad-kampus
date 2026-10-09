import 'package:flutter/material.dart';

import '../models/fase5_seed.dart';
import '../models/graduation.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/bezel_card.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Yudisium (spec 12): degree audit 7 parameter + predikat + SK massal.
class GraduationPage extends StatefulWidget {
  const GraduationPage({super.key});

  @override
  State<GraduationPage> createState() => _GraduationPageState();
}

class _GraduationPageState extends State<GraduationPage> {
  late List<YudisiumCalon> _calon;
  final _pins = <String>['132012026000100'];

  @override
  void initState() {
    super.initState();
    _calon = seedYudisium();
  }

  DegreeResult _audit(YudisiumCalon c) => degreeAudit(
    grades: c.grades,
    semesters: c.semesters,
    libraryClear: c.library,
    financeClear: c.finance,
  );

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _detail(YudisiumCalon c) async {
    final r = _audit(c);
    final pinC = TextEditingController(text: c.pin ?? '');
    final ok = await showAdminForm<bool>(
      context: context,
      title: 'Audit ${c.npm}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${c.nama} • ${c.semesters} smt • IPK ${r.ipk}'),
          const SizedBox(height: 8),
          for (final reason in r.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(reason)),
                ],
              ),
            ),
          if (r.pass)
            StatusBadge(
              label: r.predikat,
              tone: r.predikat.contains('PUJIAN')
                  ? BadgeTone.success
                  : BadgeTone.info,
              icon: Icons.emoji_events_outlined,
            ),
          const SizedBox(height: 8),
          TextField(
            controller: pinC,
            decoration: const InputDecoration(
              labelText: 'PIN Ijazah Nasional',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tutup'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Tetapkan'),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok != true) return;
    final pin = pinC.text.trim();
    if (pin.isNotEmpty) {
      final otherPins = [
        ..._pins,
        for (final x in _calon)
          if (x != c && x.pin != null) x.pin!,
      ];
      final err = validatePin(pin, otherPins);
      if (err != null) {
        _snack(err, error: true);
        return;
      }
      setState(() => c.pin = pin);
      _snack('PIN ${c.npm} tercatat unik.');
    }
  }

  Future<void> _sahkan() async {
    final sk = TextEditingController(text: 'SK-YUD/FTI/2026/08');
    final ok = await showAdminForm<bool>(
      context: context,
      title: 'Sahkan Yudisium Massal',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: sk,
            decoration: const InputDecoration(
              labelText: 'Nomor SK *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Hanya MEMENUHI yang diproses LULUS + read-only.'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
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
    if (ok != true || sk.text.trim().isEmpty) return;
    final n = _calon.where((c) => _audit(c).pass).length;
    _snack('$n lulusan disahkan ${sk.text.trim()}. Status → LULUS.');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final lolos = _calon.where((c) => _audit(c).pass).length;
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
                  eyebrow: 'Admin / Yudisium',
                  title: 'Kelulusan & Yudisium',
                  subtitle:
                      '$lolos/${_calon.length} lolos audit • SK-YUD/FTI/2026/08',
                  action: FilledButton.icon(
                    onPressed: _sahkan,
                    icon: const Icon(Icons.bolt_outlined, size: 18),
                    label: const Text('Sahkan'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _calon.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Reveal(
                    delayMs: (i * 40).clamp(0, 200),
                    child: Builder(
                      builder: (_) {
                        final r = _audit(_calon[i]);
                        return BezelCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${_calon[i].npm} • ${_calon[i].nama}',
                              style: const TextStyle(
                                fontFeatures: [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            subtitle: Text(
                              r.pass
                                  ? 'IPK ${r.ipk} • ${r.predikat}${_calon[i].pin != null ? ' • PIN ✓' : ''}'
                                  : r.reasons.join(' '),
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                StatusBadge(
                                  label: r.pass ? 'MEMENUHI' : 'KENDALA',
                                  tone: r.pass
                                      ? BadgeTone.success
                                      : BadgeTone.danger,
                                ),
                                TextButton(
                                  onPressed: () => _detail(_calon[i]),
                                  child: const Text('Audit'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
