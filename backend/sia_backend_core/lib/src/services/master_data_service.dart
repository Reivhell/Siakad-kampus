import '../exceptions/app_exception.dart';
import '../models/app_user.dart';
import '../models/master_data.dart';
import '../repositories/contracts.dart';

class MasterDataService {
  MasterDataService(this._repository);

  final MasterRepository _repository;

  Future<MasterData> all(AppUser actor) async {
    if (actor.roles.isEmpty) throw const ForbiddenException();
    final results = await Future.wait([
      _repository.programStudi(actor),
      _repository.periode(actor),
      _repository.ruangan(actor),
      _repository.mataKuliah(actor),
      _repository.kurikulum(actor),
    ]);
    return MasterData(
      programStudi: results[0] as List<ProgramStudi>,
      periode: results[1] as List<PeriodeAkademik>,
      ruangan: results[2] as List<Ruangan>,
      mataKuliah: results[3] as List<MataKuliah>,
      kurikulum: results[4] as List<Kurikulum>,
    );
  }

  Future<ProgramStudi> saveProgramStudi(
    AppUser actor, {
    String? id,
    required String kode,
    required String nama,
    required String jenjang,
  }) {
    _requireAdmin(actor);
    if (kode.trim().isEmpty || nama.trim().length < 3) {
      throw const ValidationException('Kode dan nama prodi wajib diisi.');
    }
    return _repository.saveProgramStudi(
      actor,
      id: id,
      kode: kode.trim(),
      nama: nama.trim(),
      jenjang: jenjang.trim(),
    );
  }

  Future<PeriodeAkademik> savePeriode(
    AppUser actor, {
    String? id,
    required String nama,
    required String tahunAkademik,
    required String semester,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    bool aktif = false,
  }) {
    _requireAdmin(actor);
    if (nama.trim().length < 3) {
      throw const ValidationException('Nama periode wajib diisi.');
    }
    if (!tanggalSelesai.isAfter(tanggalMulai)) {
      throw const ValidationException('Tanggal selesai harus setelah tanggal mulai.');
    }
    return _repository.savePeriode(
      actor,
      id: id,
      nama: nama.trim(),
      tahunAkademik: tahunAkademik.trim(),
      semester: semester.trim().toUpperCase(),
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      aktif: aktif,
    );
  }

  Future<PeriodeAkademik> activatePeriode(AppUser actor, String id) {
    _requireAdmin(actor);
    if (id.trim().isEmpty) throw const ValidationException('ID periode wajib diisi.');
    return _repository.activatePeriode(actor, id.trim());
  }

  Future<Ruangan> saveRuangan(
    AppUser actor, {
    String? id,
    required String kode,
    required String nama,
    required int kapasitas,
    String? gedung,
    bool aktif = true,
  }) {
    _requireAdmin(actor);
    if (kode.trim().isEmpty || nama.trim().length < 2) {
      throw const ValidationException('Kode dan nama ruangan wajib diisi.');
    }
    if (kapasitas <= 0) throw const ValidationException('Kapasitas harus > 0.');
    return _repository.saveRuangan(
      actor,
      id: id,
      kode: kode.trim(),
      nama: nama.trim(),
      kapasitas: kapasitas,
      gedung: gedung?.trim(),
      aktif: aktif,
    );
  }

  void _requireAdmin(AppUser actor) {
    if (!actor.isAdmin) throw const ForbiddenException();
  }
}
