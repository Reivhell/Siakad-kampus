import 'package:flutter/material.dart';

import '../core/admin_api_scope.dart';
import '../models/civitas.dart';
import '../models/master_data.dart';
import '../rules/admin_rules.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/admin_page.dart';
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
  List<Mahasiswa> _mhs = const [];
  List<Dosen> _dsn = const [];
  List<Prodi> _prodi = const [];
  String _angkatan = 'SEMUA';
  String _status = 'SEMUA';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _prodiNama(String id) =>
      _prodi.where((p) => p.id == id).map((p) => p.nama).join().ifEmpty('—');

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    showAdminSnack(context, m, error: error);
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = AdminApiScope.clientOf(context);
      if (client == null) throw Exception('Sesi API tidak tersedia.');
      final master = await client.getJson('/api/v1/master');
      final prodi = <Prodi>[];
      if (master is Map && master['program_studi'] is List) {
        for (final r in (master['program_studi'] as List).whereType<Map>()) {
          prodi.add(Prodi(
            id: (r['id'] ?? '').toString(),
            kode: (r['kode'] ?? '').toString(),
            nama: (r['nama'] ?? '').toString(),
            jenjang: (r['jenjang'] ?? '').toString(),
          ));
        }
      }
      final mhsPage = await client.getJson('/api/v1/civitas/mahasiswa?limit=200');
      final dsnPage = await client.getJson('/api/v1/civitas/dosen?limit=200');
      List<T> items<T>(dynamic page, T Function(Map<String, dynamic>) f) {
        if (page is! Map || page['items'] is! List) return <T>[];
        return (page['items'] as List)
            .whereType<Map>()
            .map((e) => f(e.cast<String, dynamic>()))
            .toList();
      }
      final mhs = items(mhsPage, (r) => Mahasiswa(
            npm: (r['npm'] ?? '').toString(),
            nama: (r['nama_lengkap'] ?? r['nama'] ?? '').toString(),
            prodiId: (r['id_program_studi'] ?? '').toString(),
            angkatan: (r['tahun_masuk'] is num) ? (r['tahun_masuk'] as num).toInt() : 0,
            status: (r['status'] ?? 'AKTIF').toString(),
            sks: 0,
            ipk: 0,
            dosenWali: r['id_dosen_wali']?.toString(),
          ));
      final dsn = items(dsnPage, (r) => Dosen(
            nidn: (r['nidn'] ?? '').toString(),
            nama: (r['nama_lengkap'] ?? r['nama'] ?? '').toString(),
            prodiId: (r['id_program_studi'] ?? '').toString(),
            status: (r['status'] ?? 'AKTIF').toString(),
            bebanSks: 0,
          ));
      if (!mounted) return;
      setState(() {
        _prodi = prodi;
        _mhs = mhs;
        _dsn = dsn;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }


  Future<void> _registerForm() async {
    final res = await showAdminForm<_RegisterResult>(
      context: context,
      title: 'Registrasi Mahasiswa Baru',
      child: _RegisterForm(prodi: _prodi),
    );
    if (res == null) return;
    final client = AdminApiScope.clientOf(context);
    if (client == null) {
      _snack('Sesi API tidak tersedia.', error: true);
      return;
    }
    try {
      await client.postJson('/api/v1/civitas/mahasiswa', {
        'email': res.email,
        'nama_lengkap': res.nama,
        'id_program_studi': res.prodiId,
        'tahun_masuk': res.tahun,
        'jenis_kelamin': res.jenisKelamin,
      });
      if (!mounted) return;
      _snack('Mahasiswa terdaftar.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString(), error: true);
    }
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
    final tr = AdminRules.studentTransition(m.status, to);
    if (!tr.ok) {
      _snack(tr.message ?? 'Transisi ilegal.', error: true);
      return;
    }
    final client = AdminApiScope.clientOf(context);
    if (client == null) {
      _snack('Sesi API tidak tersedia.', error: true);
      return;
    }
    try {
      await client.patchJson('/api/v1/civitas/mahasiswa/${m.npm}', {'status': to});
      if (!mounted) return;
      _snack('${m.npm} → $to.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 8),
              FilledButton.tonal(onPressed: _load, child: const Text('Muat ulang')),
            ],
          ),
        ),
      );
    }
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
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                const TabBar(
                  tabs: [
                    Tab(text: 'Mahasiswa'),
                    Tab(text: 'Dosen'),
                  ],
                ),
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
                                        child: AdminListRow(
                                          title: Text(
                                            '${m.npm} • ${m.nama}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontFeatures: const [
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
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final d = _dsn[i];
                          final warn = AdminRules.bkd(d.bebanSks).asError;
                          return BezelCard(
                            child: AdminListRow(
                              title: Text('${d.nidn} • ${d.nama}'),
                              subtitle: Text(
                                '${_prodiNama(d.prodiId)} • ${d.bebanSks} SKS${warn != null ? ' • $warn' : ' • BKD ideal'}',
                              ),
                              trailing: StatusBadge(
                                label: warn == null ? d.status : 'BKD WARNING',
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
      ),
    );
  }
}

class _RegisterResult {
  final String prodiId;
  final int tahun;
  final String nama;
  final String email;
  final String jenisKelamin;
  const _RegisterResult({
    required this.prodiId,
    required this.tahun,
    required this.nama,
    required this.email,
    required this.jenisKelamin,
  });
}

class _RegisterForm extends StatefulWidget {
  final List<Prodi> prodi;
  const _RegisterForm({required this.prodi});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  late String _prodiId;
  int _tahun = DateTime.now().year;
  String _jk = 'L';
  final _nama = TextEditingController();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prodiId = widget.prodi.isNotEmpty ? widget.prodi.first.id : '';
  }

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = widget.prodi.isNotEmpty &&
        _nama.text.trim().isNotEmpty &&
        _email.text.trim().contains('@');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<String>(
          initialSelection: _prodiId,
          label: const Text('Program Studi'),
          dropdownMenuEntries: [
            for (final p in widget.prodi)
              DropdownMenuEntry(value: p.id, label: '${p.nama} (${p.kode})'),
          ],
          onSelected: (v) => setState(() => _prodiId = v ?? _prodiId),
        ),
        const SizedBox(height: 8),
        DropdownMenu<int>(
          initialSelection: _tahun,
          label: const Text('Angkatan'),
          dropdownMenuEntries: [
            for (final y in [DateTime.now().year, DateTime.now().year - 1, DateTime.now().year - 2, DateTime.now().year - 3])
              DropdownMenuEntry(value: y, label: '$y'),
          ],
          onSelected: (v) => setState(() => _tahun = v ?? _tahun),
        ),
        const SizedBox(height: 8),
        DropdownMenu<String>(
          initialSelection: _jk,
          label: const Text('Jenis kelamin'),
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: 'L', label: 'Laki-laki'),
            DropdownMenuEntry(value: 'P', label: 'Perempuan'),
          ],
          onSelected: (v) => setState(() => _jk = v ?? _jk),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nama,
          decoration: const InputDecoration(
            labelText: 'Nama lengkap *',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email *',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text(
          'NPM, akun login, dan audit dibuat oleh backend.',
          style: Theme.of(context).textTheme.bodySmall,
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
              onPressed: ok
                  ? () => Navigator.pop(
                      context,
                      _RegisterResult(
                        prodiId: _prodiId,
                        tahun: _tahun,
                        nama: _nama.text.trim(),
                        email: _email.text.trim().toLowerCase(),
                        jenisKelamin: _jk,
                      ),
                    )
                  : null,
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
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Portal KRS terkunci pada status ini.',
              style: Theme.of(context).textTheme.bodySmall,
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
