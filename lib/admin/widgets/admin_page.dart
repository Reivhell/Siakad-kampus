import 'package:flutter/material.dart';

import 'bezel_card.dart';
import 'empty_state.dart';
import 'section_header.dart';

/// SnackBar tunggal seluruh page Admin.
///
/// Sebelumnya tiap page menyalin method `_snack` 8 baris yang identik
/// (beda nama parameter saja). Kini satu fungsi — pesan + warna error
/// konsisten di 15 modul.
void showAdminSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

/// Paginasi tunggal seluruh page Admin.
///
/// Menggantikan salinan `_Pagination` privat di tiap page.
/// Teks + tooltip dipertahankan identik agar tes QC lama tetap hijau.
class AdminPagination extends StatelessWidget {
  final int page;
  final int pages;
  final int total;
  final String unit;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const AdminPagination({
    super.key,
    required this.page,
    required this.pages,
    required this.total,
    this.unit = 'data',
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Semantics(
            liveRegion: true,
            label: 'Halaman ${page + 1} dari $pages, total $total $unit',
            child: Text(
              'Hal ${page + 1}/$pages • $total $unit',
              style: Theme.of(context).textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Sebelumnya',
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Berikutnya',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

/// Kerangka isi page Admin: scroll + lebar max + header + kartu kosong.
///
/// Menggantikan ~25 baris boilerplate
/// (SingleChildScrollView → Center → ConstrainedBox → Column →
/// SectionHeader → SizedBox) yang disalin di setiap page.
class AdminPageBody extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? action;
  final List<Widget> children;

  const AdminPageBody({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.action,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              SectionHeader(
                eyebrow: eyebrow,
                title: title,
                subtitle: subtitle,
                action: action,
              ),
              const SizedBox(height: 16),
              ...children,
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris data responsif — mobile dirakit kolom, ≥700 kembali `ListTile`.
///
/// [ListTile] memberi `trailing` lebar intrinsic. Di 360px sisa untuk
/// title tinggal 0–75px: teks wrap 12–37 baris, atau 0px (tidak terlihat
/// sama sekali). Di bawah [_wide] title/subtitle dapat lebar penuh dan
/// aksi pindah ke baris sendiri.
class AdminListRow extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool dense;

  const AdminListRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.dense = false,
  });

  /// Lebar[ListTile] masih muat; di bawah ini aksi turun ke baris baru.
  static const _wide = 700.0;

  @override
  Widget build(BuildContext context) {
    final actions = trailing;
    if (MediaQuery.sizeOf(context).width >= _wide) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        dense: dense,
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: actions,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 16)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [title, ?subtitle],
              ),
            ),
          ],
        ),
        if (actions != null)
          Padding(
            padding: EdgeInsets.only(left: leading == null ? 0 : 56, top: 8),
            child: Wrap(spacing: 8, runSpacing: 8, children: [actions]),
          ),
      ],
    );
  }
}

/// Keadaan kosong tunggal: kartu + ikon + teks.
class AdminEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const AdminEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return BezelCard(
      child: EmptyState(icon: icon, title: title, subtitle: subtitle),
    );
  }
}
