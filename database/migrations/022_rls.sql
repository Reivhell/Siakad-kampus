-- Row Level Security. Local server sets role authenticated + request.jwt.claim.sub.
-- service_role bypasses RLS; never expose its key.

DO $$
DECLARE
    t text;
BEGIN
    FOR t IN
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    END LOOP;
END $$;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- Reference data: readable by all authenticated, writable by admin.
DROP POLICY IF EXISTS role_select ON public.role;
CREATE POLICY role_select ON public.role FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS role_admin ON public.role;
CREATE POLICY role_admin ON public.role FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS prodi_select ON public.program_studi;
CREATE POLICY prodi_select ON public.program_studi FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS prodi_admin ON public.program_studi;
CREATE POLICY prodi_admin ON public.program_studi FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS periode_select ON public.periode_akademik;
CREATE POLICY periode_select ON public.periode_akademik FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS periode_admin ON public.periode_akademik;
CREATE POLICY periode_admin ON public.periode_akademik FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS ruangan_select ON public.ruangan;
CREATE POLICY ruangan_select ON public.ruangan FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS ruangan_admin ON public.ruangan;
CREATE POLICY ruangan_admin ON public.ruangan FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS mk_select ON public.mata_kuliah;
CREATE POLICY mk_select ON public.mata_kuliah FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS mk_admin ON public.mata_kuliah;
CREATE POLICY mk_admin ON public.mata_kuliah FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS kurikulum_select ON public.kurikulum;
CREATE POLICY kurikulum_select ON public.kurikulum FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS kurikulum_admin ON public.kurikulum;
CREATE POLICY kurikulum_admin ON public.kurikulum FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS kmk_select ON public.kurikulum_mata_kuliah;
CREATE POLICY kmk_select ON public.kurikulum_mata_kuliah FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS kmk_admin ON public.kurikulum_mata_kuliah;
CREATE POLICY kmk_admin ON public.kurikulum_mata_kuliah FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS prasyarat_select ON public.prasyarat_mata_kuliah;
CREATE POLICY prasyarat_select ON public.prasyarat_mata_kuliah FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS prasyarat_admin ON public.prasyarat_mata_kuliah;
CREATE POLICY prasyarat_admin ON public.prasyarat_mata_kuliah FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

-- Identity.
DROP POLICY IF EXISTS user_select ON public."user";
CREATE POLICY user_select ON public."user" FOR SELECT TO authenticated
    USING (id = auth.uid() OR public.fn_is_admin());
DROP POLICY IF EXISTS user_admin ON public."user";
CREATE POLICY user_admin ON public."user" FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS user_role_select ON public.user_role;
CREATE POLICY user_role_select ON public.user_role FOR SELECT TO authenticated
    USING (id_user = auth.uid() OR public.fn_is_admin());
DROP POLICY IF EXISTS user_role_admin ON public.user_role;
CREATE POLICY user_role_admin ON public.user_role FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS mahasiswa_select ON public.mahasiswa;
CREATE POLICY mahasiswa_select ON public.mahasiswa FOR SELECT TO authenticated
    USING (
        public.fn_is_admin()
        OR id_user = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.krs k
            JOIN public.kelas_dosen kd ON kd.id_kelas = k.id_kelas
            WHERE k.id_mahasiswa = mahasiswa.npm
              AND kd.id_dosen = public.fn_current_dosen_nidn()
        )
    );
DROP POLICY IF EXISTS mahasiswa_admin ON public.mahasiswa;
CREATE POLICY mahasiswa_admin ON public.mahasiswa FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS dosen_select ON public.dosen;
CREATE POLICY dosen_select ON public.dosen FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS dosen_admin ON public.dosen;
CREATE POLICY dosen_admin ON public.dosen FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

