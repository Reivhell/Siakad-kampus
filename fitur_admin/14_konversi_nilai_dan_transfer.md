# 14 — Konversi Nilai, Transfer Kredit, & Ekuivalensi MBKM

> Modul pengelolaan pengakuan kredit (*credit transfer*), penyetaraan mata kuliah mahasiswa pindahan dan alih jenjang, konversi paket aktivitas Merdeka Belajar Kampus Merdeka (MBKM 20 SKS), serta rekognisi pembelajaran lampau (RPL).

---

## 1. Tujuan & Ruang Lingkup Fitur

Tuntutan fleksibilitas kurikulum modern (kebijakan MBKM dan jalur RPL) mewajibkan perguruan tinggi mampu mengakui capaian pembelajaran eksternal secara akuntabel. Modul ini menyediakan antarmuka penyetaraan kurikulum dua sisi (*two-sided equivalence mapping*), menangani pola konversi multi-relasi (1-to-1, 1-to-N, N-to-1), serta menginjeksi nilai yang telah disahkan ke dalam riwayat akademik tanpa merusak integritas kueri KHS/IPK.

### Ruang Lingkup Modul:
1. **Registrasi Riwayat Asal Mahasiswa (`mahasiswa_transfer`)**:
   - Pencatatan nama perguruan tinggi asal, program studi asal, NIM asal, dan nomor SK Penyetaraan.
   - Klasifikasi jalur transfer: `PINDAHAN`, `ALIH_JENJANG_D3_KE_S1`, `MBKM_MAGANG_STUDI_INDEPENDEN`, `MBKM_PERTUKARAN`, `RPL`.
2. **Matriks Pemetaan Ekuivalensi Kurikulum Dua Sisi**:
   - Pemetaan fleksibel: satu aktivitas magang (20 SKS) dapat dipecah menjadi 4–5 mata kuliah lokal sekaligus (1-to-N mapping).
   - Pengesahan nilai huruf lokal (`A`, `AB`, `B`, dll.) berdasarkan nilai evaluasi mentor mitra/transkrip asal.
3. **Injeksi Nilai Terakreditasi ke Transkrip Akademik**:
   - Memasukkan rekaman nilai konversi ke dalam basis data nilai mahasiswa dengan atribut khusus penanda asal perolehan.
   - Perhitungan otomatis ke dalam akumulasi SKS lulus dan IPK kumulatif.
4. **Penerbitan Surat Keputusan (SK) Penyetaraan**:
   - Generator Berita Acara Ekuivalensi dan SK Dekan pengesahan transfer kredit siap cetak berformat PDF.

---

## 2. Desain Antarmuka Pengguna & Wireframe ASCII

