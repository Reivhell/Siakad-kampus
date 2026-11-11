-- Additive schema for fitur_admin specs. ERD/live schema stays canonical.
-- No table or column is renamed or dropped.

-- 05/11/12/13: civitas + graduation + PDDIKTI fields.
ALTER TABLE public.mahasiswa
    ADD COLUMN IF NOT EXISTS nik text,
    ADD COLUMN IF NOT EXISTS nama_ibu_kandung text,
    ADD COLUMN IF NOT EXISTS id_dosen_wali text,
    ADD COLUMN IF NOT EXISTS tanggal_lulus date,
    ADD COLUMN IF NOT EXISTS nomor_pin text;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'mahasiswa_id_dosen_wali_fkey'
    ) THEN
        ALTER TABLE public.mahasiswa
            ADD CONSTRAINT mahasiswa_id_dosen_wali_fkey
            FOREIGN KEY (id_dosen_wali) REFERENCES public.dosen(nidn) ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_mahasiswa_dosen_wali ON public.mahasiswa (id_dosen_wali);

-- 04: curriculum detail.
ALTER TABLE public.mata_kuliah
    ADD COLUMN IF NOT EXISTS nama_en text,
    ADD COLUMN IF NOT EXISTS sks_teori integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS sks_praktikum integer DEFAULT 0,
    ADD COLUMN IF NOT EXISTS deskripsi text;

UPDATE public.mata_kuliah
SET sks_teori = sks
WHERE sks_teori = 0 AND sks_praktikum = 0;

ALTER TABLE public.kurikulum
    ADD COLUMN IF NOT EXISTS total_sks_lulus integer NOT NULL DEFAULT 144;

ALTER TABLE public.kurikulum_mata_kuliah
    ADD COLUMN IF NOT EXISTS sifat text NOT NULL DEFAULT 'WAJIB';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'kurikulum_mata_kuliah_sifat_check'
    ) THEN
        ALTER TABLE public.kurikulum_mata_kuliah
            ADD CONSTRAINT kurikulum_mata_kuliah_sifat_check
            CHECK (sifat IN ('WAJIB', 'PILIHAN'));
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.prasyarat_mata_kuliah (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_kurikulum uuid NOT NULL REFERENCES public.kurikulum(id) ON DELETE CASCADE,
    id_mata_kuliah uuid NOT NULL REFERENCES public.mata_kuliah(id) ON DELETE CASCADE,
    id_mata_kuliah_syarat uuid REFERENCES public.mata_kuliah(id) ON DELETE RESTRICT,
    min_nilai_huruf text DEFAULT 'C',
    min_sks_kumulatif integer NOT NULL DEFAULT 0 CHECK (min_sks_kumulatif >= 0),
    tipe_prasyarat text NOT NULL DEFAULT 'HARD_PREREQUISITE'
        CHECK (tipe_prasyarat IN ('HARD_PREREQUISITE', 'CO_REQUISITE', 'CREDIT_THRESHOLD')),
    UNIQUE (id_kurikulum, id_mata_kuliah, id_mata_kuliah_syarat)
);

-- 07: KRS approval workflow. User chose DRAFT / MENUNGGU_APPROVAL / BATAL.
ALTER TABLE public.krs
    ADD COLUMN IF NOT EXISTS disetujui_oleh_pa boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS catatan_pa text,
    ADD COLUMN IF NOT EXISTS disetujui_pada timestamptz,
    ADD COLUMN IF NOT EXISTS disetujui_oleh uuid;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'krs_disetujui_oleh_fkey'
    ) THEN
        ALTER TABLE public.krs
            ADD CONSTRAINT krs_disetujui_oleh_fkey
            FOREIGN KEY (disetujui_oleh) REFERENCES public."user"(id) ON DELETE SET NULL;
    END IF;
END $$;

UPDATE public.krs SET status = 'BATAL' WHERE status = 'DIBATALKAN';

ALTER TABLE public.krs DROP CONSTRAINT IF EXISTS krs_status_check;
ALTER TABLE public.krs
    ADD CONSTRAINT krs_status_check
    CHECK (status IN ('DRAFT', 'MENUNGGU_APPROVAL', 'AKTIF', 'BATAL', 'MENGUNDURKAN_DIRI'));

CREATE INDEX IF NOT EXISTS idx_krs_status ON public.krs (status);
CREATE INDEX IF NOT EXISTS idx_krs_pa ON public.krs (disetujui_oleh_pa);

-- 08: grade weight for KHS/IPK queries.
ALTER TABLE public.nilai
    ADD COLUMN IF NOT EXISTS bobot_nilai numeric(3,2);

