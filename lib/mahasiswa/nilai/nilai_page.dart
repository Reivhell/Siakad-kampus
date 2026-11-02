import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/widgets/bezel_card.dart';
import '../../admin/widgets/empty_state.dart';
import '../../admin/widgets/kpi_card.dart';
import '../../admin/widgets/section_header.dart';
import '../../admin/widgets/status_badge.dart';
import '../../app/formatters.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/status_banner.dart';
import '../../features/mahasiswa/providers/mahasiswa_providers.dart';
import '../widgets/page_body.dart';

/// KHS per periode + watermark DRAFT (`05_nilai_dan_khs.md`).
class NilaiPage extends ConsumerStatefulWidget {
  const NilaiPage({super.key});

  @override
  ConsumerState<NilaiPage> createState() => _NilaiPageState();
}

class _NilaiPageState extends ConsumerState<NilaiPage> {
  String? _periodeId;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(mahasiswaRepositoryProvider);
    final npm = ref.watch(currentNpmProvider);
    if (npm == null) {
      return const EmptyState(
        icon: Icons.person_off_outlined,
        title: 'Sesi tidak ditemukan',
        subtitle: 'Silakan masuk kembali.',
      );
    }

    final opsi = repo.periodeKhs(npm);
    final selected = _periodeId != null && opsi.any((p) => p.id == _periodeId)
        ? _periodeId!
        : repo.periodeAktif.id;
    final rows = repo.nilaiPeriode(npm, selected);
    final ips = repo.ipsPeriode(npm, selected);
    final ipk = repo.ipk(npm);
    final sksDinilai = rows
        .where((r) => r.huruf != null)
        .fold(0, (acc, r) => acc + r.sks);
    final adaDraft = rows.any((r) => r.huruf != null && !r.sudahFinal);
    final belumInput = rows.where((r) => r.huruf == null).length;
    final namaPeriode = opsi.firstWhere((p) => p.id == selected).nama;

    return PageBody(
      children: [
        SectionHeader(
          eyebrow: 'Akademik',
          title: 'Kartu Hasil Studi',
          subtitle: 'Nilai per periode akademik',
          action: SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              key: const Key('nilai-periode'),
              initialValue: selected,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Periode',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: [
                for (final p in opsi)
                  DropdownMenuItem(value: p.id, child: Text(p.nama)),
              ],
              onChanged: (v) => setState(() => _periodeId = v),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: KpiCard(
                icon: Icons.speed,
                label: 'IPS $namaPeriode',
                value: formatDesimal(ips),
                sub: '$sksDinilai SKS dinilai',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                icon: Icons.workspace_premium_outlined,
                label: 'IPK',
                value: formatDesimal(ipk),
                sub: 'Kumulatif seluruh periode',
              ),
            ),
          ],
        ),
        if (adaDraft || belumInput > 0)
          StatusBanner(
            tone: StatusBannerTone.warning,
            icon: Icons.edit_note,
            message:
                '${adaDraft ? 'Sebagian nilai masih DRAFT (belum final). ' : ''}'
                '${belumInput > 0 ? '$belumInput MK belum diinput dosen. ' : ''}'
                'Nilai yang belum ada huruf tidak dihitung dalam IPS.',
          ),
        if (rows.isEmpty)
          const BezelCard(child: Text('Belum ada nilai pada periode ini.'))
        else
          BezelCard(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 52,
                columns: const [
                  DataColumn(label: Text('Kode')),
                  DataColumn(label: Text('Mata kuliah')),
                  DataColumn(label: Text('SKS'), numeric: true),
                  DataColumn(label: Text('UTS'), numeric: true),
                  DataColumn(label: Text('UAS'), numeric: true),
                  DataColumn(label: Text('Tugas'), numeric: true),
                  DataColumn(label: Text('Akhir'), numeric: true),
                  DataColumn(label: Text('Huruf')),
                  DataColumn(label: Text('Status')),
                ],
                rows: [
                  for (final r in rows)
                    DataRow(
                      cells: [
                        DataCell(Text(r.kodeMk)),
                        DataCell(Text(r.namaMk)),
                        DataCell(Text('${r.sks}')),
                        DataCell(Text(_angka(r.uts))),
                        DataCell(Text(_angka(r.uas))),
                        DataCell(Text(_angka(r.tugas))),
                        DataCell(Text(_angka(r.akhir))),
                        DataCell(
                          Text(
                            r.huruf ?? '—',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _warnaHuruf(context, r.huruf),
                            ),
                          ),
                        ),
                        DataCell(
                          r.huruf == null
                              ? const StatusBadge(
                                  label: 'Belum diinput',
                                  tone: BadgeTone.neutral,
                                )
                              : r.sudahFinal
                              ? const StatusBadge(
                                  label: 'Final',
                                  tone: BadgeTone.success,
                                )
                              : const StatusBadge(
                                  label: 'DRAFT',
                                  tone: BadgeTone.pending,
                                ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _angka(double? v) => v == null ? '—' : v.toStringAsFixed(0);

  Color? _warnaHuruf(BuildContext context, String? huruf) {
    if (huruf == null) return null;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (huruf == 'E') return dark ? AppColors.darkDanger : AppColors.dangerInk;
    if (huruf == 'D') return dark ? AppColors.darkAlert : AppColors.alertInk;
    return dark ? AppColors.darkPass : AppColors.passInk;
  }
}
