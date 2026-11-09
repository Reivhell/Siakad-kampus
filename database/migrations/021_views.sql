-- Read models. security_invoker keeps RLS of the querying role in force.

CREATE OR REPLACE VIEW public.v_krs_detail
WITH (security_invoker = true) AS
SELECT
    k.id,
    k.id_mahasiswa,
    m.nama_lengkap AS nama_mahasiswa,
    k.id_kelas,
    kl.kode AS kode_kelas,
    mk.id AS id_mata_kuliah,
    mk.kode AS kode_mk,
    mk.nama AS nama_mk,
    mk.sks,
    k.id_periode_akademik,
    p.nama AS periode,
    k.status,
    k.disetujui_oleh_pa,
    k.catatan_pa,
    k.terdaftar_pada
FROM public.krs k
JOIN public.mahasiswa m ON m.npm = k.id_mahasiswa
JOIN public.kelas kl ON kl.id = k.id_kelas
JOIN public.mata_kuliah mk ON mk.id = kl.id_mata_kuliah
JOIN public.periode_akademik p ON p.id = k.id_periode_akademik;

CREATE OR REPLACE VIEW public.v_khs
WITH (security_invoker = true) AS
SELECT
    k.id_mahasiswa AS npm,
    m.nama_lengkap,
    p.id AS id_periode_akademik,
    p.nama AS periode,
    mk.kode AS kode_mk,
    mk.nama AS nama_mk,
    mk.sks,
    n.nilai_uts,
    n.nilai_uas,
    n.nilai_tugas,
    n.nilai_akhir,
    n.huruf_nilai,
    COALESCE(n.bobot_nilai, 0) AS bobot_nilai,
    n.sudah_final,
    k.status AS status_krs
FROM public.krs k
JOIN public.mahasiswa m ON m.npm = k.id_mahasiswa
JOIN public.kelas kl ON kl.id = k.id_kelas
JOIN public.mata_kuliah mk ON mk.id = kl.id_mata_kuliah
JOIN public.periode_akademik p ON p.id = k.id_periode_akademik
LEFT JOIN public.nilai n ON n.id_krs = k.id
WHERE k.status = 'AKTIF';

CREATE OR REPLACE VIEW public.v_rekap_presensi_mhs
WITH (security_invoker = true) AS
SELECT
    k.id_mahasiswa AS npm,
    k.id_kelas,
    COUNT(*) FILTER (WHERE rp.status = 'HADIR') AS hadir,
    COUNT(*) FILTER (WHERE rp.status = 'IZIN') AS izin,
    COUNT(*) FILTER (WHERE rp.status = 'SAKIT') AS sakit,
    COUNT(*) FILTER (WHERE rp.status = 'ALPHA') AS alpha,
    COUNT(*) FILTER (WHERE rp.status = 'DISPENSASI') AS dispensasi,
    COUNT(*) AS total_pertemuan
FROM public.krs k
LEFT JOIN public.rekap_presensi rp ON rp.id_krs = k.id
WHERE k.status = 'AKTIF'
GROUP BY k.id_mahasiswa, k.id_kelas;

CREATE OR REPLACE VIEW public.v_beban_dosen
WITH (security_invoker = true) AS
SELECT
    d.nidn,
    d.nama_lengkap,
    p.id AS id_periode_akademik,
    p.nama AS periode,
    COUNT(DISTINCT kd.id_kelas) AS jumlah_kelas,
    COALESCE(SUM(mk.sks), 0) AS total_sks
FROM public.dosen d
JOIN public.kelas_dosen kd ON kd.id_dosen = d.nidn
JOIN public.kelas kl ON kl.id = kd.id_kelas
JOIN public.mata_kuliah mk ON mk.id = kl.id_mata_kuliah
JOIN public.periode_akademik p ON p.id = kl.id_periode_akademik
GROUP BY d.nidn, d.nama_lengkap, p.id, p.nama;

CREATE OR REPLACE VIEW public.v_dashboard_stats
WITH (security_invoker = true) AS
SELECT
    (SELECT COUNT(*) FROM public.mahasiswa WHERE status = 'AKTIF') AS mahasiswa_aktif,
    (SELECT COUNT(*) FROM public.dosen WHERE status = 'AKTIF') AS dosen_aktif,
    (SELECT COUNT(*) FROM public.program_studi) AS program_studi,
    (SELECT COUNT(*) FROM public.krs WHERE status = 'AKTIF') AS krs_aktif,
    (SELECT COUNT(*) FROM public.krs WHERE status = 'MENUNGGU_APPROVAL') AS krs_menunggu,
    (SELECT COUNT(*) FROM public.permohonan_surat WHERE status = 'MENUNGGU_VERIFIKASI') AS surat_menunggu,
    (SELECT COUNT(*) FROM public.log_aktivitas WHERE dibuat_pada >= CURRENT_DATE) AS aktivitas_hari_ini;
