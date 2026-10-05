import 'package:flutter/material.dart';

import '../models/dashboard_seed.dart';
import '../widgets/bezel_card.dart';
import '../widgets/feedback.dart';
import '../widgets/kpi_card.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Dashboard Admin — cockpit eksekutif (fitur_admin/01).
/// Desktop ≥1024: bento multi-kolom. Tablet 2 kolom. Mobile <600:
/// 1 kolom + KPI carousel horizontal.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _periode = DashboardSeed.periode;
  String _prodi = 'Semua Prodi';
  bool _presentation = false;
  bool _autoRefresh = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final isTablet = width >= 600 && width < 1024;

    return Scaffold(
      floatingActionButton: _QuickDock(isDesktop: isDesktop),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 600));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dashboard disinkronkan dengan Supabase'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerControls(context, isDesktop),
                  const SizedBox(height: 24),
                  _kpiSection(isDesktop, isTablet),
                  const SizedBox(height: 32),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(flex: 8, child: _TimelineCard()),
                        SizedBox(width: 16),
                        Expanded(flex: 4, child: _QuickActions()),
                      ],
                    )
                  else ...[
                    const Reveal(child: _TimelineCard()),
                    const SizedBox(height: 16),
                    const Reveal(child: _QuickActions()),
                  ],
                  const SizedBox(height: 32),
                  const Reveal(
                    child: SectionHeader(
                      eyebrow: 'Early warning',
                      title: 'Pusat Peringatan Dini',
                      subtitle:
                          'Anomali kuota, nilai, presensi & ruangan — kirim reminder sekali ketuk.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _warningGrid(isDesktop, isTablet),
                  const SizedBox(height: 32),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(flex: 6, child: _TaskQueue()),
                        SizedBox(width: 16),
                        Expanded(flex: 6, child: _RoomLive()),
                      ],
                    )
                  else ...[
                    const Reveal(child: _TaskQueue()),
                    const SizedBox(height: 16),
                    const Reveal(child: _RoomLive()),
                  ],
                  const SizedBox(height: 32),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(flex: 6, child: _Analytics()),
                        SizedBox(width: 16),
                        Expanded(flex: 6, child: _LiveLog()),
                      ],
                    )
                  else ...[
                    const Reveal(child: _Analytics()),
                    const SizedBox(height: 16),
                    const Reveal(child: _LiveLog()),
                  ],
                  const SizedBox(height: 32),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(flex: 6, child: _Broadcast()),
                        SizedBox(width: 16),
                        Expanded(flex: 6, child: _SystemHealth()),
                      ],
                    )
                  else ...[
                    const Reveal(child: _Broadcast()),
                    const SizedBox(height: 16),
                    const Reveal(child: _SystemHealth()),
                  ],
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerControls(BuildContext context, bool isDesktop) {
    return Reveal(
      child: BezelCard(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownMenu<String>(
              initialSelection: _periode,
              label: const Text('Periode'),
              dropdownMenuEntries: const [
                DropdownMenuEntry(
                  value: 'Ganjil 2025/2026',
                  label: 'Ganjil 2025/2026',
                ),
                DropdownMenuEntry(
                  value: 'Genap 2024/2025',
                  label: 'Genap 2024/2025',
                ),
                DropdownMenuEntry(
                  value: 'Ganjil 2024/2025',
                  label: 'Ganjil 2024/2025',
                ),
              ],
              onSelected: (v) => setState(() => _periode = v ?? _periode),
            ),
            DropdownMenu<String>(
              initialSelection: _prodi,
              label: const Text('Prodi'),
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'Semua Prodi', label: 'Semua Prodi'),
                DropdownMenuEntry(
                  value: 'Teknik Informatika',
                  label: 'Teknik Informatika',
                ),
                DropdownMenuEntry(
                  value: 'Sistem Informasi',
                  label: 'Sistem Informasi',
                ),
              ],
              onSelected: (v) => setState(() => _prodi = v ?? _prodi),
            ),
            FilterChip(
              label: Text(
                _presentation ? 'Presentasi: ON' : 'Presentasi: OFF',
              ),
              selected: _presentation,
              onSelected: (v) => setState(() => _presentation = v),
            ),
            FilterChip(
              label: Text(_autoRefresh ? 'Auto 5 mnt' : 'Manual'),
              selected: _autoRefresh,
              onSelected: (v) => setState(() => _autoRefresh = v),
            ),
            FilledButton.icon(
              onPressed: () => soon(context, 'Ekspor snapshot PDF'),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Ekspor Snapshot'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiSection(bool isDesktop, bool isTablet) {
    final cards = [
      for (var i = 0; i < DashboardSeed.kpis.length; i++)
        Reveal(
          delayMs: i * 80,
          child: KpiCard(
            icon: DashboardSeed.kpis[i].icon,
            label: DashboardSeed.kpis[i].label,
            value: _presentation && i == 1 ? '1.4xx' : DashboardSeed.kpis[i].value,
            sub: DashboardSeed.kpis[i].sub,
            starGold: DashboardSeed.kpis[i].starGold,
          ),
        ),
    ];
    if (!isDesktop && !isTablet) {
      // Mobile: carousel horizontal swipe (spec 01 §4)
      return SizedBox(
        height: 228,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(width: 260, child: cards[i]),
        ),
      );
    }
    final cols = isDesktop ? 3 : 2;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: isDesktop ? 250 : 230,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      itemBuilder: (_, i) => cards[i],
    );
  }

  Widget _warningGrid(bool isDesktop, bool isTablet) {
    final cols = isDesktop ? 3 : (isTablet ? 2 : 1);
    final tiles = [
      for (var i = 0; i < DashboardSeed.warnings.length; i++)
        Reveal(
          delayMs: i * 70,
          child: BezelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge(
                  label: DashboardSeed.warnings[i].tone.name,
                  tone: DashboardSeed.warnings[i].tone,
                ),
                const SizedBox(height: 8),
                Text(
                  DashboardSeed.warnings[i].title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  DashboardSeed.warnings[i].sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () =>
                        soon(context, DashboardSeed.warnings[i].action),
                    child: Text(DashboardSeed.warnings[i].action),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
    if (cols == 1) {
      return Column(
        children: [
          for (final t in tiles) ...[t, const SizedBox(height: 12)],
        ],
      );
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: isDesktop ? 235 : 225,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      itemBuilder: (_, i) => tiles[i],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard();

  @override
  Widget build(BuildContext context) {
    const phases = [
      ('KRS', true),
      ('KPRS', true),
      ('UTS', null),
      ('Nilai UTS', false),
      ('UAS', false),
      ('Final', false),
      ('Yudisium', false),
    ];
    return Reveal(
      child: BezelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Timeline Semester',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const StatusBadge(
                  label: 'Minggu 8/16',
                  tone: BadgeTone.info,
                  icon: Icons.schedule_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(
                value: 0.5,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, done) in phases)
                  Chip(
                    avatar: Icon(
                      done == null
                          ? Icons.play_circle_outline
                          : done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                    ),
                    label: Text(label),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'UTS sedang berjalan • Batas input nilai UTS 14 Okt 2026 • UAS 6 minggu lagi',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.person_add_outlined, '+ Mahasiswa'),
      (Icons.meeting_room_outlined, '+ Buka Kelas'),
      (Icons.co_present_outlined, '+ Dosen'),
      (Icons.campaign_outlined, 'Broadcast'),
      (Icons.warning_amber_outlined, 'Konflik Jadwal'),
    ];
    return Reveal(
      child: BezelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pintasan Aksi Cepat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (icon, label) in actions)
                  ActionChip(
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    onPressed: () => soon(context, label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskQueue extends StatefulWidget {
  const _TaskQueue();

  @override
  State<_TaskQueue> createState() => _TaskQueueState();
}

class _TaskQueueState extends State<_TaskQueue> {
  // Elemen bertipe seed privat (inferred) — cukup butuh .title/.sub.
  late List _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(DashboardSeed.queue);
  }

  void _decide(int i, bool approve) {
    final t = _items[i];
    setState(() => _items.removeAt(i));
    ok(
      context,
      approve
          ? 'Disetujui: ${t.title}. Audit tercatat.'
          : 'Ditolak: ${t.title}. Pemohon dinotifikasi.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Reveal(
      child: BezelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Antrean Persetujuan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(
                  label: '${_items.length} pending',
                  tone: BadgeTone.pending,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Antrean kosong — semua disposisi selesai.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            for (var i = 0; i < _items.length; i++) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.inbox_outlined),
                title: Text(_items[i].title),
                subtitle: Text(_items[i].sub),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Setujui',
                      onPressed: () => _decide(i, true),
                      icon: const Icon(Icons.check_circle_outline),
                    ),
                    IconButton(
                      tooltip: 'Tolak',
                      onPressed: () => _decide(i, false),
                      icon: const Icon(Icons.cancel_outlined),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoomLive extends StatelessWidget {
  const _RoomLive();

  @override
  Widget build(BuildContext context) {
    return Reveal(
      child: BezelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perkuliahan Hari Ini',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(
                  child: _MiniStat(label: 'Berlangsung', value: '18'),
                ),
                Expanded(
                  child: _MiniStat(label: 'Okupansi', value: '76%'),
                ),
                Expanded(
                  child: _MiniStat(label: 'Terpadat', value: 'Lab-K1'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(
                value: 0.76,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progres pertemuan: 62 on-track • 30 tertinggal 1–2 • 20 tertinggal > 2 (butuh make-up class)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _Analytics extends StatelessWidget {
  const _Analytics();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Reveal(
      child: BezelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analitik & Distribusi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final b in DashboardSeed.prodiBars) ...[
              Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      b.label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: b.frac,
                        minHeight: 12,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${(b.frac * 100).round()}%',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(label: 'Final 61%', tone: BadgeTone.success),
                StatusBadge(label: 'Draft 27%', tone: BadgeTone.pending),
                StatusBadge(label: 'Kosong 12%', tone: BadgeTone.danger),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveLog extends StatelessWidget {
  const _LiveLog();

  @override
  Widget build(BuildContext context) {
    return Reveal(
      child: BezelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Jejak Aktivitas Live',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => soon(context, 'Log lengkap (/admin/logs)'),
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            for (final l in DashboardSeed.liveLog)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Text(
                  l.time,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                title: Text(l.text),
              ),
          ],
        ),
      ),
    );
  }
}

class _Broadcast extends StatelessWidget {
  const _Broadcast();

  @override
  Widget build(BuildContext context) {
    return Reveal(
      child: BezelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengumuman Aktif',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.campaign_outlined),
                title: Text('Jadwal KRS diperpanjang s.d. 15 Okt 2026'),
                subtitle: Text('Tampil di beranda mahasiswa & dosen'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => soon(context, 'Buat broadcast'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Buat Broadcast'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemHealth extends StatelessWidget {
  const _SystemHealth();

  @override
  Widget build(BuildContext context) {
    return Reveal(
      child: BezelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kesehatan Sistem',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(
                  label: 'Supabase terhubung',
                  tone: BadgeTone.success,
                  icon: Icons.cloud_done_outlined,
                ),
                StatusBadge(
                  label: '48 ms',
                  tone: BadgeTone.neutral,
                  icon: Icons.speed_outlined,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Backup otomatis terakhir: hari ini 03:00 WIB • Free-tier aman',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDock extends StatelessWidget {
  final bool isDesktop;
  const _QuickDock({required this.isDesktop});

  static void _sheetGo(BuildContext context, String fitur) {
    Navigator.pop(context);
    soon(context, fitur);
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return FloatingActionButton.extended(
        onPressed: () => soon(context, 'Aksi cepat'),
        icon: const Icon(Icons.bolt_outlined),
        label: const Text('Aksi Cepat'),
      );
    }
    return FloatingActionButton(
      tooltip: 'Aksi cepat admin',
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _sheetGo(context, 'Registrasi Mahasiswa'),
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Mahasiswa'),
                ),
                FilledButton.icon(
                  onPressed: () => _sheetGo(context, 'Buka Kelas'),
                  icon: const Icon(Icons.meeting_room_outlined, size: 18),
                  label: const Text('Kelas'),
                ),
                FilledButton.icon(
                  onPressed: () => _sheetGo(context, 'Registrasi Dosen'),
                  icon: const Icon(Icons.co_present_outlined, size: 18),
                  label: const Text('Dosen'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _sheetGo(context, 'Broadcast'),
                  icon: const Icon(Icons.campaign_outlined, size: 18),
                  label: const Text('Broadcast'),
                ),
              ],
            ),
          ),
        );
      },
      child: const Icon(Icons.bolt_outlined),
    );
  }
}
