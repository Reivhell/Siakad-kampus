-- Local demo identities and one class. Never apply to production.
-- Passwords: Admin#12345 / Dosen#12345 / Mhs#12345

DO $$
DECLARE
    v_admin uuid;
    v_dosen_user uuid;
    v_mhs_user uuid;
    v_role uuid;
    v_prodi uuid;
BEGIN
    SELECT id INTO v_admin FROM public."user" WHERE lower(email) = 'admin@kampus.ac.id';
    IF v_admin IS NULL THEN
        v_admin := '80000000-0000-0000-0000-000000000001';
    END IF;

    INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at)
    VALUES (v_admin, 'admin@kampus.ac.id', crypt('Admin#12345', gen_salt('bf')), now())
    ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email,
            encrypted_password = EXCLUDED.encrypted_password,
            email_confirmed_at = COALESCE(auth.users.email_confirmed_at, now());

    INSERT INTO public."user" (id, email, nama_lengkap, telepon, aktif)
    VALUES (v_admin, 'admin@kampus.ac.id', 'Administrator SIAKAD', '081200000001', true)
    ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email,
            nama_lengkap = EXCLUDED.nama_lengkap,
            aktif = true;

    SELECT id INTO v_role FROM public.role WHERE nama = 'ADMIN';
    INSERT INTO public.user_role (id, id_user, id_role)
    VALUES (gen_random_uuid(), v_admin, v_role)
    ON CONFLICT (id_user, id_role) DO NOTHING;

    SELECT id INTO v_dosen_user FROM public."user" WHERE lower(email) = 'dosen@kampus.ac.id';
    IF v_dosen_user IS NULL THEN
        v_dosen_user := '80000000-0000-0000-0000-000000000002';
    END IF;

    INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at)
    VALUES (v_dosen_user, 'dosen@kampus.ac.id', crypt('Dosen#12345', gen_salt('bf')), now())
    ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email,
            encrypted_password = EXCLUDED.encrypted_password,
            email_confirmed_at = COALESCE(auth.users.email_confirmed_at, now());

    INSERT INTO public."user" (id, email, nama_lengkap, telepon, aktif)
    VALUES (v_dosen_user, 'dosen@kampus.ac.id', 'Dr. Budi Santoso', '081200000002', true)
    ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email,
            nama_lengkap = EXCLUDED.nama_lengkap,
            aktif = true;

    SELECT id INTO v_role FROM public.role WHERE nama = 'DOSEN';
    INSERT INTO public.user_role (id, id_user, id_role)
    VALUES (gen_random_uuid(), v_dosen_user, v_role)
    ON CONFLICT (id_user, id_role) DO NOTHING;

    SELECT id INTO v_prodi FROM public.program_studi WHERE kode = 'TI';
    INSERT INTO public.dosen
        (nidn, id_user, nama_lengkap, id_program_studi, gelar_akademik,
         jenis_kelamin, tanggal_lahir, status)
    VALUES
        ('0101010101', v_dosen_user, 'Dr. Budi Santoso', v_prodi, 'S.Kom., M.Kom.',
         'L', '1980-01-01', 'AKTIF')
    ON CONFLICT (nidn) DO UPDATE
        SET id_user = EXCLUDED.id_user, status = 'AKTIF';

    SELECT id INTO v_mhs_user FROM public."user" WHERE lower(email) = 'mahasiswa@kampus.ac.id';
    IF v_mhs_user IS NULL THEN
        v_mhs_user := '80000000-0000-0000-0000-000000000003';
    END IF;

    INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at)
    VALUES (v_mhs_user, 'mahasiswa@kampus.ac.id', crypt('Mhs#12345', gen_salt('bf')), now())
    ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email,
            encrypted_password = EXCLUDED.encrypted_password,
            email_confirmed_at = COALESCE(auth.users.email_confirmed_at, now());

    INSERT INTO public."user" (id, email, nama_lengkap, telepon, aktif)
    VALUES (v_mhs_user, 'mahasiswa@kampus.ac.id', 'Siti Aminah', '081200000003', true)
    ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email,
            nama_lengkap = EXCLUDED.nama_lengkap,
            aktif = true;

    SELECT id INTO v_role FROM public.role WHERE nama = 'MAHASISWA';
    INSERT INTO public.user_role (id, id_user, id_role)
    VALUES (gen_random_uuid(), v_mhs_user, v_role)
    ON CONFLICT (id_user, id_role) DO NOTHING;

    INSERT INTO public.mahasiswa
        (npm, id_user, nama_lengkap, id_program_studi, tahun_masuk,
         jenis_kelamin, tanggal_lahir, status, id_dosen_wali)
    VALUES
        ('2510100001', v_mhs_user, 'Siti Aminah', v_prodi, 2025,
         'P', '2006-05-10', 'AKTIF', '0101010101')
    ON CONFLICT (npm) DO UPDATE
        SET id_user = EXCLUDED.id_user, status = 'AKTIF', id_dosen_wali = EXCLUDED.id_dosen_wali;