UPDATE public.nilai
SET bobot_nilai = CASE huruf_nilai
    WHEN 'A' THEN 4.00 WHEN 'AB' THEN 3.50 WHEN 'B' THEN 3.00
    WHEN 'BC' THEN 2.50 WHEN 'C' THEN 2.00 WHEN 'D' THEN 1.00
    WHEN 'E' THEN 0.00 ELSE bobot_nilai END
WHERE bobot_nilai IS NULL AND huruf_nilai IS NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'nilai_bobot_nilai_check'
    ) THEN
        ALTER TABLE public.nilai
            ADD CONSTRAINT nilai_bobot_nilai_check
            CHECK (bobot_nilai IS NULL OR (bobot_nilai >= 0 AND bobot_nilai <= 4));
    END IF;
END $$;

-- 09: attendance header detail. rekap_presensi remains canonical.
ALTER TABLE public.presensi
    ADD COLUMN IF NOT EXISTS jam_mulai time,
    ADD COLUMN IF NOT EXISTS jam_selesai time,
    ADD COLUMN IF NOT EXISTS metode text NOT NULL DEFAULT 'LURING',
    ADD COLUMN IF NOT EXISTS id_dosen_pengajar text;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'presensi_metode_check'
    ) THEN
        ALTER TABLE public.presensi
            ADD CONSTRAINT presensi_metode_check
            CHECK (metode IN ('LURING', 'DARING', 'HYBRID'));
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'presensi_id_dosen_pengajar_fkey'
    ) THEN
        ALTER TABLE public.presensi
            ADD CONSTRAINT presensi_id_dosen_pengajar_fkey
            FOREIGN KEY (id_dosen_pengajar) REFERENCES public.dosen(nidn) ON DELETE SET NULL;
    END IF;
END $$;

ALTER TABLE public.rekap_presensi DROP CONSTRAINT IF EXISTS rekap_presensi_status_check;
ALTER TABLE public.rekap_presensi
    ADD CONSTRAINT rekap_presensi_status_check
    CHECK (status IN ('HADIR', 'IZIN', 'SAKIT', 'ALPHA', 'DISPENSASI'));

-- 10: audit metadata.
ALTER TABLE public.log_aktivitas
    ADD COLUMN IF NOT EXISTS user_agent text,
    ADD COLUMN IF NOT EXISTS hash_sebelumnya text,
    ADD COLUMN IF NOT EXISTS hash_integritas text;

CREATE INDEX IF NOT EXISTS idx_log_aktivitas_aksi ON public.log_aktivitas (aksi);
CREATE INDEX IF NOT EXISTS idx_log_aktivitas_entitas ON public.log_aktivitas (entitas, id_entitas);
CREATE INDEX IF NOT EXISTS idx_log_aktivitas_metadata_gin ON public.log_aktivitas USING GIN (metadata);

