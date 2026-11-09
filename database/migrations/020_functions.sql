-- Business functions. All privileged mutations verify admin role and write audit.

CREATE OR REPLACE FUNCTION public.fn_is_admin(p_user uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
    IF p_user IS DISTINCT FROM auth.uid() THEN
        RETURN false;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM public.user_role ur
        JOIN public.role r ON r.id = ur.id_role
        WHERE ur.id_user = p_user AND r.nama = 'ADMIN'
    );
END $$;

CREATE OR REPLACE FUNCTION public.fn_current_mhs_npm()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT npm FROM public.mahasiswa WHERE id_user = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.fn_current_dosen_nidn()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT nidn FROM public.dosen WHERE id_user = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.fn_next_npm(p_prefix text)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
    v_next integer;
BEGIN
    IF p_prefix !~ '^[0-9]{7}$' THEN
        RAISE EXCEPTION 'Prefix NPM harus 7 digit angka.';
    END IF;

    PERFORM pg_advisory_xact_lock(hashtext('npm:' || p_prefix));

    SELECT COALESCE(MAX(substring(npm FROM 8 FOR 3)::integer), 0) + 1
    INTO v_next
    FROM public.mahasiswa
    WHERE npm LIKE p_prefix || '%';

    IF v_next > 999 THEN
        RAISE EXCEPTION 'Kuota NPM untuk prefix % habis.', p_prefix;
    END IF;

    RETURN p_prefix || lpad(v_next::text, 3, '0');
END $$;

CREATE OR REPLACE FUNCTION public.fn_validate_schedule_conflict()
RETURNS trigger
LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
BEGIN
    IF NEW.jam_mulai >= NEW.jam_selesai THEN
        RAISE EXCEPTION 'Jam mulai harus lebih awal dari jam selesai.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.jadwal_kelas j
        WHERE j.id_kelas = NEW.id_kelas
          AND j.hari = NEW.hari
          AND j.id <> NEW.id
          AND NEW.jam_mulai < j.jam_selesai
          AND NEW.jam_selesai > j.jam_mulai
    ) THEN
        RAISE EXCEPTION 'Jadwal bentrok dengan kelas yang sama.';
    END IF;

    IF NEW.id_ruangan IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.jadwal_kelas j
        WHERE j.id_ruangan = NEW.id_ruangan
          AND j.hari = NEW.hari
          AND j.id <> NEW.id
          AND NEW.jam_mulai < j.jam_selesai
          AND NEW.jam_selesai > j.jam_mulai
    ) THEN
        RAISE EXCEPTION 'Ruangan sudah dipakai pada jam tersebut.';
    END IF;

    RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_validate_schedule_conflict ON public.jadwal_kelas;
CREATE TRIGGER trg_validate_schedule_conflict
    BEFORE INSERT OR UPDATE ON public.jadwal_kelas
    FOR EACH ROW EXECUTE FUNCTION public.fn_validate_schedule_conflict();

