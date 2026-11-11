import 'package:supabase/supabase.dart';
import 'package:sia_backend_core/sia_backend_core.dart';
import 'package:uuid/uuid.dart';

/// Implementasi [AuthRepository], [UserRepository], [MasterRepository],
/// [CivitasRepository], [DashboardRepository], dan [AuditRepository] melalui
/// Supabase (PostgREST + GoTrue Auth) dengan kunci service role sehingga
/// operasi backend melewati RLS — ekuivalen [PostgresBackend] tapi melalui
/// Supabase client daripada `package:postgres` mentah.
///
/// Variabel lingkungan yang dibutuhkan:
///   - SUPABASE_URL
///   - SUPABASE_SERVICE_ROLE_KEY (hanya backend)
class SupabaseBackend
    implements
        AuthRepository,
        UserRepository,
        MasterRepository,
        CivitasRepository,
        DashboardRepository,
        AuditRepository {
  SupabaseBackend({String? url, String? serviceRoleKey}) {
    final u = (url ?? const String.fromEnvironment('SUPABASE_URL')).trim();
    final k = (serviceRoleKey ??
            const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY'))
        .trim();
    if (u.isEmpty) {
      throw ArgumentError('SUPABASE_URL wajib diisi.');
    }
    if (k.isEmpty) {
      throw ArgumentError('SUPABASE_SERVICE_ROLE_KEY wajib diisi.');
    }
    _client = SupabaseClient(u, k);
  }

  late final SupabaseClient _client;

  // ================================================================== auth

  @override
  Future<AppUser?> authenticate(String identifier, String password) async {
    final id = identifier.trim();
    if (id.isEmpty || password.isEmpty) return null;
    final email = await _resolveEmail(id);
    if (email == null) return null;
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) return null;
      return await _fetchProfile(user.id);
    } on AuthException {
      return null;
    }
  }

  @override
  Future<AppUser?> findById(String id) async {
    try {
      return await _fetchProfile(id);
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<void> recordLogin(String userId, {String? ip, String? userAgent}) async {
    await run(() => _client.from('log_aktivitas').insert({
          'id_user': userId,
          'aksi': 'LOGIN',
          'entitas': 'user',
          'alamat_ip': ip,
          'user_agent': userAgent,
          'metadata': {'source': 'api'},
        }));
  }

  // ================================================================== users

  @override
  Future<Page<AppUser>> list(AppUser actor, PageRequest request,
      {String? role}) async {
    final normalized = request.normalized();
    final q = normalized.query;
    final roleIds = role == null ? const <String>{} : await _userIdsByRole(role);

    var countB = _client.from('user').select('id');
    if (q != null && q.isNotEmpty) {
      countB = countB.or('email.ilike.%$q%,nama_lengkap.ilike.%$q%');
    }
    if (roleIds.isNotEmpty) {
      countB = countB.inFilter('id', roleIds.toList(growable: false));
    }
    final countResp = await countB.count(CountOption.exact);
    final total = countResp.count;

    var dataB = _client.from('user').select('id,email,nama_lengkap,telepon,url_avatar,aktif');
    if (q != null && q.isNotEmpty) {
      dataB = dataB.or('email.ilike.%$q%,nama_lengkap.ilike.%$q%');
    }
    if (roleIds.isNotEmpty) {
      dataB = dataB.inFilter('id', roleIds.toList(growable: false));
    }
    final offset = normalized.offset;
    final rows = await dataB
        .order('nama_lengkap')
        .range(offset, offset + normalized.limit - 1);
    final roleMap = await _roleNamesForUsers(
        rows.map((r) => r['id'] as String).toList(growable: false));

    return Page(
      items: rows
          .map((r) => AppUser(
                id: r['id'] as String,
                email: r['email'] as String,
                namaLengkap: r['nama_lengkap'] as String,
                telepon: r['telepon'] as String?,
                urlAvatar: r['url_avatar'] as String?,
                aktif: r['aktif'] as bool,
                roles: roleMap[r['id'] as String] ?? const [],
              ))
          .toList(),
      total: total,
      page: normalized.page,
      limit: normalized.limit,
    );
  }

  @override
  Future<AppUser> create(AppUser actor, {
    required String email,
    required String namaLengkap,
    required List<String> roles,
    String? telepon,
    String? password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!_emailRe.hasMatch(cleanEmail)) {
      throw const ValidationException('Format email tidak valid.');
    }
    if (namaLengkap.trim().length < 3) {
      throw const ValidationException('Nama minimal 3 karakter.');
    }
    final cleanRoles = roles.map((e) => e.toUpperCase()).toSet().toList();
    if (cleanRoles.isEmpty ||
        !cleanRoles.every((r) => r == 'ADMIN' || r == 'DOSEN' || r == 'MAHASISWA')) {
      throw const ValidationException('Role harus ADMIN, DOSEN, atau MAHASISWA.');
    }
    if (password != null && password.length < 8) {
      throw const ValidationException('Password minimal 8 karakter.');
    }

    final uid = await run(() async {
      final created = await _client.auth.admin.createUser(
        AdminUserAttributes(
          email: cleanEmail,
          password: password ?? 'SIAKAD#2026',
          emailConfirm: true,
          userMetadata: {'nama_lengkap': namaLengkap.trim()},
        ),
      );
      final id = created.user?.id;
      if (id == null) throw const UnauthorizedException('Gagal membuat akun.');
      await _client.from('user').insert({
        'id': id,
        'email': cleanEmail,
        'nama_lengkap': namaLengkap.trim(),
        'telepon': telepon?.trim(),
        'aktif': true,
      });
      await _replaceRoles(id, cleanRoles);
      await _audit(actor.id, 'USER_CREATE', 'user', id, {'email': cleanEmail});
      return id;
    });
    final user = await findById(uid);
    if (user == null) throw const NotFoundException('Pengguna tidak ditemukan.');
    return user;
  }

  @override
  Future<AppUser> update(AppUser actor, String id, {
    String? namaLengkap,
    String? telepon,
    String? urlAvatar,
    bool? aktif,
    List<String>? roles,
  }) async {
    if (namaLengkap != null && namaLengkap.trim().length < 3) {
      throw const ValidationException('Nama minimal 3 karakter.');
    }
    final cleanRoles = roles?.map((e) => e.toUpperCase()).toSet().toList();
    if (cleanRoles != null &&
        (cleanRoles.isEmpty ||
            !cleanRoles.every((r) => r == 'ADMIN' || r == 'DOSEN' || r == 'MAHASISWA'))) {
      throw const ValidationException('Role harus ADMIN, DOSEN, atau MAHASISWA.');
    }

    await run(() async {
      final fields = <String, Object?>{};
      if (namaLengkap != null) fields['nama_lengkap'] = namaLengkap.trim();
      if (telepon != null) fields['telepon'] = telepon.trim();
      if (urlAvatar != null) fields['url_avatar'] = urlAvatar;
      if (aktif != null) fields['aktif'] = aktif;
      if (fields.isNotEmpty) {
        await _client.from('user').update(fields).eq('id', id);
      }
      if (roles != null) await _replaceRoles(id, cleanRoles!);
      await _audit(actor.id, 'USER_UPDATE', 'user', id, {
        if (roles != null) 'roles': roles,
        if (aktif != null) 'aktif': aktif,
      });
    });
    final user = await findById(id);
    if (user == null) throw const NotFoundException('Pengguna tidak ditemukan.');
    return user;
  }

  @override
  Future<List<String>> roles(AppUser actor) async {
    final rows = await _client.from('role').select('nama').order('nama');
    return rows.map((r) => r['nama'] as String).toList();
  }

  // ================================================================== master

  @override
  Future<List<ProgramStudi>> programStudi(AppUser actor) async {
    final rows = await _client.from('program_studi')
        .select('id,nama,kode,jenjang')
        .order('nama');
    return rows
        .map((r) => ProgramStudi(
              id: r['id'] as String,
              nama: r['nama'] as String,
              kode: r['kode'] as String,
              jenjang: r['jenjang'] as String,
            ))
        .toList();
  }

  @override
  Future<List<PeriodeAkademik>> periode(AppUser actor) async {
    final rows = await _client.from('periode_akademik')
        .select(
            'id,nama,tahun_akademik,semester,tanggal_mulai,tanggal_selesai,aktif')
        .order('aktif', ascending: false)
        .order('tanggal_mulai', ascending: false);
    return rows
        .map((r) => PeriodeAkademik(
              id: r['id'] as String,
              nama: r['nama'] as String,
              tahunAkademik: r['tahun_akademik'] as String,
              semester: r['semester'] as String,
              tanggalMulai: _parseDate(r['tanggal_mulai'])!,
              tanggalSelesai: _parseDate(r['tanggal_selesai'])!,
              aktif: r['aktif'] as bool,
            ))
        .toList();
  }

  @override
  Future<List<Ruangan>> ruangan(AppUser actor) async {
    final rows = await _client.from('ruangan')
        .select('id,kode,nama,kapasitas,gedung')
        .order('kode');
    return rows
        .map((r) => Ruangan(
              id: r['id'] as String,
              kode: r['kode'] as String,
              nama: r['nama'] as String,
              kapasitas: _int(r['kapasitas']),
              gedung: r['gedung'] as String?,
            ))
        .toList();
  }

  @override
  Future<List<MataKuliah>> mataKuliah(AppUser actor) async {
    final rows = await _client.from('mata_kuliah')
        .select(
            'id,kode,nama,sks,semester,jenis,sks_teori,sks_praktikum,deskripsi')
        .order('kode');
    return rows
        .map((r) => MataKuliah(
              id: r['id'] as String,
              kode: r['kode'] as String,
              nama: r['nama'] as String,
              sks: _int(r['sks']),
              semester: _int(r['semester']),
              jenis: r['jenis'] as String,
              sksTeori: _int(r['sks_teori']),
              sksPraktikum: _int(r['sks_praktikum']),
              deskripsi: r['deskripsi'] as String?,
            ))
        .toList();
  }

  @override
  Future<List<Kurikulum>> kurikulum(AppUser actor) async {
    final rows = await _client.from('kurikulum')
        .select('id,id_program_studi,nama,tahun,aktif,total_sks_lulus')
        .order('tahun', ascending: false)
        .order('nama');
    return rows
        .map((r) => Kurikulum(
              id: r['id'] as String,
              idProgramStudi: r['id_program_studi'] as String,
              nama: r['nama'] as String,
              tahun: _int(r['tahun']),
              aktif: r['aktif'] as bool,
              totalSksLulus: _int(r['total_sks_lulus']),
            ))
        .toList();
  }

  @override
  Future<ProgramStudi> saveProgramStudi(AppUser actor, {String? id, required String kode, required String nama, required String jenjang}) async {
    final payload = {'kode': kode, 'nama': nama, 'jenjang': jenjang};
    final row = id == null
        ? (await _client.from('program_studi').insert(payload).select().single())
        : (await _client.from('program_studi').update(payload).eq('id', id).select().single());
    await _audit(actor.id, id == null ? 'PRODI_CREATE' : 'PRODI_UPDATE', 'program_studi', row['id'] as String, {'kode': kode});
    return ProgramStudi(id: row['id'] as String, nama: row['nama'] as String, kode: row['kode'] as String, jenjang: row['jenjang'] as String);
  }

  @override
  Future<PeriodeAkademik> savePeriode(AppUser actor, {String? id, required String nama, required String tahunAkademik, required String semester, required DateTime tanggalMulai, required DateTime tanggalSelesai, bool aktif = false}) async {
    if (aktif) {
      await _client.from('periode_akademik').update({'aktif': false}).eq('aktif', true);
    }
    final payload = {
      'nama': nama, 'tahun_akademik': tahunAkademik, 'semester': semester,
      'tanggal_mulai': tanggalMulai.toIso8601String().split('T').first,
      'tanggal_selesai': tanggalSelesai.toIso8601String().split('T').first,
      'aktif': aktif,
    };
    final row = id == null
        ? (await _client.from('periode_akademik').insert(payload).select().single())
        : (await _client.from('periode_akademik').update(payload).eq('id', id).select().single());
    await _audit(actor.id, id == null ? 'PERIODE_CREATE' : 'PERIODE_UPDATE', 'periode_akademik', row['id'] as String, {'nama': nama});
    return _toPeriode(row);
  }

  @override
  Future<PeriodeAkademik> activatePeriode(AppUser actor, String id) async {
    await _client.from('periode_akademik').update({'aktif': false}).eq('aktif', true);
    final row = await _client.from('periode_akademik').update({'aktif': true}).eq('id', id).select().single();
    await _audit(actor.id, 'PERIODE_ACTIVATE', 'periode_akademik', id, const {});
    return _toPeriode(row);
  }

  @override
  Future<Ruangan> saveRuangan(AppUser actor, {String? id, required String kode, required String nama, required int kapasitas, String? gedung, bool aktif = true}) async {
    final payload = {'kode': kode, 'nama': nama, 'kapasitas': kapasitas, 'gedung': gedung};
    final row = id == null
        ? (await _client.from('ruangan').insert(payload).select().single())
        : (await _client.from('ruangan').update(payload).eq('id', id).select().single());
    await _audit(actor.id, id == null ? 'RUANGAN_CREATE' : 'RUANGAN_UPDATE', 'ruangan', row['id'] as String, {'kode': kode});
    return Ruangan(id: row['id'] as String, kode: row['kode'] as String, nama: row['nama'] as String, kapasitas: _int(row['kapasitas']), gedung: row['gedung'] as String?);
  }

  PeriodeAkademik _toPeriode(Map<String, dynamic> r) => PeriodeAkademik(
    id: r['id'] as String, nama: r['nama'] as String, tahunAkademik: r['tahun_akademik'] as String,
    semester: r['semester'] as String, tanggalMulai: _parseDate(r['tanggal_mulai'])!,
    tanggalSelesai: _parseDate(r['tanggal_selesai'])!, aktif: r['aktif'] as bool,
  );

  // ================================================================== civitas

  @override
  Future<Page<Mahasiswa>> listMahasiswa(AppUser actor, PageRequest request,
      {String? status}) async {
    if (status != null && !{'AKTIF', 'CUTI', 'LULUS', 'DO'}.contains(status)) {
      throw const ValidationException('Status mahasiswa tidak valid.');
    }
    final normalized = request.normalized();
    final q = normalized.query;

    var countB = _client.from('mahasiswa').select('npm');
    if (q != null && q.isNotEmpty) {
      countB = countB.or('npm.ilike.%$q%,nama_lengkap.ilike.%$q%');
    }
    if (status != null) {
      countB = countB.eq('status', status);
    }
    final countResp = await countB.count(CountOption.exact);
    final total = countResp.count;

    var dataB = _client.from('mahasiswa').select(
        'npm,id_user,nama_lengkap,id_program_studi,tahun_masuk,jenis_kelamin,tanggal_lahir,status,id_dosen_wali,nik,nama_ibu_kandung');
    if (q != null && q.isNotEmpty) {
      dataB = dataB.or('npm.ilike.%$q%,nama_lengkap.ilike.%$q%');
    }
    if (status != null) {
      dataB = dataB.eq('status', status);
    }
    final offset = normalized.offset;
    final rows = await dataB.order('npm').range(offset, offset + normalized.limit - 1);
    return Page(
      items: rows.map(_toMahasiswa).toList(),
      total: total,
      page: normalized.page,
      limit: normalized.limit,
    );
  }

  @override
  Future<Page<Dosen>> listDosen(AppUser actor, PageRequest request,
      {String? status}) async {
    if (status != null && !{'AKTIF', 'TIDAK_AKTIF'}.contains(status)) {
      throw const ValidationException('Status dosen tidak valid.');
    }
    final normalized = request.normalized();
    final q = normalized.query;

    var countB = _client.from('dosen').select('nidn');
    if (q != null && q.isNotEmpty) {
      countB = countB.or('nidn.ilike.%$q%,nama_lengkap.ilike.%$q%');
    }
    if (status != null) {
      countB = countB.eq('status', status);
    }
    final countResp = await countB.count(CountOption.exact);
    final total = countResp.count;

    var dataB = _client.from('dosen').select(
        'nidn,id_user,nama_lengkap,id_program_studi,status,gelar_akademik,jenis_kelamin,tanggal_lahir');
    if (q != null && q.isNotEmpty) {
      dataB = dataB.or('nidn.ilike.%$q%,nama_lengkap.ilike.%$q%');
    }
    if (status != null) {
      dataB = dataB.eq('status', status);
    }
    final offset = normalized.offset;
    final rows = await dataB.order('nama_lengkap').range(offset, offset + normalized.limit - 1);
    return Page(
      items: rows.map(_toDosen).toList(),
      total: total,
      page: normalized.page,
      limit: normalized.limit,
    );
  }

  @override
  Future<String> nextNpm(AppUser actor, String prefix) async {
    if (!RegExp(r'^[0-9]{7}$').hasMatch(prefix)) {
      throw const ValidationException('Prefix NPM harus 7 digit.');
    }
    final result = await _client.rpc('fn_next_npm', params: {'prefix': prefix});
    return result as String;
  }

  @override
  Future<Mahasiswa> createMahasiswa(AppUser actor, CreateMahasiswaInput input) async {
    if (!_emailRe.hasMatch(input.email.trim())) {
      throw const ValidationException('Format email tidak valid.');
    }
    if (input.namaLengkap.trim().length < 3) {
      throw const ValidationException('Nama minimal 3 karakter.');
    }
    if (!{'L', 'P'}.contains(input.jenisKelamin)) {
      throw const ValidationException('Jenis kelamin harus L atau P.');
    }
    final year = DateTime.now().year;
    if (input.tahunMasuk < 2000 || input.tahunMasuk > year + 1) {
      throw const ValidationException('Tahun masuk tidak valid.');
    }
    if (input.npm != null && !RegExp(r'^[0-9]{10}$').hasMatch(input.npm!)) {
      throw const ValidationException('NPM harus tepat 10 digit angka.');
    }
    if (input.password != null && input.password!.length < 8) {
      throw const ValidationException('Password minimal 8 karakter.');
    }

    return run(() async {
      final npm = input.npm ?? await _generateNpm(input);
      final password = input.password ??
          (input.tanggalLahir == null
              ? 'SIAKAD#2026'
              : '$npm#${input.tanggalLahir!.day.toString().padLeft(2, '0')}'
                  '${input.tanggalLahir!.month.toString().padLeft(2, '0')}'
                  '${input.tanggalLahir!.year.toString().substring(2)}');

      final created = await _client.auth.admin.createUser(
        AdminUserAttributes(
          email: input.email.toLowerCase(),
          password: password,
          emailConfirm: true,
        ),
      );
      final uid = created.user?.id;
      if (uid == null) throw const UnauthorizedException('Gagal membuat akun.');
      await _client.from('user').insert({
        'id': uid,
        'email': input.email.toLowerCase(),
        'nama_lengkap': input.namaLengkap.trim(),
        'telepon': input.telepon,
        'aktif': true,
      });
      await _replaceRoles(uid, const ['MAHASISWA']);
      await _client.from('mahasiswa').insert({
        'npm': npm,
        'id_user': uid,
        'nama_lengkap': input.namaLengkap.trim(),
        'id_program_studi': input.idProgramStudi,
        'tahun_masuk': input.tahunMasuk,
        'jenis_kelamin': input.jenisKelamin,
        'tanggal_lahir': input.tanggalLahir?.toIso8601String().split('T').first,
        'status': 'AKTIF',
        'id_dosen_wali': input.idDosenWali,
        'nik': input.nik,
        'nama_ibu_kandung': input.namaIbuKandung,
      });
      await _audit(actor.id, 'MAHASISWA_CREATE', 'mahasiswa', npm,
          {'email': input.email});
      return (await _findMahasiswa(npm))!;
    });
  }

  @override
  Future<Dosen> createDosen(AppUser actor, CreateDosenInput input) async {
    if (!_emailRe.hasMatch(input.email.trim())) {
      throw const ValidationException('Format email tidak valid.');
    }
    if (!RegExp(r'^[0-9]{8,}$').hasMatch(input.nidn)) {
      throw const ValidationException('NIDN minimal 8 digit angka.');
    }
    if (input.namaLengkap.trim().length < 3) {
      throw const ValidationException('Nama minimal 3 karakter.');
    }
    if (input.password != null && input.password!.length < 8) {
      throw const ValidationException('Password minimal 8 karakter.');
    }

    return run(() async {
      final password = input.password ?? 'SIAKAD#2026';
      final created = await _client.auth.admin.createUser(
        AdminUserAttributes(
          email: input.email.toLowerCase(),
          password: password,
          emailConfirm: true,
        ),
      );
      final uid = created.user?.id;
      if (uid == null) throw const UnauthorizedException('Gagal membuat akun.');
      await _client.from('user').insert({
        'id': uid,
        'email': input.email.toLowerCase(),
        'nama_lengkap': input.namaLengkap.trim(),
        'telepon': input.telepon,
        'aktif': true,
      });
      await _replaceRoles(uid, const ['DOSEN']);
      await _client.from('dosen').insert({
        'nidn': input.nidn,
        'id_user': uid,
        'nama_lengkap': input.namaLengkap.trim(),
        'id_program_studi': input.idProgramStudi,
        'gelar_akademik': input.gelarAkademik,
        'jenis_kelamin': input.jenisKelamin,
        'tanggal_lahir': input.tanggalLahir?.toIso8601String().split('T').first,
        'status': 'AKTIF',
      });
      await _audit(actor.id, 'DOSEN_CREATE', 'dosen', input.nidn,
          {'email': input.email});
      return (await _findDosen(input.nidn))!;
    });
  }

  @override
  Future<Mahasiswa> updateMahasiswa(AppUser actor, String npm, {
    String? namaLengkap,
    String? status,
    String? idDosenWali,
    String? telepon,
  }) async {
    if (status != null && !{'AKTIF', 'CUTI', 'LULUS', 'DO'}.contains(status)) {
      throw const ValidationException('Status mahasiswa tidak valid.');
    }
    if (namaLengkap != null && namaLengkap.trim().length < 3) {
      throw const ValidationException('Nama minimal 3 karakter.');
    }

    await run(() async {
      await _client.from('mahasiswa').update({
        if (namaLengkap != null) 'nama_lengkap': namaLengkap.trim(),
        if (status != null) 'status': status,
        if (idDosenWali != null) 'id_dosen_wali': idDosenWali,
      }).eq('npm', npm);
      if (telepon != null) {
        await _client.from('user').update({'telepon': telepon.trim()}).filter(
            'id', 'in',
            '(SELECT id_user FROM public.mahasiswa WHERE npm = $npm)');
      }
      await _audit(actor.id, 'MAHASISWA_UPDATE', 'mahasiswa', npm,
          {if (status != null) 'status': status});
    });
    final mhs = await _findMahasiswa(npm);
    if (mhs == null) throw const NotFoundException('Mahasiswa tidak ditemukan.');
    return mhs;
  }

  @override
  Future<Dosen> updateDosen(AppUser actor, String nidn, {
    String? namaLengkap,
    String? status,
    String? telepon,
  }) async {
    if (status != null && !{'AKTIF', 'TIDAK_AKTIF'}.contains(status)) {
      throw const ValidationException('Status dosen tidak valid.');
    }
    if (namaLengkap != null && namaLengkap.trim().length < 3) {
      throw const ValidationException('Nama minimal 3 karakter.');
    }

    await run(() async {
      await _client.from('dosen').update({
        if (namaLengkap != null) 'nama_lengkap': namaLengkap.trim(),
        if (status != null) 'status': status,
      }).eq('nidn', nidn);
      if (telepon != null) {
        await _client.from('user').update({'telepon': telepon.trim()}).filter(
            'id', 'in',
            '(SELECT id_user FROM public.dosen WHERE nidn = $nidn)');
      }
      await _audit(actor.id, 'DOSEN_UPDATE', 'dosen', nidn,
          {if (status != null) 'status': status});
    });
    final dosen = await _findDosen(nidn);
    if (dosen == null) throw const NotFoundException('Dosen tidak ditemukan.');
    return dosen;
  }

  // ================================================================== dashboard

  @override
  Future<DashboardStats> stats(AppUser actor) async {
    final row = await _client.from('v_dashboard_stats').select().maybeSingle();
    if (row == null) {
      throw const NotFoundException('Statistik dashboard tidak tersedia.');
    }
    return DashboardStats(
      mahasiswaAktif: _int(row['mahasiswa_aktif']),
      dosenAktif: _int(row['dosen_aktif']),
      programStudi: _int(row['program_studi']),
      krsAktif: _int(row['krs_aktif']),
      krsMenunggu: _int(row['krs_menunggu']),
      suratMenunggu: _int(row['surat_menunggu']),
      aktivitasHariIni: _int(row['aktivitas_hari_ini']),
    );
  }

  // ================================================================== audit

  @override
  Future<Page<AuditLog>> listLogs(AppUser actor, PageRequest request) async {
    final normalized = request.normalized();

    var countB = _client.from('log_aktivitas').select('id');
    final countResp = await countB.count(CountOption.exact);
    final total = countResp.count;

    final offset = normalized.offset;
    final rows = await _client
        .from('log_aktivitas')
        .select(
            'id,id_user,aksi,entitas,id_entitas,metadata,alamat_ip,dibuat_pada')
        .order('dibuat_pada', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + normalized.limit - 1);
    return Page(
      items: rows
          .map((r) => AuditLog(
                id: r['id'] as String,
                idUser: r['id_user'] as String?,
                aksi: r['aksi'] as String,
                entitas: r['entitas'] as String,
                idEntitas: r['id_entitas'] as String?,
                metadata: (r['metadata'] as Map?)?.cast<String, Object?>(),
                alamatIp: r['alamat_ip'] as String?,
                dibuatPada: _parseDate(r['dibuat_pada'])!,
              ))
          .toList(),
      total: total,
      page: normalized.page,
      limit: normalized.limit,
    );
  }

  // ================================================================== helpers

  Future<T> run<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on PostgrestException catch (e, st) {
      throw _mapError(e, st);
    } on AuthException catch (e, st) {
      throw _mapError(e, st);
    }
  }

  Exception _mapError(Object error, Object? stackTrace) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505':
          return const ConflictException('Data sudah ada.');
        case '42501':
          return const ForbiddenException();
        case '23503':
        case '23514':
        case '22001':
          return ValidationException(error.message);
      }
      return error;
    }
    if (error is AuthException) {
      final m = error.message;
      if (m.toLowerCase().contains('already registered') ||
          m.toLowerCase().contains('already exists')) {
        return const ConflictException('Data sudah ada.');
      }
      return UnauthorizedException(m);
    }
    return error is Exception ? error : Exception(error.toString());
  }

  Future<String?> _resolveEmail(String identifier) async {
    if (identifier.contains('@')) return identifier;
    // email langsung di tabel user
    final u = await _client.from('user').select('email').eq('email', identifier).maybeSingle();
    if (u != null) return u['email'] as String?;
    // via NPM mahasiswa
    final m = await _client.from('mahasiswa').select('id_user').eq('npm', identifier).maybeSingle();
    if (m != null) {
      final usr = await _client.from('user')
          .select('email')
          .eq('id', m['id_user'] as String)
          .maybeSingle();
      return usr?['email'] as String?;
    }
    // via NIDN dosen
    final d = await _client.from('dosen').select('id_user').eq('nidn', identifier).maybeSingle();
    if (d != null) {
      final usr = await _client.from('user')
          .select('email')
          .eq('id', d['id_user'] as String)
          .maybeSingle();
      return usr?['email'] as String?;
    }
    return null;
  }

  Future<AppUser> _fetchProfile(String userId) async {
    final row = await _client.from('user')
        .select('id,email,nama_lengkap,telepon,url_avatar,aktif')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) throw const NotFoundException('Profil tidak ditemukan.');
    final roles = await _roleNamesForUser(userId);
    return AppUser(
      id: row['id'] as String,
      email: row['email'] as String,
      namaLengkap: row['nama_lengkap'] as String,
      telepon: row['telepon'] as String?,
      urlAvatar: row['url_avatar'] as String?,
      aktif: row['aktif'] as bool,
      roles: roles,
    );
  }

  Future<List<String>> _roleNamesForUser(String userId) async {
    final roleRows = await _client.from('user_role').select('id_role').eq('id_user', userId);
    if (roleRows.isEmpty) return const [];
    final ids = roleRows
        .map((r) => r['id_role'])
        .whereType<String>()
        .toList(growable: false);
    final names = await _client.from('role').select('nama').inFilter('id', ids);
    return names.map((r) => r['nama'] as String).toList();
  }

  Future<Set<String>> _userIdsByRole(String nama) async {
    final roleRow = await _client.from('role').select('id').eq('nama', nama).maybeSingle();
    final roleId = roleRow?['id'] as String?;
    if (roleId == null) return {};
    final rows = await _client.from('user_role').select('id_user').eq('id_role', roleId);
    return rows.map((r) => r['id_user'] as String).toSet();
  }

  Future<Map<String, List<String>>> _roleNamesForUsers(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final urRows = await _client
        .from('user_role')
        .select('id_user,id_role')
        .inFilter('id_user', userIds);
    if (urRows.isEmpty) return {};
    final roleIds = urRows.map((r) => r['id_role']).whereType<String>().toSet().toList(growable: false);
    final roleRows = await _client.from('role').select('id,nama').inFilter('id', roleIds);
    final roleNameById = <String, String>{};
    for (final r in roleRows) {
      roleNameById[r['id'] as String] = r['nama'] as String;
    }
    final map = <String, List<String>>{};
    for (final r in urRows) {
      final uid = r['id_user'] as String;
      final rid = r['id_role'] as String;
      final name = roleNameById[rid];
      if (name == null) continue;
      map.putIfAbsent(uid, () => <String>[]).add(name);
    }
    return map;
  }

  Future<void> _replaceRoles(String userId, List<String> roles) async {
    await _client.from('user_role').delete().eq('id_user', userId);
    if (roles.isEmpty) return;
    final roleRows = await _client.from('role').select('id').inFilter('nama', roles);
    final rows = roleRows.map((r) => {
      'id': _newId(),
      'id_user': userId,
      'id_role': r['id'] as String,
    }).toList(growable: false);
    await _client.from('user_role').insert(rows);
  }

  Future<void> _audit(String actorId, String aksi, String entitas,
      String idEntitas, Map<String, Object?> metadata) async {
    await _client.from('log_aktivitas').insert({
      'id_user': actorId,
      'aksi': aksi,
      'entitas': entitas,
      'id_entitas': idEntitas,
      'metadata': metadata,
    });
  }

  Future<String> _generateNpm(CreateMahasiswaInput input) async {
    final prodi = await _client.from('program_studi')
        .select('kode')
        .eq('id', input.idProgramStudi)
        .maybeSingle();
    if (prodi == null) throw const ValidationException('Program studi tidak ditemukan.');
    final kode = prodi['kode'] as String;
    final pp = RegExp(r'^[0-9]{2}$').hasMatch(kode)
        ? kode
        : switch (kode) {
            'TI' => '10',
            'SI' => '20',
            _ => '99',
          };
    final yy = (input.tahunMasuk % 100).toString().padLeft(2, '0');
    final prefix = '$yy''001''$pp';
    final result = await _client.rpc('fn_next_npm', params: {'prefix': prefix});
    return result as String;
  }

  Future<Mahasiswa?> _findMahasiswa(String npm) async {
    final rows = await _client.from('mahasiswa')
        .select(
            'npm,id_user,nama_lengkap,id_program_studi,tahun_masuk,jenis_kelamin,tanggal_lahir,status,id_dosen_wali,nik,nama_ibu_kandung')
        .eq('npm', npm);
    if (rows.isEmpty) return null;
    return _toMahasiswa(rows.first);
  }

  Future<Dosen?> _findDosen(String nidn) async {
    final rows = await _client.from('dosen')
        .select('nidn,id_user,nama_lengkap,id_program_studi,status,gelar_akademik,jenis_kelamin,tanggal_lahir')
        .eq('nidn', nidn);
    if (rows.isEmpty) return null;
    return _toDosen(rows.first);
  }

  Mahasiswa _toMahasiswa(Map<String, dynamic> r) => Mahasiswa(
        npm: r['npm'] as String,
        idUser: r['id_user'] as String,
        namaLengkap: r['nama_lengkap'] as String,
        idProgramStudi: r['id_program_studi'] as String,
        tahunMasuk: _int(r['tahun_masuk']),
        jenisKelamin: r['jenis_kelamin'] as String,
        status: r['status'] as String,
        tanggalLahir: _parseDate(r['tanggal_lahir']),
        idDosenWali: r['id_dosen_wali'] as String?,
        nik: r['nik'] as String?,
        namaIbuKandung: r['nama_ibu_kandung'] as String?,
      );

  Dosen _toDosen(Map<String, dynamic> r) => Dosen(
        nidn: r['nidn'] as String,
        idUser: r['id_user'] as String,
        namaLengkap: r['nama_lengkap'] as String,
        idProgramStudi: r['id_program_studi'] as String,
        status: r['status'] as String,
        gelarAkademik: r['gelar_akademik'] as String?,
        jenisKelamin: r['jenis_kelamin'] as String?,
        tanggalLahir: _parseDate(r['tanggal_lahir']),
      );

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  static int _int(Object? v) => (v as num?)?.toInt() ?? 0;

  String _newId() => const Uuid().v4();

  final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> close() => _client.dispose();
}
