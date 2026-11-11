class DashboardStats {
  const DashboardStats({
    required this.mahasiswaAktif,
    required this.dosenAktif,
    required this.programStudi,
    required this.krsAktif,
    required this.krsMenunggu,
    required this.suratMenunggu,
    required this.aktivitasHariIni,
  });

  final int mahasiswaAktif;
  final int dosenAktif;
  final int programStudi;
  final int krsAktif;
  final int krsMenunggu;
  final int suratMenunggu;
  final int aktivitasHariIni;

  Map<String, Object?> toJson() => {
        'mahasiswa_aktif': mahasiswaAktif,
        'dosen_aktif': dosenAktif,
        'program_studi': programStudi,
        'krs_aktif': krsAktif,
        'krs_menunggu': krsMenunggu,
        'surat_menunggu': suratMenunggu,
        'aktivitas_hari_ini': aktivitasHariIni,
      };
}

class AuditLog {
  const AuditLog({
    required this.id,
    required this.aksi,
    required this.entitas,
    required this.dibuatPada,
    this.idUser,
    this.idEntitas,
    this.metadata,
    this.alamatIp,
  });

  final String id;
  final String aksi;
  final String entitas;
  final DateTime dibuatPada;
  final String? idUser;
  final String? idEntitas;
  final Map<String, Object?>? metadata;
  final String? alamatIp;

  Map<String, Object?> toJson() => {
        'id': id,
        'id_user': idUser,
        'aksi': aksi,
        'entitas': entitas,
        'id_entitas': idEntitas,
        'metadata': metadata,
        'alamat_ip': alamatIp,
        'dibuat_pada': dibuatPada.toUtc().toIso8601String(),
      };
}