### 2.1 Matriks Ekuivalensi Konversi Nilai (Desktop / Web ≥ 1024 px)
```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 🔄 MATRIKS KONVERSI NILAI & TRANSFER KREDIT                      [+ Registrasi Transfer] [⬇ Unduh SK]   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Mahasiswa: [2410010901] Bagus Prasetyo (S1 TI - 2024)   Jalur: [ ALIH JENJANG D3 KE S1 (Politeknik) ] │
│ SK Penyetaraan: [ SK-KONV/FTI/2026/015 ]   Status: 🟢 DISAHKAN (Total Diakui: 68 SKS dari 110 SKS Asal)│
├───────────────────────────────────────────┬────────────────────────────────────────────────────────────┤
│ 🏫 MATA KULIAH ASAL (TRANSKRIP ASLI)      │ 🏛️ MATA KULIAH KURIKULUM LOKAL (YANG DIAKUI)               │
├───────────────────────────────────────────┼────────────────────────────────────────────────────────────┤
│ • [TI101] Algoritma Pemrograman (3 SKS)   │ ➔ [TI101] Algoritma & Pemrograman I (3 SKS)                │
│   Nilai Asal: A (Skor: 88.0)              │   Nilai Diakui: [ A (4.00) ▼ ]    Status: [ Terpetakan ✓ ] │
│ ───────────────────────────────────────── │ ────────────────────────────────────────────────────────── │
│ • [TI205] Praktikum Basis Data (2 SKS)    │ ➔ [TI202] Basis Data Terpadu (4 SKS)                       │
│ • [TI206] Teori Basis Data (2 SKS)        │   (Pola N-to-1: Menggabungkan 2 MK Asal menjadi 1 MK Lokal)│
│   Nilai Asal: B (3.0) & A (4.0)           │   Nilai Diakui: [ AB (3.50) ▼ ]   Status: [ Terpetakan ✓ ] │
│ ───────────────────────────────────────── │ ────────────────────────────────────────────────────────── │
│ • [MBKM01] Magang Software Eng (20 SKS)   │ ➔ Dipecah Menjadi 4 Mata Kuliah Lokal:                     │
│   Mitra: PT Telkom Indonesia              │   1. [TI401] Rekayasa Perangkat Lunak (3 SKS) -> Nilai: A  │
│   Nilai Evaluasi Mitra: 92.5 (A)          │   2. [TI402] Manajemen Proyek TI (3 SKS)      -> Nilai: A  │
│                                           │   3. [TI403] Kapita Selekta Industri (4 SKS)  -> Nilai: A  │
│                                           │   4. [TI404] Praktik Kerja Lapangan (10 SKS)  -> Nilai: A  │
├───────────────────────────────────────────┴────────────────────────────────────────────────────────────┤
│ Total SKS Diakui: 68 SKS (Sisa SKS yang Wajib Ditempuh untuk Lulus S1: 76 SKS)                         │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Rincian Fitur & Pola Pemetaan Ekuivalensi

### 3.1 Pola Relasi Pemetaan Mata Kuliah
Sistem mendukung 3 skenario pemetaan konversi kurikulum:
1. **Pola 1-to-1 (Direct Mapping)**:
   - Satu mata kuliah dari institusi asal dipetakan langsung ke satu mata kuliah lokal yang memiliki kemiripan silabus $\ge 70\%$.
2. **Pola N-to-1 (Merger Mapping)**:
   - Dua atau lebih mata kuliah asal (misal: "Praktikum Jaringan" 2 SKS dan "Teori Jaringan" 2 SKS) digabungkan menjadi satu mata kuliah kurikulum lokal ("Jaringan Komputer" 3 SKS). Nilai huruf disesuaikan dengan rata-rata tertimbang bobot SKS asal.
3. **Pola 1-to-N (Aktivitas MBKM 20 SKS)**:
   - Satu sertifikat/kegiatan magang atau studi independen MBKM berbobot total 20 SKS dikonversikan ke beberapa mata kuliah kurikulum prodi (biasanya mata kuliah pilihan dan kerja praktik) hingga total kumulatif tepat 20 SKS.

### 3.2 Tanda Khusus pada Transkrip Akademik (Transcript Annotation)
- Pada Kartu Hasil Studi (KHS) dan Transkrip Nilai Akademik, mata kuliah yang diperoleh melalui jalur konversi diberi kode penanda catatan kaki (*footnote*):
  - `*T` : Diperoleh melalui program Transfer Kredit Antar-Universitas.
  - `*M` : Diperoleh melalui program Merdeka Belajar Kampus Merdeka (MBKM).
  - `*R` : Diperoleh melalui jalur Rekognisi Pembelajaran Lampau (RPL).
- Nilai konversi **tidak memiliki relasi dengan tabel `kelas`** reguler pada semester aktif, melainkan langsung merujuk ke master `mata_kuliah` melalui tabel perantara `nilai_konversi`.

---

## 4. Logika Bisnis & Algoritma Penunjang

### 4.1 Prosedur Injeksi Nilai Konversi ke Basis Data Nilai Mahasiswa
```sql
CREATE OR REPLACE FUNCTION public.fn_admin_commit_credit_transfer(
    p_transfer_id UUID,
    p_nomor_sk VARCHAR(100),
    p_actor_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_injected_count INTEGER := 0;
    v_rec RECORD;
    v_student_npm VARCHAR(10);
BEGIN
    -- Validasi wewenang Admin
    IF NOT EXISTS (
        SELECT 1 FROM public.user_role ur
        JOIN public.role r ON ur.id_role = r.id
        WHERE ur.id_user = p_actor_id AND r.nama = 'ADMIN'
    ) THEN
        RAISE EXCEPTION 'Akses Ditolak: Hanya Administrator yang berwenang mengesahkan konversi nilai.';
    END IF;

    -- Ambil identitas mahasiswa dari record transfer
    SELECT id_mahasiswa INTO v_student_npm
    FROM public.mahasiswa_transfer
    WHERE id = p_transfer_id;

    -- Update SK pada tabel induk transfer
    UPDATE public.mahasiswa_transfer
    SET nomor_sk_penyetaraan = p_nomor_sk,
        status = 'DISAHKAN',
        disahkan_pada = NOW()
    WHERE id = p_transfer_id;

    -- Loop baris pemetaan konversi yang disetujui
    FOR v_rec IN (
        SELECT id_mata_kuliah_lokal, nilai_huruf_diakui, bobot_diakui
        FROM public.konversi_nilai_detail
        WHERE id_transfer = p_transfer_id
    )
    LOOP
        -- Injeksi atau timpa ke tabel nilai resmi mahasiswa
        INSERT INTO public.nilai_konversi_transkrip (
            id_mahasiswa, id_mata_kuliah, nilai_huruf, bobot_nilai, nomor_sk, asal_perolehan
        ) VALUES (
            v_student_npm, v_rec.id_mata_kuliah_lokal, v_rec.nilai_huruf_diakui, 
            v_rec.bobot_diakui, p_nomor_sk, 'TRANSFER_KREDIT'
        )
        ON CONFLICT (id_mahasiswa, id_mata_kuliah) 
        DO UPDATE SET nilai_huruf = EXCLUDED.nilai_huruf, bobot_nilai = EXCLUDED.bobot_nilai;

        v_injected_count := v_injected_count + 1;
    END LOOP;

    -- Catat log aktivitas audit
    INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
    VALUES (
        p_actor_id,
        'ADMIN_SAHKAN_KONVERSI_NILAI',
        'mahasiswa_transfer',
        p_transfer_id,
        jsonb_build_object(
            'npm', v_student_npm,
            'nomor_sk', p_nomor_sk,
            'total_mk_diakui', v_injected_count
        )
    );

    RETURN v_injected_count;
END;
$$;
```

---

## 5. Skema Data & Kueri Database Terkait

### 5.1 Skema Tabel Transfer Kredit & Detail Pemetaan
```sql
-- 1. Tabel Registrasi Riwayat Asal Transfer
CREATE TABLE IF NOT EXISTS public.mahasiswa_transfer (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mahasiswa VARCHAR(10) NOT NULL REFERENCES public.mahasiswa(npm) ON DELETE CASCADE,
    jenis_transfer VARCHAR(50) NOT NULL 
        CHECK (jenis_transfer IN ('PINDAHAN', 'ALIH_JENJANG', 'MBKM_MAGANG', 'MBKM_PERTUKARAN', 'RPL')),
    nama_institusi_asal VARCHAR(150) NOT NULL, -- Contoh: "Politeknik Negeri Jakarta" / "PT Telkom"
    prodi_asal VARCHAR(100),
    nim_asal VARCHAR(50),
    nomor_sk_penyetaraan VARCHAR(100),
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'VERIFIKASI', 'DISAHKAN')),
    dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    disahkan_pada TIMESTAMP WITH TIME ZONE
);