-- Academic offering.
DROP POLICY IF EXISTS kelas_select ON public.kelas;
CREATE POLICY kelas_select ON public.kelas FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS kelas_admin ON public.kelas;
CREATE POLICY kelas_admin ON public.kelas FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS kelas_dosen_select ON public.kelas_dosen;
CREATE POLICY kelas_dosen_select ON public.kelas_dosen FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS kelas_dosen_admin ON public.kelas_dosen;
CREATE POLICY kelas_dosen_admin ON public.kelas_dosen FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS jadwal_select ON public.jadwal_kelas;
CREATE POLICY jadwal_select ON public.jadwal_kelas FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS jadwal_admin ON public.jadwal_kelas;
CREATE POLICY jadwal_admin ON public.jadwal_kelas FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

-- KRS.
DROP POLICY IF EXISTS krs_select ON public.krs;
CREATE POLICY krs_select ON public.krs FOR SELECT TO authenticated
    USING (
        public.fn_is_admin()
        OR id_mahasiswa = public.fn_current_mhs_npm()
        OR EXISTS (
            SELECT 1 FROM public.kelas_dosen kd
            WHERE kd.id_kelas = krs.id_kelas
              AND kd.id_dosen = public.fn_current_dosen_nidn()
        )
    );
DROP POLICY IF EXISTS krs_insert_self ON public.krs;
CREATE POLICY krs_insert_self ON public.krs FOR INSERT TO authenticated
    WITH CHECK (
        id_mahasiswa = public.fn_current_mhs_npm()
        AND status IN ('DRAFT', 'MENUNGGU_APPROVAL')
    );
DROP POLICY IF EXISTS krs_update_self ON public.krs;
CREATE POLICY krs_update_self ON public.krs FOR UPDATE TO authenticated
    USING (id_mahasiswa = public.fn_current_mhs_npm())
    WITH CHECK (id_mahasiswa = public.fn_current_mhs_npm()
        AND status IN ('DRAFT', 'MENUNGGU_APPROVAL', 'BATAL'));
DROP POLICY IF EXISTS krs_update_pa ON public.krs;
CREATE POLICY krs_update_pa ON public.krs FOR UPDATE TO authenticated
    USING (
        status = 'MENUNGGU_APPROVAL'
        AND EXISTS (
            SELECT 1 FROM public.kelas_dosen kd
            WHERE kd.id_kelas = krs.id_kelas
              AND kd.id_dosen = public.fn_current_dosen_nidn()
        )
    )
    WITH CHECK (status IN ('AKTIF', 'BATAL'));
DROP POLICY IF EXISTS krs_admin ON public.krs;
CREATE POLICY krs_admin ON public.krs FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

-- Grades.
DROP POLICY IF EXISTS nilai_select ON public.nilai;
CREATE POLICY nilai_select ON public.nilai FOR SELECT TO authenticated
    USING (
        public.fn_is_admin()
        OR EXISTS (
            SELECT 1 FROM public.krs k
            WHERE k.id = nilai.id_krs
              AND k.id_mahasiswa = public.fn_current_mhs_npm()
        )
        OR EXISTS (
            SELECT 1 FROM public.krs k
            JOIN public.kelas_dosen kd ON kd.id_kelas = k.id_kelas
            WHERE k.id = nilai.id_krs
              AND kd.id_dosen = public.fn_current_dosen_nidn()
        )
    );
DROP POLICY IF EXISTS nilai_update_dosen ON public.nilai;
CREATE POLICY nilai_update_dosen ON public.nilai FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.krs k
            JOIN public.kelas_dosen kd ON kd.id_kelas = k.id_kelas
            WHERE k.id = nilai.id_krs
              AND kd.id_dosen = public.fn_current_dosen_nidn()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.krs k
            JOIN public.kelas_dosen kd ON kd.id_kelas = k.id_kelas
            WHERE k.id = nilai.id_krs
              AND kd.id_dosen = public.fn_current_dosen_nidn()
        )
    );
DROP POLICY IF EXISTS nilai_insert_dosen ON public.nilai;
CREATE POLICY nilai_insert_dosen ON public.nilai FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.krs k
            JOIN public.kelas_dosen kd ON kd.id_kelas = k.id_kelas
            WHERE k.id = nilai.id_krs
              AND kd.id_dosen = public.fn_current_dosen_nidn()
        )
    );