CREATE OR REPLACE FUNCTION public.fn_admin_force_add_krs(
    p_mahasiswa text,
    p_kelas uuid,
    p_actor uuid DEFAULT auth.uid()
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
    v_id uuid;
    v_periode uuid;
BEGIN
    IF NOT public.fn_is_admin(p_actor) THEN
        RAISE EXCEPTION 'Hanya admin yang boleh menambah KRS paksa.' USING ERRCODE = '42501';
    END IF;

    SELECT id_periode_akademik INTO v_periode FROM public.kelas WHERE id = p_kelas;
    IF v_periode IS NULL THEN
        RAISE EXCEPTION 'Kelas tidak ditemukan.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.krs k
        JOIN public.kelas kl ON kl.id = k.id_kelas
        WHERE k.id_mahasiswa = p_mahasiswa
          AND k.id_periode_akademik = v_periode
          AND k.status <> 'BATAL'
          AND kl.id_mata_kuliah = (SELECT id_mata_kuliah FROM public.kelas WHERE id = p_kelas)
    ) THEN
        RAISE EXCEPTION 'Mata kuliah sudah ada di KRS periode ini.';
    END IF;

    INSERT INTO public.krs
        (id_mahasiswa, id_kelas, id_periode_akademik, status, disetujui_oleh_pa, disetujui_pada)
    VALUES
        (p_mahasiswa, p_kelas, v_periode, 'AKTIF', true, now())
    RETURNING id INTO v_id;

    INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
    VALUES (p_actor, 'KRS_FORCE_ADD', 'krs', v_id::text,
            jsonb_build_object('npm', p_mahasiswa, 'kelas', p_kelas));

    RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.fn_admin_emergency_bypass_krs(
    p_krs uuid,
    p_alasan text,
    p_actor uuid DEFAULT auth.uid()
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
    IF NOT public.fn_is_admin(p_actor) THEN
        RAISE EXCEPTION 'Hanya admin yang boleh bypass KRS.' USING ERRCODE = '42501';
    END IF;

    UPDATE public.krs
    SET status = 'AKTIF', disetujui_oleh_pa = true, disetujui_pada = now(),
        catatan_pa = COALESCE(catatan_pa, '') || E'\n[EMERGENCY] ' || p_alasan
    WHERE id = p_krs;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'KRS tidak ditemukan.';
    END IF;

    INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
    VALUES (p_actor, 'KRS_EMERGENCY_BYPASS', 'krs', p_krs::text,
            jsonb_build_object('alasan', p_alasan));
END $$;

CREATE OR REPLACE FUNCTION public.kunci_nilai() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT OLD.sudah_final AND NEW.sudah_final THEN
        NEW.disubmit_pada := now();
    END IF;

    IF OLD.sudah_final
       AND current_setting('siakad.allow_unlock', true) IS DISTINCT FROM 'on' THEN
        IF (NEW.sudah_final, NEW.nilai_uts, NEW.nilai_uas,
            NEW.nilai_tugas, NEW.nilai_akhir, NEW.huruf_nilai)
           IS DISTINCT FROM
           (OLD.sudah_final, OLD.nilai_uts, OLD.nilai_uas,
            OLD.nilai_tugas, OLD.nilai_akhir, OLD.huruf_nilai)
        THEN
            RAISE EXCEPTION 'Nilai sudah difinalisasi, tidak dapat diubah lagi.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_admin_unlock_class_grades(
    p_kelas uuid,
    p_alasan text,
    p_actor uuid DEFAULT auth.uid()
) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
    v_count integer;
BEGIN
    IF NOT public.fn_is_admin(p_actor) THEN
        RAISE EXCEPTION 'Hanya admin yang boleh membuka kunci nilai.' USING ERRCODE = '42501';
    END IF;

    PERFORM set_config('siakad.allow_unlock', 'on', true);

    UPDATE public.nilai n
    SET sudah_final = false
    FROM public.krs k
    WHERE n.id_krs = k.id AND k.id_kelas = p_kelas AND n.sudah_final;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
    VALUES (p_actor, 'GRADE_UNLOCK', 'kelas', p_kelas::text,
            jsonb_build_object('alasan', p_alasan, 'jumlah', v_count));

    RETURN v_count;
END $$;

