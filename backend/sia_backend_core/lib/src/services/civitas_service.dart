import '../exceptions/app_exception.dart';
import '../models/app_user.dart';
import '../models/civitas.dart';
import '../models/pagination.dart';
import '../repositories/contracts.dart';

const _mahasiswaStatus = {'AKTIF', 'CUTI', 'LULUS', 'DO'};
const _dosenStatus = {'AKTIF', 'TIDAK_AKTIF'};
const _gender = {'L', 'P'};

class CivitasService {
  CivitasService(this._repository);

  final CivitasRepository _repository;

  Future<Page<Mahasiswa>> listMahasiswa(AppUser actor, PageRequest request, {String? status}) {
    _requireStaff(actor);
    if (status != null && !_mahasiswaStatus.contains(status)) {
      throw const ValidationException('Status mahasiswa tidak valid.');
    }
    return _repository.listMahasiswa(actor, request.normalized(), status: status);
  }

  Future<Page<Dosen>> listDosen(AppUser actor, PageRequest request, {String? status}) {
    _requireStaff(actor);
    if (status != null && !_dosenStatus.contains(status)) {
      throw const ValidationException('Status dosen tidak valid.');
    }
    return _repository.listDosen(actor, request.normalized(), status: status);
  }

  Future<String> nextNpm(AppUser actor, String prefix) {
    _requireAdmin(actor);
    if (!RegExp(r'^[0-9]{7}$').hasMatch(prefix)) {
      throw const ValidationException('Prefix NPM harus 7 digit.');
    }
    return _repository.nextNpm(actor, prefix);
  }

  Future<Mahasiswa> createMahasiswa(AppUser actor, CreateMahasiswaInput input) async {
    _requireAdmin(actor);
    _validateEmail(input.email);
    if (input.namaLengkap.trim().length < 3) {
      throw const ValidationException('Nama minimal 3 karakter.');
    }
    if (!_gender.contains(input.jenisKelamin)) {
      throw const ValidationException('Jenis kelamin harus L atau P.');
    }
    final year = DateTime.now().year;
    if (input.tahunMasuk < 2000 || input.tahunMasuk > year + 1) {
      throw const ValidationException('Tahun masuk tidak valid.');
    }
    if (input.npm != null && !RegExp(r'^[0-9]{10}$').hasMatch(input.npm!)) {
      throw const ValidationException('NPM harus tepat 10 digit angka.');
    }
    if (input.password != null && input.password!.length < 8) {
      throw const ValidationException('Password minimal 8 karakter.');
    }
    return _repository.createMahasiswa(actor, input);
  }

  Future<Dosen> createDosen(AppUser actor, CreateDosenInput input) async {
    _requireAdmin(actor);
    _validateEmail(input.email);
    if (!RegExp(r'^[0-9]{8,}$').hasMatch(input.nidn)) {
      throw const ValidationException('NIDN minimal 8 digit angka.');
    }
    if (input.namaLengkap.trim().length < 3) {
      throw const ValidationException('Nama minimal 3 karakter.');
    }
    if (input.password != null && input.password!.length < 8) {
      throw const ValidationException('Password minimal 8 karakter.');
    }
    return _repository.createDosen(actor, input);
  }

  Future<Mahasiswa> updateMahasiswa(
    AppUser actor,
    String npm, {
    String? namaLengkap,
    String? status,
    String? idDosenWali,
    String? telepon,
  }) {
    _requireAdmin(actor);
    if (status != null && !_mahasiswaStatus.contains(status)) {
      throw const ValidationException('Status mahasiswa tidak valid.');
    }
    if (namaLengkap != null && namaLengkap.trim().length < 3) {
      throw const ValidationException('Nama minimal 3 karakter.');
    }
    return _repository.updateMahasiswa(
      actor,
      npm,
      namaLengkap: namaLengkap?.trim(),
      status: status,
      idDosenWali: idDosenWali,
      telepon: telepon?.trim(),
    );
  }

  Future<Dosen> updateDosen(
    AppUser actor,
    String nidn, {
    String? namaLengkap,
    String? status,
    String? telepon,
  }) {
    _requireAdmin(actor);
    if (status != null && !_dosenStatus.contains(status)) {
      throw const ValidationException('Status dosen tidak valid.');
    }
    if (namaLengkap != null && namaLengkap.trim().length < 3) {
      throw const ValidationException('Nama minimal 3 karakter.');
    }
    return _repository.updateDosen(
      actor,
      nidn,
      namaLengkap: namaLengkap?.trim(),
      status: status,
      telepon: telepon?.trim(),
    );
  }

  void _requireStaff(AppUser actor) {
    if (!actor.roles.any((r) => r == 'ADMIN' || r == 'DOSEN')) {
      throw const ForbiddenException();
    }
  }

  void _requireAdmin(AppUser actor) {
    if (!actor.isAdmin) throw const ForbiddenException();
  }

  void _validateEmail(String email) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      throw const ValidationException('Format email tidak valid.');
    }
  }
}
