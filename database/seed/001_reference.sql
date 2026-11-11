-- Idempotent reference data. Safe on both local Postgres and Supabase.

INSERT INTO public.role (id, nama) VALUES
    ('10000000-0000-0000-0000-000000000001', 'ADMIN'),
    ('10000000-0000-0000-0000-000000000002', 'DOSEN'),
    ('10000000-0000-0000-0000-000000000003', 'MAHASISWA')
ON CONFLICT (nama) DO NOTHING;

INSERT INTO public.program_studi (id, nama, kode, jenjang) VALUES
    ('20000000-0000-0000-0000-000000000001', 'Teknik Informatika', 'TI', 'S1'),
    ('20000000-0000-0000-0000-000000000002', 'Sistem Informasi', 'SI', 'S1')
ON CONFLICT (kode) DO NOTHING;

INSERT INTO public.periode_akademik
    (id, nama, tahun_akademik, semester, tanggal_mulai, tanggal_selesai, aktif)
VALUES
    ('30000000-0000-0000-0000-000000000001', '2025/2026 Ganjil', '2025/2026', 'GANJIL', '2025-09-01', '2026-01-31', false),
    ('30000000-0000-0000-0000-000000000002', '2025/2026 Genap', '2025/2026', 'GENAP', '2026-02-01', '2026-06-30', false)
ON CONFLICT (nama) DO NOTHING;

UPDATE public.periode_akademik
SET aktif = true
WHERE id = '30000000-0000-0000-0000-000000000001'
  AND NOT EXISTS (SELECT 1 FROM public.periode_akademik WHERE aktif);

INSERT INTO public.ruangan (id, kode, nama, kapasitas, gedung) VALUES
    ('40000000-0000-0000-0000-000000000001', 'LAB-1', 'Laboratorium Komputer 1', 40, 'Gedung A'),
    ('40000000-0000-0000-0000-000000000002', 'R-201', 'Ruang Kuliah 201', 50, 'Gedung B'),
    ('40000000-0000-0000-0000-000000000003', 'AUD-1', 'Aula Utama', 200, 'Gedung A')
ON CONFLICT (kode) DO NOTHING;

INSERT INTO public.mata_kuliah (id, kode, nama, sks, semester, jenis) VALUES
    ('50000000-0000-0000-0000-000000000001', 'IF101', 'Algoritma dan Pemrograman', 3, 1, 'WAJIB'),
    ('50000000-0000-0000-0000-000000000002', 'IF102', 'Struktur Data', 3, 3, 'WAJIB'),
    ('50000000-0000-0000-0000-000000000003', 'IF201', 'Basis Data', 3, 4, 'WAJIB'),
    ('50000000-0000-0000-0000-000000000004', 'IF202', 'Pemrograman Web', 3, 5, 'WAJIB'),
    ('50000000-0000-0000-0000-000000000005', 'IF301', 'Rekayasa Perangkat Lunak', 3, 6, 'WAJIB'),
    ('50000000-0000-0000-0000-000000000006', 'IF302', 'Kecerdasan Artifisial', 3, 7, 'PILIHAN'),
    ('50000000-0000-0000-0000-000000000007', 'SI101', 'Pengantar Sistem Informasi', 3, 1, 'WAJIB'),
    ('50000000-0000-0000-0000-000000000008', 'SI201', 'Analisis Proses Bisnis', 3, 3, 'WAJIB')
ON CONFLICT (kode) DO NOTHING;

INSERT INTO public.kurikulum (id, id_program_studi, nama, tahun, aktif, total_sks_lulus)
SELECT '60000000-0000-0000-0000-000000000001', id, 'Kurikulum TI 2025', 2025, false, 144
FROM public.program_studi WHERE kode = 'TI'
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.kurikulum (id, id_program_studi, nama, tahun, aktif, total_sks_lulus)
SELECT '60000000-0000-0000-0000-000000000002', id, 'Kurikulum SI 2025', 2025, false, 144
FROM public.program_studi WHERE kode = 'SI'
ON CONFLICT (id) DO NOTHING;

UPDATE public.kurikulum k
SET aktif = true
WHERE k.id IN ('60000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000002')
  AND NOT EXISTS (
      SELECT 1 FROM public.kurikulum x
      WHERE x.id_program_studi = k.id_program_studi AND x.aktif
  );

