import 'package:flutter/material.dart';

import '../models/master_data.dart';
import '../models/master_seed.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/bezel_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Master Data: Prodi | Periode | Ruangan (spec 03).
/// Periode: single-active invariant + wizard konfirmasi ketik.
class MasterPage extends StatefulWidget {
  const MasterPage({super.key});

  @override
  State<MasterPage> createState() => _MasterPageState();
}

class _MasterPageState extends State<MasterPage> {
  late List<Prodi> _prodi;
  late List<Periode> _periode;
  late List<Ruangan> _ruang;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prodi = seedProdi();
    _periode = seedPeriode();
    _ruang = seedRuangan();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Periode? get _aktif {
    for (final p in _periode) {
      if (p.aktif) return p;
    }
    return null;
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

  Future<void> _switchPeriode(Periode target) async {
    if (target.aktif) return;
    final old = _aktif?.nama ?? '—';
    final confirm = TextEditingController();
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Wizard Pergantian Periode'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Aktifkan: ${target.nama}'),
              Text(
                'Pre-flight: nilai 98,4% final ✓ • 12 mhs administrasi gantung [!]',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Dampak: "$old" jadi arsip • portal KRS semester baru terbuka • jadwal baru merujuk periode ini.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              const Text('Ketik "AKTIFKAN SEMESTER BARU":'),
              const SizedBox(height: 8),
              TextField(
                controller: confirm,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'AKTIFKAN SEMESTER BARU',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batalkan'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              confirm.text.trim() == 'AKTIFKAN SEMESTER BARU',
            ),
            child: const Text('Eksekusi'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() {
      _periode = switchActivePeriod(_periode, target.id);
    });
    _snack('Periode aktif: ${target.nama}. "$old" diarsipkan atomik.');
  }

  Future<void> _prodiForm({Prodi? edit}) async {
    final kode = TextEditingController(text: edit?.kode ?? '');
    final nama = TextEditingController(text: edit?.nama ?? '');
    String jenjang = edit?.jenjang ?? 'S1';
    final locked = edit != null && prodiKodeLocked(edit);
    final lockedCount = edit?.studentCount ?? 0;
    final ok = await showAdminForm<bool>(
      context: context,
      title: edit == null ? 'Tambah Prodi' : 'Edit Prodi',
      child: StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: kode,
              enabled: !locked,
              maxLength: 2,
              decoration: InputDecoration(
                labelText: 'Kode 2 digit *',
                border: const OutlineInputBorder(),
                helperText: locked
                    ? 'Terkunci: sudah ada $lockedCount mahasiswa.'
                    : 'Dipakai digit NPM ke 6–7.',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nama,
              decoration: const InputDecoration(
                labelText: 'Nama prodi *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownMenu<String>(
              initialSelection: jenjang,
              label: const Text('Jenjang'),
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'D3', label: 'D3'),
                DropdownMenuEntry(value: 'S1', label: 'S1'),
                DropdownMenuEntry(value: 'S2', label: 'S2'),
                DropdownMenuEntry(value: 'S3', label: 'S3'),
              ],
              onSelected: (v) => setS(() => jenjang = v ?? jenjang),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (nama.text.trim().isEmpty || kode.text.trim().isEmpty) {
      _snack('Kode + nama wajib.', error: true);
      return;
    }
    if (_prodi.any(
      (p) =>
          p.kode == kode.text.trim() && p.id != edit?.id ||
          p.nama.toLowerCase() == nama.text.trim().toLowerCase() &&
              p.id != edit?.id,
    )) {
      _snack('Kode/nama prodi duplikat.', error: true);
      return;
    }
    setState(() {
      if (edit == null) {
        _prodi.add(
          Prodi(
            id: 'p-${DateTime.now().millisecondsSinceEpoch}',
            kode: kode.text.trim(),
            nama: nama.text.trim(),
            jenjang: jenjang,
          ),
        );
      } else {
        if (!locked) edit.kode = kode.text.trim();
        edit
          ..nama = nama.text.trim()
          ..jenjang = jenjang;
      }
    });
    _snack('Prodi disimpan.');
  }

  Future<void> _ruangForm({Ruangan? edit}) async {
    final kode = TextEditingController(text: edit?.kode ?? '');
    final nama = TextEditingController(text: edit?.nama ?? '');
    final kap = TextEditingController(
      text: edit == null ? '' : edit.kapasitas.toString(),
    );
    final gedung = TextEditingController(text: edit?.gedung ?? '');
    bool tersedia = edit?.tersedia ?? true;
    final ok = await showAdminForm<bool>(
      context: context,
      title: edit == null ? 'Tambah Ruangan' : 'Edit Ruangan',
      child: StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: kode,
              decoration: const InputDecoration(
                labelText: 'Kode unik *',
                border: OutlineInputBorder(),
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
            TextField(
              controller: kap,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kapasitas kursi *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: gedung,
              decoration: const InputDecoration(
                labelText: 'Gedung *',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tersedia dijadwalkan'),
              value: tersedia,
              onChanged: (v) => setS(() => tersedia = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final k = int.tryParse(kap.text.trim()) ?? 0;
    if (kode.text.trim().isEmpty || nama.text.trim().isEmpty || k <= 0) {
      _snack('Kode, nama valid + kapasitas > 0 wajib.', error: true);
      return;
    }
    setState(() {
      if (edit == null) {
        _ruang.add(
          Ruangan(
            id: 'r-${DateTime.now().millisecondsSinceEpoch}',
            kode: kode.text.trim(),
            nama: nama.text.trim(),
            kapasitas: k,
            gedung: gedung.text.trim().isEmpty
                ? 'Gedung Utama'
                : gedung.text.trim(),
            tersedia: tersedia,
          ),
        );
      } else {
        edit
          ..kode = kode.text.trim()
          ..nama = nama.text.trim()
          ..kapasitas = k
          ..gedung = gedung.text.trim()
          ..tersedia = tersedia;
      }
    });
    _snack('Ruangan disimpan.');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return DefaultTabController(
      length: 3,
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
                    eyebrow: 'Admin / Master',
                    title: 'Master Data Akademik',
                    subtitle:
                        'Periode aktif: ${_aktif?.nama ?? 'BELUM ADA — pilih periode!'}',
                  ),
                ),
                const SizedBox(height: 12),
                const TabBar(
                  tabs: [
                    Tab(text: 'Prodi'),
                    Tab(text: 'Periode'),
                    Tab(text: 'Ruangan'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 640,
                  child: TabBarView(
                    children: [
                      _prodiTab(width),
                      _periodeTab(width),
                      _ruangTab(width),
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

  Widget _prodiTab(double width) {
    final q = _search.text.toLowerCase();
    final list = _prodi
        .where(
          (p) =>
              q.isEmpty ||
              p.nama.toLowerCase().contains(q) ||
              p.kode.contains(q),
        )
        .toList();
    return Column(
      children: [
        BezelCard(
          child: FilterBar(
            searchController: _search,
            searchHint: 'Cari prodi / kode…',
            onSearchChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _prodiForm,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tambah Prodi'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: list.isEmpty
              ? const BezelCard(
                  child: EmptyState(
                    icon: Icons.storage_outlined,
                    title: 'Prodi tidak ditemukan',
                    subtitle: 'Ubah kata kunci pencarian.',
                  ),
                )
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    return BezelCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${p.nama} (${p.jenjang})'),
                        subtitle: Text(
                          'Kode ${p.kode} • ${p.studentCount} mhs${prodiKodeLocked(p) ? ' • kode terkunci' : ''}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _prodiForm(edit: p),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _periodeTab(double width) {
    return Column(
      children: [
        BezelCard(
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aktivasi periode baru otomatis mengarsipkan periode berjalan (partial unique index).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _periode.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final p = _periode[i];
              return BezelCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.nama),
                  subtitle: Text(
                    '${p.tahun} • ${p.semester} • ${_fmt(p.mulai)} – ${_fmt(p.selesai)}',
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusBadge(
                        label: p.aktif ? 'AKTIF' : 'ARSIP',
                        tone: p.aktif
                            ? BadgeTone.success
                            : BadgeTone.neutral,
                      ),
                      if (!p.aktif)
                        FilledButton.tonal(
                          onPressed: () => _switchPeriode(p),
                          child: const Text('Aktifkan'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _ruangTab(double width) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _ruangForm(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tambah Ruangan'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: width >= 1024 ? 3 : (width >= 600 ? 2 : 1),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 190,
            ),
            itemCount: _ruang.length,
            itemBuilder: (_, i) {
              final r = _ruang[i];
              return BezelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusBadge(
                          label: r.tersedia ? 'TERSEDIA' : 'RENOVASI',
                          tone: r.tersedia
                              ? BadgeTone.success
                              : BadgeTone.pending,
                        ),
                      ],
                    ),
                    Text(
                      '${r.kode} • ${r.gedung}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Kapasitas ${r.kapasitas} kursi • ${r.tipe}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => _ruangForm(edit: r),
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
