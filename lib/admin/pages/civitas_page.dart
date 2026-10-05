import 'package:flutter/material.dart';

import '../models/civitas.dart';
import '../models/civitas_seed.dart';
import '../models/master_data.dart';
import '../models/master_seed.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/bezel_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Civitas: Mahasiswa (NPM generator + mutasi status) & Dosen (NIDN + BKD).
class CivitasPage extends StatefulWidget {
  const CivitasPage({super.key});

  @override
  State<CivitasPage> createState() => _CivitasPageState();
}

class _CivitasPageState extends State<CivitasPage> {
  final _search = TextEditingController();
  late List<Mahasiswa> _mhs;
  late List<Dosen> _dsn;
  late List<Prodi> _prodi;
  String _angkatan = 'SEMUA';
  String _status = 'SEMUA';

  @override
  void initState() {
    super.initState();
    _mhs = seedMahasiswa();
    _dsn = seedDosenCivitas();
    _prodi = seedProdi();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _prodiNama(String id) => _prodi
      .where((p) => p.id == id)
      .map((p) => p.nama)
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

  Future<void> _registerForm() async {
    final res = await showAdminForm<_RegisterResult>(
      context: context,
      title: 'Registrasi Mahasiswa Baru',
      child: _RegisterForm(
        prodi: _prodi,
        existingNpms: _mhs.map((m) => m.npm).toList(),
      ),
    );
    if (res == null) return;
    if (res.nama.isEmpty) {
      _snack('Nama wajib.', error: true);
      return;
    }
    setState(() {
      _mhs.add(
        Mahasiswa(
          npm: res.npm,
          nama: res.nama,
          prodiId: res.prodiId,
          angkatan: res.tahun,
        ),
      );
    });
    _snack('Mahasiswa ${res.npm} terdaftar + akun dibuat.');
  }

  Future<void> _mutateStatus(Mahasiswa m) async {
    final targets = statusTransitions[m.status] ?? const [];
    if (targets.isEmpty) {
      _snack('${m.status} terminal — tidak ada transisi.', error: true);
      return;
    }
    final to = await showAdminForm<String>(
      context: context,
      title: 'Mutasi ${m.npm}',
      child: _MutateForm(current: m.status, targets: targets),
    );
    if (to == null) return;
    if (!canTransition(m.status, to)) {
      _snack('Transisi ilegal.', error: true);
      return;
    }
    setState(() => m.status = to);
    _snack('${m.npm} → $to. Audit tercatat.');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final q = _search.text.toLowerCase();
    final list = _mhs.where((m) {
      if (q.isNotEmpty &&
          !m.nama.toLowerCase().contains(q) &&
          !m.npm.contains(q)) {
        return false;
      }
      if (_angkatan != 'SEMUA' && m.angkatan.toString() != _angkatan) {
        return false;
      }
      if (_status != 'SEMUA' && m.status != _status) return false;
      return true;
    }).toList();

    return DefaultTabController(
      length: 2,
      child: SingleChildScrollView(
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
                    eyebrow: 'Admin / Civitas',
                    title: 'Civitas Akademika',
                    subtitle:
                        '${_mhs.length} mhs • ${_dsn.length} dosen • NPM AA+FFF+PP+UUU',
                    action: FilledButton.icon(
                      onPressed: _registerForm,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Mahasiswa'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const TabBar(tabs: [Tab(text: 'Mahasiswa'), Tab(text: 'Dosen')]),
                const SizedBox(height: 16),
                SizedBox(
                  height: 620,
                  child: TabBarView(
                    children: [
                      Column(
                        children: [
                          BezelCard(
                            child: FilterBar(
                              searchController: _search,
                              searchHint: 'Cari NPM / nama…',
                              onSearchChanged: (_) => setState(() {}),
                              filters: [
                                FilterOption(
                                  label: 'Angkatan',
                                  value: _angkatan,
                                  options: const [
                                    'SEMUA',
                                    '2026',
                                    '2025',
                                    '2024',
                                    '2023',
                                    '2022',
                                  ],
                                  onSelected: (v) =>
                                      setState(() => _angkatan = v),
                                ),
                                FilterOption(
                                  label: 'Status',
                                  value: _status,
                                  options: const [
                                    'SEMUA',
                                    'AKTIF',
                                    'CUTI',
                                    'LULUS',
                                    'DO',
                                    'NON_AKTIF',
                                  ],
                                  onSelected: (v) =>
                                      setState(() => _status = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: list.isEmpty
                                ? const BezelCard(
                                    child: EmptyState(
                                      icon: Icons.school_outlined,
                                      title: 'Tidak ada mahasiswa cocok',
                                      subtitle: 'Ubah kata kunci/filter.',
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: list.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (_, i) {
                                      final m = list[i];
                                      return BezelCard(
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            '${m.npm} • ${m.nama}',
                                            style: const TextStyle(
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${_prodiNama(m.prodiId)} • ${m.angkatan} • ${m.sks} SKS • IPK ${m.ipk}',
                                          ),
                                          trailing: Wrap(
                                            spacing: 4,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              _MhsBadge(status: m.status),
                                              TextButton(
                                                onPressed: () =>
                                                    _mutateStatus(m),
                                                child: const Text('Mutasi'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                      ListView.separated(
                        itemCount: _dsn.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final d = _dsn[i];
                          final warn = bkdWarning(d.bebanSks);
                          return BezelCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('${d.nidn} • ${d.nama}'),
                              subtitle: Text(
                                '${_prodiNama(d.prodiId)} • ${d.bebanSks} SKS${warn != null ? ' • $warn' : ' • BKD ideal'}',
                              ),
                              trailing: StatusBadge(
                                label: warn == null
                                    ? d.status
                                    : 'BKD WARNING',
                                tone: warn == null
                                    ? BadgeTone.success
                                    : BadgeTone.pending,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterResult {
  final String prodiId;
  final int tahun;
  final String nama;
  final String npm;
  const _RegisterResult(this.prodiId, this.tahun, this.nama, this.npm);
}

class _RegisterForm extends StatefulWidget {
  final List<Prodi> prodi;
  final List<String> existingNpms;
  const _RegisterForm({required this.prodi, required this.existingNpms});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  late String _prodiId;
  int _tahun = 2026;
  final _nama = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prodiId = widget.prodi.first.id;
  }

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  String? get _preview {
    try {
      final prodi = widget.prodi.firstWhere((p) => p.id == _prodiId);
      final prefix =
          '${(_tahun % 100).toString().padLeft(2, '0')}$facultyCodeTI${prodi.kode}';
      return generateNpm(
        year: _tahun,
        facultyCode: facultyCodeTI,
        prodiCode: prodi.kode,
        nextSequence: nextSequenceFor(prefix, widget.existingNpms),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<String>(
          initialSelection: _prodiId,
          label: const Text('Program Studi'),
          dropdownMenuEntries: [
            for (final p in widget.prodi)
              DropdownMenuEntry(
                value: p.id,
                label: '${p.nama} (${p.kode})',
              ),
          ],
          onSelected: (v) => setState(() => _prodiId = v ?? _prodiId),
        ),
        const SizedBox(height: 8),
        DropdownMenu<int>(
          initialSelection: _tahun,
          label: const Text('Angkatan'),
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: 2026, label: '2026'),
            DropdownMenuEntry(value: 2025, label: '2025'),
            DropdownMenuEntry(value: 2024, label: '2024'),
          ],
          onSelected: (v) => setState(() => _tahun = v ?? _tahun),
        ),
        const SizedBox(height: 12),
        BezelCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  preview ?? 'Kuota urut penuh (999)',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const StatusBadge(label: 'NPM AUTO', tone: BadgeTone.info),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nama,
          decoration: const InputDecoration(
            labelText: 'Nama lengkap *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Akun login dibuat otomatis. Password awal: NPM#TglLahir.',
          style: TextStyle(fontSize: 12),
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
              onPressed: preview == null
                  ? null
                  : () => Navigator.pop(
                      context,
                      _RegisterResult(
                        _prodiId,
                        _tahun,
                        _nama.text.trim(),
                        preview,
                      ),
                    ),
              child: const Text('Daftarkan'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MutateForm extends StatefulWidget {
  final String current;
  final List<String> targets;
  const _MutateForm({required this.current, required this.targets});

  @override
  State<_MutateForm> createState() => _MutateFormState();
}

class _MutateFormState extends State<_MutateForm> {
  late String _to;

  @override
  void initState() {
    super.initState();
    _to = widget.targets.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Status kini: ${widget.current}'),
        const SizedBox(height: 8),
        DropdownMenu<String>(
          initialSelection: _to,
          label: const Text('Status baru'),
          dropdownMenuEntries: [
            for (final t in widget.targets)
              DropdownMenuEntry(value: t, label: t),
          ],
          onSelected: (v) => setState(() => _to = v ?? _to),
        ),
        if (!krsUnlocked(_to))
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Portal KRS terkunci pada status ini.',
              style: TextStyle(fontSize: 12),
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
              onPressed: () => Navigator.pop(context, _to),
              child: const Text('Mutasi'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MhsBadge extends StatelessWidget {
  final String status;
  const _MhsBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      'AKTIF' => const StatusBadge(label: 'AKTIF', tone: BadgeTone.success),
      'CUTI' => const StatusBadge(label: 'CUTI', tone: BadgeTone.pending),
      'LULUS' => const StatusBadge(label: 'LULUS', tone: BadgeTone.info),
      'DO' => const StatusBadge(label: 'DO', tone: BadgeTone.danger),
      _ => StatusBadge(label: status, tone: BadgeTone.neutral),
    };
  }
}

extension on String {
  String ifEmpty(String fb) => isEmpty ? fb : this;
}