INSERT INTO public.kurikulum_mata_kuliah
    (id, id_kurikulum, id_mata_kuliah, semester_rekomendasi, sifat)
SELECT gen_random_uuid(), k.id, mk.id, mk.semester, mk.jenis
FROM public.kurikulum k
JOIN public.mata_kuliah mk ON mk.kode IN
    ('IF101', 'IF102', 'IF201', 'IF202', 'IF301', 'IF302')
WHERE k.id = '60000000-0000-0000-0000-000000000001'
ON CONFLICT (id_kurikulum, id_mata_kuliah) DO NOTHING;

INSERT INTO public.kurikulum_mata_kuliah
    (id, id_kurikulum, id_mata_kuliah, semester_rekomendasi, sifat)
SELECT gen_random_uuid(), k.id, mk.id, mk.semester, mk.jenis
FROM public.kurikulum k
JOIN public.mata_kuliah mk ON mk.kode IN ('SI101', 'SI201', 'IF201')
WHERE k.id = '60000000-0000-0000-0000-000000000002'
ON CONFLICT (id_kurikulum, id_mata_kuliah) DO NOTHING;

INSERT INTO public.prasyarat_mata_kuliah
    (id_kurikulum, id_mata_kuliah, id_mata_kuliah_syarat, min_nilai_huruf, tipe_prasyarat)
SELECT k.id, mk.id, syarat.id, 'C', 'HARD_PREREQUISITE'
FROM public.kurikulum k
JOIN public.mata_kuliah mk ON mk.kode = 'IF102'
JOIN public.mata_kuliah syarat ON syarat.kode = 'IF101'
WHERE k.id = '60000000-0000-0000-0000-000000000001'
ON CONFLICT (id_kurikulum, id_mata_kuliah, id_mata_kuliah_syarat) DO NOTHING;

INSERT INTO public.prasyarat_mata_kuliah
    (id_kurikulum, id_mata_kuliah, id_mata_kuliah_syarat, min_nilai_huruf, tipe_prasyarat)
SELECT k.id, mk.id, syarat.id, 'C', 'HARD_PREREQUISITE'
FROM public.kurikulum k
JOIN public.mata_kuliah mk ON mk.kode = 'IF202'
JOIN public.mata_kuliah syarat ON syarat.kode = 'IF201'
WHERE k.id = '60000000-0000-0000-0000-000000000001'
ON CONFLICT (id_kurikulum, id_mata_kuliah, id_mata_kuliah_syarat) DO NOTHING;

INSERT INTO public.template_surat
    (id, kode_klasifikasi, nama_layanan, konten_template, butuh_tujuan_instansi, aktif)
VALUES
    ('70000000-0000-0000-0000-000000000001', 'AKD-AKTIF', 'Surat Keterangan Aktif Kuliah',
     'Yang bertanda tangan di bawah ini menerangkan bahwa {{nama}} ({{npm}}) adalah mahasiswa aktif Program Studi {{prodi}}.',
     false, true),
    ('70000000-0000-0000-0000-000000000002', 'AKD-CUTI', 'Surat Pengantar Cuti Akademik',
     'Dengan ini kami mengajukan cuti akademik untuk {{nama}} ({{npm}}) pada semester {{semester}}.',
     false, true),
    ('70000000-0000-0000-0000-000000000003', 'AKD-LULUS', 'Surat Keterangan Lulus',
     'Berdasarkan hasil yudisium, {{nama}} ({{npm}}) dinyatakan LULUS dari Program Studi {{prodi}}.',
     false, true),
    ('70000000-0000-0000-0000-000000000004', 'AKD-RISET', 'Surat Pengantar Penelitian',
     'Kami memohon izin penelitian di {{tujuan}} untuk keperluan akademik mahasiswa {{nama}} ({{npm}}).',
     true, true),
    ('70000000-0000-0000-0000-000000000005', 'AKD-BEASISWA', 'Surat Keterangan Bebas Beasiswa',
     'Menerangkan bahwa {{nama}} ({{npm}}) tidak sedang menerima beasiswa lain pada periode ini.',
     false, true)
ON CONFLICT (kode_klasifikasi) DO NOTHING;