END $$;

INSERT INTO public.kelas
    (id, id_mata_kuliah, id_periode_akademik, kode, kapasitas, jumlah_terdaftar)
SELECT
    '90000000-0000-0000-0000-000000000001',
    mk.id,
    p.id,
    'IF201-A',
    40,
    0
FROM public.mata_kuliah mk, public.periode_akademik p
WHERE mk.kode = 'IF201' AND p.aktif = true
ON CONFLICT (kode) DO NOTHING;

INSERT INTO public.kelas_dosen (id, id_kelas, id_dosen, pengampu_utama)
SELECT gen_random_uuid(), '90000000-0000-0000-0000-000000000001', '0101010101', true
WHERE NOT EXISTS (
    SELECT 1 FROM public.kelas_dosen
    WHERE id_kelas = '90000000-0000-0000-0000-000000000001'
      AND id_dosen = '0101010101'
);

INSERT INTO public.jadwal_kelas (id, id_kelas, id_ruangan, hari, jam_mulai, jam_selesai)
SELECT '91000000-0000-0000-0000-000000000001',
       '90000000-0000-0000-0000-000000000001',
       r.id, 1, '08:00', '10:30'
FROM public.ruangan r
WHERE r.kode = 'LAB-1'
  AND NOT EXISTS (
      SELECT 1 FROM public.jadwal_kelas
      WHERE id_kelas = '90000000-0000-0000-0000-000000000001'
  );

INSERT INTO public.krs
    (id, id_mahasiswa, id_kelas, id_periode_akademik, status,
     disetujui_oleh_pa, disetujui_pada)
SELECT '92000000-0000-0000-0000-000000000001', '2510100001',
       '90000000-0000-0000-0000-000000000001', p.id, 'AKTIF', true, now()
FROM public.periode_akademik p
WHERE p.aktif = true
ON CONFLICT (id_mahasiswa, id_kelas) DO NOTHING;

INSERT INTO public.nilai
    (id, id_krs, nilai_uts, nilai_uas, nilai_tugas, nilai_akhir,
     huruf_nilai, bobot_nilai, sudah_final, disubmit_pada)
VALUES
    ('93000000-0000-0000-0000-000000000001',
     '92000000-0000-0000-0000-000000000001',
     85, 90, 88, 88, 'A', 4.00, true, now())
ON CONFLICT (id_krs) DO NOTHING;

INSERT INTO public.presensi
    (id, id_kelas, pertemuan_ke, tanggal_pertemuan, topik, jam_mulai, jam_selesai, metode)
VALUES
    ('94000000-0000-0000-0000-000000000001',
     '90000000-0000-0000-0000-000000000001', 1, CURRENT_DATE,
     'Pengenalan Basis Data', '08:00', '10:30', 'LURING')
ON CONFLICT (id_kelas, pertemuan_ke) DO NOTHING;

INSERT INTO public.rekap_presensi (id, id_presensi, id_krs, status, keterangan)
VALUES
    ('95000000-0000-0000-0000-000000000001',
     '94000000-0000-0000-0000-000000000001',
     '92000000-0000-0000-0000-000000000001', 'HADIR', NULL)
ON CONFLICT (id_presensi, id_krs) DO NOTHING;
