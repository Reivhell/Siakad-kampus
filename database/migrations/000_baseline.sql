--
-- PostgreSQL database dump
--


-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS public;


--
-- Name: kunci_nilai(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.kunci_nilai() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
    IF NOT OLD.sudah_final AND NEW.sudah_final THEN
        NEW.disubmit_pada := now();
    END IF;

    IF OLD.sudah_final THEN
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


--
-- Name: perbarui_jumlah_terdaftar(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.perbarui_jumlah_terdaftar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ DECLARE
    target_kelas uuid[];
BEGIN
    IF TG_OP = 'DELETE' THEN
        target_kelas := ARRAY[OLD.id_kelas];
    ELSIF TG_OP = 'UPDATE' AND OLD.id_kelas IS DISTINCT FROM NEW.id_kelas THEN
        target_kelas := ARRAY[OLD.id_kelas, NEW.id_kelas];  -- kelas lama + baru
    ELSE
        target_kelas := ARRAY[NEW.id_kelas];
    END IF;

    UPDATE kelas k
    SET jumlah_terdaftar = (
        SELECT COUNT(*) FROM krs r
        WHERE r.id_kelas = k.id AND r.status = 'AKTIF'
    )
    WHERE k.id = ANY(target_kelas);

    RETURN COALESCE(NEW, OLD);
END;
 $$;


--
-- Name: set_diperbarui_pada(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_diperbarui_pada() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
    NEW.diperbarui_pada := now();
    RETURN NEW;
END;
 $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: dosen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dosen (
    nidn text NOT NULL,
    id_user uuid,
    nama_lengkap text NOT NULL,
    id_program_studi uuid NOT NULL,
    gelar_akademik text,
    jenis_kelamin text NOT NULL,
    tanggal_lahir date,
    status text DEFAULT 'AKTIF'::text NOT NULL,
    dibuat_pada timestamp with time zone DEFAULT now() NOT NULL,
    diperbarui_pada timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT dosen_jenis_kelamin_check CHECK ((jenis_kelamin = ANY (ARRAY['L'::text, 'P'::text]))),
    CONSTRAINT dosen_nidn_check CHECK ((nidn ~ '^[0-9]+$'::text)),
    CONSTRAINT dosen_status_check CHECK ((status = ANY (ARRAY['AKTIF'::text, 'TIDAK_AKTIF'::text])))
);


--
-- Name: jadwal_kelas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jadwal_kelas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id_kelas uuid NOT NULL,
    id_ruangan uuid,
    hari integer NOT NULL,
    jam_mulai time without time zone NOT NULL,
    jam_selesai time without time zone NOT NULL,
    CONSTRAINT jadwal_kelas_check CHECK ((jam_selesai > jam_mulai)),
    CONSTRAINT jadwal_kelas_hari_check CHECK (((hari >= 1) AND (hari <= 7)))
);


--
-- Name: kelas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kelas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id_mata_kuliah uuid NOT NULL,
    id_periode_akademik uuid NOT NULL,
    kode text NOT NULL,
    kapasitas integer DEFAULT 30 NOT NULL,
    jumlah_terdaftar integer DEFAULT 0 NOT NULL,
    dibuat_pada timestamp with time zone DEFAULT now() NOT NULL,
    diperbarui_pada timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT kelas_jumlah_terdaftar_check CHECK ((jumlah_terdaftar >= 0)),
    CONSTRAINT kelas_kapasitas_check CHECK ((kapasitas > 0))
);


--
-- Name: kelas_dosen; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kelas_dosen (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id_kelas uuid NOT NULL,
    id_dosen text NOT NULL,
    pengampu_utama boolean DEFAULT true NOT NULL
);


--
-- Name: krs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.krs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id_mahasiswa text NOT NULL,
    id_kelas uuid NOT NULL,
    id_periode_akademik uuid NOT NULL,
    status text DEFAULT 'AKTIF'::text NOT NULL,
    terdaftar_pada timestamp with time zone DEFAULT now() NOT NULL,
    diperbarui_pada timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT krs_status_check CHECK ((status = ANY (ARRAY['AKTIF'::text, 'DIBATALKAN'::text, 'MENGUNDURKAN_DIRI'::text])))
);


