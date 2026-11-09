class ProgramStudi {
  const ProgramStudi({
    required this.id,
    required this.nama,
    required this.kode,
    required this.jenjang,
  });

  final String id;
  final String nama;
  final String kode;
  final String jenjang;

  Map<String, Object?> toJson() => {
        'id': id,
        'nama': nama,
        'kode': kode,
        'jenjang': jenjang,
      };
}

class PeriodeAkademik {
  const PeriodeAkademik({
    required this.id,
    required this.nama,
    required this.tahunAkademik,
    required this.semester,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.aktif,
  });

  final String id;
  final String nama;
  final String tahunAkademik;
  final String semester;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final bool aktif;

  Map<String, Object?> toJson() => {
        'id': id,
        'nama': nama,
        'tahun_akademik': tahunAkademik,
        'semester': semester,
        'tanggal_mulai': tanggalMulai.toIso8601String().split('T').first,
        'tanggal_selesai': tanggalSelesai.toIso8601String().split('T').first,
        'aktif': aktif,
      };
}

class Ruangan {
  const Ruangan({
    required this.id,
    required this.kode,
    required this.nama,
    required this.kapasitas,
    this.gedung,
  });

  final String id;
  final String kode;
  final String nama;
  final int kapasitas;
  final String? gedung;

  Map<String, Object?> toJson() => {
        'id': id,
        'kode': kode,
        'nama': nama,
        'kapasitas': kapasitas,
        'gedung': gedung,
      };
}

class MataKuliah {
  const MataKuliah({
    required this.id,
    required this.kode,
    required this.nama,
    required this.sks,
    required this.semester,
    required this.jenis,
    this.sksTeori = 0,
    this.sksPraktikum = 0,
    this.deskripsi,
  });

  final String id;
  final String kode;
  final String nama;
  final int sks;
  final int semester;
  final String jenis;
  final int sksTeori;
  final int sksPraktikum;
  final String? deskripsi;

  Map<String, Object?> toJson() => {
        'id': id,
        'kode': kode,
        'nama': nama,
        'sks': sks,
        'semester': semester,
        'jenis': jenis,
        'sks_teori': sksTeori,
        'sks_praktikum': sksPraktikum,
        'deskripsi': deskripsi,
      };
}

class Kurikulum {
  const Kurikulum({
    required this.id,
    required this.idProgramStudi,
    required this.nama,
    required this.tahun,
    required this.aktif,
    required this.totalSksLulus,
  });

  final String id;
  final String idProgramStudi;
  final String nama;
  final int tahun;
  final bool aktif;
  final int totalSksLulus;

  Map<String, Object?> toJson() => {
        'id': id,
        'id_program_studi': idProgramStudi,
        'nama': nama,
        'tahun': tahun,
        'aktif': aktif,
        'total_sks_lulus': totalSksLulus,
      };
}

class MasterData {
  const MasterData({
    required this.programStudi,
    required this.periode,
    required this.ruangan,
    required this.mataKuliah,
    required this.kurikulum,
  });

  final List<ProgramStudi> programStudi;
  final List<PeriodeAkademik> periode;
  final List<Ruangan> ruangan;
  final List<MataKuliah> mataKuliah;
  final List<Kurikulum> kurikulum;

  Map<String, Object?> toJson() => {
        'program_studi': programStudi.map((e) => e.toJson()).toList(),
        'periode_akademik': periode.map((e) => e.toJson()).toList(),
        'ruangan': ruangan.map((e) => e.toJson()).toList(),
        'mata_kuliah': mataKuliah.map((e) => e.toJson()).toList(),
        'kurikulum': kurikulum.map((e) => e.toJson()).toList(),
      };
}
