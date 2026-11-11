import 'package:sia_backend_core/sia_backend_core.dart';
import 'package:test/test.dart';

void main() {
  const admin = AppUser(
    id: 'admin-1',
    email: 'admin@kampus.ac.id',
    namaLengkap: 'Admin',
    roles: ['ADMIN'],
  );
  const student = AppUser(
    id: 'mhs-1',
    email: 'mhs@kampus.ac.id',
    namaLengkap: 'Mahasiswa',
    roles: ['MAHASISWA'],
  );

  group('AuthService', () {
    test('rejects empty credentials before hitting repository', () async {
      final service = AuthService(
        repository: _FakeAuthRepository(),
        tokens: TokenService('test-secret-0123456789-abcdefghijklmnop'),
      );

      expect(
        () => service.login('', ''),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects unknown credentials', () async {
      final service = AuthService(
        repository: _FakeAuthRepository(),
        tokens: TokenService('test-secret-0123456789-abcdefghijklmnop'),
      );

      expect(
        () => service.login('admin@kampus.ac.id', 'wrong'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('issues a token for a valid user', () async {
      final service = AuthService(
        repository: _FakeAuthRepository(user: admin),
        tokens: TokenService('test-secret-0123456789-abcdefghijklmnop'),
      );

      final result = await service.login('admin@kampus.ac.id', 'Admin#12345');
      expect(result.user.id, admin.id);
      expect(result.token, isNotEmpty);
    });
  });

  group('UserService', () {
    test('blocks non-admin listing', () {
      final service = UserService(_FakeUserRepository());
      expect(
        () => service.list(student, const PageRequest()),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('rejects invalid role', () {
      final service = UserService(_FakeUserRepository());
      expect(
        () => service.create(
          admin,
          email: 'x@kampus.ac.id',
          namaLengkap: 'User Test',
          roles: const ['SUPERUSER'],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('CivitasService', () {
    test('rejects malformed npm', () {
      final service = CivitasService(_FakeCivitasRepository());
      expect(
        () => service.createMahasiswa(
          admin,
          const CreateMahasiswaInput(
            email: 'x@kampus.ac.id',
            namaLengkap: 'User Test',
            idProgramStudi: 'prodi-1',
            tahunMasuk: 2026,
            jenisKelamin: 'L',
            npm: '123',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects malformed nidn', () {
      final service = CivitasService(_FakeCivitasRepository());
      expect(
        () => service.createDosen(
          admin,
          const CreateDosenInput(
            email: 'x@kampus.ac.id',
            nidn: 'abc',
            namaLengkap: 'Dosen Test',
            idProgramStudi: 'prodi-1',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.user});
  final AppUser? user;

  @override
  Future<AppUser?> authenticate(String identifier, String password) async {
    if (user == null) return null;
    return password == 'Admin#12345' ? user : null;
  }

  @override
  Future<AppUser?> findById(String id) async => user;

  @override
  Future<void> recordLogin(String userId, {String? ip, String? userAgent}) async {}
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<AppUser> create(AppUser actor,
          {required String email,
          required String namaLengkap,
          required List<String> roles,
          String? telepon,
          String? password}) async =>
      throw UnimplementedError();

  @override
  Future<AppUser?> findById(String id) async => null;

  @override
  Future<Page<AppUser>> list(AppUser actor, PageRequest request, {String? role}) async =>
      const Page(items: [], total: 0, page: 1, limit: 20);

  @override
  Future<List<String>> roles(AppUser actor) async => const ['ADMIN'];

  @override
  Future<AppUser> update(AppUser actor, String id,
          {String? namaLengkap,
          String? telepon,
          String? urlAvatar,
          bool? aktif,
          List<String>? roles}) async =>
      throw UnimplementedError();
}

class _FakeCivitasRepository implements CivitasRepository {
  @override
  Future<Mahasiswa> createMahasiswa(AppUser actor, CreateMahasiswaInput input) async =>
      throw UnimplementedError();

  @override
  Future<Dosen> createDosen(AppUser actor, CreateDosenInput input) async =>
      throw UnimplementedError();

  @override
  Future<Page<Dosen>> listDosen(AppUser actor, PageRequest request, {String? status}) async =>
      const Page(items: [], total: 0, page: 1, limit: 20);

  @override
  Future<Page<Mahasiswa>> listMahasiswa(AppUser actor, PageRequest request,
          {String? status}) async =>
      const Page(items: [], total: 0, page: 1, limit: 20);

  @override
  Future<String> nextNpm(AppUser actor, String prefix) async => '${prefix}000';

  @override
  Future<Dosen> updateDosen(AppUser actor, String nidn,
          {String? namaLengkap, String? status, String? telepon}) async =>
      throw UnimplementedError();

  @override
  Future<Mahasiswa> updateMahasiswa(AppUser actor, String npm,
          {String? namaLengkap,
          String? status,
          String? idDosenWali,
          String? telepon}) async =>
      throw UnimplementedError();
}
