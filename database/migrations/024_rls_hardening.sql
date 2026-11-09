-- Remove self-service row updates that allow privilege escalation.
DROP POLICY IF EXISTS user_update_self ON public."user";
DROP POLICY IF EXISTS mahasiswa_update_self ON public.mahasiswa;
DROP POLICY IF EXISTS dosen_update_self ON public.dosen;

DROP POLICY IF EXISTS permohonan_insert_self ON public.permohonan_surat;
CREATE POLICY permohonan_insert_self ON public.permohonan_surat FOR INSERT TO authenticated
    WITH CHECK (
        id_mahasiswa = public.fn_current_mhs_npm()
        AND status = 'MENUNGGU_VERIFIKASI'
        AND nomor_surat IS NULL
        AND token_verifikasi IS NULL
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

DROP POLICY IF EXISTS bimbingan_dosen_write ON public.bimbingan_akademik;
CREATE POLICY bimbingan_dosen_write ON public.bimbingan_akademik FOR ALL TO authenticated
    USING (id_dosen = public.fn_current_dosen_nidn())
    WITH CHECK (id_dosen = public.fn_current_dosen_nidn());
