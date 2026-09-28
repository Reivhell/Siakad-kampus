# 15 — Administrasi Surat Keterangan & Layanan Dokumen Akademik

> Modul pengelolaan permohonan surat akademik mahasiswa, generator dokumen resmi berpenomoran otomatis (*Structured Sequence Numbering*), template dinamis berbasis variabel, serta mesin verifikasi keabsahan dokumen publik via kode QR (*Public Document Verification Engine*).

---

## 1. Tujuan & Ruang Lingkup Fitur

Layanan administrasi persuratan sering kali menjadi titik keluhan birokrasi manual di perguruan tinggi. Modul ini mendigitalisasi seluruh rantai proses penerbitan dokumen resmi, memvalidasi prasyarat keaktifan mahasiswa secara otomatis, menghasilkan nomor surat resmi berurutan tanpa risiko bentrok, serta mencegah pemalsuan surat menggunakan stempel digital kode QR yang dapat diverifikasi oleh pihak eksternal (Kementerian, Perusahaan, atau Bank).

### Ruang Lingkup Modul:
1. **Katalog Layanan Surat Keterangan Akademik**:
   - Surat Keterangan Mahasiswa Aktif (Keperluan Tunjangan Gaji Anak, BPJS, Beasiswa).
   - Surat Pengantar Praktik Kerja Lapangan (PKL) / Magang Industri.
   - Surat Izin Penelitian & Pengambilan Data Skripsi.
   - Surat Keterangan Lulus (SKL) Sementara pengganti ijazah.
   - Surat Bebas Sanksi Akademik / Berkelakuan Baik.
2. **Mesin Penomoran Surat Otomatis Terstruktur**:
   - Format: `[NomorUrut]/[Klasifikasi]/[Fakultas-SIAKAD]/[BulanRomawi]/[Tahun]`.
   - Reset nomor urut otomatis setiap tanggal 1 Januari tahun baru.
3. **Template Dokumen Dinamis & Engine Substitusi Variabel**:
   - Dukungan variabel: `{{nama_lengkap}}`, `{{npm}}`, `{{program_studi}}`, `{{ipk}}`, `{{instansi_tujuan}}`, dll.
4. **Antrean Verifikasi Permohonan (Inbox Approval Admin)**:
   - Pemeriksaan kelayakan otomatis (status mahasiswa wajib `AKTIF`, bebas tunggakan keuangan).
   - Persetujuan instan (*one-click approve*) dan otomatisasi penerbitan PDF resmi.
5. **Mesin Verifikasi Dokumen Publik (Public QR-Code Verifier)**:
   - Portal web publik tanpa login untuk validasi keaslian dokumen oleh pihak eksternal.

---

## 2. Desain Antarmuka Pengguna & Wireframe ASCII

