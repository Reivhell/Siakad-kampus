/// Sesi login, termasuk JWT token dari backend.
class AppSession {
  final String npm;
  final AppRole role;
  final String? token;
  final Map<String, dynamic> user;

  const AppSession({
    required this.npm,
    required this.role,
    this.token,
    this.user = const {},
  });

  List<String> get roles {
    final r = user['roles'];
    if (r is List) return r.whereType<String>().toList(growable: false);
    return const [];
  }

  String get displayName {
    final n = user['nama_lengkap'] ?? user['name'] ?? user['email'];
    return (n is String && n.trim().isNotEmpty) ? n.trim() : npm;
  }
}

/// Peran yang dikenal gerbang.
enum AppRole { admin, dosen, mahasiswa }

/// Tentukan peran utama dari payload user (klaim `roles` dari backend/JWT).
AppRole resolveRole(String identifier, {Map<String, dynamic>? user}) {
  final roles = <String>[];
  final raw = user?['roles'];
  if (raw is List) {
    for (final r in raw) {
      if (r is String) roles.add(r.toUpperCase());
    }
  }
  if (roles.contains('ADMIN') || roles.contains('SUPER_ADMIN')) {
    return AppRole.admin;
  }
  if (roles.contains('DOSEN') || roles.contains('LECTURER')) {
    return AppRole.dosen;
  }
  if (roles.contains('MAHASISWA') || roles.contains('STUDENT')) {
    return AppRole.mahasiswa;
  }
  // Fallback aman: tanpa klaim peran yang dikenal, jangan memberi akses admin.
  return AppRole.mahasiswa;
}
