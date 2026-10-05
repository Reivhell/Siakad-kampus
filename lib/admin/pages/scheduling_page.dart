import 'package:flutter/material.dart';

import '../models/civitas.dart';
import '../models/civitas_seed.dart';
import '../models/curriculum.dart';
import '../models/curriculum_seed.dart';
import '../models/master_data.dart';
import '../models/master_seed.dart';
import '../models/scheduling.dart';
import '../models/scheduling_seed.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/bezel_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Kelas + Penjadwalan bebas bentrok (spec 06).
/// Timetable Hari × Jam + live conflict checker + paralel generator.
class SchedulingPage extends StatefulWidget {
  const SchedulingPage({super.key});

  @override
  State<SchedulingPage> createState() => _SchedulingPageState();
}

class _SchedulingPageState extends State<SchedulingPage> {
  late List<KelasKuliah> _kelas;
  late List<JadwalSlot> _jadwal;
  late List<Ruangan> _ruang;
  late List<Dosen> _dosen;
  late List<MataKuliah> _mk;
  int _hariFilter = 0; // 0 = semua

  @override
  void initState() {
    super.initState();
    _kelas = seedKelas();
    _jadwal = seedJadwal();
    _ruang = seedRuangan();
    _dosen = seedDosenCivitas();
    _mk = seedMk();
  }

  String _mkNama(String id) => _mk
      .where((m) => m.id == id)
      .map((m) => m.nama)
      .join()
      .ifEmpty('—');
  int _mkSks(String id) {
    for (final m in _mk) {
      if (m.id == id) return m.sks;
    }
    return 3;
  }
  String _ruangKode(String id) =>
      _ruang.where((r) => r.id == id).map((r) => r.kode).join().ifEmpty('—');
  String _dosenNama(String nidn) => _dosen
      .where((d) => d.nidn == nidn)
      .map((d) => d.nama)
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

  Future<void> _openKelasForm() async {
    final res = await showAdminForm<_KelasDraft>(
      context: context,
      title: 'Buka Kelas Paralel',
      child: _KelasForm(mk: _mk),
    );
    if (res == null) return;
    if (res.kapasitas <= 0) {
      _snack('Kapasitas harus > 0.', error: true);
      return;
    }
    final mk = _mk.firstWhere((x) => x.id == res.mkId);
    setState(() {
      for (var i = 0; i < res.paralel; i++) {
        final suffix = String.fromCharCode(65 + i);
        _kelas.add(
          KelasKuliah(
            id: 'kl-${DateTime.now().millisecondsSinceEpoch}-$suffix',
            mkId: res.mkId,
            kode: '${mk.kode}-$suffix',
            kapasitas: res.kapasitas,
            dosenIds: const [],
            leadDosenId: '',
          ),
        );
      }
    });
    _snack('${res.paralel} paralel ${mk.kode} dibuka, periode aktif terkunci.');
  }