DROP POLICY IF EXISTS nilai_admin ON public.nilai;
CREATE POLICY nilai_admin ON public.nilai FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

-- Attendance.
DROP POLICY IF EXISTS presensi_select ON public.presensi;
CREATE POLICY presensi_select ON public.presensi FOR SELECT TO authenticated
    USING (
        public.fn_is_admin()
        OR EXISTS (
            SELECT 1 FROM public.kelas_dosen kd
            WHERE kd.id_kelas = presensi.id_kelas
              AND kd.id_dosen = public.fn_current_dosen_nidn()
        )
        OR EXISTS (
            SELECT 1 FROM public.krs k
            WHERE k.id_kelas = presensi.id_kelas
              AND k.id_mahasiswa = public.fn_current_mhs_npm()
        )
    );
DROP POLICY IF EXISTS presensi_dosen_write ON public.presensi;
CREATE POLICY presensi_dosen_write ON public.presensi FOR ALL TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.kelas_dosen kd
        WHERE kd.id_kelas = presensi.id_kelas
          AND kd.id_dosen = public.fn_current_dosen_nidn()
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.kelas_dosen kd
        WHERE kd.id_kelas = presensi.id_kelas
          AND kd.id_dosen = public.fn_current_dosen_nidn()
    ));
DROP POLICY IF EXISTS presensi_admin ON public.presensi;
CREATE POLICY presensi_admin ON public.presensi FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS rekap_select ON public.rekap_presensi;
CREATE POLICY rekap_select ON public.rekap_presensi FOR SELECT TO authenticated
    USING (
        public.fn_is_admin()
        OR EXISTS (
            SELECT 1 FROM public.krs k
            WHERE k.id = rekap_presensi.id_krs
              AND k.id_mahasiswa = public.fn_current_mhs_npm()
        )
        OR EXISTS (
            SELECT 1 FROM public.krs k
            JOIN public.kelas_dosen kd ON kd.id_kelas = k.id_kelas
            WHERE k.id = rekap_presensi.id_krs
              AND kd.id_dosen = public.fn_current_dosen_nidn()
        )
    );
DROP POLICY IF EXISTS rekap_dosen_write ON public.rekap_presensi;
CREATE POLICY rekap_dosen_write ON public.rekap_presensi FOR ALL TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.krs k
        JOIN public.kelas_dosen kd ON kd.id_kelas = k.id_kelas
        WHERE k.id = rekap_presensi.id_krs
          AND kd.id_dosen = public.fn_current_dosen_nidn()
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.krs k
        JOIN public.kelas_dosen kd ON kd.id_kelas = k.id_kelas
        WHERE k.id = rekap_presensi.id_krs
          AND kd.id_dosen = public.fn_current_dosen_nidn()
    ));
DROP POLICY IF EXISTS rekap_admin ON public.rekap_presensi;
CREATE POLICY rekap_admin ON public.rekap_presensi FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

-- Audit.
DROP POLICY IF EXISTS audit_select ON public.log_aktivitas;
CREATE POLICY audit_select ON public.log_aktivitas FOR SELECT TO authenticated
    USING (public.fn_is_admin());
DROP POLICY IF EXISTS audit_insert ON public.log_aktivitas;
CREATE POLICY audit_insert ON public.log_aktivitas FOR INSERT TO authenticated
    WITH CHECK (id_user = auth.uid() OR public.fn_is_admin());

-- Advising.
DROP POLICY IF EXISTS bimbingan_select ON public.bimbingan_akademik;
CREATE POLICY bimbingan_select ON public.bimbingan_akademik FOR SELECT TO authenticated
    USING (
        public.fn_is_admin()
        OR id_mahasiswa = public.fn_current_mhs_npm()
        OR id_dosen = public.fn_current_dosen_nidn()
    );