CREATE OR REPLACE FUNCTION public.fn_admin_grant_attendance_dispensation(
    p_presensi uuid,
    p_krs uuid,
    p_alasan text,
    p_actor uuid DEFAULT auth.uid()
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
    v_id uuid;
BEGIN
    IF NOT public.fn_is_admin(p_actor) THEN
        RAISE EXCEPTION 'Hanya admin yang boleh memberi dispensasi.' USING ERRCODE = '42501';
    END IF;

    INSERT INTO public.rekap_presensi (id_presensi, id_krs, status, keterangan)
    VALUES (p_presensi, p_krs, 'DISPENSASI', p_alasan)
    ON CONFLICT (id_presensi, id_krs)
    DO UPDATE SET status = 'DISPENSASI', keterangan = EXCLUDED.keterangan
    RETURNING id INTO v_id;

    INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
    VALUES (p_actor, 'ATTENDANCE_DISPENSATION', 'rekap_presensi', v_id::text,
            jsonb_build_object('presensi', p_presensi, 'krs', p_krs, 'alasan', p_alasan));

    RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.fn_admin_finalize_yudisium(
    p_yudisium uuid,
    p_actor uuid DEFAULT auth.uid()
) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
    v_count integer;
    v_tanggal date;
BEGIN
    IF NOT public.fn_is_admin(p_actor) THEN
        RAISE EXCEPTION 'Hanya admin yang boleh mengesahkan yudisium.' USING ERRCODE = '42501';
    END IF;

    SELECT COALESCE(tanggal_sk, CURRENT_DATE) INTO v_tanggal
    FROM public.yudisium WHERE id = p_yudisium;

    IF v_tanggal IS NULL THEN
        RAISE EXCEPTION 'Yudisium tidak ditemukan.';
    END IF;

    UPDATE public.yudisium SET status = 'DISAHKAN' WHERE id = p_yudisium;

    UPDATE public.mahasiswa m
    SET status = 'LULUS', tanggal_lulus = v_tanggal
    FROM public.peserta_yudisium p
    WHERE p.id_yudisium = p_yudisium
      AND p.id_mahasiswa = m.npm
      AND p.status_audit = 'MEMENUHI';

    GET DIAGNOSTICS v_count = ROW_COUNT;

    INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
    VALUES (p_actor, 'YUDISIUM_FINALIZE', 'yudisium', p_yudisium::text,
            jsonb_build_object('jumlah_lulus', v_count));

    RETURN v_count;
END $$;

CREATE OR REPLACE FUNCTION public.fn_admin_commit_credit_transfer(
    p_transfer uuid,
    p_actor uuid DEFAULT auth.uid()
) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
    v_npm text;
    v_sk text;
    v_count integer;
BEGIN
    IF NOT public.fn_is_admin(p_actor) THEN
        RAISE EXCEPTION 'Hanya admin yang boleh mengesahkan transfer kredit.' USING ERRCODE = '42501';
    END IF;

    SELECT id_mahasiswa, COALESCE(nomor_sk_penyetaraan, 'TRANSFER-' || p_transfer)
    INTO v_npm, v_sk
    FROM public.mahasiswa_transfer WHERE id = p_transfer;

    IF v_npm IS NULL THEN
        RAISE EXCEPTION 'Transfer kredit tidak ditemukan.';
    END IF;

    INSERT INTO public.nilai_konversi_transkrip
        (id_mahasiswa, id_mata_kuliah, nilai_huruf, bobot_nilai, nomor_sk)
    SELECT v_npm, d.id_mata_kuliah_lokal, d.nilai_huruf_diakui,
           d.bobot_diakui, v_sk
    FROM public.konversi_nilai_detail d
    WHERE d.id_transfer = p_transfer
    ON CONFLICT (id_mahasiswa, id_mata_kuliah)
    DO UPDATE SET nilai_huruf = EXCLUDED.nilai_huruf,
                  bobot_nilai = EXCLUDED.bobot_nilai,
                  nomor_sk = EXCLUDED.nomor_sk;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    UPDATE public.mahasiswa_transfer
    SET status = 'DISAHKAN', disahkan_pada = now()
    WHERE id = p_transfer;

    INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
    VALUES (p_actor, 'CREDIT_TRANSFER_COMMIT', 'mahasiswa_transfer', p_transfer::text,
            jsonb_build_object('npm', v_npm, 'jumlah_mk', v_count));

    RETURN v_count;
END $$;

CREATE OR REPLACE FUNCTION public.fn_next_letter_number(
    p_tahun integer,
    p_klasifikasi text
) RETURNS TABLE (nomor text, urut integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
    v_next integer;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext('surat:' || p_tahun || ':' || p_klasifikasi));

    SELECT COALESCE(MAX(nomor_urut), 0) + 1 INTO v_next
    FROM public.permohonan_surat
    WHERE tahun_terbit = p_tahun;

    RETURN QUERY SELECT
        lpad(v_next::text, 3, '0') || '/' || p_klasifikasi || '/' || p_tahun,
        v_next;
END $$;

CREATE OR REPLACE FUNCTION public.fn_admin_issue_academic_letter(
    p_permohonan uuid,
    p_pejabat text DEFAULT NULL,
    p_actor uuid DEFAULT auth.uid()
) RETURNS TABLE (nomor_surat text, token uuid)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
    v_klasifikasi text;
    v_tahun integer := extract(year FROM CURRENT_DATE)::integer;
    v_nomor text;
    v_urut integer;
    v_token uuid := gen_random_uuid();
BEGIN
    IF NOT public.fn_is_admin(p_actor) THEN
        RAISE EXCEPTION 'Hanya admin yang boleh menerbitkan surat.' USING ERRCODE = '42501';
    END IF;

    SELECT t.kode_klasifikasi INTO v_klasifikasi
    FROM public.permohonan_surat p
    JOIN public.template_surat t ON t.id = p.id_template
    WHERE p.id = p_permohonan;

    IF v_klasifikasi IS NULL THEN
        RAISE EXCEPTION 'Permohonan surat tidak ditemukan.';
    END IF;

    SELECT n.nomor, n.urut INTO v_nomor, v_urut
    FROM public.fn_next_letter_number(v_tahun, v_klasifikasi) n;

    UPDATE public.permohonan_surat
    SET nomor_surat = v_nomor,
        nomor_urut = v_urut,
        tahun_terbit = v_tahun,
        token_verifikasi = v_token,
        pejabat_penandatangan = p_pejabat,
        status = 'SELESAI',
        diterbitkan_pada = now()
    WHERE id = p_permohonan;

    INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
    VALUES (p_actor, 'LETTER_ISSUE', 'permohonan_surat', p_permohonan::text,
            jsonb_build_object('nomor', v_nomor));

    RETURN QUERY SELECT v_nomor, v_token;
END $$;

CREATE OR REPLACE FUNCTION public.fn_verify_letter(p_token uuid)
RETURNS TABLE (
    nomor_surat text,
    nama_mahasiswa text,
    npm text,
    layanan text,
    status text,
    diterbitkan_pada timestamptz,
    berlaku_hingga date
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT p.nomor_surat, m.nama_lengkap, m.npm, t.nama_layanan,
           p.status, p.diterbitkan_pada, p.berlaku_hingga
    FROM public.permohonan_surat p
    JOIN public.mahasiswa m ON m.npm = p.id_mahasiswa
    JOIN public.template_surat t ON t.id = p.id_template
    WHERE p.token_verifikasi = p_token AND p.status = 'SELESAI'
$$;

GRANT EXECUTE ON FUNCTION public.fn_verify_letter(uuid) TO anon, authenticated;

-- Audit chain: append-only + hash of previous row.
CREATE OR REPLACE FUNCTION public.fn_audit_chain()
RETURNS trigger
LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
DECLARE
    v_prev text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext('log_aktivitas'));

    SELECT hash_integritas INTO v_prev
    FROM public.log_aktivitas
    ORDER BY dibuat_pada DESC, id DESC
    LIMIT 1;

    NEW.hash_sebelumnya := v_prev;
    NEW.hash_integritas := encode(digest(
        COALESCE(v_prev, '') || NEW.id::text ||
        COALESCE(NEW.id_user::text, '') || NEW.aksi ||
        COALESCE(NEW.entitas, '') || COALESCE(NEW.id_entitas, '') ||
        COALESCE(NEW.metadata::text, '') || NEW.dibuat_pada::text,
        'sha256'
    ), 'hex');

    RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_audit_chain ON public.log_aktivitas;
CREATE TRIGGER trg_audit_chain
    BEFORE INSERT ON public.log_aktivitas
    FOR EACH ROW EXECUTE FUNCTION public.fn_audit_chain();

CREATE OR REPLACE FUNCTION public.fn_audit_append_only()
RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'log_aktivitas bersifat append-only.';
END $$;

DROP TRIGGER IF EXISTS trg_audit_append_only ON public.log_aktivitas;
CREATE TRIGGER trg_audit_append_only
    BEFORE UPDATE OR DELETE ON public.log_aktivitas
    FOR EACH ROW EXECUTE FUNCTION public.fn_audit_append_only();
