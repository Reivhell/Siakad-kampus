import '../exceptions/app_exception.dart';
import '../models/app_user.dart';
import '../models/pagination.dart';
import '../repositories/contracts.dart';

const _roles = {'ADMIN', 'DOSEN', 'MAHASISWA'};

class UserService {
  UserService(this._repository);

  final UserRepository _repository;

  Future<Page<AppUser>> list(AppUser actor, PageRequest request, {String? role}) {
    _requireAdmin(actor);
    return _repository.list(actor, request.normalized(), role: role);
  }

  Future<AppUser> get(AppUser actor, String id) {
    _requireAdmin(actor);
    return _repository.findById(id).then((user) {
      if (user == null) throw const NotFoundException('Pengguna tidak ditemukan.');
      return user;
    });
  }

  Future<AppUser> create(
    AppUser actor, {
    required String email,
    required String namaLengkap,
    required List<String> roles,
    String? telepon,
    String? password,
  }) async {
    _requireAdmin(actor);
    final cleanEmail = email.trim().toLowerCase();
    if (!_email.hasMatch(cleanEmail)) {
      throw const ValidationException('Format email tidak valid.');
    }
    if (namaLengkap.trim().length < 3) {
      throw const ValidationException('Nama minimal 3 karakter.');
    }
    final cleanRoles = roles.map((e) => e.toUpperCase()).toSet().toList();
    if (cleanRoles.isEmpty || !cleanRoles.every(_roles.contains)) {
      throw const ValidationException('Role harus ADMIN, DOSEN, atau MAHASISWA.');
    }
    if (password != null && password.length < 8) {
      throw const ValidationException('Password minimal 8 karakter.');
    }
    return _repository.create(
      actor,
      email: cleanEmail,
      namaLengkap: namaLengkap.trim(),
      roles: cleanRoles,
      telepon: telepon?.trim(),
      password: password,
    );
  }

  Future<AppUser> update(
    AppUser actor,
    String id, {
    String? namaLengkap,
    String? telepon,
    String? urlAvatar,
    bool? aktif,
    List<String>? roles,
  }) async {
    _requireAdmin(actor);
    if (namaLengkap != null && namaLengkap.trim().length < 3) {
      throw const ValidationException('Nama minimal 3 karakter.');
    }
    final cleanRoles = roles?.map((e) => e.toUpperCase()).toSet().toList();
    if (cleanRoles != null && (cleanRoles.isEmpty || !cleanRoles.every(_roles.contains))) {
      throw const ValidationException('Role harus ADMIN, DOSEN, atau MAHASISWA.');
    }
    return _repository.update(
      actor,
      id,
      namaLengkap: namaLengkap?.trim(),
      telepon: telepon?.trim(),
      urlAvatar: urlAvatar,
      aktif: aktif,
      roles: cleanRoles,
    );
  }

  Future<List<String>> roles(AppUser actor) {
    _requireAdmin(actor);
    return _repository.roles(actor);
  }

  void _requireAdmin(AppUser actor) {
    if (!actor.isAdmin) throw const ForbiddenException();
  }
}

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
