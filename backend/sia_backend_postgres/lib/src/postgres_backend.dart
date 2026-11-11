import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:sia_backend_core/sia_backend_core.dart';

class PostgresBackend
    implements
        AuthRepository,
        UserRepository,
        MasterRepository,
        CivitasRepository,
        DashboardRepository,
        AuditRepository {
  PostgresBackend(String url, {int maxConnections = 10}) {
    final uri = Uri.parse(url);
    // Password di URL biasanya percent-encoded (mis. %40 untuk @).
    final userInfo = uri.userInfo.split(':').map(Uri.decodeComponent).toList();
    final isLocal = uri.host == '127.0.0.1' || uri.host == 'localhost';
    final ssl = switch (uri.queryParameters['sslmode']) {
      'disable' => SslMode.disable,
      'require' => SslMode.require,
      _ => isLocal ? SslMode.disable : SslMode.require,
    };
    _pool = Pool.withEndpoints(
      [
        Endpoint(
          host: uri.host,
          port: uri.hasPort ? uri.port : 5432,
          database: uri.pathSegments.first,
          username: userInfo.first,
          password: userInfo.length > 1 && userInfo[1].isNotEmpty ? userInfo[1] : null,
        ),
      ],
      settings: PoolSettings(maxConnectionCount: maxConnections, sslMode: ssl),
    );
  }

  late final Pool<void> _pool;

  Future<void> close() => _pool.close();

  // ---------------------------------------------------------------- auth

  @override
  Future<AppUser?> authenticate(String identifier, String password) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT u.id, u.email, u.nama_lengkap, u.telepon, u.url_avatar, u.aktif,
               COALESCE(array_agg(r.nama ORDER BY r.nama)
                   FILTER (WHERE r.nama IS NOT NULL), '{}') AS roles
        FROM auth.users au
        JOIN public."user" u ON u.id = au.id
        LEFT JOIN public.user_role ur ON ur.id_user = u.id
        LEFT JOIN public.role r ON r.id = ur.id_role
        WHERE (
            lower(u.email) = @identifier
            OR EXISTS (SELECT 1 FROM public.mahasiswa m WHERE m.id_user = u.id AND m.npm = @identifier)
            OR EXISTS (SELECT 1 FROM public.dosen d WHERE d.id_user = u.id AND d.nidn = @identifier)
          )
          AND au.encrypted_password = crypt(@password, au.encrypted_password)
        GROUP BY u.id, u.email, u.nama_lengkap, u.telepon, u.url_avatar, u.aktif
      '''),
      parameters: {'identifier': identifier, 'password': password},
    );
    if (result.isEmpty) return null;
    return _toUser(result.first);
  }

  @override
  Future<AppUser?> findById(String id) async {
    final result = await _pool.execute(
      Sql.named(_userSelect + ' WHERE u.id = @id GROUP BY u.id, u.email, u.nama_lengkap, u.telepon, u.url_avatar, u.aktif'),
      parameters: {'id': id},
    );
    return result.isEmpty ? null : _toUser(result.first);
  }

  @override
  Future<void> recordLogin(String userId, {String? ip, String? userAgent}) async {
    await _pool.execute(
      Sql.named('''
        INSERT INTO public.log_aktivitas (id_user, aksi, entitas, alamat_ip, user_agent, metadata)
        VALUES (@id, 'LOGIN', 'user', @ip, @agent, '{"source":"api"}'::jsonb)
      '''),
      parameters: {'id': userId, 'ip': ip, 'agent': userAgent},
    );
  }

  // ---------------------------------------------------------------- users

  @override
  Future<Page<AppUser>> list(AppUser actor, PageRequest request, {String? role}) {
    return _asUser(actor, (tx) async {
      final params = {
        'q': request.query,
        'role': role,
        'limit': request.limit,
        'offset': request.offset,
      };
      final count = await tx.execute(
        Sql.named('''
          SELECT count(*) FROM public."user" u
          WHERE (@q::text IS NULL OR u.email ILIKE '%' || @q || '%' OR u.nama_lengkap ILIKE '%' || @q || '%')
            AND (@role::text IS NULL OR EXISTS (
              SELECT 1 FROM public.user_role ur JOIN public.role r ON r.id = ur.id_role
              WHERE ur.id_user = u.id AND r.nama = @role
            ))
        '''),
        parameters: {'q': request.query, 'role': role},
      );
      final rows = await tx.execute(
        Sql.named('''
          $_userSelect
          WHERE (@q::text IS NULL OR u.email ILIKE '%' || @q || '%' OR u.nama_lengkap ILIKE '%' || @q || '%')
            AND (@role::text IS NULL OR EXISTS (
              SELECT 1 FROM public.user_role ur JOIN public.role r ON r.id = ur.id_role
              WHERE ur.id_user = u.id AND r.nama = @role
            ))
          GROUP BY u.id, u.email, u.nama_lengkap, u.telepon, u.url_avatar, u.aktif
          ORDER BY u.nama_lengkap
          LIMIT @limit OFFSET @offset
        '''),
        parameters: params,
      );
      return Page(
        items: rows.map(_toUser).toList(),
        total: _int(count.first[0]),
        page: request.page,
        limit: request.limit,
      );
    });
  }

  @override
  Future<AppUser> create(
    AppUser actor, {
    required String email,
    required String namaLengkap,
    required List<String> roles,
    String? telepon,
    String? password,
  }) async {
    try {
      final user = await _pool.runTx((tx) async {
        final auth = await tx.execute(
          Sql.named('''
            INSERT INTO auth.users (email, encrypted_password, email_confirmed_at, raw_user_meta_data)
            VALUES (@email, crypt(@password, gen_salt('bf')), now(),
                    jsonb_build_object('nama_lengkap', @nama::text))
            RETURNING id
          '''),
          parameters: {
            'email': email,
            'password': password ?? 'SIAKAD#2026',
            'nama': namaLengkap,
          },
        );
        final id = auth.first[0]! as String;
        await tx.execute(
          Sql.named('''
            INSERT INTO public."user" (id, email, nama_lengkap, telepon, aktif)
            VALUES (@id, @email, @nama, @telepon, true)
          '''),
          parameters: {'id': id, 'email': email, 'nama': namaLengkap, 'telepon': telepon},
        );
        await _replaceRoles(tx, id, roles);
        await _audit(tx, actor.id, 'USER_CREATE', 'user', id, {'email': email});
        return id;
      });
      return (await findById(user))!;
    } on ServerException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<AppUser> update(
    AppUser actor,
    String id, {
    String? namaLengkap,
    String? telepon,
    String? urlAvatar,
    bool? aktif,
    List<String>? roles,
  }) async {
    try {
      await _asUser(actor, (tx) async {
        await tx.execute(
          Sql.named('''
            UPDATE public."user"
            SET nama_lengkap = COALESCE(@nama, nama_lengkap),
                telepon = COALESCE(@telepon, telepon),
                url_avatar = COALESCE(@avatar, url_avatar),
                aktif = COALESCE(@aktif, aktif)
            WHERE id = @id
          '''),
          parameters: {
            'id': id,
            'nama': namaLengkap,
            'telepon': telepon,
            'avatar': urlAvatar,
            'aktif': aktif,
          },
        );
        if (roles != null) await _replaceRoles(tx, id, roles);
        await _audit(tx, actor.id, 'USER_UPDATE', 'user', id, {
          if (roles != null) 'roles': roles,
          if (aktif != null) 'aktif': aktif,
        });
      });
      final user = await findById(id);
      if (user == null) throw const NotFoundException('Pengguna tidak ditemukan.');
      return user;
    } on ServerException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<List<String>> roles(AppUser actor) {
    return _asUser(actor, (tx) async {
      final rows = await tx.execute('SELECT nama FROM public.role ORDER BY nama');
      return rows.map((r) => r[0]! as String).toList();
    });
  }

  // -------------------------------------------------------------- master

  @override
  Future<List<ProgramStudi>> programStudi(AppUser actor) {
    return _asUser(actor, (tx) async {
      final rows = await tx.execute(
        'SELECT id, nama, kode, jenjang FROM public.program_studi ORDER BY nama',
      );
      return rows
          .map((r) => ProgramStudi(
                id: r[0]! as String,
                nama: r[1]! as String,
                kode: r[2]! as String,
                jenjang: r[3]! as String,
              ))
          .toList();
    });
  }

  @override
  Future<List<PeriodeAkademik>> periode(AppUser actor) {
    return _asUser(actor, (tx) async {
      final rows = await tx.execute('''
        SELECT id, nama, tahun_akademik, semester, tanggal_mulai, tanggal_selesai, aktif
        FROM public.periode_akademik ORDER BY aktif DESC, tanggal_mulai DESC
      ''');
      return rows
          .map((r) => PeriodeAkademik(
                id: r[0]! as String,
                nama: r[1]! as String,
                tahunAkademik: r[2]! as String,
                semester: r[3]! as String,
                tanggalMulai: r[4]! as DateTime,
                tanggalSelesai: r[5]! as DateTime,
                aktif: r[6]! as bool,
              ))
          .toList();
    });
  }

  @override
  Future<List<Ruangan>> ruangan(AppUser actor) {
    return _asUser(actor, (tx) async {
      final rows = await tx.execute(
        'SELECT id, kode, nama, kapasitas, gedung FROM public.ruangan ORDER BY kode',
      );
      return rows
          .map((r) => Ruangan(
                id: r[0]! as String,
                kode: r[1]! as String,
                nama: r[2]! as String,
                kapasitas: _int(r[3]),
                gedung: r[4] as String?,
              ))
          .toList();
    });
  }

  @override
  Future<List<MataKuliah>> mataKuliah(AppUser actor) {
    return _asUser(actor, (tx) async {
      final rows = await tx.execute('''
        SELECT id, kode, nama, sks, semester, jenis, sks_teori, sks_praktikum, deskripsi
        FROM public.mata_kuliah ORDER BY kode
      ''');
      return rows
          .map((r) => MataKuliah(
                id: r[0]! as String,
                kode: r[1]! as String,
                nama: r[2]! as String,
                sks: _int(r[3]),
                semester: _int(r[4]),
                jenis: r[5]! as String,
                sksTeori: _int(r[6]),
                sksPraktikum: _int(r[7]),
                deskripsi: r[8] as String?,
              ))
          .toList();
    });
  }

  @override
  Future<List<Kurikulum>> kurikulum(AppUser actor) {
    return _asUser(actor, (tx) async {
      final rows = await tx.execute('''
        SELECT id, id_program_studi, nama, tahun, aktif, total_sks_lulus
        FROM public.kurikulum ORDER BY tahun DESC, nama
      ''');
      return rows
          .map((r) => Kurikulum(
                id: r[0]! as String,
                idProgramStudi: r[1]! as String,
                nama: r[2]! as String,
                tahun: _int(r[3]),
                aktif: r[4]! as bool,
                totalSksLulus: _int(r[5]),
              ))
          .toList();
    });
  }

  @override
  Future<ProgramStudi> saveProgramStudi(AppUser actor, {String? id, required String kode, required String nama, required String jenjang}) {
    return _asUser(actor, (tx) async {
      final rows = await tx.execute(Sql.named(id == null
          ? "INSERT INTO public.program_studi (kode, nama, jenjang) VALUES (@kode, @nama, @jenjang) RETURNING id, nama, kode, jenjang"
          : "UPDATE public.program_studi SET kode=@kode, nama=@nama, jenjang=@jenjang WHERE id=@id::uuid RETURNING id, nama, kode, jenjang"),
          parameters: {'id': id, 'kode': kode, 'nama': nama, 'jenjang': jenjang});
      await tx.execute(Sql.named("INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata) VALUES (@u, @a, 'program_studi', @e, '{}'::jsonb)"),
          parameters: {'u': actor.id, 'a': id == null ? 'PRODI_CREATE' : 'PRODI_UPDATE', 'e': rows.first[0]});
      final r = rows.first;
      return ProgramStudi(id: r[0]! as String, nama: r[1]! as String, kode: r[2]! as String, jenjang: r[3]! as String);
    });
  }

  @override
  Future<PeriodeAkademik> savePeriode(AppUser actor, {String? id, required String nama, required String tahunAkademik, required String semester, required DateTime tanggalMulai, required DateTime tanggalSelesai, bool aktif = false}) {
    return _asUser(actor, (tx) async {
      if (aktif) await tx.execute('UPDATE public.periode_akademik SET aktif = false WHERE aktif = true');
      final p = {'id': id, 'nama': nama, 'ta': tahunAkademik, 'sem': semester,
        'mulai': tanggalMulai.toIso8601String().split('T').first,
        'selesai': tanggalSelesai.toIso8601String().split('T').first, 'aktif': aktif};
      final rows = await tx.execute(Sql.named(id == null
          ? "INSERT INTO public.periode_akademik (nama,tahun_akademik,semester,tanggal_mulai,tanggal_selesai,aktif) VALUES (@nama,@ta,@sem,@mulai::date,@selesai::date,@aktif) RETURNING id,nama,tahun_akademik,semester,tanggal_mulai,tanggal_selesai,aktif"
          : "UPDATE public.periode_akademik SET nama=@nama,tahun_akademik=@ta,semester=@sem,tanggal_mulai=@mulai::date,tanggal_selesai=@selesai::date,aktif=@aktif WHERE id=@id::uuid RETURNING id,nama,tahun_akademik,semester,tanggal_mulai,tanggal_selesai,aktif"),
          parameters: p);
      await tx.execute(Sql.named("INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata) VALUES (@u, @a, 'periode_akademik', @e, '{}'::jsonb)"),
          parameters: {'u': actor.id, 'a': id == null ? 'PERIODE_CREATE' : 'PERIODE_UPDATE', 'e': rows.first[0]});
      return _toPeriode(rows.first);
    });
  }

  @override
  Future<PeriodeAkademik> activatePeriode(AppUser actor, String id) {
    return _asUser(actor, (tx) async {
      await tx.execute('UPDATE public.periode_akademik SET aktif = false WHERE aktif = true');
      final rows = await tx.execute(Sql.named("UPDATE public.periode_akademik SET aktif = true WHERE id=@id::uuid RETURNING id,nama,tahun_akademik,semester,tanggal_mulai,tanggal_selesai,aktif"), parameters: {'id': id});
      if (rows.isEmpty) throw const NotFoundException('Periode tidak ditemukan.');
      await tx.execute(Sql.named("INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata) VALUES (@u, 'PERIODE_ACTIVATE', 'periode_akademik', @e, '{}'::jsonb)"), parameters: {'u': actor.id, 'e': id});
      return _toPeriode(rows.first);
    });
  }

  @override
  Future<Ruangan> saveRuangan(AppUser actor, {String? id, required String kode, required String nama, required int kapasitas, String? gedung, bool aktif = true}) {
    return _asUser(actor, (tx) async {
      final rows = await tx.execute(Sql.named(id == null
          ? "INSERT INTO public.ruangan (kode,nama,kapasitas,gedung) VALUES (@kode,@nama,@kap,@gedung) RETURNING id,kode,nama,kapasitas,gedung"
          : "UPDATE public.ruangan SET kode=@kode,nama=@nama,kapasitas=@kap,gedung=@gedung WHERE id=@id::uuid RETURNING id,kode,nama,kapasitas,gedung"),
          parameters: {'id': id, 'kode': kode, 'nama': nama, 'kap': kapasitas, 'gedung': gedung});
      await tx.execute(Sql.named("INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata) VALUES (@u, @a, 'ruangan', @e, '{}'::jsonb)"),
          parameters: {'u': actor.id, 'a': id == null ? 'RUANGAN_CREATE' : 'RUANGAN_UPDATE', 'e': rows.first[0]});
      final r = rows.first;
      return Ruangan(id: r[0]! as String, kode: r[1]! as String, nama: r[2]! as String, kapasitas: _int(r[3]), gedung: r[4] as String?);
    });
  }

  PeriodeAkademik _toPeriode(ResultRow r) => PeriodeAkademik(
    id: r[0]! as String, nama: r[1]! as String, tahunAkademik: r[2]! as String,
    semester: r[3]! as String, tanggalMulai: (r[4] as DateTime), tanggalSelesai: (r[5] as DateTime), aktif: r[6]! as bool,
  );

  // ------------------------------------------------------------- civitas

  @override
  Future<Page<Mahasiswa>> listMahasiswa(AppUser actor, PageRequest request, {String? status}) {
    return _asUser(actor, (tx) async {
      final params = {
        'q': request.query,
        'status': status,
        'limit': request.limit,
        'offset': request.offset,
      };
      const filter = '''
        WHERE (@q::text IS NULL OR m.npm ILIKE '%' || @q || '%' OR m.nama_lengkap ILIKE '%' || @q || '%')
          AND (@status::text IS NULL OR m.status = @status)
      ''';
      final count = await tx.execute(
        Sql.named('SELECT count(*) FROM public.mahasiswa m $filter'),
        parameters: {'q': request.query, 'status': status},
      );
      final rows = await tx.execute(
        Sql.named('''
          SELECT m.npm, m.id_user, m.nama_lengkap, m.id_program_studi, m.tahun_masuk,
                 m.jenis_kelamin, m.tanggal_lahir, m.status, m.id_dosen_wali, m.nik,
                 m.nama_ibu_kandung
          FROM public.mahasiswa m $filter
          ORDER BY m.npm LIMIT @limit OFFSET @offset
        '''),
        parameters: params,
      );
      return Page(
        items: rows.map(_toMahasiswa).toList(),
        total: _int(count.first[0]),
        page: request.page,
        limit: request.limit,
      );
    });
  }

  @override
  Future<Page<Dosen>> listDosen(AppUser actor, PageRequest request, {String? status}) {
    return _asUser(actor, (tx) async {
      final params = {
        'q': request.query,
        'status': status,
        'limit': request.limit,
        'offset': request.offset,
      };
      const filter = '''
        WHERE (@q::text IS NULL OR d.nidn ILIKE '%' || @q || '%' OR d.nama_lengkap ILIKE '%' || @q || '%')
          AND (@status::text IS NULL OR d.status = @status)
      ''';
      final count = await tx.execute(
        Sql.named('SELECT count(*) FROM public.dosen d $filter'),
        parameters: {'q': request.query, 'status': status},
      );
      final rows = await tx.execute(
        Sql.named('''
          SELECT d.nidn, d.id_user, d.nama_lengkap, d.id_program_studi, d.status,
                 d.gelar_akademik, d.jenis_kelamin, d.tanggal_lahir
          FROM public.dosen d $filter
          ORDER BY d.nama_lengkap LIMIT @limit OFFSET @offset
        '''),
        parameters: params,
      );
      return Page(
        items: rows.map(_toDosen).toList(),
        total: _int(count.first[0]),
        page: request.page,
        limit: request.limit,
      );
    });
  }

  @override
  Future<String> nextNpm(AppUser actor, String prefix) {
    return _asUser(actor, (tx) async {
      final rows = await tx.execute(
        Sql.named('SELECT public.fn_next_npm(@prefix)'),
        parameters: {'prefix': prefix},
      );
      return rows.first[0]! as String;
    });
  }

  @override
  Future<Mahasiswa> createMahasiswa(AppUser actor, CreateMahasiswaInput input) async {
    try {
      return await _pool.runTx((tx) async {
        final npm = input.npm ?? await _generateNpm(tx, input);
        final password = input.password ??
            (input.tanggalLahir == null
                ? 'SIAKAD#2026'
                : '$npm#${input.tanggalLahir!.day.toString().padLeft(2, '0')}'
                    '${input.tanggalLahir!.month.toString().padLeft(2, '0')}'
                    '${input.tanggalLahir!.year.toString().substring(2)}');

        final auth = await tx.execute(
          Sql.named('''
            INSERT INTO auth.users (email, encrypted_password, email_confirmed_at)
            VALUES (@email, crypt(@password, gen_salt('bf')), now()) RETURNING id
          '''),
          parameters: {'email': input.email.toLowerCase(), 'password': password},
        );
        final id = auth.first[0]! as String;

        await tx.execute(
          Sql.named('''
            INSERT INTO public."user" (id, email, nama_lengkap, telepon, aktif)
            VALUES (@id, @email, @nama, @telepon, true)
          '''),
          parameters: {
            'id': id,
            'email': input.email.toLowerCase(),
            'nama': input.namaLengkap.trim(),
            'telepon': input.telepon,
          },
        );
        await _replaceRoles(tx, id, const ['MAHASISWA']);
        await tx.execute(
          Sql.named('''
            INSERT INTO public.mahasiswa
              (npm, id_user, nama_lengkap, id_program_studi, tahun_masuk,
               jenis_kelamin, tanggal_lahir, status, id_dosen_wali, nik, nama_ibu_kandung)
            VALUES (@npm, @id, @nama, @prodi, @tahun, @jk, @lahir, 'AKTIF',
                    @wali, @nik, @ibu)
          '''),
          parameters: {
            'npm': npm,
            'id': id,
            'nama': input.namaLengkap.trim(),
            'prodi': input.idProgramStudi,
            'tahun': input.tahunMasuk,
            'jk': input.jenisKelamin,
            'lahir': input.tanggalLahir,
            'wali': input.idDosenWali,
            'nik': input.nik,
            'ibu': input.namaIbuKandung,
          },
        );
        await _audit(tx, actor.id, 'MAHASISWA_CREATE', 'mahasiswa', npm, {'email': input.email});
        return (await _findMahasiswa(tx, npm))!;
      });
    } on ServerException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<Dosen> createDosen(AppUser actor, CreateDosenInput input) async {
    try {
      return await _pool.runTx((tx) async {
        final password = input.password ?? 'SIAKAD#2026';
        final auth = await tx.execute(
          Sql.named('''
            INSERT INTO auth.users (email, encrypted_password, email_confirmed_at)
            VALUES (@email, crypt(@password, gen_salt('bf')), now()) RETURNING id
          '''),
          parameters: {'email': input.email.toLowerCase(), 'password': password},
        );
        final id = auth.first[0]! as String;

        await tx.execute(
          Sql.named('''
            INSERT INTO public."user" (id, email, nama_lengkap, telepon, aktif)
            VALUES (@id, @email, @nama, @telepon, true)
          '''),
          parameters: {
            'id': id,
            'email': input.email.toLowerCase(),
            'nama': input.namaLengkap.trim(),
            'telepon': input.telepon,
          },
        );
        await _replaceRoles(tx, id, const ['DOSEN']);
        await tx.execute(
          Sql.named('''
            INSERT INTO public.dosen
              (nidn, id_user, nama_lengkap, id_program_studi, gelar_akademik,
               jenis_kelamin, tanggal_lahir, status)
            VALUES (@nidn, @id, @nama, @prodi, @gelar, @jk, @lahir, 'AKTIF')
          '''),
          parameters: {
            'nidn': input.nidn,
            'id': id,
            'nama': input.namaLengkap.trim(),
            'prodi': input.idProgramStudi,
            'gelar': input.gelarAkademik,
            'jk': input.jenisKelamin,
            'lahir': input.tanggalLahir,
          },
        );
        await _audit(tx, actor.id, 'DOSEN_CREATE', 'dosen', input.nidn, {'email': input.email});
        return (await _findDosen(tx, input.nidn))!;
      });
    } on ServerException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<Mahasiswa> updateMahasiswa(
    AppUser actor,
    String npm, {
    String? namaLengkap,
    String? status,
    String? idDosenWali,
    String? telepon,
  }) async {
    try {
      return await _asUser(actor, (tx) async {
        await tx.execute(
          Sql.named('''
            UPDATE public.mahasiswa
            SET nama_lengkap = COALESCE(@nama, nama_lengkap),
                status = COALESCE(@status, status),
                id_dosen_wali = COALESCE(@wali, id_dosen_wali)
            WHERE npm = @npm
          '''),
          parameters: {'npm': npm, 'nama': namaLengkap, 'status': status, 'wali': idDosenWali},
        );
        if (telepon != null) {
          await tx.execute(
            Sql.named('''
              UPDATE public."user" u SET telepon = @telepon
              FROM public.mahasiswa m WHERE m.id_user = u.id AND m.npm = @npm
            '''),
            parameters: {'npm': npm, 'telepon': telepon},
          );
        }
        await _audit(tx, actor.id, 'MAHASISWA_UPDATE', 'mahasiswa', npm, {
          if (status != null) 'status': status,
        });
        final mhs = await _findMahasiswa(tx, npm);
        if (mhs == null) throw const NotFoundException('Mahasiswa tidak ditemukan.');
        return mhs;
      });
    } on ServerException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<Dosen> updateDosen(
    AppUser actor,
    String nidn, {
    String? namaLengkap,
    String? status,
    String? telepon,
  }) async {
    try {
      return await _asUser(actor, (tx) async {
        await tx.execute(
          Sql.named('''
            UPDATE public.dosen
            SET nama_lengkap = COALESCE(@nama, nama_lengkap),
                status = COALESCE(@status, status)
            WHERE nidn = @nidn
          '''),
          parameters: {'nidn': nidn, 'nama': namaLengkap, 'status': status},
        );
        if (telepon != null) {
          await tx.execute(
            Sql.named('''
              UPDATE public."user" u SET telepon = @telepon
              FROM public.dosen d WHERE d.id_user = u.id AND d.nidn = @nidn
            '''),
            parameters: {'nidn': nidn, 'telepon': telepon},
          );
        }
        await _audit(tx, actor.id, 'DOSEN_UPDATE', 'dosen', nidn, {
          if (status != null) 'status': status,
        });
        final dosen = await _findDosen(tx, nidn);
        if (dosen == null) throw const NotFoundException('Dosen tidak ditemukan.');
        return dosen;
      });
    } on ServerException catch (e) {
      throw _mapError(e);
    }
  }

  // ------------------------------------------------------------ dashboard

  @override
  Future<DashboardStats> stats(AppUser actor) {
    return _asUser(actor, (tx) async {
      final rows = await tx.execute('SELECT * FROM public.v_dashboard_stats');
      final r = rows.first;
      return DashboardStats(
        mahasiswaAktif: _int(r[0]),
        dosenAktif: _int(r[1]),
        programStudi: _int(r[2]),
        krsAktif: _int(r[3]),
        krsMenunggu: _int(r[4]),
        suratMenunggu: _int(r[5]),
        aktivitasHariIni: _int(r[6]),
      );
    });
  }

  @override
  Future<Page<AuditLog>> listLogs(AppUser actor, PageRequest request) {
    return _asUser(actor, (tx) async {
      final count = await tx.execute('SELECT count(*) FROM public.log_aktivitas');
      final rows = await tx.execute(
        Sql.named('''
          SELECT id, id_user, aksi, entitas, id_entitas, metadata, alamat_ip, dibuat_pada
          FROM public.log_aktivitas ORDER BY dibuat_pada DESC, id DESC
          LIMIT @limit OFFSET @offset
        '''),
        parameters: {'limit': request.limit, 'offset': request.offset},
      );
      return Page(
        items: rows
            .map((r) => AuditLog(
                  id: r[0]! as String,
                  idUser: r[1] as String?,
                  aksi: r[2]! as String,
                  entitas: r[3]! as String,
                  idEntitas: r[4] as String?,
                  metadata: (r[5] as Map?)?.cast<String, Object?>(),
                  alamatIp: r[6] as String?,
                  dibuatPada: r[7]! as DateTime,
                ))
            .toList(),
        total: _int(count.first[0]),
        page: request.page,
        limit: request.limit,
      );
    });
  }

  Future<Map<String, Object?>?> verifyLetter(String token) async {
    final result = await _pool.execute(
      Sql.named('SELECT * FROM public.fn_verify_letter(@token::uuid)'),
      parameters: {'token': token},
    );
    return result.isEmpty ? null : result.first.toColumnMap();
  }

  // --------------------------------------------------------------- helpers

  Future<T> _asUser<T>(AppUser actor, Future<T> Function(TxSession tx) fn) {
    return _pool.runTx((tx) async {
      await tx.execute('SET LOCAL ROLE authenticated');
      await tx.execute(
        Sql.named("SELECT set_config('request.jwt.claim.sub', @sub, true)"),
        parameters: {'sub': actor.id},
      );
      return fn(tx);
    });
  }

  Future<String> _generateNpm(TxSession tx, CreateMahasiswaInput input) async {
    final prodi = await tx.execute(
      Sql.named('SELECT kode FROM public.program_studi WHERE id = @id'),
      parameters: {'id': input.idProgramStudi},
    );
    if (prodi.isEmpty) throw const ValidationException('Program studi tidak ditemukan.');
    final kode = prodi.first[0]! as String;
    final pp = RegExp(r'^[0-9]{2}$').hasMatch(kode)
        ? kode
        : switch (kode) {
            'TI' => '10',
            'SI' => '20',
            _ => '99',
          };
    final yy = (input.tahunMasuk % 100).toString().padLeft(2, '0');
    final prefix = '$yy'
        '001'
        '$pp';
    final rows = await tx.execute(
      Sql.named('SELECT public.fn_next_npm(@prefix)'),
      parameters: {'prefix': prefix},
    );
    return rows.first[0]! as String;
  }

  Future<Mahasiswa?> _findMahasiswa(TxSession tx, String npm) async {
    final rows = await tx.execute(
      Sql.named('''
        SELECT npm, id_user, nama_lengkap, id_program_studi, tahun_masuk,
               jenis_kelamin, tanggal_lahir, status, id_dosen_wali, nik, nama_ibu_kandung
        FROM public.mahasiswa WHERE npm = @npm
      '''),
      parameters: {'npm': npm},
    );
    return rows.isEmpty ? null : _toMahasiswa(rows.first);
  }

  Future<Dosen?> _findDosen(TxSession tx, String nidn) async {
    final rows = await tx.execute(
      Sql.named('''
        SELECT nidn, id_user, nama_lengkap, id_program_studi, status,
               gelar_akademik, jenis_kelamin, tanggal_lahir
        FROM public.dosen WHERE nidn = @nidn
      '''),
      parameters: {'nidn': nidn},
    );
    return rows.isEmpty ? null : _toDosen(rows.first);
  }

  Future<void> _replaceRoles(TxSession tx, String userId, List<String> roles) async {
    await tx.execute(
      Sql.named('DELETE FROM public.user_role WHERE id_user = @id'),
      parameters: {'id': userId},
    );
    await tx.execute(
      Sql.named('''
        INSERT INTO public.user_role (id, id_user, id_role)
        SELECT gen_random_uuid(), @id, r.id FROM public.role r WHERE r.nama = ANY(@roles::text[])
        ON CONFLICT (id_user, id_role) DO NOTHING
      '''),
      parameters: {'id': userId, 'roles': roles},
    );
  }

  Future<void> _audit(
    TxSession tx,
    String actorId,
    String aksi,
    String entitas,
    String idEntitas,
    Map<String, Object?> metadata,
  ) async {
    await tx.execute(
      Sql.named('''
        INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
        VALUES (@user, @aksi, @entitas, @id, @metadata::jsonb)
      '''),
      parameters: {
        'user': actorId,
        'aksi': aksi,
        'entitas': entitas,
        'id': idEntitas,
        'metadata': jsonEncode(metadata),
      },
    );
  }

  AppUser _toUser(ResultRow row) => AppUser(
        id: row[0]! as String,
        email: row[1]! as String,
        namaLengkap: row[2]! as String,
        telepon: row[3] as String?,
        urlAvatar: row[4] as String?,
        aktif: row[5]! as bool,
        roles: (row[6] as List?)?.cast<String>() ?? const [],
      );

  Mahasiswa _toMahasiswa(ResultRow r) => Mahasiswa(
        npm: r[0]! as String,
        idUser: r[1]! as String,
        namaLengkap: r[2]! as String,
        idProgramStudi: r[3]! as String,
        tahunMasuk: _int(r[4]),
        jenisKelamin: r[5]! as String,
        tanggalLahir: r[6] as DateTime?,
        status: r[7]! as String,
        idDosenWali: r[8] as String?,
        nik: r[9] as String?,
        namaIbuKandung: r[10] as String?,
      );

  Dosen _toDosen(ResultRow r) => Dosen(
        nidn: r[0]! as String,
        idUser: r[1]! as String,
        namaLengkap: r[2]! as String,
        idProgramStudi: r[3]! as String,
        status: r[4]! as String,
        gelarAkademik: r[5] as String?,
        jenisKelamin: r[6] as String?,
        tanggalLahir: r[7] as DateTime?,
      );

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;

  static Exception _mapError(ServerException e) {
    if (e.code == '23505') return const ConflictException('Data sudah ada.');
    if (e.code == '42501') return const ForbiddenException();
    if (e.code == '23503' || e.code == '23514' || e.code == '22001') {
      return ValidationException(e.message);
    }
    return e;
  }
}

const _userSelect = '''
  SELECT u.id, u.email, u.nama_lengkap, u.telepon, u.url_avatar, u.aktif,
         COALESCE(array_agg(r.nama ORDER BY r.nama) FILTER (WHERE r.nama IS NOT NULL), '{}') AS roles
  FROM public."user" u
  LEFT JOIN public.user_role ur ON ur.id_user = u.id
  LEFT JOIN public.role r ON r.id = ur.id_role
''';