--
-- Name: kurikulum; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kurikulum (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id_program_studi uuid NOT NULL,
    nama text NOT NULL,
    tahun integer NOT NULL,
    aktif boolean DEFAULT false NOT NULL,
    dibuat_pada timestamp with time zone DEFAULT now() NOT NULL,
    diperbarui_pada timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: kurikulum_mata_kuliah; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kurikulum_mata_kuliah (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id_kurikulum uuid NOT NULL,
    id_mata_kuliah uuid NOT NULL,
    semester_rekomendasi integer NOT NULL,
    CONSTRAINT kurikulum_mata_kuliah_semester_rekomendasi_check CHECK (((semester_rekomendasi >= 1) AND (semester_rekomendasi <= 8)))
);


--
-- Name: log_aktivitas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_aktivitas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id_user uuid,
    aksi text NOT NULL,
    entitas text NOT NULL,
    id_entitas text,
    metadata jsonb,
    alamat_ip text,
    dibuat_pada timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: mahasiswa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mahasiswa (
    npm text NOT NULL,
    id_user uuid,
    nama_lengkap text NOT NULL,
    id_program_studi uuid NOT NULL,
    tahun_masuk integer NOT NULL,
    jenis_kelamin text NOT NULL,
    tanggal_lahir date,
    status text DEFAULT 'AKTIF'::text NOT NULL,
    dibuat_pada timestamp with time zone DEFAULT now() NOT NULL,
    diperbarui_pada timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mahasiswa_jenis_kelamin_check CHECK ((jenis_kelamin = ANY (ARRAY['L'::text, 'P'::text]))),
    CONSTRAINT mahasiswa_npm_check CHECK ((npm ~ '^[0-9]{10}$'::text)),
    CONSTRAINT mahasiswa_status_check CHECK ((status = ANY (ARRAY['AKTIF'::text, 'CUTI'::text, 'LULUS'::text, 'DO'::text])))
);


--
-- Name: mata_kuliah; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mata_kuliah (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    kode text NOT NULL,
    nama text NOT NULL,
    sks integer NOT NULL,
    semester integer NOT NULL,
    jenis text NOT NULL,
    dibuat_pada timestamp with time zone DEFAULT now() NOT NULL,
    diperbarui_pada timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mata_kuliah_jenis_check CHECK ((jenis = ANY (ARRAY['WAJIB'::text, 'PILIHAN'::text]))),
    CONSTRAINT mata_kuliah_semester_check CHECK (((semester >= 1) AND (semester <= 8))),
    CONSTRAINT mata_kuliah_sks_check CHECK ((sks > 0))
);


--
-- Name: nilai; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nilai (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id_krs uuid NOT NULL,
    nilai_uts numeric(5,2),
    nilai_uas numeric(5,2),
    nilai_tugas numeric(5,2),
    nilai_akhir numeric(5,2),
    huruf_nilai text,
    sudah_final boolean DEFAULT false NOT NULL,
    disubmit_pada timestamp with time zone,
    diperbarui_pada timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT nilai_huruf_nilai_check CHECK ((huruf_nilai = ANY (ARRAY['A'::text, 'AB'::text, 'B'::text, 'BC'::text, 'C'::text, 'D'::text, 'E'::text]))),
    CONSTRAINT nilai_nilai_akhir_check CHECK (((nilai_akhir >= (0)::numeric) AND (nilai_akhir <= (100)::numeric))),
    CONSTRAINT nilai_nilai_tugas_check CHECK (((nilai_tugas >= (0)::numeric) AND (nilai_tugas <= (100)::numeric))),
    CONSTRAINT nilai_nilai_uas_check CHECK (((nilai_uas >= (0)::numeric) AND (nilai_uas <= (100)::numeric))),
    CONSTRAINT nilai_nilai_uts_check CHECK (((nilai_uts >= (0)::numeric) AND (nilai_uts <= (100)::numeric)))
);


--
-- Name: periode_akademik; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.periode_akademik (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nama text NOT NULL,
    tahun_akademik text NOT NULL,
    semester text NOT NULL,
    tanggal_mulai date NOT NULL,
    tanggal_selesai date NOT NULL,
    aktif boolean DEFAULT false NOT NULL,
    dibuat_pada timestamp with time zone DEFAULT now() NOT NULL,
    diperbarui_pada timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT periode_akademik_check CHECK ((tanggal_selesai > tanggal_mulai)),
    CONSTRAINT periode_akademik_semester_check CHECK ((semester = ANY (ARRAY['GANJIL'::text, 'GENAP'::text])))
);


--
-- Name: presensi; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.presensi (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id_kelas uuid NOT NULL,
    pertemuan_ke integer NOT NULL,
    tanggal_pertemuan date NOT NULL,
    topik text,
    dibuat_pada timestamp with time zone DEFAULT now() NOT NULL,
    diperbarui_pada timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT presensi_pertemuan_ke_check CHECK ((pertemuan_ke > 0))
);


--
-- Name: program_studi; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.program_studi (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nama text NOT NULL,
    kode text NOT NULL,
    jenjang text NOT NULL,
    dibuat_pada timestamp with time zone DEFAULT now() NOT NULL,
    diperbarui_pada timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT program_studi_jenjang_check CHECK ((jenjang = ANY (ARRAY['D3'::text, 'S1'::text, 'S2'::text, 'S3'::text])))
);


--
-- Name: rekap_presensi; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rekap_presensi (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id_presensi uuid NOT NULL,
    id_krs uuid NOT NULL,
    status text NOT NULL,
    keterangan text,
    dicatat_pada timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT rekap_presensi_status_check CHECK ((status = ANY (ARRAY['HADIR'::text, 'IZIN'::text, 'SAKIT'::text, 'ALPHA'::text])))
);


--
-- Name: role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nama text NOT NULL,
    CONSTRAINT role_nama_check CHECK ((nama = ANY (ARRAY['ADMIN'::text, 'DOSEN'::text, 'MAHASISWA'::text])))
);


