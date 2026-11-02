import 'package:flutter/foundation.dart';

import '../../admin/models/app_user.dart';
import '../../admin/models/users_seed.dart';

/// Akun sesi aktif. `npm` hanya terisi untuk role mahasiswa.
class AuthAccount {
  final AppUser user;
  final String? npm;

  const AuthAccount({required this.user, this.npm});

  bool get isAdmin => user.roles.contains(UserRole.admin);
  bool get isMahasiswa => user.roles.contains(UserRole.mahasiswa);
  bool get isDosen => user.roles.contains(UserRole.dosen);
}

class AuthResult {
  final AuthAccount? account;
  final String? error;

  const AuthResult.ok(this.account) : error = null;
  const AuthResult.fail(this.error) : account = null;

  bool get sukses => account != null;
}

/// Auth seed-lokal (pengganti Supabase Auth pada MVP).
///
/// Password demo berbeda per role dan HANYA untuk membangun alur login;
/// pada fase backend kredensial dipindah ke Supabase Auth (§14) dan
/// password plaintext tidak pernah disimpan.
class AuthRepository {
  final List<AppUser> users;
  final Map<String, String> passwordByUserId;
  final Map<String, String> npmByUserId;

  AuthRepository({
    required this.users,
    required this.passwordByUserId,
    required this.npmByUserId,
  });

  factory AuthRepository.seed() {
    final users = seedUsers();
    return AuthRepository(
      users: users,
      passwordByUserId: {
        for (final u in users) u.id: _passwordForRole(u),
      },
      npmByUserId: const {
        'u-mhs-1': '2410010015',
        'u-mhs-2': '2510010002',
        'u-mhs-3': '2410010016',
      },
    );
  }

  static String _passwordForRole(AppUser u) {
    if (u.roles.contains(UserRole.admin)) return 'Admin123!';
    if (u.roles.contains(UserRole.mahasiswa)) return 'Mahasiswa123!';
    return 'Dosen123!';
  }

  /// Password demo untuk ditampilkan di layar login (build demo).
  String? demoPasswordFor(AppUser u) => passwordByUserId[u.id];

  AuthResult signIn(String identifier, String password) {
    final id = identifier.trim().toLowerCase();
    if (id.isEmpty || password.isEmpty) {
      return const AuthResult.fail('Email/NPM dan password wajib diisi.');
    }

    AppUser? user;
    for (final u in users) {
      if (u.email.toLowerCase() == id) {
        user = u;
        break;
      }
      if (npmByUserId[u.id] == id) {
        user = u;
        break;
      }
    }
    if (user == null) {
      return const AuthResult.fail('Akun tidak ditemukan.');
    }
    if (user.status == AccountStatus.terkunci) {
      return const AuthResult.fail(
        'Akun terkunci. Hubungi administrator untuk membuka akses.',
      );
    }
    if (user.status == AccountStatus.nonaktif) {
      return const AuthResult.fail(
        'Akun nonaktif. Hubungi administrator.',
      );
    }
    if (passwordByUserId[user.id] != password) {
      return const AuthResult.fail('Password salah.');
    }
    if (user.roles.contains(UserRole.dosen) &&
        !user.roles.contains(UserRole.admin) &&
        !user.roles.contains(UserRole.mahasiswa)) {
      return const AuthResult.fail(
        'Portal dosen belum tersedia pada MVP ini.',
      );
    }
    return AuthResult.ok(
      AuthAccount(user: user, npm: npmByUserId[user.id]),
    );
  }
}

/// Sesi aplikasi — satu sumber kebenaran untuk guard navigasi.
class AuthSession extends ChangeNotifier {
  AuthAccount? _account;

  AuthAccount? get account => _account;

  bool get hasSession => _account != null;

  void signIn(AuthAccount account) {
    _account = account;
    notifyListeners();
  }

  void signOut() {
    _account = null;
    notifyListeners();
  }
}
