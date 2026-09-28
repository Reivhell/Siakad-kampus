import 'dart:math';

/// Model + logika murni manajemen pengguna (spec 02 §4–§5).
/// Tanpa dependensi Flutter agar mudah diuji.
enum UserRole { admin, dosen, mahasiswa }

enum AccountStatus { aktif, nonaktif, terkunci }

class AppUser {
  final String id;
  String nama;
  String email;
  String? telepon;
  Set<UserRole> roles;
  AccountStatus status;
  bool hasRelations;
  String? lastLogin;

  AppUser({
    required this.id,
    required this.nama,
    required this.email,
    this.telepon,
    required this.roles,
    this.status = AccountStatus.aktif,
    this.hasRelations = false,
    this.lastLogin,
  });
}

class ValidationResult {
  final bool ok;
  final String? message;
  const ValidationResult._(this.ok, this.message);
  const ValidationResult.success() : this._(true, null);
  const ValidationResult.failed(String m) : this._(false, m);
}

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Password policy 02 §3.4: min 8, 1 besar, 1 kecil, 1 angka/simbol.
String? validatePassword(String v) {
  if (v.length < 8) return 'Minimal 8 karakter.';
  if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Butuh 1 huruf besar.';
  if (!RegExp(r'[a-z]').hasMatch(v)) return 'Butuh 1 huruf kecil.';
  if (!RegExp(r'[0-9\W]').hasMatch(v)) return 'Butuh 1 angka/simbol.';
  return null;
}

String? validateUserEmail(String v, List<AppUser> existing, {String? selfId}) {
  final e = v.trim().toLowerCase();
  if (!_emailRe.hasMatch(e)) return 'Format email tidak valid.';
  final clash = existing.any(
    (u) => u.email.toLowerCase() == e && u.id != selfId,
  );
  if (clash) return 'Email telah digunakan oleh akun lain.';
  return null;
}

/// Guard 02 §4.2: anti self-lockout + proteksi admin terakhir.
ValidationResult validateUserAction({
  required String targetUserId,
  required String currentAdminId,
  required String actionType, // DEACTIVATE | REVOKE_ADMIN
  required List<AppUser> all,
}) {
  if (targetUserId == currentAdminId) {
    return const ValidationResult.failed(
      'Tindakan ditolak: tidak dapat menonaktifkan / mencabut hak akun sendiri.',
    );
  }
  if (actionType == 'DEACTIVATE' || actionType == 'REVOKE_ADMIN') {
    final others = all.where(
      (u) =>
          u.id != targetUserId &&
          u.roles.contains(UserRole.admin) &&
          u.status == AccountStatus.aktif,
    ).length;
    if (others < 1) {
      return const ValidationResult.failed(
        'Tindakan ditolak: target adalah administrator aktif terakhir.',
      );
    }
  }
  return const ValidationResult.success();
}

/// Generator 02 §4.3: KataSifat-KataBenda-3digit! (memenuhi policy).
String generateTempPassword([Random? rng]) {
  final r = rng ?? Random.secure();
  const adj = ['Kampus', 'Cendekia', 'Unggul', 'Wacana', 'Ilmu'];
  const noun = ['Merdeka', 'Bangsa', 'Ajar', 'Tugas', 'Karya'];
  final a = adj[r.nextInt(adj.length)];
  final n = noun[r.nextInt(noun.length)];
  final d = 100 + r.nextInt(900);
  return '$a-$n-$d!';
}

List<AppUser> filterUsers(
  List<AppUser> all, {
  String query = '',
  String role = 'SEMUA',
  String status = 'SEMUA',
}) {
  final q = query.trim().toLowerCase();
  return all.where((u) {
    if (q.isNotEmpty &&
        !u.nama.toLowerCase().contains(q) &&
        !u.email.toLowerCase().contains(q)) {
      return false;
    }
    if (role == 'MULTI-ROLE' && u.roles.length < 2) return false;
    if (role == 'ADMIN' && !u.roles.contains(UserRole.admin)) return false;
    if (role == 'DOSEN' && !u.roles.contains(UserRole.dosen)) return false;
    if (role == 'MAHASISWA' && !u.roles.contains(UserRole.mahasiswa)) {
      return false;
    }
    switch (status) {
      case 'AKTIF':
        if (u.status != AccountStatus.aktif) return false;
      case 'NONAKTIF':
        if (u.status != AccountStatus.nonaktif) return false;
      case 'TERKUNCI':
        if (u.status != AccountStatus.terkunci) return false;
    }
    return true;
  }).toList();
}
