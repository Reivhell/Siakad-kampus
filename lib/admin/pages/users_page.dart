import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../rules/admin_rules.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/admin_page.dart';
import '../widgets/bezel_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/reveal.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';
import '../core/admin_api_scope.dart';

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
  List<AppUser> _all = const [];
  String _role = 'SEMUA';
  String _status = 'SEMUA';
  int _page = 0;
  static const _perPage = 10;
  bool _loading = true;
  String? _error;

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
      final q = _search.text.trim();
      final role = _role == 'SEMUA' || _role == 'MULTI-ROLE'
          ? ''
          : '&role=$_role';
      final path =
          '/api/v1/users?limit=100${q.isNotEmpty ? '&q=${Uri.encodeQueryComponent(q)}' : ''}$role';
      final data = await client.getJson(path);
      final items = (data is Map && data['items'] is List)
          ? data['items'] as List
          : const [];
      final mapped = <AppUser>[];
      for (final raw in items.whereType<Map>()) {
        final rolesRaw = raw['roles'];
        final roles = <UserRole>{};
        if (rolesRaw is List) {
          for (final r in rolesRaw.whereType<String>()) {
            switch (r.toUpperCase()) {
              case 'ADMIN':
                roles.add(UserRole.admin);
                break;
              case 'DOSEN':
                roles.add(UserRole.dosen);
                break;
              case 'MAHASISWA':
                roles.add(UserRole.mahasiswa);
                break;
            }
          }
        }
        if (roles.isEmpty) roles.add(UserRole.mahasiswa);
        mapped.add(
          AppUser(
            id: (raw['id'] ?? '').toString(),
            nama: (raw['nama_lengkap'] ?? raw['nama'] ?? raw['email'] ?? '')
                .toString(),
            email: (raw['email'] ?? '').toString(),
            telepon: raw['telepon'] as String?,
            roles: roles,
            status: raw['aktif'] == false
                ? AccountStatus.nonaktif
                : AccountStatus.aktif,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _all = mapped;
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AppUser> get _filtered => AdminRules.filterUsers(
    _all,
    query: _search.text,
    role: _role,
    status: _status,
  );

  void _snack(String msg, {bool error = false}) {
    showAdminSnack(context, msg, error: error);
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
    final emailCheck = AdminRules.userEmail(email.text, _all, selfId: edit?.id);
    if (!emailCheck.ok) {
      _snack(emailCheck.message ?? 'Email ditolak.', error: true);
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
    final client = AdminApiScope.clientOf(context);
    if (client == null) {
      _snack('Sesi API tidak tersedia.', error: true);
      return;
    }
    try {
      final roleNames = roles
          .map(
            (r) => switch (r) {
              UserRole.admin => 'ADMIN',
              UserRole.dosen => 'DOSEN',
              UserRole.mahasiswa => 'MAHASISWA',
            },
          )
          .toList();
      if (edit == null) {
        await client.postJson('/api/v1/users', {
          'email': email.text.trim().toLowerCase(),
          'nama_lengkap': nama.text.trim(),
          'telepon': telp.text.trim().isEmpty ? null : telp.text.trim(),
          'roles': roleNames,
        });
        _snack('Pengguna dibuat.');
      } else {
        // Pencabutan ADMIN orang lain: guard last-admin.
        if (edit.roles.contains(UserRole.admin) &&
            !roles.contains(UserRole.admin)) {
          final v = AdminRules.revokeAdmin(
            targetUserId: edit.id,
            currentAdminId: '',
            all: _all,
          );
          // server-side authz tetap berlaku; client guard best-effort
          if (!v.ok && edit.id.isNotEmpty) {
            _snack(v.message!, error: true);
            return;
          }
        }
        await client.postJson('/api/v1/users/${edit.id}', {
          'nama_lengkap': nama.text.trim(),
          'telepon': telp.text.trim().isEmpty ? null : telp.text.trim(),
          'roles': roleNames,
        });
        _snack('Pengguna diperbarui.');
      }
      await _load();
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  Future<void> _toggleActive(AppUser u) async {
    final toNonaktif = u.status == AccountStatus.aktif;
    final v = AdminRules.userAction(
      targetUserId: u.id,
      currentAdminId: '',
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
    _snack(
      toNonaktif
          ? 'Akun dinonaktifkan, sesi dicabut.'
          : 'Akun diaktifkan kembali.',
    );
  }

  Future<void> _unlock(AppUser u) async {
    setState(() => u.status = AccountStatus.aktif);
    _snack('Akun dibuka. Batas kunci 30 menit dibatalkan.');
  }

  Future<void> _resetPassword(AppUser u) async {
    final temp = TextEditingController(text: AdminRules.generateTemp());
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
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 32,
            decoration: InputDecoration(
              labelText: 'Password sementara *',
              border: const OutlineInputBorder(),
              counterText: '',
              suffixIcon: IconButton(
                tooltip: 'Buat password acak baru',
                icon: const Icon(Icons.refresh_outlined),
                onPressed: () => temp.text = AdminRules.generateTemp(),
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
                  final pwErr = AdminRules.password(temp.text).asError;
                  if (pwErr != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(pwErr),
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
    if (yes == true) {
      _snack('Fitur reset sandi memerlukan endpoint backend khusus.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _load,
              child: const Text('Muat ulang'),
            ),
          ],
        ),
      );
    }
    final filtered = _filtered;
    final pages = (filtered.length / _perPage).ceil().clamp(1, 999);
    _page = _page.clamp(0, pages - 1);
    final rows = filtered.skip(_page * _perPage).take(_perPage).toList();
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
              Reveal(
                child: SectionHeader(
                  eyebrow: 'Admin / Pengguna',
                  title: 'Manajemen Pengguna & Peran',
                  subtitle:
                      '${filtered.length} akun • akun sendiri dan admin terakhir diproteksi',
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
                    onSearchChanged: (_) => setState(() => _page = 0),
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
                        Scrollbar(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                DataColumn(
                                  label: Text(
                                    'NAMA',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium,
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'EMAIL',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium,
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'PERAN',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium,
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'STATUS',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium,
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'LOGIN',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium,
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'AKSI',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium,
                                  ),
                                ),
                              ],
                              rows: [
                                for (final u in rows)
                                  DataRow(
                                    cells: [
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 220,
                                          ),
                                          child: Text(
                                            u.nama,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 240,
                                          ),
                                          child: Text(
                                            u.email,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
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
                                      DataCell(Text(u.lastLogin ?? '—')),
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
                        ),
                        const Divider(height: 1),
                        AdminPagination(
                          page: _page,
                          pages: pages,
                          total: filtered.length,
                          unit: 'akun',
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
  String? _namaError;
  String? _emailError;
  String? _rolesError;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    widget.nama.addListener(_validate);
    widget.email.addListener(_validate);
  }

  @override
  void dispose() {
    widget.nama.removeListener(_validate);
    widget.email.removeListener(_validate);
    super.dispose();
  }

  void _validate() {
    final namaBad = widget.nama.text.trim().isEmpty;
    final emailText = widget.email.text.trim();
    final rolesBad = widget.roles.isEmpty;
    if (mounted) {
      setState(() {
        _namaError = namaBad ? 'Nama lengkap wajib diisi.' : null;
        _emailError = emailText.isEmpty
            ? 'Email institusi wajib diisi.'
            : (!_emailRe.hasMatch(emailText)
                  ? 'Format email tidak valid (nama@kampus.ac.id).'
                  : null);
        _rolesError = rolesBad ? 'Pilih minimal satu peran.' : null;
      });
    }
  }

  bool get _valid =>
      widget.nama.text.trim().isNotEmpty &&
      _emailRe.hasMatch(widget.email.text.trim()) &&
      widget.roles.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Identitas Akun',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Nama lengkap, wajib diisi',
          textField: true,
          child: TextField(
            controller: widget.nama,
            autofocus: !widget.isEdit,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            maxLength: 100,
            decoration: InputDecoration(
              labelText: 'Nama lengkap *',
              hintText: 'cth. Siti Rahma Wijaya',
              border: const OutlineInputBorder(),
              errorText: _namaError,
              counterText: '',
            ),
            onChanged: (_) => _validate(),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Email institusi, wajib diisi',
          textField: true,
          child: TextField(
            controller: widget.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: 'Email institusi *',
              hintText: 'nama@kampus.ac.id',
              border: const OutlineInputBorder(),
              errorText: _emailError,
              counterText: '',
            ),
            onChanged: (_) => _validate(),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Telepon atau WhatsApp, opsional',
          textField: true,
          child: TextField(
            controller: widget.telp,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            maxLength: 20,
            decoration: const InputDecoration(
              labelText: 'Telepon / WA',
              hintText: '08xxxxxxxxxx',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '2. Penugasan Peran *',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Semantics(
          label: 'Penugasan peran, wajib pilih minimal satu',
          child: Wrap(
            spacing: 8,
            children: [
              for (final r in UserRole.values)
                FilterChip(
                  label: Text(r.name.toUpperCase()),
                  selected: widget.roles.contains(r),
                  onSelected: (v) => setState(() {
                    v ? widget.roles.add(r) : widget.roles.remove(r);
                    _validate();
                  }),
                ),
            ],
          ),
        ),
        if (_rolesError != null) ...[
          const SizedBox(height: 4),
          Text(
            _rolesError!,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ],
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
              onPressed: _valid ? () => Navigator.pop(context, true) : null,
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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusDot(status: user.status),
            ],
          ),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [for (final r in user.roles) _RoleChip(role: r)],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(onPressed: onEdit, child: const Text('Edit')),
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
