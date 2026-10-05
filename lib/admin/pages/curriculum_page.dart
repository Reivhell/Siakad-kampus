import 'package:flutter/material.dart';

import '../models/curriculum.dart';
import '../models/curriculum_seed.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/bezel_card.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Kurikulum & MK (spec 04): matriks smt 1–8 + prereq engine + validasi.
class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});

  @override
  State<CurriculumPage> createState() => _CurriculumPageState();
}

class _CurriculumPageState extends State<CurriculumPage> {
  final _search = TextEditingController();
  late List<MataKuliah> _mk;
  late List<Kurikulum> _kur;
  late List<KurikulumMk> _maps;
  late List<PrereqRule> _rules;
  String _edisi = 'k-2024';

  @override
  void initState() {
    super.initState();
    _mk = seedMk();
    _kur = seedKurikulum();
    _maps = seedMapping();
    _rules = List.of(seedPrereq());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Map<String, MataKuliah> get _byId => {for (final m in _mk) m.id: m};

  int _semesterTotal(int smt) =>
      semesterSksTotal(_edisi, smt, _maps, _byId);

  int get _grandTotal {
    var t = 0;
    for (var s = 1; s <= 8; s++) {
      t += _semesterTotal(s);
    }
    return t;
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

  Future<void> _mkForm({MataKuliah? edit}) async {
    final kode = TextEditingController(text: edit?.kode ?? '');
    final nama = TextEditingController(text: edit?.nama ?? '');
    final sks = TextEditingController(
      text: edit == null ? '' : edit.sks.toString(),
    );
    final teori = TextEditingController(
      text: edit == null ? '' : edit.sksTeori.toString(),
    );
    final prak = TextEditingController(
      text: edit == null ? '' : edit.sksPraktikum.toString(),
    );
    final usedInActiveClass = edit != null; // seed: lock kode+bobot
    final ok = await showAdminForm<bool>(
      context: context,
      title: edit == null ? 'Tambah Mata Kuliah' : 'Edit Mata Kuliah',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: kode,
            enabled: !usedInActiveClass,
            decoration: InputDecoration(
              labelText: 'Kode unik *',
              border: const OutlineInputBorder(),
              helperText: usedInActiveClass
                  ? 'Terkunci: dipakai kelas aktif.'
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nama,
            decoration: const InputDecoration(
              labelText: 'Nama *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: sks,
                  enabled: !usedInActiveClass,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'SKS *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: teori,
                  enabled: !usedInActiveClass,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Teori',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: prak,
                  enabled: !usedInActiveClass,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Praktikum',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
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
                child: const Text('Simpan'),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok != true) return;
    final draft = MataKuliah(
      id: edit?.id ?? 'mk-${DateTime.now().millisecondsSinceEpoch}',
      kode: kode.text.trim(),
      nama: nama.text.trim(),
      sks: int.tryParse(sks.text) ?? 0,
      sksTeori: int.tryParse(teori.text) ?? 0,
      sksPraktikum: int.tryParse(prak.text) ?? 0,
      semesterDefault: edit?.semesterDefault ?? 1,
    );
    final err = validateSksComposition(draft);
    if (draft.kode.isEmpty || draft.nama.isEmpty || err != null) {
      _snack(err ?? 'Kode + nama wajib.', error: true);
      return;
    }
    setState(() {
      if (edit == null) {
        _mk.add(draft);
        _maps.add(
          KurikulumMk(kurikulumId: _edisi, mkId: draft.id, semester: 1),
        );
      } else {
        edit.nama = draft.nama;
      }
    });
    _snack('MK disimpan. SKS = teori + praktikum ✓');
  }

  Future<void> _prereqDialog(MataKuliah mk) async {
    final existing = _rules.where((r) => r.mkId == mk.id).toList();
    final minSks = TextEditingController(
      text: existing
          .where((r) => r.minSks > 0)
          .map((r) => r.minSks.toString())
          .join(', '),
    );
    await showAdminForm<void>(
      context: context,
      title: 'Prasyarat — ${mk.kode}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hard prereq:', style: Theme.of(context).textTheme.titleSmall),
          for (final r in existing.where((r) => r.syaratMkId != null))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                '${_byId[r.syaratMkId]?.kode ?? '?'} • min ${r.minHuruf}',
              ),
              trailing: IconButton(
                tooltip: 'Hapus aturan',
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() => _rules.remove(r));
                  Navigator.pop(context);
                  _prereqDialog(mk);
                },
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: minSks,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Min SKS kumulatif (mis. Skripsi 120)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final cand in _mk.where((m) => m.id != mk.id))
                ActionChip(
                  label: Text(cand.kode),
                  onPressed: () {
                    final trial = [
                      ..._rules,
                      PrereqRule(
                        kurikulumId: _edisi,
                        mkId: mk.id,
                        syaratMkId: cand.id,
                      ),
                    ];
                    if (hasPrereqCycle(trial)) {
                      _snack('Ditolak: prasyarat melingkar terdeteksi.', error: true);
                      return;
                    }
                    setState(() => _rules = trial);
                    Navigator.pop(context);
                    _prereqDialog(mk);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: () {
                  final v = int.tryParse(minSks.text.trim()) ?? 0;
                  setState(() {
                    _rules.removeWhere(
                      (r) => r.mkId == mk.id && r.minSks > 0,
                    );
                    if (v > 0) {
                      _rules.add(
                        PrereqRule(
                          kurikulumId: _edisi,
                          mkId: mk.id,
                          tipe: 'CREDIT_THRESHOLD',
                          minSks: v,
                        ),
                      );
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text('Simpan Aturan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final q = _search.text.toLowerCase();
    final kur = _kur.firstWhere((k) => k.id == _edisi);
    final bank = _mk
        .where(
          (m) =>
              q.isEmpty ||
              m.nama.toLowerCase().contains(q) ||
              m.kode.toLowerCase().contains(q),
        )
        .toList();

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
                  eyebrow: 'Admin / Kurikulum',
                  title: 'Kurikulum & Mata Kuliah',
                  subtitle:
                      '${kur.nama} • total paket $_grandTotal SKS (target ${kur.totalSksLulus})',
                  action: FilledButton.icon(
                    onPressed: _mkForm,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah MK'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Reveal(
                child: BezelCard(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DropdownMenu<String>(
                        initialSelection: _edisi,
                        label: const Text('Edisi'),
                        dropdownMenuEntries: [
                          for (final k in _kur)
                            DropdownMenuEntry(
                              value: k.id,
                              label:
                                  '${k.nama}${k.aktif ? ' ● AKTIF' : ''}',
                            ),
                        ],
                        onSelected: (v) =>
                            setState(() => _edisi = v ?? _edisi),
                      ),
                      SizedBox(
                        width: 240,
                        child: SearchBar(
                          controller: _search,
                          hintText: 'Cari kode / nama MK…',
                          leading: const Icon(Icons.search),
                          elevation: const WidgetStatePropertyAll(0),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
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
                        'Matriks Semester 1–8',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var s = 1; s <= 8; s++)
                              Container(
                                width: 220,
                                margin: const EdgeInsets.only(right: 12),
                                child: _SemesterCol(
                                  semester: s,
                                  total: _semesterTotal(s),
                                  cards: [
                                    for (final m in _maps.where(
                                      (x) =>
                                          x.kurikulumId == _edisi &&
                                          x.semester == s,
                                    ))
                                      if (_byId[m.mkId] != null)
                                        _MkCard(
                                          mk: _byId[m.mkId]!,
                                          sifat: m.sifat,
                                          onTap: () => _prereqDialog(
                                            _byId[m.mkId]!,
                                          ),
                                          onEdit: () => _mkForm(
                                            edit: _byId[m.mkId],
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Reveal(
                child: SectionHeader(
                  eyebrow: 'Bank MK',
                  title: 'Katalog (${bank.length})',
                  subtitle: 'SKS = teori + praktikum • hapus diblokir bila tertaut kurikulum/kelas',
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < bank.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Reveal(
                    delayMs: (i * 30).clamp(0, 300),
                    child: BezelCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('[${bank[i].kode}] ${bank[i].nama}'),
                        subtitle: Text(
                          '${bank[i].sks} SKS (T${bank[i].sksTeori}+P${bank[i].sksPraktikum}) • ${bank[i].jenis}',
                          style: const TextStyle(
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Atur prasyarat',
                              icon: const Icon(
                                Icons.account_tree_outlined,
                              ),
                              onPressed: () => _prereqDialog(bank[i]),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _mkForm(edit: bank[i]),
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

class _SemesterCol extends StatelessWidget {
  final int semester;
  final int total;
  final List<Widget> cards;
  const _SemesterCol({
    required this.semester,
    required this.total,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    final capErr = validateSemesterCap(semester, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'SMT $semester',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(width: 8),
            StatusBadge(
              label: '$total SKS',
              tone: capErr != null ? BadgeTone.danger : BadgeTone.info,
            ),
          ],
        ),
        if (capErr != null)
          Text(
            capErr,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        const SizedBox(height: 8),
        if (cards.isEmpty)
          Text('— kosong —', style: Theme.of(context).textTheme.bodySmall),
        for (final c in cards) ...[c, const SizedBox(height: 8)],
      ],
    );
  }
}

class _MkCard extends StatelessWidget {
  final MataKuliah mk;
  final String sifat;
  final VoidCallback onTap, onEdit;
  const _MkCard({
    required this.mk,
    required this.sifat,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '[${mk.kode}]',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    sifat,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            Text(
              mk.nama,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              '${mk.sks} SKS',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Wrap(
              spacing: 0,
              children: [
                TextButton(
                  onPressed: onTap,
                  child: const Text('Prasyarat'),
                ),
                TextButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