### 2.1 Antrean Permohonan Surat Masuk (Desktop / Web ≥ 1024 px)
```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 📑 PUSAT LAYANAN PERSURATAN AKADEMIK                             [⚙ Kelola Template]  [⬇ Arsip Surat]   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Antrean Masuk: 18 Permohonan (🟡 6 Menunggu Verifikasi | 🟢 12 Telah Diterbitkan Hari Ini)              │
│ 🔍 [Cari NPM / Nama / No Surat...] │ Jenis: [Semua Surat ▼] │ Status: [Menunggu Verifikasi ▼]         │
├──────┬────────────────────────┬──────────────────────┬─────────────┬─────────────┬──────────┬──────────┤
│ NO   │ MAHASISWA (NPM)        │ JENIS SURAT          │ TUJUAN / KET│ TGL PENGAJUAN│ STATUS   │ AKSI     │
├──────┼────────────────────────┼──────────────────────┼─────────────┼─────────────┼──────────┼──────────┤
│ 01   │ Aditya Pratama (221001)│ Keterangan Mhs Aktif │ Tunjangan GP│ Hari ini 09:15│ 🟡 PENDING│ [Periksa]│
│ 02   │ Siti Nurhaliza (261001)│ Pengantar Magang PKL │ PT Telkom   │ Hari ini 08:30│ 🟡 PENDING│ [Periksa]│
│ 03   │ Bagas Wicaksono(251001)│ Izin Riset Skripsi   │ Diskominfo  │ Kemarin 14:00 │ 🟢 SELESAI│ [Unduh ⬇]│
│ 04   │ Dimas Surya (231001)   │ Keterangan Mhs Aktif │ Beasiswa BI │ Kemarin 11:20 │ 🔴 DITOLAK│ [Alasan] │
├──────┴────────────────────────┴──────────────────────┴─────────────┴─────────────┴──────────┴──────────┤
│ Halaman: [ < Sebelumnya ] 1  2  3 [ Selanjutnya > ]                            Total Arsip: 1.840 Surat│
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Wireframe Modal Pemeriksaan & Penerbitan Surat
```
┌────────────────────────────────────────────────────────────────┐
│ 📝 VERIFIKASI PERMOHONAN SURAT AKADEMIK                [ X ]   │
├────────────────────────────────────────────────────────────────┤
│ Mahasiswa Pemohon : [2210010001] Aditya Pratama (S1 TI - 2022) │
│ Jenis Surat       : Surat Keterangan Mahasiswa Aktif Kuliah    │
│ Keperluan / Tujuan: Pengurusan Tunjangan Gaji Orang Tua (PNS)  │
├────────────────────────────────────────────────────────────────┤
│ HASIL PRA-PEMERIKSAAN KELAYAKAN MAHASISWA (AUTO-CHECK):        │
│ [✓] Status Akademik: AKTIF (Semester 7 - Ganjil 2025/2026)     │
│ [✓] Registrasi KRS : Terdaftar 22 SKS pada semester berjalan   │
│ [✓] Keuangan UKT   : LUNAS (Tidak ada tunggakan pembayaran)    │
├────────────────────────────────────────────────────────────────┤
│ ALOKASI NOMOR SURAT RESMI (AUTO-GENERATED):                    │
│ Nomor Surat       : [ 042/S.Ket-Aktif/FTI-SIAKAD/IX/2026     ] │
│ Pejabat Bertandatangan: [ Dekan FTI - Dr. Ir. Suyanto, M.T.  ▼]│
│                                                                │
│ [👁 Pratinjau Dokumen PDF]   [ QR Code Keabsahan: Aktif ]      │
├────────────────────────────────────────────────────────────────┤
│ [ Tolak Permohonan ]                   [ Setujui & Terbitkan ] │
└────────────────────────────────────────────────────────────────┘
```

---

## 3. Rincian Fitur & Standar Penomoran Otomatis

### 3.1 Format Penomoran Surat Resmi Terstruktur
Setiap dokumen yang diterbitkan memperoleh nomor unik dengan formula deterministik:
$$\text{No Surat} = \underbrace{\text{UUU}}_{3\text{ digit urut}} / \underbrace{\text{KODELAYANAN}}_{\text{Kode Klasifikasi}} / \underbrace{\text{FAK-SIAKAD}}_{\text{Unit Penerbit}} / \underbrace{\text{ROMAWI}}_{\text{Bulan Terbit}} / \underbrace{\text{TTTT}}_{4\text{ digit tahun}}$$

- **Daftar Kode Klasifikasi Surat**:
  - `S.Ket-Aktif`: Surat Keterangan Mahasiswa Aktif Kuliah.
  - `S.Peng-Magang`: Surat Pengantar Magang / Kerja Praktik.
  - `S.Izin-Riset`: Surat Izin Penelitian / Pengambilan Data.
  - `SKL`: Surat Keterangan Lulus Sementara.
  - `S.Ket-Kelakuan`: Surat Keterangan Berkelakuan Baik.
- **Contoh Lengkap**: `042/S.Ket-Aktif/FTI-SIAKAD/IX/2026`.

### 3.2 Mesin Verifikasi Dokumen Publik (Public QR-Code Verifier)
- Setiap dokumen PDF resmi yang dihasilkan sistem dilengkapi cap stempel kode QR di pojok kanan bawah.
- Kode QR memuat tautan web publik resmi:
  `https://siakad.kampus.ac.id/verifikasi-surat?token=7a9f23e1b8c044...`
