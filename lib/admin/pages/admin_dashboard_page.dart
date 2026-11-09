import 'package:flutter/material.dart';

import '../core/admin_api_scope.dart';
import '../widgets/bezel_card.dart';
import '../widgets/kpi_card.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Dashboard Admin — ringkasan operasional dari backend.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _periode = '—';
  bool _presentation = false;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
      final data = await client.getJson('/api/v1/dashboard');
      final master = await client.getJson('/api/v1/master');
      String periode = _periode;
      if (master is Map && master['periode_akademik'] is List) {
        for (final p in (master['periode_akademik'] as List).whereType<Map>()) {
          if (p['aktif'] == true) {
            periode = (p['nama'] ?? periode).toString();
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _stats = data is Map ? data.cast<String, dynamic>() : const {};
        _periode = periode;
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

  int _int(String k) => (_stats[k] is num) ? (_stats[k] as num).toInt() : 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final isTablet = width >= 600 && width < 1024;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                _header(context),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  BezelCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Muat ulang'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _kpiSection(isDesktop, isTablet),
                  const SizedBox(height: 24),
                  const Reveal(
                    child: SectionHeader(
                      eyebrow: 'Ringkasan',
                      title: 'Status Operasional',
                      subtitle: 'Indikator utama dari data backend.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _statusGrid(isDesktop, isTablet),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Reveal(
      child: BezelCard(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            InputChip(label: Text('Periode: $_periode'), onPressed: _load),
            FilterChip(
              label: Text(_presentation ? 'Mode presentasi' : 'Mode normal'),
              selected: _presentation,
              onSelected: (v) => setState(() => _presentation = v),
            ),
            FilledButton.icon(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Muat ulang'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiSection(bool isDesktop, bool isTablet) {
    final defs =
        <({IconData icon, String label, String value, String sub, bool star})>[
          (
            icon: Icons.calendar_month_outlined,
            label: 'Periode Aktif',
            value: _periode,
            sub: 'Sumber: master akademik',
            star: false,
          ),
          (
            icon: Icons.school_outlined,
            label: 'Mahasiswa Aktif',
            value: _presentation ? '—' : '${_int('mahasiswa_aktif')}',
            sub: 'Status aktif',
            star: false,
          ),
          (
            icon: Icons.co_present_outlined,
            label: 'Dosen Aktif',
            value: '${_int('dosen_aktif')}',
            sub: 'Status aktif',
            star: false,
          ),
          (
            icon: Icons.account_tree_outlined,
            label: 'Program Studi',
            value: '${_int('program_studi')}',
            sub: 'Terdaftar',
            star: false,
          ),
          (
            icon: Icons.how_to_reg_outlined,
            label: 'KRS Aktif',
            value: '${_int('krs_aktif')}',
            sub: 'Menunggu: ${_int('krs_menunggu')}',
            star: false,
          ),
          (
            icon: Icons.mark_email_unread_outlined,
            label: 'Surat Menunggu',
            value: '${_int('surat_menunggu')}',
            sub: 'Aktivitas hari ini: ${_int('aktivitas_hari_ini')}',
            star: true,
          ),
        ];
    final cards = [
      for (var i = 0; i < defs.length; i++)
        Reveal(
          delayMs: i * 60,
          child: KpiCard(
            icon: defs[i].icon,
            label: defs[i].label,
            value: defs[i].value,
            sub: defs[i].sub,
            starGold: defs[i].star,
          ),
        ),
    ];
    if (!isDesktop && !isTablet) {
      return SizedBox(
        height: 220,
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
        mainAxisExtent:
            (isDesktop ? 240 : 228) * MediaQuery.textScalerOf(context).scale(1),
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      itemBuilder: (_, i) => cards[i],
    );
  }

  Widget _statusGrid(bool isDesktop, bool isTablet) {
    final items = <({String title, String sub, BadgeTone tone})>[
      (
        title: 'KRS menunggu persetujuan',
        sub: '${_int('krs_menunggu')} pengajuan',
        tone: _int('krs_menunggu') > 0 ? BadgeTone.pending : BadgeTone.success,
      ),
      (
        title: 'Permohonan surat menunggu',
        sub: '${_int('surat_menunggu')} permohonan',
        tone: _int('surat_menunggu') > 0
            ? BadgeTone.pending
            : BadgeTone.success,
      ),
      (
        title: 'Aktivitas tercatat hari ini',
        sub: '${_int('aktivitas_hari_ini')} entri',
        tone: BadgeTone.info,
      ),
    ];
    final tiles = [
      for (final it in items)
        BezelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      it.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StatusBadge(label: it.tone.name, tone: it.tone),
                ],
              ),
              const SizedBox(height: 6),
              Text(it.sub, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
    ];
    if (!isDesktop && !isTablet) {
      return Column(
        children: [
          for (final t in tiles) ...[t, const SizedBox(height: 12)],
        ],
      );
    }
    final cols = isDesktop ? 3 : 2;
    return GridView.count(
      crossAxisCount: cols,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tiles,
    );
  }
}
