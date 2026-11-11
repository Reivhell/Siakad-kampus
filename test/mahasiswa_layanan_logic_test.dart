import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/features/mahasiswa/models/mahasiswa_layanan_models.dart';
import 'package:siakad_kampus/features/mahasiswa/repositories/mahasiswa_repository.dart';
import 'package:siakad_kampus/features/mahasiswa/seed/mahasiswa_seed.dart';

void main() {
  group('kurikulum & transkrip', () {
    test('kurikulum TI berjumlah 144 SKS / 48 mata kuliah', () {
      final repo = MahasiswaRepository.seed();
      expect(repo.kurikulum.length, 48);
      expect(repo.totalSksKurikulum, 144);
    });

    test('progress Siti membedakan lulus, berjalan, dan belum', () {
      final repo = MahasiswaRepository.seed();
      final rows = repo.kurikulumProgress(npmSiti);
      expect(rows.length, 48);
      expect(rows.where((r) => r.status == StatusKurikulum.lulus).length, 22);
      expect(rows.where((r) => r.status == StatusKurikulum.berjalan).length, 4);
      expect(rows.where((r) => r.status == StatusKurikulum.belum).length, 22);
      expect(repo.sksKurikulumLulus(npmSiti), 64);
      final ti101 = rows.firstWhere((r) => r.mk.kode == 'TI101');
      expect(ti101.status, StatusKurikulum.lulus);
      expect(ti101.huruf, 'A');
      final ti305 = rows.firstWhere((r) => r.mk.kode == 'TI305');
      expect(ti305.status, StatusKurikulum.berjalan);
    });

    test('transkrip dikelompokkan per periode, terbaru dulu', () {
      final repo = MahasiswaRepository.seed();
      final rows = repo.transkripPeriode(npmSiti);
      expect(rows.length, 5);
      expect(rows.first.periodeId, periodeAktifId);
      expect(rows.first.rows.length, 6);
      expect(rows.first.ips, isNotNull);
    });

    test('Ayu memiliki 144 SKS lulus dari 8 semester', () {
      final repo = MahasiswaRepository.seed();
      expect(repo.sksLulusMahasiswa(npmAyu), 144);
      expect(repo.ipk(npmAyu), greaterThan(2.0));
      expect(repo.transkripPeriode(npmAyu).length, 8);
    });
  });

  group('yudisium', () {
    test('Siti belum memenuhi syarat dan ditolak mengajukan', () {
      final repo = MahasiswaRepository.seed();
      final cek = repo.cekYudisium(npmSiti);
      expect(cek.sksLulus, 66);
      expect(cek.sksTarget, 144);
      expect(cek.semuaTercapai, isFalse);
      expect(cek.kekurangan, isNotEmpty);
      expect(repo.ajukanYudisium(npmSiti), contains('Belum memenuhi syarat'));
      expect(repo.yudisiumMahasiswa(npmSiti), isNull);
    });

    test('Ayu memenuhi syarat dan dapat mengajukan sekali', () {
      final repo = MahasiswaRepository.seed();
      final cek = repo.cekYudisium(npmAyu);
      expect(cek.sksCukup, isTrue);
      expect(cek.ipkCukup, isTrue);
      expect(cek.tanpaE, isTrue);
      expect(cek.statusAktif, isTrue);
      expect(cek.bebasTanggungan, isTrue);
      expect(cek.bisaAjukan, isTrue);

      expect(repo.ajukanYudisium(npmAyu), isNull);
      expect(repo.yudisiumMahasiswa(npmAyu)!.status, StatusPengajuan.pengajuan);
      expect(repo.ajukanYudisium(npmAyu), contains('sudah ada'));
    });
  });

  group('bimbingan & dosen wali', () {
    test('ajukan bimbingan tervalidasi dan masuk ke log', () {
      final repo = MahasiswaRepository.seed();
      expect(repo.bimbinganMahasiswa(npmSiti).length, 3);
      expect(repo.ajukanBimbingan(npmSiti, 'pendek'), contains('minimal 8'));
      expect(
        repo.ajukanBimbingan(
          npmSiti,
          'Konsultasi rencana magang semester depan',
          catatan: 'Ingin membahas konversi MBKM.',
        ),
        isNull,
      );
      expect(repo.bimbinganMahasiswa(npmSiti).length, 4);
      expect(repo.bimbinganMahasiswa(npmSiti).first.dosen, 'Dr. Hendra Wijaya');
    });
  });

  group('surat akademik', () {
    test('ajukan, cegah duplikat, lalu batalkan', () {
      final repo = MahasiswaRepository.seed();
      expect(repo.suratMahasiswa(npmSiti).length, 2);
      expect(
        repo.ajukanSurat(npmSiti, JenisSurat.keteranganAktif, 'pendek'),
        contains('minimal 10'),
      );
      expect(
        repo.ajukanSurat(
          npmSiti,
          JenisSurat.beasiswa,
          'Melengkapi berkas beasiswa prestasi akademik.',
        ),
        isNull,
      );

      final baru = repo.suratMahasiswa(npmSiti).first;
      expect(baru.status, StatusSurat.pengajuan);
      expect(
        repo.ajukanSurat(
          npmSiti,
          JenisSurat.beasiswa,
          'Pengajuan beasiswa kedua yang masih diproses.',
        ),
        contains('sedang diproses'),
      );

      expect(repo.batalkanSurat(npmSiti, baru.id), isNull);
      expect(repo.batalkanSurat(npmSiti, baru.id), contains('PENGAJUAN'));
    });

    test('surat terbit menyimpan nomor dan token verifikasi', () {
      final repo = MahasiswaRepository.seed();
      final terbit = repo
          .suratMahasiswa(npmSiti)
          .firstWhere((s) => s.status == StatusSurat.terbit);
      expect(terbit.nomor, isNotNull);
      expect(terbit.verifikasiToken, isNotNull);
      expect(terbit.verifikasiUrl, contains('/verifikasi/'));
    });
  });

  group('layanan pengajuan', () {
    test('cuti: validasi, ajukan, cegah duplikat, batalkan', () {
      final repo = MahasiswaRepository.seed();
      expect(repo.ajukanCuti(npmSiti, alasan: 'pendek'), contains('minimal'));
      expect(
        repo.ajukanCuti(
          npmSiti,
          alasan: 'Alasan kesehatan dengan surat keterangan dokter.',
        ),
        isNull,
      );
      final cuti = repo.cutiMahasiswa(npmSiti).single;
      expect(cuti.status, StatusPengajuan.pengajuan);
      expect(
        repo.ajukanCuti(
          npmSiti,
          alasan: 'Pengajuan cuti kedua saat masih menunggu.',
        ),
        contains('sedang diproses'),
      );
      expect(repo.batalkanCuti(npmSiti, cuti.id), isNull);
      expect(repo.batalkanCuti(npmSiti, cuti.id), contains('menunggu'));
    });

    test('banding nilai hanya untuk nilai final', () {
      final repo = MahasiswaRepository.seed();
      expect(
        repo.ajukanBanding(
          npmSiti,
          'TI999',
          'Nilai tidak sesuai berita acara.',
        ),
        contains('tidak ditemukan'),
      );
      expect(
        repo.ajukanBanding(
          npmSiti,
          'TI303',
          'Nilai tidak sesuai berita acara.',
        ),
        contains('belum final'),
      );
      expect(
        repo.ajukanBanding(
          npmSiti,
          'TI301',
          'Komponen UAS tidak muncul pada KHS periode ini.',
        ),
        isNull,
      );
      expect(
        repo.ajukanBanding(
          npmSiti,
          'TI301',
          'Banding kedua untuk mata kuliah yang sama.',
        ),
        contains('sedang diproses'),
      );
    });

    test('konversi: validasi SKS dan catatan', () {
      final repo = MahasiswaRepository.seed();
      expect(
        repo.ajukanKonversi(
          npmSiti,
          jenis: JenisKonversi.mbkm,
          institusiAsal: 'PT Nusantara Digital',
          sksDimohonkan: 0,
          catatan: 'Kegiatan magang bersertifikat selama satu semester.',
        ),
        contains('1'),
      );
      expect(
        repo.ajukanKonversi(
          npmSiti,
          jenis: JenisKonversi.mbkm,
          institusiAsal: 'PT Nusantara Digital',
          sksDimohonkan: 20,
          catatan: 'pendek',
        ),
        contains('minimal'),
      );
      expect(
        repo.ajukanKonversi(
          npmSiti,
          jenis: JenisKonversi.mbkm,
          institusiAsal: 'PT Nusantara Digital',
          sksDimohonkan: 20,
          catatan: 'Magang bersertifikat konversi 20 SKS semester ini.',
        ),
        isNull,
      );
      expect(repo.konversiMahasiswa(npmSiti).single.sksDimohonkan, 20);
    });
  });

  group('pengumuman & kalender', () {
    test('status baca pengumuman tersimpan per repo', () {
      final repo = MahasiswaRepository.seed();
      expect(repo.jumlahPengumumanBelumDibaca, 2);
      expect(repo.pengumumanSudahDibaca('PGM-01'), isTrue);
      repo.tandaiPengumumanDibaca('PGM-02');
      expect(repo.jumlahPengumumanBelumDibaca, 1);
      repo.tandaiSemuaPengumumanDibaca();
      expect(repo.jumlahPengumumanBelumDibaca, 0);
    });

    test('event berikutnya dan sisa hari dihitung benar', () {
      final repo = MahasiswaRepository.seed();
      final acuan = DateTime(2026, 11, 9);
      final event = repo.eventBerikutnya(now: acuan);
      expect(event, isNotNull);
      expect(event!.kategori, KategoriKalender.uas);
      expect(event.tanggal, DateTime(2026, 12, 21));
      expect(event.sisaHari(acuan), 42);
      expect(repo.eventMendatang(now: acuan, batas: 3).length, 3);
    });

    test('validasi formulir murni', () {
      expect(validasiTopikBimbingan('cukup panjang'), isNull);
      expect(validasiKeperluanSurat('pendek'), contains('minimal'));
      expect(validasiAlasan('alasan yang cukup panjang'), isNull);
      expect(validasiSksKonversi(145), isNotNull);
    });
  });
}