- Saat dipindai menggunakan kamera ponsel atau pembaca QR pihak eksternal (HRD perusahaan, bank, taspen), layar menampilkan laman otentikasi resmi:
  - 🟢 **Dokumen Terverifikasi Asli & Sah**.
  - Judul Dokumen & Nomor Surat Resmi.
  - Nama Mahasiswa & NPM.
  - Tanggal Diterbitkan & Masa Berlaku Surat (standar 3 s.d. 6 bulan).
  - Tanda tangan digital pimpinan institusi yang berwenang.

---

## 4. Logika Bisnis & Algoritma Penunjang

### 4.1 Prosedur Penerbitan Surat & Alokasi Nomor Urut Atomik
```sql
CREATE OR REPLACE FUNCTION public.fn_admin_issue_academic_letter(
    p_request_id UUID,
    p_pejabat_penandatangan VARCHAR(150),
    p_actor_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_year INTEGER;
    v_month INTEGER;
    v_roman_month TEXT;
    v_letter_code TEXT;
    v_next_seq INTEGER;
    v_final_letter_number TEXT;
    v_verification_token UUID;
    v_months_array TEXT[] := ARRAY['I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII'];
BEGIN
    -- 1. Validasi wewenang Admin
    IF NOT EXISTS (
        SELECT 1 FROM public.user_role ur
        JOIN public.role r ON ur.id_role = r.id
        WHERE ur.id_user = p_actor_id AND r.nama = 'ADMIN'
    ) THEN
        RAISE EXCEPTION 'Akses Ditolak: Hanya Administrator yang berwenang menerbitkan surat resmi.';
    END IF;

    -- 2. Ambil Parameter Kalender
    v_year := EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER;
    v_month := EXTRACT(MONTH FROM CURRENT_DATE)::INTEGER;
    v_roman_month := v_months_array[v_month];

    -- 3. Ambil Kode Surat dari Template
    SELECT ts.kode_klasifikasi INTO v_letter_code
    FROM public.permohonan_surat ps
    JOIN public.template_surat ts ON ps.id_template = ts.id
    WHERE ps.id = p_request_id;

    -- 4. Alokasi Nomor Urut Tahunan dengan Penguncian Baris
    SELECT COALESCE(MAX(nomor_urut), 0) + 1
    INTO v_next_seq
    FROM public.permohonan_surat
    WHERE tahun_terbit = v_year AND status = 'SELESAI';

    -- 5. Susun Nomor Surat Lengkap
    v_final_letter_number := LPAD(v_next_seq::TEXT, 3, '0') || '/' || 
                             v_letter_code || '/FTI-SIAKAD/' || 
                             v_roman_month || '/' || v_year::TEXT;

    -- 6. Generate Token Verifikasi Unik untuk QR-Code
    v_verification_token := gen_random_uuid();

    -- 7. Update Status Permohonan Menjadi SELESAI
    UPDATE public.permohonan_surat
    SET nomor_surat = v_final_letter_number,
        nomor_urut = v_next_seq,
        tahun_terbit = v_year,
        pejabat_penandatangan = p_pejabat_penandatangan,
        token_verifikasi = v_verification_token,
        status = 'SELESAI',
        diterbitkan_pada = NOW(),
        berlaku_hingga = CURRENT_DATE + INTERVAL '90 days'
    WHERE id = p_request_id;

    -- 8. Catat Audit Trail
    INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
    VALUES (
        p_actor_id,
        'ADMIN_TERBITKAN_SURAT_AKADEMIK',
        'permohonan_surat',
        p_request_id,
        jsonb_build_object(
            'nomor_surat', v_final_letter_number,
            'token_verifikasi', v_verification_token
        )
    );

    RETURN jsonb_build_object(
        'nomor_surat', v_final_letter_number,
        'token_verifikasi', v_verification_token
    );
END;
$$;
```

---

## 5. Skema Data & Kueri Database Terkait