--
-- Name: ruangan; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ruangan (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    kode text NOT NULL,
    nama text NOT NULL,
    kapasitas integer NOT NULL,
    gedung text,
    CONSTRAINT ruangan_kapasitas_check CHECK ((kapasitas > 0))
);


--
-- Name: user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."user" (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email text NOT NULL,
    nama_lengkap text NOT NULL,
    telepon text,
    url_avatar text,
    aktif boolean DEFAULT true NOT NULL,
    dibuat_pada timestamp with time zone DEFAULT now() NOT NULL,
    diperbarui_pada timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_role (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id_user uuid NOT NULL,
    id_role uuid NOT NULL,
    ditugaskan_pada timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: dosen dosen_id_user_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosen
    ADD CONSTRAINT dosen_id_user_key UNIQUE (id_user);


--
-- Name: dosen dosen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosen
    ADD CONSTRAINT dosen_pkey PRIMARY KEY (nidn);


--
-- Name: jadwal_kelas jadwal_kelas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jadwal_kelas
    ADD CONSTRAINT jadwal_kelas_pkey PRIMARY KEY (id);


--
-- Name: kelas_dosen kelas_dosen_id_kelas_id_dosen_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kelas_dosen
    ADD CONSTRAINT kelas_dosen_id_kelas_id_dosen_key UNIQUE (id_kelas, id_dosen);


--
-- Name: kelas_dosen kelas_dosen_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kelas_dosen
    ADD CONSTRAINT kelas_dosen_pkey PRIMARY KEY (id);


--
-- Name: kelas kelas_kode_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kelas
    ADD CONSTRAINT kelas_kode_key UNIQUE (kode);


--
-- Name: kelas kelas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kelas
    ADD CONSTRAINT kelas_pkey PRIMARY KEY (id);


--
-- Name: krs krs_id_mahasiswa_id_kelas_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.krs
    ADD CONSTRAINT krs_id_mahasiswa_id_kelas_key UNIQUE (id_mahasiswa, id_kelas);


--
-- Name: krs krs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.krs
    ADD CONSTRAINT krs_pkey PRIMARY KEY (id);


--
-- Name: kurikulum_mata_kuliah kurikulum_mata_kuliah_id_kurikulum_id_mata_kuliah_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kurikulum_mata_kuliah
    ADD CONSTRAINT kurikulum_mata_kuliah_id_kurikulum_id_mata_kuliah_key UNIQUE (id_kurikulum, id_mata_kuliah);


--
-- Name: kurikulum_mata_kuliah kurikulum_mata_kuliah_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kurikulum_mata_kuliah
    ADD CONSTRAINT kurikulum_mata_kuliah_pkey PRIMARY KEY (id);


--
-- Name: kurikulum kurikulum_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kurikulum
    ADD CONSTRAINT kurikulum_pkey PRIMARY KEY (id);


--
-- Name: log_aktivitas log_aktivitas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_aktivitas
    ADD CONSTRAINT log_aktivitas_pkey PRIMARY KEY (id);


--
-- Name: mahasiswa mahasiswa_id_user_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mahasiswa
    ADD CONSTRAINT mahasiswa_id_user_key UNIQUE (id_user);


--
-- Name: mahasiswa mahasiswa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mahasiswa
    ADD CONSTRAINT mahasiswa_pkey PRIMARY KEY (npm);


--
-- Name: mata_kuliah mata_kuliah_kode_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mata_kuliah
    ADD CONSTRAINT mata_kuliah_kode_key UNIQUE (kode);


--
-- Name: mata_kuliah mata_kuliah_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mata_kuliah
    ADD CONSTRAINT mata_kuliah_pkey PRIMARY KEY (id);


--
-- Name: nilai nilai_id_krs_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nilai
    ADD CONSTRAINT nilai_id_krs_key UNIQUE (id_krs);


--
-- Name: nilai nilai_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nilai
    ADD CONSTRAINT nilai_pkey PRIMARY KEY (id);


--
-- Name: periode_akademik periode_akademik_nama_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periode_akademik
    ADD CONSTRAINT periode_akademik_nama_key UNIQUE (nama);


--
-- Name: periode_akademik periode_akademik_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periode_akademik
    ADD CONSTRAINT periode_akademik_pkey PRIMARY KEY (id);


--
-- Name: presensi presensi_id_kelas_pertemuan_ke_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presensi
    ADD CONSTRAINT presensi_id_kelas_pertemuan_ke_key UNIQUE (id_kelas, pertemuan_ke);


--
-- Name: presensi presensi_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presensi
    ADD CONSTRAINT presensi_pkey PRIMARY KEY (id);


--
-- Name: program_studi program_studi_kode_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_studi
    ADD CONSTRAINT program_studi_kode_key UNIQUE (kode);


--
-- Name: program_studi program_studi_nama_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_studi
    ADD CONSTRAINT program_studi_nama_key UNIQUE (nama);


--
-- Name: program_studi program_studi_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_studi
    ADD CONSTRAINT program_studi_pkey PRIMARY KEY (id);


--
-- Name: rekap_presensi rekap_presensi_id_presensi_id_krs_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rekap_presensi
    ADD CONSTRAINT rekap_presensi_id_presensi_id_krs_key UNIQUE (id_presensi, id_krs);


--
-- Name: rekap_presensi rekap_presensi_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rekap_presensi
    ADD CONSTRAINT rekap_presensi_pkey PRIMARY KEY (id);


--
-- Name: role role_nama_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_nama_key UNIQUE (nama);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (id);


--
-- Name: ruangan ruangan_kode_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ruangan
    ADD CONSTRAINT ruangan_kode_key UNIQUE (kode);


--
-- Name: ruangan ruangan_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ruangan
    ADD CONSTRAINT ruangan_pkey PRIMARY KEY (id);


--
-- Name: user user_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_email_key UNIQUE (email);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: user_role user_role_id_user_id_role_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_id_user_id_role_key UNIQUE (id_user, id_role);


--
-- Name: user_role user_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_pkey PRIMARY KEY (id);


--
-- Name: idx_dosen_program_studi; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dosen_program_studi ON public.dosen USING btree (id_program_studi);


--
-- Name: idx_jadwal_kelas_id_kelas; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_jadwal_kelas_id_kelas ON public.jadwal_kelas USING btree (id_kelas);


--
-- Name: idx_kelas_mata_kuliah; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kelas_mata_kuliah ON public.kelas USING btree (id_mata_kuliah);


--
-- Name: idx_kelas_periode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kelas_periode ON public.kelas USING btree (id_periode_akademik);


--
-- Name: idx_krs_kelas; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_krs_kelas ON public.krs USING btree (id_kelas);


--
-- Name: idx_krs_mahasiswa_periode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_krs_mahasiswa_periode ON public.krs USING btree (id_mahasiswa, id_periode_akademik);


--
-- Name: idx_kurikulum_prodi; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kurikulum_prodi ON public.kurikulum USING btree (id_program_studi);


--
-- Name: idx_log_aktivitas_dibuat_pada; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_log_aktivitas_dibuat_pada ON public.log_aktivitas USING btree (dibuat_pada DESC);


--
-- Name: idx_log_aktivitas_id_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_log_aktivitas_id_user ON public.log_aktivitas USING btree (id_user);


--
-- Name: idx_mahasiswa_program_studi; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mahasiswa_program_studi ON public.mahasiswa USING btree (id_program_studi);


--
-- Name: idx_presensi_id_kelas; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_presensi_id_kelas ON public.presensi USING btree (id_kelas);


--
-- Name: idx_rekap_krs; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rekap_krs ON public.rekap_presensi USING btree (id_krs);


--
-- Name: idx_rekap_presensi_id_presensi; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rekap_presensi_id_presensi ON public.rekap_presensi USING btree (id_presensi);


--
-- Name: uq_kurikulum_aktif_prodi; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_kurikulum_aktif_prodi ON public.kurikulum USING btree (id_program_studi) WHERE aktif;


--
-- Name: uq_periode_aktif; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_periode_aktif ON public.periode_akademik USING btree (aktif) WHERE aktif;


--
-- Name: dosen trg_dosen_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_dosen_updated BEFORE UPDATE ON public.dosen FOR EACH ROW EXECUTE FUNCTION public.set_diperbarui_pada();


--
-- Name: kelas trg_kelas_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_kelas_updated BEFORE UPDATE ON public.kelas FOR EACH ROW EXECUTE FUNCTION public.set_diperbarui_pada();


--
-- Name: krs trg_krs_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_krs_updated BEFORE UPDATE ON public.krs FOR EACH ROW EXECUTE FUNCTION public.set_diperbarui_pada();


--
-- Name: nilai trg_kunci_nilai; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_kunci_nilai BEFORE UPDATE ON public.nilai FOR EACH ROW EXECUTE FUNCTION public.kunci_nilai();


--
-- Name: kurikulum trg_kurikulum_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_kurikulum_updated BEFORE UPDATE ON public.kurikulum FOR EACH ROW EXECUTE FUNCTION public.set_diperbarui_pada();


--
-- Name: mahasiswa trg_mahasiswa_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_mahasiswa_updated BEFORE UPDATE ON public.mahasiswa FOR EACH ROW EXECUTE FUNCTION public.set_diperbarui_pada();


--
-- Name: mata_kuliah trg_mata_kuliah_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_mata_kuliah_updated BEFORE UPDATE ON public.mata_kuliah FOR EACH ROW EXECUTE FUNCTION public.set_diperbarui_pada();


--
-- Name: nilai trg_nilai_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_nilai_updated BEFORE UPDATE ON public.nilai FOR EACH ROW EXECUTE FUNCTION public.set_diperbarui_pada();


--
-- Name: krs trg_perbarui_jumlah_terdaftar; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_perbarui_jumlah_terdaftar AFTER INSERT OR DELETE OR UPDATE ON public.krs FOR EACH ROW EXECUTE FUNCTION public.perbarui_jumlah_terdaftar();


--
-- Name: periode_akademik trg_periode_akademik_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_periode_akademik_updated BEFORE UPDATE ON public.periode_akademik FOR EACH ROW EXECUTE FUNCTION public.set_diperbarui_pada();


--
-- Name: presensi trg_presensi_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_presensi_updated BEFORE UPDATE ON public.presensi FOR EACH ROW EXECUTE FUNCTION public.set_diperbarui_pada();


--
-- Name: program_studi trg_program_studi_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_program_studi_updated BEFORE UPDATE ON public.program_studi FOR EACH ROW EXECUTE FUNCTION public.set_diperbarui_pada();


--
-- Name: user trg_user_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_user_updated BEFORE UPDATE ON public."user" FOR EACH ROW EXECUTE FUNCTION public.set_diperbarui_pada();


--
-- Name: dosen dosen_id_program_studi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosen
    ADD CONSTRAINT dosen_id_program_studi_fkey FOREIGN KEY (id_program_studi) REFERENCES public.program_studi(id);


--
-- Name: dosen dosen_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dosen
    ADD CONSTRAINT dosen_id_user_fkey FOREIGN KEY (id_user) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: jadwal_kelas jadwal_kelas_id_kelas_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jadwal_kelas
    ADD CONSTRAINT jadwal_kelas_id_kelas_fkey FOREIGN KEY (id_kelas) REFERENCES public.kelas(id) ON DELETE CASCADE;


--
-- Name: jadwal_kelas jadwal_kelas_id_ruangan_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jadwal_kelas
    ADD CONSTRAINT jadwal_kelas_id_ruangan_fkey FOREIGN KEY (id_ruangan) REFERENCES public.ruangan(id);


--
-- Name: kelas_dosen kelas_dosen_id_dosen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kelas_dosen
    ADD CONSTRAINT kelas_dosen_id_dosen_fkey FOREIGN KEY (id_dosen) REFERENCES public.dosen(nidn) ON DELETE CASCADE;


--
-- Name: kelas_dosen kelas_dosen_id_kelas_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kelas_dosen
    ADD CONSTRAINT kelas_dosen_id_kelas_fkey FOREIGN KEY (id_kelas) REFERENCES public.kelas(id) ON DELETE CASCADE;


--
-- Name: kelas kelas_id_mata_kuliah_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kelas
    ADD CONSTRAINT kelas_id_mata_kuliah_fkey FOREIGN KEY (id_mata_kuliah) REFERENCES public.mata_kuliah(id);


--
-- Name: kelas kelas_id_periode_akademik_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kelas
    ADD CONSTRAINT kelas_id_periode_akademik_fkey FOREIGN KEY (id_periode_akademik) REFERENCES public.periode_akademik(id);


--
-- Name: krs krs_id_kelas_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.krs
    ADD CONSTRAINT krs_id_kelas_fkey FOREIGN KEY (id_kelas) REFERENCES public.kelas(id);


--
-- Name: krs krs_id_mahasiswa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.krs
    ADD CONSTRAINT krs_id_mahasiswa_fkey FOREIGN KEY (id_mahasiswa) REFERENCES public.mahasiswa(npm) ON DELETE CASCADE;


--
-- Name: krs krs_id_periode_akademik_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.krs
    ADD CONSTRAINT krs_id_periode_akademik_fkey FOREIGN KEY (id_periode_akademik) REFERENCES public.periode_akademik(id);


--
-- Name: kurikulum kurikulum_id_program_studi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kurikulum
    ADD CONSTRAINT kurikulum_id_program_studi_fkey FOREIGN KEY (id_program_studi) REFERENCES public.program_studi(id);


--
-- Name: kurikulum_mata_kuliah kurikulum_mata_kuliah_id_kurikulum_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kurikulum_mata_kuliah
    ADD CONSTRAINT kurikulum_mata_kuliah_id_kurikulum_fkey FOREIGN KEY (id_kurikulum) REFERENCES public.kurikulum(id) ON DELETE CASCADE;


--
-- Name: kurikulum_mata_kuliah kurikulum_mata_kuliah_id_mata_kuliah_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kurikulum_mata_kuliah
    ADD CONSTRAINT kurikulum_mata_kuliah_id_mata_kuliah_fkey FOREIGN KEY (id_mata_kuliah) REFERENCES public.mata_kuliah(id);


--
-- Name: log_aktivitas log_aktivitas_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_aktivitas
    ADD CONSTRAINT log_aktivitas_id_user_fkey FOREIGN KEY (id_user) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: mahasiswa mahasiswa_id_program_studi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mahasiswa
    ADD CONSTRAINT mahasiswa_id_program_studi_fkey FOREIGN KEY (id_program_studi) REFERENCES public.program_studi(id);


--
-- Name: mahasiswa mahasiswa_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mahasiswa
    ADD CONSTRAINT mahasiswa_id_user_fkey FOREIGN KEY (id_user) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: nilai nilai_id_krs_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nilai
    ADD CONSTRAINT nilai_id_krs_fkey FOREIGN KEY (id_krs) REFERENCES public.krs(id) ON DELETE CASCADE;


--
-- Name: presensi presensi_id_kelas_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.presensi
    ADD CONSTRAINT presensi_id_kelas_fkey FOREIGN KEY (id_kelas) REFERENCES public.kelas(id) ON DELETE CASCADE;


--
-- Name: rekap_presensi rekap_presensi_id_krs_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rekap_presensi
    ADD CONSTRAINT rekap_presensi_id_krs_fkey FOREIGN KEY (id_krs) REFERENCES public.krs(id);


--
-- Name: rekap_presensi rekap_presensi_id_presensi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rekap_presensi
    ADD CONSTRAINT rekap_presensi_id_presensi_fkey FOREIGN KEY (id_presensi) REFERENCES public.presensi(id) ON DELETE CASCADE;


--
-- Name: user_role user_role_id_role_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_id_role_fkey FOREIGN KEY (id_role) REFERENCES public.role(id);


--
-- Name: user_role user_role_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_id_user_fkey FOREIGN KEY (id_user) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--


