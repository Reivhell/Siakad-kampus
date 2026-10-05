import 'package:flutter/material.dart';

import '../models/audit.dart';
import '../models/audit_seed.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/bezel_card.dart';
import '../widgets/feedback.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Audit Trail Explorer (spec 10): filter + diff inspector + anomali + chain.
class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  final _search = TextEditingController();
  late List<AuditEntry> _all;
  String _kategori = 'SEMUA';
  String _entitas = 'SEMUA';
  int _page = 0;
  static const _perPage = 10;

  @override
  void initState() {
    super.initState();
    _all = seedAudit();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AuditEntry> get _filtered => filterAudit(
    _all,
    query: _search.text,
    aksi: _kategori,
    entitas: _entitas,
  );

  Future<void> _inspect(AuditEntry e) async {
    final rows = diffStates(e.before, e.after);
    await showAdminForm<void>(
      context: context,
      title: 'Inspeksi ${e.aksi}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${e.aktor} • ${e.ip}'),
          Text(
            '${e.waktu.day}/${e.waktu.month} ${e.waktu.hour}:${e.waktu.minute.toString().padLeft(2, '0')} • ${e.entitas}',
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Text('Tanpa state diff — event notifikasi murni.'),
          for (final r in rows)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: r.changed
                    ? Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      r.field,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.before,
                      style: TextStyle(
                        color: r.changed
                            ? Theme.of(context).colorScheme.error
                            : null,
                        decoration: r.changed
                            ? TextDecoration.lineThrough
                            : null,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 14),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.after,
                      style: TextStyle(
                        color: r.changed
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: r.changed
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'hash ${e.hash} ← prev ${e.hashPrev.isEmpty ? 'GENESIS' : e.hashPrev}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final filtered = _filtered;
    final pages = (filtered.length / _perPage).ceil().clamp(1, 999);
    _page = _page.clamp(0, pages - 1);
    final rows = filtered
        .skip(_page * _perPage)
        .take(_perPage)
        .toList();
    final valid = verifyChain(_all);
    final anomalies = _all.where(isAnomaly).length;

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
                  eyebrow: 'Admin / Audit',
                  title: 'Jejak Audit & Keamanan',
                  subtitle:
                      '${_all.length} rekaman • $anomalies anomali • append-only WORM',
                  action: FilledButton.tonalIcon(
                    onPressed: () => soon(context, 'Ekspor CSV audit'),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Ekspor CSV'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Reveal(
                child: Wrap(
                  spacing: 8,
                  children: [
                    StatusBadge(
                      label: valid ? 'RANTAI VALID' : 'TAMPER ALARM',
                      tone: valid ? BadgeTone.success : BadgeTone.danger,
                      icon: Icons.link_outlined,
                    ),
                    StatusBadge(
                      label: '$anomalies ANOMALI',
                      tone: anomalies == 0
                          ? BadgeTone.neutral
                          : BadgeTone.pending,
                      icon: Icons.warning_amber_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Reveal(
                child: BezelCard(
                  child: FilterBar(
                    searchController: _search,
                    searchHint: 'Cari ID / aktor / aksi…',
                    onSearchChanged: (_) =>
                        setState(() => _page = 0),
                    onRefresh: () => setState(() {}),
                    filters: [
                      FilterOption(
                        label: 'Kategori',
                        value: _kategori,
                        options: const [
                          'SEMUA',
                          'Administratif',
                          'Dosen',
                          'Mahasiswa',
                          'Keamanan',
                          'Sistem',
                        ],
                        onSelected: (v) => setState(() {
                          _kategori = v;
                          _page = 0;
                        }),
                      ),
                      FilterOption(
                        label: 'Entitas',
                        value: _entitas,
                        options: const [
                          'SEMUA',
                          'nilai',
                          'krs',
                          'kelas',
                          'user',
                        ],
                        onSelected: (v) => setState(() {
                          _entitas = v;
                          _page = 0;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Reveal(
                  child: BezelCard(
                    child: EmptyState(
                      icon: Icons.history_outlined,
                      title: 'Tidak ada log cocok',
                      subtitle: 'Ubah kata kunci/filter.',
                    ),
                  ),
                )
              else
                for (var i = 0; i < rows.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Reveal(
                      delayMs: (i * 30).clamp(0, 240),
                      child: BezelCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: isAnomaly(rows[i])
                              ? const Icon(Icons.warning_amber_outlined)
                              : const Icon(Icons.history_outlined),
                          title: Text(
                            '${rows[i].aksi} • ${rows[i].aktor}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${rows[i].entitas} • ${rows[i].ip} • ${rows[i].waktu.day}/${rows[i].waktu.month} ${rows[i].waktu.hour}:${rows[i].waktu.minute.toString().padLeft(2, '0')}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (isAnomaly(rows[i]))
                                const StatusBadge(
                                  label: 'ANOMALI',
                                  tone: BadgeTone.danger,
                                ),
                              TextButton(
                                onPressed: () => _inspect(rows[i]),
                                child: const Text('Inspect'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              if (pages > 1)
                Row(
                  children: [
                    Text('Hal ${_page + 1}/$pages'),
                    const Spacer(),
                    IconButton(
                      onPressed: _page > 0
                          ? () => setState(() => _page--)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      onPressed: _page < pages - 1
                          ? () => setState(() => _page++)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
