class Mahasiswa {
  const Mahasiswa({
    required this.npm,
    required this.idUser,
    required this.namaLengkap,
    required this.idProgramStudi,
    required this.tahunMasuk,
    required this.jenisKelamin,
    required this.status,
    this.tanggalLahir,
    this.idDosenWali,
    this.nik,
    this.namaIbuKandung,
  });

  final String npm;
  final String idUser;
  final String namaLengkap;
  final String idProgramStudi;
  final int tahunMasuk;
  final String jenisKelamin;
  final String status;
  final DateTime? tanggalLahir;
  final String? idDosenWali;
  final String? nik;
  final String? namaIbuKandung;

  Map<String, Object?> toJson() => {
        'npm': npm,
        'id_user': idUser,
        'nama_lengkap': namaLengkap,
        'id_program_studi': idProgramStudi,
        'tahun_masuk': tahunMasuk,
        'jenis_kelamin': jenisKelamin,
        'status': status,
        'tanggal_lahir': tanggalLahir?.toIso8601String().split('T').first,
        'id_dosen_wali': idDosenWali,
        'nik': nik,
        'nama_ibu_kandung': namaIbuKandung,
      };
}

class Dosen {
  const Dosen({
    required this.nidn,
    required this.idUser,
    required this.namaLengkap,
    required this.idProgramStudi,
    required this.status,
    this.gelarAkademik,
    this.jenisKelamin,
    this.tanggalLahir,
  });

  final String nidn;
  final String idUser;
  final String namaLengkap;
  final String idProgramStudi;
  final String status;
  final String? gelarAkademik;
  final String? jenisKelamin;
  final DateTime? tanggalLahir;

  Map<String, Object?> toJson() => {
        'nidn': nidn,
        'id_user': idUser,
        'nama_lengkap': namaLengkap,
        'id_program_studi': idProgramStudi,
        'status': status,
        'gelar_akademik': gelarAkademik,
        'jenis_kelamin': jenisKelamin,
        'tanggal_lahir': tanggalLahir?.toIso8601String().split('T').first,
      };
}

class CreateMahasiswaInput {
  const CreateMahasiswaInput({
    required this.email,
    required this.namaLengkap,
    required this.idProgramStudi,
    required this.tahunMasuk,
    required this.jenisKelamin,
    this.npm,
    this.password,
    this.telepon,
    this.tanggalLahir,
    this.idDosenWali,
    this.nik,
    this.namaIbuKandung,
  });

  final String email;
  final String namaLengkap;
  final String idProgramStudi;
  final int tahunMasuk;
  final String jenisKelamin;
  final String? npm;
  final String? password;
  final String? telepon;
  final DateTime? tanggalLahir;
  final String? idDosenWali;
  final String? nik;
  final String? namaIbuKandung;
}

class CreateDosenInput {
  const CreateDosenInput({
    required this.email,
    required this.nidn,
    required this.namaLengkap,
    required this.idProgramStudi,
    this.password,
    this.telepon,
    this.gelarAkademik,
    this.jenisKelamin,
    this.tanggalLahir,
  });

  final String email;
  final String nidn;
  final String namaLengkap;
  final String idProgramStudi;
  final String? password;
  final String? telepon;
  final String? gelarAkademik;
  final String? jenisKelamin;
  final DateTime? tanggalLahir;
}
