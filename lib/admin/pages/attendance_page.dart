import 'package:flutter/material.dart';

import '../models/attendance.dart';
import '../models/attendance_seed.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/bezel_card.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Monitoring Presensi (spec 09): 16 pertemuan + skrining 75% + dispensasi.
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late List<KelasPresensi> _kelas;
  late List<SkriningMhs> _skrining;

  @override
  void initState() {
    super.initState();
    _kelas = seedKelasPresensi();
    _skrining = seedSkrining();
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _dispensasi(SkriningMhs s) async {
    final surat = TextEditingController();
    int sesi = 2;
    final el = evaluateUas(
      total: s.total,
      hadir: s.hadir,
      dispensasi: s.dispensasi,
    );
    final ok = await showAdminForm<bool>(
      context: context,
      title: 'Dispensasi ${s.npm}',
      child: StatefulBuilder(
        builder: (ctx, setS) {
          final proj = projectedPct(
            total: s.total,
            hadir: s.hadir,
            dispensasiNow: s.dispensasi,
            tambahan: sesi,
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.nama} • hadir ${s.hadir}/${s.total}'),
              Text(
                'Kini ${el.percentage}% ${el.eligible ? '🟢 BERHAK' : '🔴 TIDAK BERHAK'}',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: surat,
                decoration: const InputDecoration(
                  labelText: 'Nomor surat tugas *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownMenu<int>(
                initialSelection: sesi,
                label: const Text('Sesi dimaafkan'),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 1, label: '1 sesi'),
                  DropdownMenuEntry(value: 2, label: '2 sesi'),
                  DropdownMenuEntry(value: 3, label: '3 sesi'),
                ],
                onSelected: (v) => setS(() => sesi = v ?? sesi),
              ),
              const SizedBox(height: 8),
              StatusBadge(
                label: 'Proyeksi $proj% ${proj >= 75 ? '🟢 BERHAK' : '🔴 TETAP GUGUR'}',
                tone: proj >= 75 ? BadgeTone.success : BadgeTone.danger,
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
                    child: const Text('Sahkan'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || surat.text.trim().isEmpty) return;
    setState(() => s.dispensasi += sesi);
    _snack('Dispensasi ${s.npm} +$sesi sesi disahkan.');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final atRisk = _skrining
        .where(
          (s) =>
              !evaluateUas(
                total: s.total,
                hadir: s.hadir,
                dispensasi: s.dispensasi,
              ).eligible,
        )
        .length;

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
                  eyebrow: 'Admin / Presensi',
                  title: 'Monitoring Presensi',
                  subtitle:
                      'Minggu $mingguBerjalan/16 • $atRisk mhs terancam gugur UAS',
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _kelas.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Reveal(
                    delayMs: (i * 40).clamp(0, 240),
                    child: BezelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '[${_kelas[i].kode}] ${_kelas[i].mkNama}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              StatusBadge(
                                label: meetingTrack(
                                  _kelas[i].realisasi,
                                  mingguBerjalan,
                                ),
                                tone: isBehindSchedule(
                                  _kelas[i].realisasi,
                                  mingguBerjalan,
                                )
                                    ? BadgeTone.danger
                                    : BadgeTone.success,
                              ),
                            ],
                          ),
                          Text(
                            '${_kelas[i].dosen} • ${_kelas[i].realisasi}/16 sesi',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: _kelas[i].realisasi / 16,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Reveal(
                child: SectionHeader(
                  eyebrow: 'Skrining',
                  title: 'Terancam Gugur UAS (< 75%)',
                  subtitle: 'Dispensasi resmi memulihkan hak ujian',
                ),
              ),
              const SizedBox(height: 8),
              for (final s in _skrining)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Reveal(
                    child: Builder(
                      builder: (_) {
                        final el = evaluateUas(
                          total: s.total,
                          hadir: s.hadir,
                          dispensasi: s.dispensasi,
                        );
                        return BezelCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${s.npm} • ${s.nama}'),
                            subtitle: Text(
                              '${s.hadir}+${s.dispensasi} dispensasi / ${s.total} → ${el.percentage}%',
                              style: const TextStyle(
                                fontFeatures: [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                StatusBadge(
                                  label: el.eligible
                                      ? 'BERHAK'
                                      : 'GUGUR',
                                  tone: el.eligible
                                      ? BadgeTone.success
                                      : BadgeTone.danger,
                                ),
                                FilledButton.tonal(
                                  onPressed: () => _dispensasi(s),
                                  child: const Text('Dispensasi'),
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
