import 'scheduling.dart';

List<KelasKuliah> seedKelas() => [
  KelasKuliah(
    id: 'kl-ti101a',
    mkId: 'mk-ti101',
    kode: 'TI101-A',
    kapasitas: 40,
    terdaftar: 38,
    dosenIds: const ['0412088501'],
    leadDosenId: '0412088501',
  ),
  KelasKuliah(
    id: 'kl-ti202a',
    mkId: 'mk-ti202',
    kode: 'TI202-A',
    kapasitas: 40,
    terdaftar: 40,
    dosenIds: const ['0405128703'],
    leadDosenId: '0405128703',
  ),
  KelasKuliah(
    id: 'kl-ti301b',
    mkId: 'mk-ti301',
    kode: 'TI301-B',
    kapasitas: 40,
    terdaftar: 35,
    dosenIds: const ['0420119002'],
    leadDosenId: '0420119002',
  ),
  KelasKuliah(
    id: 'kl-tanpa-dosen',
    mkId: 'mk-ti102',
    kode: 'TI102-A',
    kapasitas: 40,
    terdaftar: 12,
    dosenIds: const [],
    leadDosenId: '',
  ),
];

List<JadwalSlot> seedJadwal() => [
  JadwalSlot(
    id: 'j1',
    kelasId: 'kl-ti101a',
    ruangId: 'r-lab1',
    hari: 1,
    mulai: 8 * 60,
    selesai: 9 * 60 + 40,
  ),
  JadwalSlot(
    id: 'j2',
    kelasId: 'kl-ti202a',
    ruangId: 'r-lab1',
    hari: 2,
    mulai: 8 * 60,
    selesai: 9 * 60 + 40,
  ),
  JadwalSlot(
    id: 'j3',
    kelasId: 'kl-ti301b',
    ruangId: 'r-a201',
    hari: 2,
    mulai: 10 * 60,
    selesai: 12 * 60 + 30,
  ),
];

Map<String, List<String>> dosenByKelas(List<KelasKuliah> kelas) => {
  for (final k in kelas) k.id: k.dosenIds,
};
