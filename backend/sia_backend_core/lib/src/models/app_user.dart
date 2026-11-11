class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.namaLengkap,
    this.telepon,
    this.urlAvatar,
    this.aktif = true,
    this.roles = const [],
  });

  final String id;
  final String email;
  final String namaLengkap;
  final String? telepon;
  final String? urlAvatar;
  final bool aktif;
  final List<String> roles;

  bool get isAdmin => roles.contains('ADMIN');

  Map<String, Object?> toJson() => {
        'id': id,
        'email': email,
        'nama_lengkap': namaLengkap,
        'telepon': telepon,
        'url_avatar': urlAvatar,
        'aktif': aktif,
        'roles': roles,
      };
}

class AuthResult {
  const AuthResult({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final DateTime expiresAt;
  final AppUser user;

  Map<String, Object?> toJson() => {
        'access_token': token,
        'expires_at': expiresAt.toUtc().toIso8601String(),
        'user': user.toJson(),
      };
}
