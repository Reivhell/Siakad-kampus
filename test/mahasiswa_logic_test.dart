import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/features/mahasiswa/models/mahasiswa_models.dart';
import 'package:siakad_kampus/features/mahasiswa/repositories/mahasiswa_repository.dart';
import 'package:siakad_kampus/features/mahasiswa/seed/mahasiswa_seed.dart';

Kelas _kelas({
  String id = 'k1',
  String kodeMk = 'TI1',
  int kapasitas = 30,
  int terdaftar = 10,
  int hari = 1,
  String mulai = '08:00',
  String selesai = '09:40',
  int sks = 3,
}) => Kelas(
  id: id,
  kode: 'TI1-A',
  kodeMk: kodeMk,
  namaMk: 'MK $kodeMk',
  sks: sks,
  dosen: 'Dosen',
  kapasitas: kapasitas,
  jadwal: [
    JadwalSlot(hari: hari, jamMulai: mulai, jamSelesai: selesai, ruangan: 'R-1'),
  ],
  periodeId: periodeAktifId,
  jumlahTerdaftar: terdaftar,
);

void main() {
  group('maxSks', () {
    test('semester 1–2 atau IPS null selalu 20', () {
      expect(maxSks(semester: 1, ipsLalu: null), 20);
      expect(maxSks(semester: 2, ipsLalu: 3.9), 20);
      expect(maxSks(semester: 5, ipsLalu: null), 20);
    });

    test('plafon bertingkat mengikuti IPS lalu', () {
      expect(maxSks(semester: 5, ipsLalu: 3.5), 24);
      expect(maxSks(semester: 5, ipsLalu: 3.0), 24);
      expect(maxSks(semester: 5, ipsLalu: 2.8), 21);
      expect(maxSks(semester: 5, ipsLalu: 2.0), 18);
      expect(maxSks(semester: 5, ipsLalu: 1.7), 15);
      expect(maxSks(semester: 5, ipsLalu: 1.0), 12);
    });
  });

  test('IPS & SKS lulus hanya menghitung huruf yang ada', () {
    final rows = [
      const NilaiRecord(
        npm: 'x',
        periodeId: 'p',
        kodeMk: 'A',
        namaMk: 'A',
        sks: 3,
        huruf: 'A',
        sudahFinal: true,
      ),
      const NilaiRecord(
        npm: 'x',
        periodeId: 'p',
        kodeMk: 'B',
        namaMk: 'B',
        sks: 3,
        huruf: 'B',
        sudahFinal: true,
      ),
      const NilaiRecord(
        npm: 'x',
        periodeId: 'p',
        kodeMk: 'C',
        namaMk: 'C',
        sks: 3,
      ),
    ];
    expect(ipsDari(rows), 3.5);
    expect(sksLulus(rows), 6);
  });

  test('presensi: belum dicatat dosen tidak menjadi ALPHA', () {
    final rows = [
      const PresensiRecord(
        npm: 'x',
        kelasId: 'k',
        pertemuanKe: 1,
        tanggal: '1',
        status: 'HADIR',
      ),
      const PresensiRecord(
        npm: 'x',
        kelasId: 'k',
        pertemuanKe: 2,
        tanggal: '2',
        status: 'HADIR',
      ),
      const PresensiRecord(
        npm: 'x',
        kelasId: 'k',
        pertemuanKe: 3,
        tanggal: '3',
      ),
      const PresensiRecord(
        npm: 'x',
        kelasId: 'k',
        pertemuanKe: 4,
        tanggal: '4',
      ),
    ];
    final r = rekapPresensi('k', rows);
    expect(r.tercatat, 2);
    expect(r.persen, 100);
    expect(r.kritis, isFalse);
  });

  group('validasiTambahKrs', () {
    test('menolak bila gate UKT belum lolos', () {
      final hasil = validasiTambahKrs(
        kandidat: _kelas(),
        terpilih: const [],
        sksTerpilih: 0,
        plafonSks: 24,
        gate: const GateKrs.blokir('UKT belum lunas.'),
        statusMahasiswa: StatusMahasiswa.aktif,
      );
      expect(hasil.ok, isFalse);
      expect(hasil.pesan, contains('UKT'));
    });

    test('menolak status non-aktif', () {
      final hasil = validasiTambahKrs(
        kandidat: _kelas(),
        terpilih: const [],
        sksTerpilih: 0,
        plafonSks: 24,
        gate: const GateKrs.lolos(),
        statusMahasiswa: StatusMahasiswa.cuti,
      );
      expect(hasil.ok, isFalse);
      expect(hasil.pesan, contains('CUTI'));
    });

    test('menolak kelas penuh', () {
      final hasil = validasiTambahKrs(
        kandidat: _kelas(kapasitas: 30, terdaftar: 30),
        terpilih: const [],
        sksTerpilih: 0,
        plafonSks: 24,
        gate: const GateKrs.lolos(),
        statusMahasiswa: StatusMahasiswa.aktif,
      );
      expect(hasil.ok, isFalse);
      expect(hasil.pesan, contains('penuh'));
    });

    test('menolak MK ganda', () {
      final hasil = validasiTambahKrs(
        kandidat: _kelas(id: 'k2', kodeMk: 'TI1'),
        terpilih: [_kelas(id: 'k1', kodeMk: 'TI1')],
        sksTerpilih: 3,
        plafonSks: 24,
        gate: const GateKrs.lolos(),
        statusMahasiswa: StatusMahasiswa.aktif,
      );
      expect(hasil.ok, isFalse);
      expect(hasil.pesan, contains('ganda'));
    });

    test('menolak melebihi plafon SKS', () {
      final hasil = validasiTambahKrs(
        kandidat: _kelas(id: 'k2', kodeMk: 'TI2'),
        terpilih: [_kelas(id: 'k1', kodeMk: 'TI1')],
        sksTerpilih: 21,
        plafonSks: 21,
        gate: const GateKrs.lolos(),
        statusMahasiswa: StatusMahasiswa.aktif,
      );
      expect(hasil.ok, isFalse);
      expect(hasil.pesan, contains('plafon'));
    });

    test('menolak bentrok jadwal', () {
      final hasil = validasiTambahKrs(
        kandidat: _kelas(
          id: 'k2',
          kodeMk: 'TI2',
          hari: 1,
          mulai: '09:00',
          selesai: '10:30',
        ),
        terpilih: [
          _kelas(id: 'k1', kodeMk: 'TI1', hari: 1, mulai: '08:00', selesai: '09:40'),
        ],
        sksTerpilih: 3,
        plafonSks: 24,
        gate: const GateKrs.lolos(),
        statusMahasiswa: StatusMahasiswa.aktif,
      );
      expect(hasil.ok, isFalse);
      expect(hasil.pesan, contains('Bentrok'));
    });

    test('menerima kelas yang valid', () {
      final hasil = validasiTambahKrs(
        kandidat: _kelas(id: 'k2', kodeMk: 'TI2', hari: 2),
        terpilih: [_kelas(id: 'k1', kodeMk: 'TI1', hari: 1)],
        sksTerpilih: 3,
        plafonSks: 24,
        gate: const GateKrs.lolos(),
        statusMahasiswa: StatusMahasiswa.aktif,
      );
      expect(hasil.ok, isTrue);
    });
  });

  group('gate UKT/SPP', () {
    test('Siti lunas → KRS terbuka', () {
      final repo = MahasiswaRepository.seed();
      expect(repo.gate(npmSiti).lolos, isTrue);
    });

    test('Reza belum lunas → KRS terblokir', () {
      final repo = MahasiswaRepository.seed();
      final gate = repo.gate(npmReza);
      expect(gate.lolos, isFalse);
      expect(gate.pesan, contains('UKT/SPP'));
    });

    test('dispensasi admin membuka blokir', () {
      final repo = MahasiswaRepository.seed();
      repo.setDispensasi(npmReza, true);
      expect(repo.gate(npmReza).lolos, isTrue);
      expect(repo.dispensasiAktif(npmReza), isTrue);
    });

    test('Reza tidak bisa menambah KRS sebelum lunas', () {
      final repo = MahasiswaRepository.seed();
      final err = repo.tambahKrs(npmReza, 'K-TI301-A');
      expect(err, isNotNull);
      expect(err, contains('UKT'));
      expect(repo.kelasDipilih(npmReza), isEmpty);
    });
  });

  group('alur KRS', () {
    test('tambah → ajukan → disetujui admin', () {
      final repo = MahasiswaRepository.seed();
      repo.setDispensasi(npmReza, true);

      expect(repo.tambahKrs(npmReza, 'K-TI301-A'), isNull);
      expect(repo.statusKrs(npmReza), StatusKrs.draft);
      expect(repo.sksDipilih(npmReza), 3);

      expect(repo.ajukanKrs(npmReza), isNull);
      expect(repo.statusKrs(npmReza), StatusKrs.menungguApproval);

      repo.setujuiKrs(npmReza);
      expect(repo.statusKrs(npmReza), StatusKrs.aktif);
      expect(repo.jadwalMinggu(npmReza).length, 1);
    });

    test('kelas penuh ditolak', () {
      final repo = MahasiswaRepository.seed();
      repo.setDispensasi(npmReza, true);
      final err = repo.tambahKrs(npmReza, 'K-TI309-E');
      expect(err, contains('penuh'));
    });

    test('bentrok jadwal ditolak', () {
      final repo = MahasiswaRepository.seed();
      repo.setDispensasi(npmReza, true);
      expect(repo.tambahKrs(npmReza, 'K-TI301-A'), isNull);
      final err = repo.tambahKrs(npmReza, 'K-TI310-A');
      expect(err, contains('Bentrok'));
    });

    test('melebihi plafon 20 SKS ditolak (IPS lalu null)', () {
      final repo = MahasiswaRepository.seed();
      repo.setDispensasi(npmReza, true);
      for (final id in [
        'K-TI301-A',
        'K-TI302-B',
        'K-TI303-A',
        'K-TI304-B',
        'K-TI305-A',
        'K-TI306-A',
      ]) {
        expect(repo.tambahKrs(npmReza, id), isNull, reason: id);
      }
      expect(repo.sksDipilih(npmReza), 18);
      final err = repo.tambahKrs(npmReza, 'K-TI307-A');
      expect(err, contains('plafon'));
    });

    test('batalkan KRS mengosongkan pilihan', () {
      final repo = MahasiswaRepository.seed();
      repo.setDispensasi(npmReza, true);
      expect(repo.tambahKrs(npmReza, 'K-TI301-A'), isNull);
      expect(repo.batalkanKrs(npmReza), isNull);
      expect(repo.kelasDipilih(npmReza), isEmpty);
      expect(repo.statusKrs(npmReza), isNull);
    });
  });

  group('data akademik Siti', () {
    test('IPK & SKS lulus terhitung', () {
      final repo = MahasiswaRepository.seed();
      expect(repo.ipk(npmSiti), closeTo(3.46, 0.01));
      expect(repo.sksLulusMahasiswa(npmSiti), 66);
      expect(repo.sksTempuh(npmSiti), 78);
      expect(repo.plafonSks(npmSiti), 24);
    });

    test('presensi Jaringan Komputer kritis (<75%)', () {
      final repo = MahasiswaRepository.seed();
      final rekap = repo.rekapSemua(npmSiti);
      final jaringan = rekap.firstWhere((r) => r.kelasId == 'K-TI302-B');
      expect(jaringan.persen, lessThan(75));
      expect(jaringan.kritis, isTrue);
      expect(repo.kelasPresensiKritis(npmSiti).length, 1);
    });

    test('profil edit terbatas telepon/avatar', () {
      final repo = MahasiswaRepository.seed();
      expect(repo.updateProfil(npmSiti, telepon: '0812'), isNotNull);
      expect(repo.updateProfil(npmSiti, telepon: '+62 812-0000-0000'), isNull);
      expect(repo.profile(npmSiti)!.telepon, '+62 812-0000-0000');
    });
  });
}
