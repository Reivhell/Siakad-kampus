import 'app_user.dart';

/// Seed 6 akun: 2 admin (guard last-admin teruji), 2 dosen, 2 mhs.
List<AppUser> seedUsers() => [
  AppUser(
    id: 'u-admin-1',
    nama: 'Administrator Pusat',
    email: 'admin@kampus.ac.id',
    telepon: '+62 812-0000-0001',
    roles: {UserRole.admin},
    lastLogin: '10 mnt lalu',
  ),
  AppUser(
    id: 'u-admin-2',
    nama: 'Dr. Aris Munandar',
    email: 'aris.munandar@kampus.ac.id',
    roles: {UserRole.admin, UserRole.dosen},
    lastLogin: '1 jam lalu',
  ),
  AppUser(
    id: 'u-dosen-1',
    nama: 'Budi Santoso, M.T.',
    email: 'budi.santoso@kampus.ac.id',
    roles: {UserRole.dosen},
    status: AccountStatus.nonaktif,
    hasRelations: true,
    lastLogin: '14 hari lalu',
  ),
  AppUser(
    id: 'u-dosen-2',
    nama: 'Dr. Hendra Wijaya',
    email: 'hendra.wijaya@kampus.ac.id',
    roles: {UserRole.dosen},
    lastLogin: 'Kemarin',
  ),
  AppUser(
    id: 'u-mhs-1',
    nama: 'Siti Nurhaliza',
    email: 'siti.261001@mhs.kampus.ac.id',
    roles: {UserRole.mahasiswa},
    hasRelations: true,
    lastLogin: '2 jam lalu',
  ),
  AppUser(
    id: 'u-mhs-2',
    nama: 'Rendy Firmansyah',
    email: 'rendy.251002@mhs.kampus.ac.id',
    roles: {UserRole.mahasiswa},
    status: AccountStatus.terkunci,
    hasRelations: true,
    lastLogin: 'Kemarin',
  ),
];

const currentAdminId = 'u-admin-1';
