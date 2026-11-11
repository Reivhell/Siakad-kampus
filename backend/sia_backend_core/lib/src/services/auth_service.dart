import '../auth/token_service.dart';
import '../exceptions/app_exception.dart';
import '../models/app_user.dart';
import '../repositories/contracts.dart';

class AuthService {
  AuthService({required AuthRepository repository, required TokenService tokens})
      : _repository = repository,
        _tokens = tokens;

  final AuthRepository _repository;
  final TokenService _tokens;

  Future<AuthResult> login(
    String identifier,
    String password, {
    String? ip,
    String? userAgent,
  }) async {
    final id = identifier.trim().toLowerCase();
    if (id.isEmpty || password.isEmpty) {
      throw const ValidationException('Email/NPM/NIDN dan password wajib diisi.');
    }

    final user = await _repository.authenticate(id, password);
    if (user == null) {
      throw const UnauthorizedException('Kredensial salah.');
    }
    if (!user.aktif) {
      throw const ForbiddenException('Akun tidak aktif.');
    }

    await _repository.recordLogin(user.id, ip: ip, userAgent: userAgent);
    return _tokens.issue(user);
  }

  Future<AppUser> me(String token) async {
    final claims = _tokens.verify(token);
    final user = await _repository.findById(claims.sub);
    if (user == null) {
      throw const UnauthorizedException('Pengguna tidak ditemukan.');
    }
    if (!user.aktif) {
      throw const ForbiddenException('Akun tidak aktif.');
    }
    return user;
  }

  TokenClaims verify(String token) => _tokens.verify(token);
}