DROP POLICY IF EXISTS bimbingan_dosen_write ON public.bimbingan_akademik;
CREATE POLICY bimbingan_dosen_write ON public.bimbingan_akademik FOR ALL TO authenticated
    USING (id_dosen = public.fn_current_dosen_nidn())
    WITH CHECK (id_dosen = public.fn_current_dosen_nidn());
DROP POLICY IF EXISTS bimbingan_admin ON public.bimbingan_akademik;
CREATE POLICY bimbingan_admin ON public.bimbingan_akademik FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

-- Graduation.
DROP POLICY IF EXISTS yudisium_select ON public.yudisium;
CREATE POLICY yudisium_select ON public.yudisium FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS yudisium_admin ON public.yudisium;
CREATE POLICY yudisium_admin ON public.yudisium FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS peserta_yudisium_select ON public.peserta_yudisium;
CREATE POLICY peserta_yudisium_select ON public.peserta_yudisium FOR SELECT TO authenticated
    USING (public.fn_is_admin() OR id_mahasiswa = public.fn_current_mhs_npm());
DROP POLICY IF EXISTS peserta_yudisium_admin ON public.peserta_yudisium;
CREATE POLICY peserta_yudisium_admin ON public.peserta_yudisium FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

-- Credit transfer.
DROP POLICY IF EXISTS transfer_select ON public.mahasiswa_transfer;
CREATE POLICY transfer_select ON public.mahasiswa_transfer FOR SELECT TO authenticated
    USING (public.fn_is_admin() OR id_mahasiswa = public.fn_current_mhs_npm());
DROP POLICY IF EXISTS transfer_admin ON public.mahasiswa_transfer;
CREATE POLICY transfer_admin ON public.mahasiswa_transfer FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS konversi_select ON public.konversi_nilai_detail;
CREATE POLICY konversi_select ON public.konversi_nilai_detail FOR SELECT TO authenticated
    USING (
        public.fn_is_admin()
        OR EXISTS (
            SELECT 1 FROM public.mahasiswa_transfer t
            WHERE t.id = konversi_nilai_detail.id_transfer
              AND t.id_mahasiswa = public.fn_current_mhs_npm()
        )
    );
DROP POLICY IF EXISTS konversi_admin ON public.konversi_nilai_detail;
CREATE POLICY konversi_admin ON public.konversi_nilai_detail FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS nilai_konversi_select ON public.nilai_konversi_transkrip;
CREATE POLICY nilai_konversi_select ON public.nilai_konversi_transkrip FOR SELECT TO authenticated
    USING (public.fn_is_admin() OR id_mahasiswa = public.fn_current_mhs_npm());
DROP POLICY IF EXISTS nilai_konversi_admin ON public.nilai_konversi_transkrip;
CREATE POLICY nilai_konversi_admin ON public.nilai_konversi_transkrip FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

-- Letters.
DROP POLICY IF EXISTS template_surat_select ON public.template_surat;
CREATE POLICY template_surat_select ON public.template_surat FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS template_surat_admin ON public.template_surat;
CREATE POLICY template_surat_admin ON public.template_surat FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());

DROP POLICY IF EXISTS permohonan_select ON public.permohonan_surat;
CREATE POLICY permohonan_select ON public.permohonan_surat FOR SELECT TO authenticated
    USING (public.fn_is_admin() OR id_mahasiswa = public.fn_current_mhs_npm());
DROP POLICY IF EXISTS permohonan_insert_self ON public.permohonan_surat;
CREATE POLICY permohonan_insert_self ON public.permohonan_surat FOR INSERT TO authenticated
    WITH CHECK (
        id_mahasiswa = public.fn_current_mhs_npm()
        AND status = 'MENUNGGU_VERIFIKASI'
        AND nomor_surat IS NULL
        AND token_verifikasi IS NULL
    );
DROP POLICY IF EXISTS permohonan_admin ON public.permohonan_surat;
CREATE POLICY permohonan_admin ON public.permohonan_surat FOR ALL TO authenticated
    USING (public.fn_is_admin()) WITH CHECK (public.fn_is_admin());
