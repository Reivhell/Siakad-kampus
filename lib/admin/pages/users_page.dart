import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/users_seed.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/bezel_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

/// Manajemen Pengguna & Peran (spec 02).
/// Cari debounce + filter role/status + paginasi 10.
/// Guard self-lockout & admin-terakhir di setiap aksi kritis.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _search = TextEditingController();
  late List<AppUser> _all;
  String _role = 'SEMUA';
  String _status = 'SEMUA';
  int _page = 0;
  static const _perPage = 10;

  @override
  void initState() {
    super.initState();
    _all = seedUsers();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AppUser> get _filtered =>
      filterUsers(_all, query: _search.text, role: _role, status: _status);

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<void> _openForm({AppUser? edit}) async {
    final nama = TextEditingController(text: edit?.nama ?? '');
    final email = TextEditingController(text: edit?.email ?? '');
    final telp = TextEditingController(text: edit?.telepon ?? '');
    final roles = Set<UserRole>.of(edit?.roles ?? {UserRole.mahasiswa});
    final ok = await showAdminForm<bool>(
      context: context,
      title: edit == null ? 'Registrasi Pengguna' : 'Edit Pengguna',
      child: _UserForm(
        nama: nama,
        email: email,
        telp: telp,
        roles: roles,
        isEdit: edit != null,
      ),
    );
    if (ok != true) return;
    final emailErr = validateUserEmail(
      email.text,
      _all,
      selfId: edit?.id,
    );
    if (emailErr != null) {
      _snack(emailErr, error: true);
      return;
    }
    if (nama.text.trim().isEmpty) {
      _snack('Nama lengkap wajib diisi.', error: true);
      return;
    }
    if (roles.isEmpty) {
      _snack('Pilih minimal satu peran.', error: true);
      return;
    }
    setState(() {
      if (edit == null) {
        _all.add(
          AppUser(
            id: 'u-${DateTime.now().millisecondsSinceEpoch}',
            nama: nama.text.trim(),
            email: email.text.trim().toLowerCase(),
            telepon: telp.text.trim().isEmpty ? null : telp.text.trim(),
            roles: roles,
          ),
        );
      } else {
        // Pencabutan ADMIN orang lain: sesama admin boleh; guard last-admin.
        if (edit.roles.contains(UserRole.admin) &&
            !roles.contains(UserRole.admin)) {
          final v = validateUserAction(
            targetUserId: edit.id,
            currentAdminId: currentAdminId,
            actionType: 'REVOKE_ADMIN',
            all: _all,
          );
          if (!v.ok) {
            _snack(v.message!, error: true);
            return;
          }
        }
        edit
          ..nama = nama.text.trim()
          ..email = email.text.trim().toLowerCase()
          ..telepon = telp.text.trim().isEmpty ? null : telp.text.trim()
          ..roles = roles;
      }
      _page = 0;
    });
    _snack(edit == null ? 'Pengguna dibuat + magic link terkirim.' : 'Pengguna diperbarui.');
  }

  Future<void> _toggleActive(AppUser u) async {
    final toNonaktif = u.status == AccountStatus.aktif;
    final v = validateUserAction(
      targetUserId: u.id,
      currentAdminId: currentAdminId,
      actionType: 'DEACTIVATE',
      all: _all,
    );
    if (toNonaktif && !v.ok) {
      _snack(v.message!, error: true);
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmKeywordDialog(
        title: toNonaktif ? 'Nonaktifkan Akun' : 'Aktifkan Kembali',
        message:
            '${u.nama} (${u.email}). ${toNonaktif ? 'Sesi JWT dicabut, login ditolak, histori tetap utuh.' : 'Akun dapat login kembali.'}',
        confirmLabel: toNonaktif ? 'Nonaktifkan' : 'Aktifkan',
      ),
    );
    if (yes != true) return;
    setState(() {
      u.status = toNonaktif ? AccountStatus.nonaktif : AccountStatus.aktif;
    });
    _snack(toNonaktif ? 'Akun dinonaktifkan, sesi dicabut.' : 'Akun diaktifkan kembali.');
  }

  Future<void> _unlock(AppUser u) async {
    setState(() => u.status = AccountStatus.aktif);
    _snack('Kunci dibuka instan (lockout 30 mnt dibatalkan).');
  }

  Future<void> _resetPassword(AppUser u) async {
    final temp = TextEditingController(text: generateTempPassword());
    final yes = await showAdminForm<bool>(
      context: context,
      title: 'Reset Password — ${u.nama}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Password sementara (wajib ganti saat login pertama).'),
          const SizedBox(height: 8),
          TextField(
            controller: temp,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh_outlined),
                onPressed: () => temp.text = generateTempPassword(),
              ),
            ),
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
                onPressed: () {
                  if (validatePassword(temp.text) != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(validatePassword(temp.text)!),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Kirim Reset'),
              ),
            ],
          ),
        ],
      ),
    );
    if (yes == true) _snack('Tautan + password sementara dikirim ke ${u.email}.');
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final pages = (filtered.length / _perPage).ceil().clamp(1, 999);
    _page = _page.clamp(0, pages - 1);
    final rows = filtered
        .skip(_page * _perPage)
        .take(_perPage)
        .toList();
    final width = MediaQuery.sizeOf(context).width;

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
                  eyebrow: 'Admin / Pengguna',
                  title: 'Manajemen Pengguna & Peran',
                  subtitle:
                      '${filtered.length} akun • proteksi self-lockout + admin-terakhir aktif',
                  action: FilledButton.icon(
                    onPressed: _openForm,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Reveal(
                child: BezelCard(
                  child: FilterBar(
                    searchController: _search,
                    searchHint: 'Cari nama / email…',
                    onSearchChanged: (_) =>
                        setState(() => _page = 0),
                    onRefresh: () => setState(() {}),
                    filters: [
                      FilterOption(
                        label: 'Peran',
                        value: _role,
                        options: const [
                          'SEMUA',
                          'ADMIN',
                          'DOSEN',
                          'MAHASISWA',
                          'MULTI-ROLE',
                        ],
                        onSelected: (v) => setState(() {
                          _role = v;
                          _page = 0;
                        }),
                      ),
                      FilterOption(
                        label: 'Status',
                        value: _status,
                        options: const [
                          'SEMUA',
                          'AKTIF',
                          'NONAKTIF',
                          'TERKUNCI',
                        ],
                        onSelected: (v) => setState(() {
                          _status = v;
                          _page = 0;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (rows.isEmpty)
                const Reveal(
                  child: BezelCard(
                    child: EmptyState(
                      icon: Icons.group_off_outlined,
                      title: 'Tidak ada pengguna cocok',
                      subtitle: 'Ubah kata kunci atau filter peran/status.',
                    ),
                  ),
                )
              else if (width < 700)
                for (var i = 0; i < rows.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Reveal(
                      delayMs: i * 40,
                      child: _UserTile(
                        user: rows[i],
                        onEdit: () => _openForm(edit: rows[i]),
                        onToggle: () => _toggleActive(rows[i]),
                        onUnlock: () => _unlock(rows[i]),
                        onReset: () => _resetPassword(rows[i]),
                      ),
                    ),
                  )
              else
                Reveal(
                  child: BezelCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('NAMA')),
                              DataColumn(label: Text('EMAIL')),
                              DataColumn(label: Text('PERAN')),
                              DataColumn(label: Text('STATUS')),
                              DataColumn(label: Text('LOGIN')),
                              DataColumn(label: Text('AKSI')),
                            ],
                            rows: [
                              for (final u in rows)
                                DataRow(
                                  cells: [
                                    DataCell(Text(u.nama)),
                                    DataCell(
                                      Text(
                                        u.email,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    DataCell(
                                      Wrap(
                                        spacing: 4,
                                        children: [
                                          for (final r in u.roles)
                                            _RoleChip(role: r),
                                        ],
                                      ),
                                    ),
                                    DataCell(_StatusDot(status: u.status)),
                                    DataCell(
                                      Text(u.lastLogin ?? '—'),
                                    ),
                                    DataCell(
                                      _RowMenu(
                                        user: u,
                                        onEdit: () => _openForm(edit: u),
                                        onToggle: () => _toggleActive(u),
                                        onUnlock: () => _unlock(u),
                                        onReset: () => _resetPassword(u),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        _Pagination(
                          page: _page,
                          pages: pages,
                          total: filtered.length,
                          onPrev: _page > 0
                              ? () => setState(() => _page--)
                              : null,
                          onNext: _page < pages - 1
                              ? () => setState(() => _page++)
                              : null,
                        ),
                      ],
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

class _UserForm extends StatefulWidget {
  final TextEditingController nama, email, telp;
  final Set<UserRole> roles;
  final bool isEdit;
  const _UserForm({
    required this.nama,
    required this.email,
    required this.telp,
    required this.roles,
    required this.isEdit,
  });

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('1. Identitas Akun', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: widget.nama,
          decoration: const InputDecoration(
            labelText: 'Nama lengkap *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.email,
          decoration: const InputDecoration(
            labelText: 'Email institusi *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.telp,
          decoration: const InputDecoration(
            labelText: 'Telepon / WA',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '2. Penugasan Peran *',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final r in UserRole.values)
              FilterChip(
                label: Text(r.name.toUpperCase()),
                selected: widget.roles.contains(r),
                onSelected: (v) => setState(() {
                  v ? widget.roles.add(r) : widget.roles.remove(r);
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Magic link aktivasi dikirim otomatis. Hard-delete diblokir bila akun punya relasi data.',
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
    );
  }
}

class _RoleChip extends StatelessWidget {
  final UserRole role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = role.name.toUpperCase();
    final color = switch (role) {
      UserRole.admin => cs.primary,
      UserRole.dosen => cs.tertiary,
      UserRole.mahasiswa => cs.secondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final AccountStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      AccountStatus.aktif => const StatusBadge(
        label: 'AKTIF',
        tone: BadgeTone.success,
      ),
      AccountStatus.nonaktif => const StatusBadge(
        label: 'NONAKTIF',
        tone: BadgeTone.neutral,
      ),
      AccountStatus.terkunci => const StatusBadge(
        label: 'TERKUNCI',
        tone: BadgeTone.danger,
        icon: Icons.lock_outline,
      ),
    };
  }
}

class _RowMenu extends StatelessWidget {
  final AppUser user;
  final VoidCallback onEdit, onToggle, onUnlock, onReset;
  const _RowMenu({
    required this.user,
    required this.onEdit,
    required this.onToggle,
    required this.onUnlock,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Aksi',
      onSelected: (v) {
        switch (v) {
          case 'edit':
            onEdit();
          case 'toggle':
            onToggle();
          case 'unlock':
            onUnlock();
          case 'reset':
            onReset();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Detail / Edit')),
        const PopupMenuItem(value: 'reset', child: Text('Reset password')),
        if (user.status == AccountStatus.terkunci)
          const PopupMenuItem(value: 'unlock', child: Text('Buka kunci')),
        PopupMenuItem(
          value: 'toggle',
          child: Text(
            user.status == AccountStatus.aktif
                ? 'Nonaktifkan akses'
                : 'Aktifkan kembali',
          ),
        ),
        if (user.hasRelations)
          const PopupMenuItem(
            enabled: false,
            child: Text('Hapus diblokir: punya relasi'),
          ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback onEdit, onToggle, onUnlock, onReset;
  const _UserTile({
    required this.user,
    required this.onEdit,
    required this.onToggle,
    required this.onUnlock,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return BezelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  user.nama,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusDot(status: user.status),
            ],
          ),
          Text(user.email, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [for (final r in user.roles) _RoleChip(role: r)],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: onEdit,
                child: const Text('Edit'),
              ),
              FilledButton.tonal(
                onPressed: onReset,
                child: const Text('Reset'),
              ),
              if (user.status == AccountStatus.terkunci)
                FilledButton.tonal(
                  onPressed: onUnlock,
                  child: const Text('Unlock'),
                )
              else
                FilledButton.tonal(
                  onPressed: onToggle,
                  child: Text(
                    user.status == AccountStatus.aktif
                        ? 'Nonaktif'
                        : 'Aktifkan',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int page, pages, total;
  final VoidCallback? onPrev, onNext;
  const _Pagination({
    required this.page,
    required this.pages,
    required this.total,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Hal ${page + 1}/$pages • $total akun',
            style: Theme.of(context).textTheme.labelMedium,
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