  Future<void> _alokasiForm(KelasKuliah k) async {
    final available = _ruang.where((r) => r.tersedia).toList();
    if (available.isEmpty) {
      _snack('Semua ruangan renovasi — tidak ada target alokasi.', error: true);
      return;
    }
    int hari = 1;
    String ruangId = available.first.id;
    final mulaiC = TextEditingController(text: '08:00');
    final selesaiC = TextEditingController(text: '09:40');
    await showAdminForm<void>(
      context: context,
      title: 'Alokasi ${k.kode}',
      child: StatefulBuilder(
        builder: (ctx, setS) {
          final mulai = _parse(mulaiC.text) ?? 480;
          final selesai = _parse(selesaiC.text) ?? 580;
          final cand = JadwalSlot(
            id: 'draft',
            kelasId: k.id,
            ruangId: ruangId,
            hari: hari,
            mulai: mulai,
            selesai: selesai,
          );
          final ruang = _ruang.firstWhere((r) => r.id == ruangId);
          final roomHit = roomConflict(cand, _jadwal);
          final lecHit = lecturerConflict(
            cand,
            k.dosenIds,
            dosenByKelas(_kelas),
            _jadwal,
          );
          final capErr = capacityCheck(k.kapasitas, ruang.kapasitas);
          final durErr = durationCheck(_mkSks(k.mkId), mulai, selesai);
          final blackout = isBlackoutWarning(hari, mulai, selesai);
          final clear =
              roomHit == null && lecHit == null && capErr == null && durErr == null;
          String? hitKode(JadwalSlot s) => _kelas
              .where((x) => x.id == s.kelasId)
              .map((x) => x.kode)
              .join();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_mkNama(k.mkId)} • ${_mkSks(k.mkId)} SKS • ${k.terdaftar}/${k.kapasitas}',
              ),
              const SizedBox(height: 8),
              DropdownMenu<int>(
                initialSelection: hari,
                label: const Text('Hari'),
                dropdownMenuEntries: [
                  for (final e in dayNames.entries)
                    DropdownMenuEntry(value: e.key, label: e.value),
                ],
                onSelected: (v) => setS(() => hari = v ?? hari),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: mulaiC,
                      decoration: const InputDecoration(
                        labelText: 'Mulai HH:MM',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setS(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: selesaiC,
                      decoration: const InputDecoration(
                        labelText: 'Selesai HH:MM',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setS(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownMenu<String>(
                initialSelection: ruangId,
                label: const Text('Ruangan'),
                dropdownMenuEntries: [
                  for (final r in _ruang.where((r) => r.tersedia))
                    DropdownMenuEntry(
                      value: r.id,
                      label: '${r.kode} (${r.kapasitas})',
                    ),
                ],
                onSelected: (v) => setS(() => ruangId = v ?? ruangId),
              ),
              const SizedBox(height: 12),
              _Check(
                ok: roomHit == null,
                text: roomHit == null
                    ? '${ruang.kode} kosong ${dayNames[hari]} ${mulaiC.text}–${selesaiC.text}'
                    : 'Bentrok ruangan dengan ${hitKode(roomHit)}!',
              ),
              _Check(
                ok: lecHit == null,
                text: lecHit == null
                    ? 'Dosen bebas di slot ini'
                    : 'Dosen double-booking di ${hitKode(lecHit)}!',
              ),
              _Check(
                ok: capErr == null,
                text: capErr ?? 'Muatan ${k.kapasitas}/${ruang.kapasitas} aman',
              ),
              _Check(
                ok: durErr == null,
                text: durErr ?? 'Durasi memenuhi SKS',
              ),
              if (blackout)
                const _Check(
                  ok: true,
                  text: 'Peringatan: slot Jumat 11:30–13:00 (ibadah)',
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: clear
                        ? () {
                            setState(() {
                              _jadwal.add(
                                JadwalSlot(
                                  id: 'j-${DateTime.now().millisecondsSinceEpoch}',
                                  kelasId: k.id,
                                  ruangId: ruangId,
                                  hari: hari,
                                  mulai: mulai,
                                  selesai: selesai,
                                ),
                              );
                            });
                            Navigator.pop(ctx);
                            _snack('Jadwal ${k.kode} tersimpan.');
                          }
                        : null,
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  int? _parse(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h > 23 || m > 59) return null;
    return h * 60 + m;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final slots = _jadwal
        .where((j) => _hariFilter == 0 || j.hari == _hariFilter)
        .toList()
      ..sort((a, b) =>
          a.hari != b.hari
              ? a.hari.compareTo(b.hari)
              : a.mulai.compareTo(b.mulai));

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
                  eyebrow: 'Admin / Perkuliahan',
                  title: 'Kelas & Penjadwalan',
                  subtitle:
                      '${_kelas.length} kelas • ${_jadwal.length} slot • ${_kelas.where((k) => k.dosenIds.isEmpty).length} tanpa dosen',
                  action: FilledButton.icon(
                    onPressed: _openKelasForm,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Buka Kelas'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Reveal(
                child: BezelCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Hari:'),
                      for (final e in [
                        const MapEntry(0, 'Semua'),
                        ...dayNames.entries,
                      ])
                        ChoiceChip(
                          label: Text(e.value),
                          selected: _hariFilter == e.key,
                          onSelected: (_) =>
                              setState(() => _hariFilter = e.key),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (slots.isEmpty)
                const Reveal(
                  child: BezelCard(
                    child: EmptyState(
                      icon: Icons.calendar_month_outlined,
                      title: 'Belum ada slot hari ini',
                      subtitle: 'Klik kelas di bawah untuk menjadwalkan.',
                    ),
                  ),
                )
              else
                for (var i = 0; i < slots.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Reveal(
                      delayMs: (i * 30).clamp(0, 240),
                      child: _SlotCard(
                        slot: slots[i],
                        kelas: _kelas.firstWhere(
                          (k) => k.id == slots[i].kelasId,
                        ),
                        mkNama: _mkNama(
                          _kelas
                              .firstWhere((k) => k.id == slots[i].kelasId)
                              .mkId,
                        ),
                        ruangKode: _ruangKode(slots[i].ruangId),
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              Reveal(
                child: SectionHeader(
                  eyebrow: 'Rombel',
                  title: 'Daftar Kelas',
                  subtitle: 'Ketuk jadwal untuk alokasi slot + cek bentrok live',
                ),
              ),
              const SizedBox(height: 8),
              for (final k in _kelas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Reveal(
                    child: BezelCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('[${k.kode}] ${_mkNama(k.mkId)}'),
                        subtitle: Text(
                          k.dosenIds.isEmpty
                              ? '${k.terdaftar}/${k.kapasitas} • BELUM ADA DOSEN'
                              : '${k.terdaftar}/${k.kapasitas} • ${_dosenNama(k.leadDosenId)}${k.terdaftar >= k.kapasitas ? ' • PENUH' : ''}',
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            if (k.dosenIds.isEmpty)
                              const StatusBadge(
                                label: 'NO DOSEN',
                                tone: BadgeTone.danger,
                              )
                            else if (k.terdaftar >= k.kapasitas)
                              const StatusBadge(
                                label: 'PENUH',
                                tone: BadgeTone.pending,
                              ),
                            FilledButton.tonal(
                              onPressed: () => _alokasiForm(k),
                              child: const Text('Jadwal'),
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

class _KelasDraft {
  final String mkId;
  final int paralel;
  final int kapasitas;
  const _KelasDraft(this.mkId, this.paralel, this.kapasitas);
}

class _KelasForm extends StatefulWidget {
  final List<MataKuliah> mk;
  const _KelasForm({required this.mk});

  @override
  State<_KelasForm> createState() => _KelasFormState();
}

class _KelasFormState extends State<_KelasForm> {
  late String _mkId;
  int _paralel = 2;
  final _kap = TextEditingController(text: '40');

  @override
  void initState() {
    super.initState();
    _mkId = widget.mk.first.id;
  }

  @override
  void dispose() {
    _kap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownMenu<String>(
          initialSelection: _mkId,
          label: const Text('Mata Kuliah'),
          dropdownMenuEntries: [
            for (final m in widget.mk)
              DropdownMenuEntry(
                value: m.id,
                label: '[${m.kode}] ${m.nama}',
              ),
          ],
          onSelected: (v) => setState(() => _mkId = v ?? _mkId),
        ),
        const SizedBox(height: 8),
        DropdownMenu<int>(
          initialSelection: _paralel,
          label: const Text('Jumlah paralel'),
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: 1, label: '1 (A)'),
            DropdownMenuEntry(value: 2, label: '2 (A–B)'),
            DropdownMenuEntry(value: 3, label: '3 (A–C)'),
          ],
          onSelected: (v) => setState(() => _paralel = v ?? _paralel),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _kap,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Kapasitas per kelas',
            border: OutlineInputBorder(),
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
              onPressed: () => Navigator.pop(
                context,
                _KelasDraft(
                  _mkId,
                  _paralel,
                  int.tryParse(_kap.text) ?? 0,
                ),
              ),
              child: const Text('Buka'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Check extends StatelessWidget {
  final bool ok;
  final String text;
  const _Check({required this.ok, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.error,
            size: 16,
            color: ok
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final JadwalSlot slot;
  final KelasKuliah kelas;
  final String mkNama, ruangKode;
  const _SlotCard({
    required this.slot,
    required this.kelas,
    required this.mkNama,
    required this.ruangKode,
  });

  @override
  Widget build(BuildContext context) {
    return BezelCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  dayNames[slot.hari]!.substring(0, 3),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  fmtTime(slot.mulai),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[${kelas.kode}] $mkNama',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '$ruangKode • ${fmtTime(slot.mulai)}–${fmtTime(slot.selesai)} • ${kelas.terdaftar}/${kelas.kapasitas}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fb) => isEmpty ? fb : this;
}