-- 2. Tabel Rincian Pemetaan Mata Kuliah
CREATE TABLE IF NOT EXISTS public.konversi_nilai_detail (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_transfer UUID NOT NULL REFERENCES public.mahasiswa_transfer(id) ON DELETE CASCADE,
    kode_mk_asal VARCHAR(50) NOT NULL,
    nama_mk_asal VARCHAR(150) NOT NULL,
    sks_asal INTEGER NOT NULL CHECK (sks_asal > 0),
    nilai_huruf_asal VARCHAR(5) NOT NULL,
    id_mata_kuliah_lokal UUID NOT NULL REFERENCES public.mata_kuliah(id) ON DELETE RESTRICT,
    nilai_huruf_diakui VARCHAR(5) NOT NULL CHECK (nilai_huruf_diakui IN ('A', 'AB', 'B', 'BC', 'C', 'D')),
    bobot_diakui NUMERIC(3,2) NOT NULL CHECK (bobot_diakui >= 1.00 AND bobot_diakui <= 4.00)
);

-- 3. Tabel Nilai Konversi Resmi (Masuk ke Transkrip Kumulatif)
CREATE TABLE IF NOT EXISTS public.nilai_konversi_transkrip (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mahasiswa VARCHAR(10) NOT NULL REFERENCES public.mahasiswa(npm) ON DELETE CASCADE,
    id_mata_kuliah UUID NOT NULL REFERENCES public.mata_kuliah(id) ON DELETE RESTRICT,
    nilai_huruf VARCHAR(5) NOT NULL,
    bobot_nilai NUMERIC(3,2) NOT NULL,
    nomor_sk VARCHAR(100) NOT NULL,
    asal_perolehan VARCHAR(50) NOT NULL DEFAULT 'TRANSFER_KREDIT',
    dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_mhs_mk_konversi UNIQUE (id_mahasiswa, id_mata_kuliah)
);

