import 'package:flutter/material.dart';

import '../models/krs.dart';
import '../models/krs_seed.dart';
import '../models/scheduling.dart';
import '../models/scheduling_seed.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/bezel_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Administrasi KRS (spec 07): monitoring + plafon IPS + force-add/drop/switch.
class KrsPage extends StatefulWidget {
  const KrsPage({super.key});

  @override
  State<KrsPage> createState() => _KrsPageState();
}

class _KrsPageState extends State<KrsPage> {
  final _search = TextEditingController();
  late List<KrsEntry> _entries;
  late List<KelasKuliah> _kelas;
  String _status = 'SEMUA';

  @override
  void initState() {
    super.initState();
    _entries = seedKrs();
    _kelas = seedKelas();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _kelasKode(String id) => _kelas
      .where((k) => k.id == id)
      .map((k) => k.kode)
      .join()
      .ifEmpty('—');

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _forceAdd(KrsEntry e) async {
    final info = krsStudents[e.npm];
    if (info == null) return;
    final (nama, prodi, angkatan, ips, diambil) = info;
    final semester = 2026 - angkatan + 1;
    final plafon = calculateMaxSks(semester: semester, ips: ips);
    String targetId = _kelas.first.id;
    final surat = TextEditingController();
    final res = await showAdminForm<bool>(
      context: context,
      title: 'Force-Add ${e.npm}',
      child: StatefulBuilder(
        builder: (ctx, setS) {
          final target = _kelas.firstWhere((k) => k.id == targetId);
          final penuh = target.terdaftar >= target.kapasitas;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$nama ($prodi • $angkatan)'),
              Text(
                'IPS $ips → plafon $plafon SKS • diambil $diambil SKS',
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              DropdownMenu<String>(
                initialSelection: targetId,
                label: const Text('Kelas target (3 SKS)'),
                dropdownMenuEntries: [
                  for (final k in _kelas)
                    DropdownMenuEntry(
                      value: k.id,
                      label:
                          '[${k.kode}] ${k.terdaftar}/${k.kapasitas}${k.terdaftar >= k.kapasitas ? ' PENUH' : ''}',
                    ),
                ],
                onSelected: (v) => setS(() => targetId = v ?? targetId),
              ),
              const SizedBox(height: 8),
              StatusBadge(
                label: penuh ? '100% PENUH — override' : 'Kuota tersedia',
                tone: penuh ? BadgeTone.pending : BadgeTone.success,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: surat,
                decoration: const InputDecoration(
                  labelText: 'Nomor surat dispensasi *',
                  border: OutlineInputBorder(),
                ),
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
                    child: const Text('Eksekusi'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    if (res != true) return;
    if (surat.text.trim().isEmpty) {
      _snack('Surat dispensasi wajib.', error: true);
      return;
    }
    // Kapasitas fisik acuan spec 07 §3.3 (ruang LAB-KOMP-1 45 kursi).
    // Naik ke lookup ruangan nyata saat backend wiring.
    const acuanRuangFisik = 45;
    final mkByKelas = {for (final k in _kelas) k.id: k.mkId};
    final perByKelas = {for (final k in _kelas) k.id: 'per-2526-ganjil'};
    final err = forceAddGuard(
      npm: e.npm,
      targetKelasId: targetId,
      mkByKelas: mkByKelas,
      kelasPeriode: perByKelas,
      existing: _entries,
      kapasitasRuang: acuanRuangFisik,
    );
    if (err != null) {
      _snack(err, error: true);
      return;
    }
    setState(() {
      e.kelasId = targetId;
      e.status = 'AKTIF';
      e.paApproved = true;
      _kelas.firstWhere((k) => k.id == targetId).terdaftar++;
    });
    _snack('Force-add ${_kelasKode(targetId)} OK. Audit ADMIN_FORCE_ADD_KRS.');
  }

  void _bypass(KrsEntry e) {
    setState(() {
      e.status = 'AKTIF';
      e.paApproved = true;
    });
    _snack('${e.npm} disahkan langsung (mandat Kaprodi).');
  }

  void _drop(KrsEntry e) {
    setState(() => e.status = 'BATAL');
    _snack('${e.npm} dibatalkan → MENGUNDURKAN_DIRI tercatat.');
  }

  Future<void> _switch(KrsEntry e) async {
    final others = _kelas.where((k) => k.id != e.kelasId).toList();
    if (others.isEmpty) {
      _snack('Tidak ada kelas paralel tujuan.', error: true);
      return;
    }
    String to = others.first.id;
    final ok = await showAdminForm<bool>(
      context: context,
      title: 'Pindah Kelas',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownMenu<String>(
            initialSelection: to,
            label: const Text('Kelas tujuan'),
            dropdownMenuEntries: [
              for (final k in _kelas.where((k) => k.id != e.kelasId))
                DropdownMenuEntry(value: k.id, label: '[${k.kode}]'),
            ],
            onSelected: (v) => to = v ?? to,
          ),
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
                child: const Text('Pindah'),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok != true) return;
    final counters = {for (final k in _kelas) k.id: k.terdaftar};
    final r = switchClass(
      entryId: e.id,
      toKelasId: to,
      entries: _entries,
      counters: counters,
    );
    setState(() {
      _entries = r.entries;
      for (final k in _kelas) {
        k.terdaftar = r.counters[k.id] ?? k.terdaftar;
      }
    });
    _snack('Pindah atomik: counter −1/+1 sinkron.');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final q = _search.text.toLowerCase();
    final list = _entries.where((e) {
      if (q.isNotEmpty &&
          !e.npm.contains(q) &&
          !(krsStudents[e.npm]?.$1.toLowerCase().contains(q) ?? false)) {
        return false;
      }
      if (_status != 'SEMUA' && e.status != _status) return false;
      return true;
    }).toList();
    final approved = _entries.where((e) => e.status == 'AKTIF').length;

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
                  eyebrow: 'Admin / KRS',
                  title: 'Administrasi KRS',
                  subtitle:
                      'Portal DIBUKA • $approved/${_entries.length} tersahkan • plafon IPS aktif',
                ),
              ),
              const SizedBox(height: 16),
              Reveal(
                child: BezelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _entries.isEmpty
                              ? 0
                              : approved / _entries.length,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusBadge(
                            label: 'Gel.1 akhir ✓',
                            tone: BadgeTone.success,
                          ),
                          StatusBadge(
                            label: 'Gel.4 maba buka',
                            tone: BadgeTone.info,
                          ),
                          StatusBadge(
                            label: '3 force-add antre',
                            tone: BadgeTone.pending,
                          ),
                        ],
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
                    searchHint: 'Cari NPM / nama…',
                    onSearchChanged: (_) => setState(() {}),
                    filters: [
                      FilterOption(
                        label: 'Status',
                        value: _status,
                        options: const [
                          'SEMUA',
                          'DRAFT',
                          'MENUNGGU_APPROVAL',
                          'AKTIF',
                          'BATAL',
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
                      icon: Icons.fact_check_outlined,
                      title: 'Tidak ada entri cocok',
                      subtitle: 'Ubah kata kunci/status.',
                    ),
                  ),
                )
              else
                for (var i = 0; i < list.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Reveal(
                      delayMs: (i * 40).clamp(0, 240),
                      child: _KrsCard(
                        entry: list[i],
                        onForceAdd: () => _forceAdd(list[i]),
                        onBypass: () => _bypass(list[i]),
                        onSwitch: () => _switch(list[i]),
                        onDrop: () => _drop(list[i]),
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

class _KrsCard extends StatelessWidget {
  final KrsEntry entry;
  final VoidCallback onForceAdd, onBypass, onSwitch, onDrop;
  const _KrsCard({
    required this.entry,
    required this.onForceAdd,
    required this.onBypass,
    required this.onSwitch,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final info = krsStudents[entry.npm];
    final plafon = info == null
        ? 24
        : calculateMaxSks(semester: 2026 - info.$3 + 1, ips: info.$4);
    final over =
        info != null ? lockCheck(info.$5, plafon) != null : false;
    return BezelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${entry.npm} • ${info?.$1 ?? '—'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              StatusBadge(
                label: entry.status,
                tone: switch (entry.status) {
                  'AKTIF' => BadgeTone.success,
                  'MENUNGGU_APPROVAL' => BadgeTone.pending,
                  'BATAL' => BadgeTone.danger,
                  _ => BadgeTone.neutral,
                },
              ),
            ],
          ),
          if (info != null)
            Text(
              '${info.$2} • ${info.$3} • IPS ${info.$4} → plafon $plafon SKS • ambil ${info.$5} SKS${over ? ' • OVER!' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: over ? Theme.of(context).colorScheme.error : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: onForceAdd,
                child: const Text('Force-Add'),
              ),
              FilledButton.tonal(
                onPressed: onBypass,
                child: const Text('Bypass PA'),
              ),
              FilledButton.tonal(
                onPressed: onSwitch,
                child: const Text('Pindah'),
              ),
              FilledButton.tonal(
                onPressed: onDrop,
                child: const Text('Drop'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fb) => isEmpty ? fb : this;
}
