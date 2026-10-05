import 'krs.dart';

List<KrsEntry> seedKrs() => [
  KrsEntry(
    id: 'krs-1',
    npm: '2410010015',
    kelasId: 'kl-ti301b',
    status: 'MENUNGGU_APPROVAL',
  ),
  KrsEntry(
    id: 'krs-2',
    npm: '2410010022',
    kelasId: 'kl-ti202a',
    status: 'AKTIF',
    paApproved: true,
  ),
  KrsEntry(
    id: 'krs-3',
    npm: '2410010034',
    kelasId: 'kl-ti101a',
    status: 'DRAFT',
  ),
  KrsEntry(
    id: 'krs-4',
    npm: '2410010050',
    kelasId: 'kl-ti101a',
    status: 'DRAFT',
  ),
];

/// NPM -> (nama, prodi, angkatan, ipsLalu, sksDiambil)
const krsStudents = {
  '2410010015': ('Reza Pratama', 'S1 TI', 2024, 3.10, 22),
  '2410010022': ('Dinda Safitri', 'S1 TI', 2024, 3.60, 24),
  '2410010034': ('Kevin Sanjaya', 'S1 TI', 2024, 2.20, 18),
  '2410010050': ('Nurul Hidayah', 'S1 TI', 2024, 3.45, 21),
};

List<KrsWindow> seedWindows() => [
  KrsWindow(
    id: 'w1',
    nama: 'Gel. 1 — Tingkat Akhir (7+)',
    minSemester: 7,
    maxSemester: 14,
    buka: DateTime(2026, 8, 1),
    tutup: DateTime(2026, 8, 2, 23, 59),
  ),
  KrsWindow(
    id: 'w2',
    nama: 'Gel. 2 — Semester 5–6',
    minSemester: 5,
    maxSemester: 6,
    buka: DateTime(2026, 8, 3),
    tutup: DateTime(2026, 8, 4, 23, 59),
  ),
  KrsWindow(
    id: 'w3',
    nama: 'Gel. 3 — Semester 3–4',
    minSemester: 3,
    maxSemester: 4,
    buka: DateTime(2026, 8, 5),
    tutup: DateTime(2026, 8, 6, 23, 59),
  ),
  KrsWindow(
    id: 'w4',
    nama: 'Gel. 4 — Maba + Umum',
    minSemester: 1,
    maxSemester: 2,
    buka: DateTime(2026, 8, 7),
    tutup: DateTime(2026, 8, 10, 23, 59),
  ),
];