CREATE INDEX IF NOT EXISTS idx_nilai_konversi_mhs ON public.nilai_konversi_transkrip(id_mahasiswa);
```

---

## 6. Struktur Log Aktivitas & Payload Metadata JSON

```json
{
  "event_timestamp": "2026-09-28T13:30:00+08:00",
  "actor_id": "c1f8a840-7e32-4759-9943-8f0a0d4c9801",
  "actor_name": "Administrator Pusat",
  "aksi": "ADMIN_SAHKAN_KONVERSI_NILAI",
  "entitas": "mahasiswa_transfer",
  "id_entitas": "1f12a840-8821-4b12-9901-8f0a0d4c9333",
  "metadata": {
    "npm": "2410010901",
    "student_name": "Bagus Prasetyo",
    "jenis_transfer": "ALIH_JENJANG",
    "institusi_asal": "Politeknik Negeri Jakarta",
    "nomor_sk": "SK-KONV/FTI/2026/015",
    "total_sks_diakui": 68,
    "ipk_konversi": 3.42
  }
}
```

---

## 7. Penanganan Kasus Khusus (Edge Cases) & Validasi Sistem

| Skenario Kasus Khusus | Risiko Masalah | Solusi Penanganan Sistem |
| :--- | :--- | :--- |
| **Mata kuliah asal bernilai D atau E** | Nilai tidak layak diakui masuk ke transkrip. | Validasi form konversi menolak pemetaan jika nilai huruf asal bernilai `D` atau `E` (minimal diakui huruf `C`). |
| **Total konversi melebihi batas regulasi Dikti** | Kampus melanggar batas maksimal pengakuan kredit transfer (maksimal 70% total SKS S1). | Mesin validasi memberi peringatan keras jika total SKS yang diakui $> 100$ SKS untuk jenjang S1 (mahasiswa wajib menempuh minimal 36–44 SKS di kampus lokal). |
| **MK yang sudah dikonversi diambil lagi di kelas reguler** | Terjadi duplikasi nilai pada transkrip akhir. | Saat registrasi KRS, mesin validasi prasyarat menandai mata kuliah yang telah lulus lewat jalur konversi sehingga mahasiswa dicegah mengambilnya kembali. |
| **Konversi aktivitas magang MBKM melebihi 20 SKS** | Pelanggaran plafon maksimal kredit semester. | Sistem membatasi total SKS paket ekuivalensi MBKM per semester tidak boleh melampaui batas mutlak 20 SKS. |
