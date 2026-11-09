import '../models/app_user.dart';
import '../models/civitas.dart';
import '../models/dashboard.dart';
import '../models/master_data.dart';
import '../models/pagination.dart';

abstract interface class AuthRepository {
  Future<AppUser?> authenticate(String identifier, String password);
  Future<AppUser?> findById(String id);
  Future<void> recordLogin(String userId, {String? ip, String? userAgent});
}

abstract interface class UserRepository {
  Future<Page<AppUser>> list(AppUser actor, PageRequest request, {String? role});
  Future<AppUser?> findById(String id);
  Future<AppUser> create(AppUser actor, {
    required String email,
    required String namaLengkap,
    required List<String> roles,
    String? telepon,
    String? password,
  });
  Future<AppUser> update(
    AppUser actor,
    String id, {
    String? namaLengkap,
    String? telepon,
    String? urlAvatar,
    bool? aktif,
    List<String>? roles,
  });
  Future<List<String>> roles(AppUser actor);
}

abstract interface class MasterRepository {
  Future<List<ProgramStudi>> programStudi(AppUser actor);
  Future<List<PeriodeAkademik>> periode(AppUser actor);
  Future<List<Ruangan>> ruangan(AppUser actor);
  Future<List<MataKuliah>> mataKuliah(AppUser actor);
  Future<List<Kurikulum>> kurikulum(AppUser actor);
  Future<ProgramStudi> saveProgramStudi(AppUser actor, {String? id, required String kode, required String nama, required String jenjang});
  Future<PeriodeAkademik> savePeriode(AppUser actor, {String? id, required String nama, required String tahunAkademik, required String semester, required DateTime tanggalMulai, required DateTime tanggalSelesai, bool aktif = false});
  Future<PeriodeAkademik> activatePeriode(AppUser actor, String id);
  Future<Ruangan> saveRuangan(AppUser actor, {String? id, required String kode, required String nama, required int kapasitas, String? gedung, bool aktif = true});
}

abstract interface class CivitasRepository {
  Future<Page<Mahasiswa>> listMahasiswa(AppUser actor, PageRequest request, {String? status});
  Future<Page<Dosen>> listDosen(AppUser actor, PageRequest request, {String? status});
  Future<String> nextNpm(AppUser actor, String prefix);
  Future<Mahasiswa> createMahasiswa(AppUser actor, CreateMahasiswaInput input);
  Future<Dosen> createDosen(AppUser actor, CreateDosenInput input);
  Future<Mahasiswa> updateMahasiswa(
    AppUser actor,
    String npm, {
    String? namaLengkap,
    String? status,
    String? idDosenWali,
    String? telepon,
  });
  Future<Dosen> updateDosen(AppUser actor, String nidn, {String? namaLengkap, String? status, String? telepon});
}

abstract interface class DashboardRepository {
  Future<DashboardStats> stats(AppUser actor);
}

abstract interface class AuditRepository {
  Future<Page<AuditLog>> listLogs(AppUser actor, PageRequest request);
}