-- 11: advising.
CREATE TABLE IF NOT EXISTS public.bimbingan_akademik (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mahasiswa text NOT NULL REFERENCES public.mahasiswa(npm) ON DELETE CASCADE,
    id_dosen text NOT NULL REFERENCES public.dosen(nidn) ON DELETE RESTRICT,
    id_periode_akademik uuid NOT NULL REFERENCES public.periode_akademik(id) ON DELETE RESTRICT,
    tanggal_konsultasi date NOT NULL DEFAULT CURRENT_DATE,
    topik_bimbingan text NOT NULL,
    catatan_dosen text NOT NULL,
    solusi_rekomendasi text,
    status_verifikasi_krs boolean NOT NULL DEFAULT false,
    dibuat_pada timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bimbingan_mhs ON public.bimbingan_akademik (id_mahasiswa);
CREATE INDEX IF NOT EXISTS idx_bimbingan_dosen ON public.bimbingan_akademik (id_dosen);

-- 12: graduation.
CREATE TABLE IF NOT EXISTS public.yudisium (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_periode_akademik uuid NOT NULL REFERENCES public.periode_akademik(id) ON DELETE RESTRICT,
    nama_periode text NOT NULL,
    nomor_sk text,
    tanggal_sk date,
    status text NOT NULL DEFAULT 'DIBUKA'
        CHECK (status IN ('DIBUKA', 'VERIFIKASI', 'DISAHKAN')),
    dibuat_pada timestamptz NOT NULL DEFAULT now(),
    diperbarui_pada timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.peserta_yudisium (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_yudisium uuid NOT NULL REFERENCES public.yudisium(id) ON DELETE CASCADE,
    id_mahasiswa text NOT NULL REFERENCES public.mahasiswa(npm) ON DELETE RESTRICT,
    total_sks_lulus integer NOT NULL,
    ipk_akhir numeric(3,2) NOT NULL,
    predikat_kelulusan text NOT NULL,
    nomor_ijazah_nasional text,
    nomor_seri_transkrip text,
    status_audit text NOT NULL DEFAULT 'PENDING'
        CHECK (status_audit IN ('PENDING', 'MEMENUHI', 'DITOLAK')),
    catatan_audit text,
    UNIQUE (id_yudisium, id_mahasiswa)
);

CREATE INDEX IF NOT EXISTS idx_peserta_yudisium_mhs ON public.peserta_yudisium (id_mahasiswa);

-- 14: credit transfer.
CREATE TABLE IF NOT EXISTS public.mahasiswa_transfer (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mahasiswa text NOT NULL REFERENCES public.mahasiswa(npm) ON DELETE CASCADE,
    jenis_transfer text NOT NULL
        CHECK (jenis_transfer IN ('PINDAHAN', 'ALIH_JENJANG', 'MBKM_MAGANG', 'MBKM_PERTUKARAN', 'RPL')),
    nama_institusi_asal text NOT NULL,
    prodi_asal text,
    nim_asal text,
    nomor_sk_penyetaraan text,
    status text NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT', 'VERIFIKASI', 'DISAHKAN')),
    dibuat_pada timestamptz NOT NULL DEFAULT now(),
    disahkan_pada timestamptz
);

CREATE TABLE IF NOT EXISTS public.konversi_nilai_detail (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_transfer uuid NOT NULL REFERENCES public.mahasiswa_transfer(id) ON DELETE CASCADE,
    kode_mk_asal text NOT NULL,
    nama_mk_asal text NOT NULL,
    sks_asal integer NOT NULL CHECK (sks_asal > 0),
    nilai_huruf_asal text NOT NULL,
    id_mata_kuliah_lokal uuid NOT NULL REFERENCES public.mata_kuliah(id) ON DELETE RESTRICT,
    nilai_huruf_diakui text NOT NULL
        CHECK (nilai_huruf_diakui IN ('A', 'AB', 'B', 'BC', 'C', 'D')),
    bobot_diakui numeric(3,2) NOT NULL CHECK (bobot_diakui >= 0 AND bobot_diakui <= 4)
);

CREATE TABLE IF NOT EXISTS public.nilai_konversi_transkrip (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mahasiswa text NOT NULL REFERENCES public.mahasiswa(npm) ON DELETE CASCADE,
    id_mata_kuliah uuid NOT NULL REFERENCES public.mata_kuliah(id) ON DELETE RESTRICT,
    nilai_huruf text NOT NULL,
    bobot_nilai numeric(3,2) NOT NULL,
    nomor_sk text NOT NULL,
    asal_perolehan text NOT NULL DEFAULT 'TRANSFER_KREDIT',
    dibuat_pada timestamptz NOT NULL DEFAULT now(),
    UNIQUE (id_mahasiswa, id_mata_kuliah)
);

CREATE INDEX IF NOT EXISTS idx_nilai_konversi_mhs ON public.nilai_konversi_transkrip (id_mahasiswa);

-- 15: letters.
CREATE TABLE IF NOT EXISTS public.template_surat (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    kode_klasifikasi text NOT NULL UNIQUE,
    nama_layanan text NOT NULL,
    konten_template text NOT NULL,
    butuh_tujuan_instansi boolean NOT NULL DEFAULT false,
    aktif boolean NOT NULL DEFAULT true,
    dibuat_pada timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.permohonan_surat (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mahasiswa text NOT NULL REFERENCES public.mahasiswa(npm) ON DELETE RESTRICT,
    id_template uuid NOT NULL REFERENCES public.template_surat(id) ON DELETE RESTRICT,
    tujuan_instansi text,
    keterangan_keperluan text NOT NULL,
    nomor_surat text UNIQUE,
    nomor_urut integer,
    tahun_terbit integer,
    pejabat_penandatangan text,
    token_verifikasi uuid UNIQUE,
    status text NOT NULL DEFAULT 'MENUNGGU_VERIFIKASI'
        CHECK (status IN ('MENUNGGU_VERIFIKASI', 'SELESAI', 'DITOLAK')),
    catatan_penolakan text,
    file_url text,
    dibuat_pada timestamptz NOT NULL DEFAULT now(),
    diterbitkan_pada timestamptz,
    berlaku_hingga date
);

CREATE INDEX IF NOT EXISTS idx_permohonan_surat_mhs ON public.permohonan_surat (id_mahasiswa);
CREATE INDEX IF NOT EXISTS idx_permohonan_token ON public.permohonan_surat (token_verifikasi);

-- New tables get updated_at triggers where the column exists.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_yudisium_updated') THEN
        CREATE TRIGGER trg_yudisium_updated BEFORE UPDATE ON public.yudisium
            FOR EACH ROW EXECUTE FUNCTION public.set_diperbarui_pada();
    END IF;
END $$;