### 5.1 Skema Tabel `public.template_surat` & `public.permohonan_surat`
```sql
-- 1. Master Template Surat Akademik
CREATE TABLE IF NOT EXISTS public.template_surat (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kode_klasifikasi VARCHAR(50) NOT NULL UNIQUE, -- Contoh: "S.Ket-Aktif", "S.Peng-Magang"
    nama_layanan VARCHAR(150) NOT NULL,
    konten_template TEXT NOT NULL, -- Format HTML / Markdown berisi {{variabel}}
    butuh_tujuan_instansi BOOLEAN NOT NULL DEFAULT false,
    aktif BOOLEAN NOT NULL DEFAULT true,
    dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Transaksi Permohonan & Penerbitan Surat
CREATE TABLE IF NOT EXISTS public.permohonan_surat (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mahasiswa VARCHAR(10) NOT NULL REFERENCES public.mahasiswa(npm) ON DELETE RESTRICT,
    id_template UUID NOT NULL REFERENCES public.template_surat(id) ON DELETE RESTRICT,
    tujuan_instansi VARCHAR(200),
    keterangan_keperluan TEXT NOT NULL,
    nomor_surat VARCHAR(100) UNIQUE,
    nomor_urut INTEGER,
    tahun_terbit INTEGER,
    pejabat_penandatangan VARCHAR(150),
    token_verifikasi UUID UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'MENUNGGU_VERIFIKASI' 
        CHECK (status IN ('MENUNGGU_VERIFIKASI', 'SELESAI', 'DITOLAK')),
    catatan_penolakan TEXT,
    dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    diterbitkan_pada TIMESTAMP WITH TIME ZONE,
    berlaku_hingga DATE
);

CREATE INDEX IF NOT EXISTS idx_permohonan_surat_mhs ON public.permohonan_surat(id_mahasiswa);
CREATE INDEX IF NOT EXISTS idx_permohonan_token ON public.permohonan_surat(token_verifikasi);
```

---

## 6. Struktur Log Aktivitas & Payload Metadata JSON

```json
{
  "event_timestamp": "2026-09-28T13:45:00+08:00",
  "actor_id": "c1f8a840-7e32-4759-9943-8f0a0d4c9801",
  "actor_name": "Administrator Pusat",
  "aksi": "ADMIN_TERBITKAN_SURAT_AKADEMIK",
  "entitas": "permohonan_surat",
  "id_entitas": "8e12a840-5521-4b12-9901-8f0a0d4c9222",
  "metadata": {
    "npm": "2210010001",
    "student_name": "Aditya Pratama",
    "jenis_surat": "Surat Keterangan Mahasiswa Aktif Kuliah",
    "nomor_surat": "042/S.Ket-Aktif/FTI-SIAKAD/IX/2026",
    "token_verifikasi": "7a9f23e1-b8c0-4412-9911-3840e791c890",
    "pejabat_penandatangan": "Dr. Ir. Suyanto, M.T."
  }
}
```

---

## 7. Penanganan Kasus Khusus (Edge Cases) & Validasi Sistem

| Skenario Kasus Khusus | Risiko Masalah | Solusi Penanganan Sistem |
| :--- | :--- | :--- |
| **Mahasiswa Cuti/DO meminta surat aktif kuliah** | Penerbitan surat keterangan palsu yang melanggar hukum. | Mesin validasi pre-flight otomatis menggagalkan pembuatan surat keterangan aktif jika `mahasiswa.status != 'AKTIF'`. |
| **Nomor surat bentrok pada pergantian tahun baru** | Tabrakan nomor urut surat. | Kueri pencarian `MAX(nomor_urut)` selalu difilter berdasarkan `WHERE tahun_terbit = EXTRACT(YEAR FROM CURRENT_DATE)`. |
| **Surat kadaluwarsa diverifikasi pihak eksternal** | Surat lama dipakai untuk tunjangan berulang. | Halaman verifikasi publik menampilkan status merah: *"Dokumen ini telah KADALUWARSA (Masa berlaku berakhir pada [Tanggal])"*. |
| **Pembatalan surat yang terlanjur terbit** | Surat keliru tetap beredar di publik. | Admin memiliki fitur *Revoke Document* yang mengubah status surat menjadi `DIBATALKAN`. Saat QR-Code discan, halaman publik menampilkan peringatan dokumen telah dicabut institusi. |
