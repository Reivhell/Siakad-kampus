# 07 — Administrasi & Monitoring KRS (Kartu Rencana Studi)

> Modul pengawasan pengisian kartu rencana studi mahasiswa, pengaturan jendela waktu registrasi berjenjang (*staggered registration*), penegakan batas beban SKS berbasis IPS, serta kewenangan intervensi administratif (*Force-Add / Drop / Class Switch*).

---

## 1. Tujuan & Ruang Lingkup Fitur

Pengisian Kartu Rencana Studi (KRS) adalah titik puncak transaksi konkurensi tertinggi dalam sistem akademik. Modul ini menyediakan kontrol operasional bagi Administrator untuk mengelola lalu lintas registrasi, mengawasi kepatuhan beban SKS mahasiswa, menyelesaikan kendala kuota kelas penuh, serta menyediakan audit atas setiap tindakan intervensi manual.

### Ruang Lingkup Modul:
1. **Pengaturan Jendela Registrasi KRS (`jendela_krs`)**:
   - Kontrol buka/tutup masa pengisian KRS reguler dan masa perbaikan/perubahan KRS (KPRS).
   - Pengaturan jadwal pembukaan berjenjang (*staggered batch window*) per angkatan/prodi guna mereduksi lonjakan beban server.
2. **Dashboard Monitoring KRS Real-Time**:
   - Pemantauan matriks keterisian mahasiswa: *Belum Mengisi*, *Draft*, *Menunggu Persetujuan Dosen Wali*, dan *Telah Disahkan (Terkunci)*.
   - Deteksi dini kelas-kelas yang kuotanya kritis atau minim peminat.
3. **Fasilitas Intervensi Administratif (Admin Override Suite)**:
   - **Force-Add**: Memasukkan mahasiswa ke kelas yang kuotanya telah 100% penuh atas disposisi resmi pimpinan fakultas.
   - **Drop / Pembatalan KRS**: Menggugurkan registrasi mata kuliah mahasiswa akibat pelanggaran syarat SPP atau cuti mendadak.
   - **Pindah Kelas (Switch Class)**: Memindahkan pendaftaran mahasiswa dari satu kelas paralel ke kelas lain tanpa kehilangan riwayat studi.
   - **Bypass Plafon SKS**: Dispensasi khusus pengambilan melebihi beban maksimal bagi mahasiswa tingkat akhir yang mengulang.
4. **Mesin Validasi Beban SKS Berbasis IPS Sebelumnya**:
   - Penerapan aturan nasional batas maksimal SKS berdasarkan capaian akademik semester lampau.

---

## 2. Desain Antarmuka Pengguna & Wireframe ASCII

### 2.1 Dashboard Pengawasan KRS Real-Time (Desktop / Web ≥ 1024 px)
```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 📝 PUSAT OPERASIONAL KRS MAHASISWA                               [⚙ Atur Jadwal KRS]  [⚡ Override KRS] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Semester: [ Ganjil 2025/2026 ● AKTIF ]   Status Portal: 🟢 DIBUKA (Sisa Waktu: 3 Hari 14 Jam 20 Mnt)   │
│ Progres Global: [■■■■■■■■■■■■■■■■■■□□] 92.4% (1.312 / 1.420 Mahasiswa Telah Menyelesaikan KRS)         │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 🔍 [Cari NPM / Nama...] │ Prodi: [Semua Prodi ▼] │ Angkatan: [2024 ▼] │ Status: [Menunggu Approval ▼]  │
├──────┬────────────┬────────────────────────┬─────────┬──────────┬────────┬───────────┬─────────────────┤
│ NO   │ NPM        │ NAMA MAHASISWA         │ PRODI   │ ANGKATAN │ SKS    │ STATUS    │ AKSI INTERVENSI │
├──────┼────────────┼────────────────────────┼─────────┼──────────┼────────┼───────────┼─────────────────┤
│ 01   │ 2410010015 │ Reza Pratama           │ S1 TI   │ 2024     │ 22 SKS │ 🟡 PENDING│ [Bypass Approval│
│ 02   │ 2410010022 │ Dinda Safitri          │ S1 TI   │ 2024     │ 24 SKS │ 🟢 APPROVED│ [Detail KHS]    │
│ 03   │ 2410010034 │ Kevin Sanjaya          │ S1 TI   │ 2024     │ 18 SKS │ ⚪ DRAFT   │ [Kirim Reminder]│
│ 04   │ 2410010050 │ Nurul Hidayah          │ S1 TI   │ 2024     │ 24 SKS │ 🔴 KUOTA! │ [Force-Add Kelas│
├──────┴────────────┴────────────────────────┴─────────┴──────────┴────────┴───────────┴─────────────────┤
│ Antrean Disposisi Force-Add Menunggu Eksekusi Admin: 3 Permohonan                                      │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Wireframe Modal Eksekusi Force-Add KRS (Kapasitas Penuh)
```
┌────────────────────────────────────────────────────────────────┐
│ ⚡ ADMINISTRATIF OVERRIDE: FORCE-ADD MAHASISWA KE KELAS [ X ]  │
├────────────────────────────────────────────────────────────────┤
│ Mahasiswa Sasaran  : [2410010050] Nurul Hidayah (S1 TI - 2024) │
│ IPS Semester Lalu  : 3.45 (Beban Maksimal: 24 SKS)             │
│ SKS Terambil Saat Ini: 21 SKS (Tersisa Kuota: 3 SKS)           │
├────────────────────────────────────────────────────────────────┤
│ PILIH KELAS TARGET (MATA KULIAH 3 SKS):                        │
│ Kelas Pilihan      : [TI301-A] Basis Data Lanjut (3 SKS)    ▼ ]│
│ Status Kuota Kelas : ⚠️ 40 / 40 Kursi (100% PENUH)             │
│ Kapasitas Ruangan  : 45 Kursi (LAB-KOMP-1) -> [Aman Secara Fisik]
├────────────────────────────────────────────────────────────────┤
│ DASAR HUKUM / ALASAN DISPENSASI ADMIN:                         │
│ Nomor Surat Izin * : [ DISP-KRS/FTI/2026/089                 ] │
│ Alasan Persetujuan*: (o) Mata Kuliah Wajib Prasyarat Kelulusan │
│                      ( ) Penyetaraan Kurikulum Transfer        │
│                      ( ) Rekomendasi Khusus Kaprodi            │
│ Catatan Khusus     : [ Mahasiswa tingkat 3 mengejar semester ] │
├────────────────────────────────────────────────────────────────┤
│ [ Batalkan ]                             [ Eksekusi Force-Add ]│
└────────────────────────────────────────────────────────────────┘
```

---

## 3. Rincian Fitur & Aturan Bisnis

### 3.1 Kontrol Jendela KRS Berjenjang (Staggered Window)
Untuk mencegah *server bottleneck* saat ribuan mahasiswa berebut kelas secara bersamaan, admin dapat mengonfigurasi jadwal akses bertingkat:
- **Hari 1–2**: Khusus Mahasiswa Tingkat Akhir (Semester 7 ke atas) untuk memastikan mata kuliah skripsi/kelulusan terpenuhi.
- **Hari 3–4**: Khusus Mahasiswa Semester 5–6.
- **Hari 5–6**: Khusus Mahasiswa Semester 3–4.
- **Hari 7**: Mahasiswa Baru (Semester 1–2) paket otomatis dan pembukaan umum (*free-for-all*).

### 3.2 Matriks Batasan Beban SKS Berdasarkan IPS Lampau
Sesuai pedoman akademik nasional, kapasitas maksimal pengambilan SKS pada semester reguler dihitung secara otomatis berdasarkan Indeks Prestasi Semester (IPS) yang diperoleh mahasiswa pada semester aktif sebelumnya:

| Capaian IPS Semester Lalu | Beban SKS Maksimal Diizinkan |
| :---: | :---: |
| $\text{IPS} \ge 3.00$ | **24 SKS** |
| $2.50 \le \text{IPS} < 3.00$ | **21 SKS** |
| $2.00 \le \text{IPS} < 2.50$ | **18 SKS** |
| $1.50 \le \text{IPS} < 2.00$ | **15 SKS** |
| $\text{IPS} < 1.50$ | **12 SKS** |
| **Mahasiswa Baru (Semester 1 & 2)** | **Paket Tetap (20 SKS)** |

- Mahasiswa tidak dapat mengunci formulir KRS apabila total SKS yang dipilih melampaui batas plafon ini tanpa dispensasi bypass dari Admin.

### 3.3 Kewenangan Intervensi Administratif (Admin Force Powers)
1. **Force-Add ke Kelas Penuh**:
   - Menambahkan mahasiswa ke baris pendaftaran `krs` meskipun `kelas.jumlah_terdaftar >= kelas.kapasitas`.
   - Mengabaikan pengecekan kapasitas kelas, tetapi sistem tetap memvalidasi kapasitas fisik ruangan (`ruangan.kapasitas`) untuk mencegah ketiadaan kursi fisik.
2. **Pindah Kelas Otomatis (Atomic Switch Class)**:
   - Mengubah referensi `id_kelas` pada tabel `krs` dari Kelas A ke Kelas B.
   - Counter `jumlah_terdaftar` di Kelas A berkurang 1, dan di Kelas B bertambah 1 secara atomik.
3. **Bypass Approval Dosen Wali**:
   - Jika Dosen Wali berhalangan hadir atau sakit hingga batas akhir masa KRS, Admin memiliki hak legal untuk mengesahkan KRS mahasiswa secara langsung atas mandat Ketua Program Studi.

---

## 4. Logika Bisnis & Algoritma Penunjang

### 4.1 Logika Hitung Plafon SKS Berdasarkan IPS (Dart)
```dart
int calculateMaxAllowedCredits({
  required int currentSemester,
  required double? previousSemesterGpa,
}) {
  // Mahasiswa baru semester 1 & 2 menggunakan paket tetap institusi
  if (currentSemester <= 2 || previousSemesterGpa == null) {
    return 20;
  }

  if (previousSemesterGpa >= 3.00) return 24;
  if (previousSemesterGpa >= 2.50) return 21;
  if (previousSemesterGpa >= 2.00) return 18;
  if (previousSemesterGpa >= 1.50) return 15;
  return 12;
}
```

### 4.2 Prosedur Atomik Force-Add KRS oleh Admin
```sql
CREATE OR REPLACE FUNCTION public.fn_admin_force_add_krs(
    p_student_npm VARCHAR(10),
    p_target_class_id UUID,
    p_surat_dispensasi VARCHAR(100),
    p_alasan TEXT,
    p_actor_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_krs_id UUID;
    v_course_id UUID;
    v_course_name TEXT;
    v_class_code TEXT;
    v_active_period_id UUID;
BEGIN
    -- 1. Verifikasi Wewenang Admin
    IF NOT EXISTS (
        SELECT 1 FROM public.user_role ur
        JOIN public.role r ON ur.id_role = r.id
        WHERE ur.id_user = p_actor_id AND r.nama = 'ADMIN'
    ) THEN
        RAISE EXCEPTION 'Akses Ditolak: Hanya Administrator yang berwenang mengeksekusi Force-Add KRS.';
    END IF;

    -- 2. Ambil Informasi Kelas & Periode Aktif
    SELECT k.id_mata_kuliah, mk.nama, k.kode, k.id_periode_akademik
    INTO v_course_id, v_course_name, v_class_code, v_active_period_id
    FROM public.kelas k
    JOIN public.mata_kuliah mk ON k.id_mata_kuliah = mk.id
    WHERE k.id = p_target_class_id;

    -- 3. Cek apakah mahasiswa sudah terdaftar di kelas lain untuk mata kuliah yang sama
    IF EXISTS (
        SELECT 1 FROM public.krs krs_entry
        JOIN public.kelas k ON krs_entry.id_kelas = k.id
        WHERE krs_entry.id_mahasiswa = p_student_npm 
          AND k.id_mata_kuliah = v_course_id 
          AND k.id_periode_akademik = v_active_period_id
          AND krs_entry.status = 'AKTIF'
    ) THEN
        RAISE EXCEPTION 'Mahasiswa telah terdaftar pada kelas lain untuk mata kuliah "%"!', v_course_name;
    END IF;

    -- 4. Injeksi Pendaftaran KRS dengan Flag Dispensasi
    v_krs_id := gen_random_uuid();
    INSERT INTO public.krs (id, id_mahasiswa, id_kelas, status, disetujui_oleh_pa)
    VALUES (v_krs_id, p_student_npm, p_target_class_id, 'AKTIF', true);

    -- 5. Perbarui Counter Keterisian Kelas
    UPDATE public.kelas
    SET jumlah_terdaftar = jumlah_terdaftar + 1
    WHERE id = p_target_class_id;

    -- 6. Rekam Jejak Audit Intervensi
    INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
    VALUES (
        p_actor_id,
        'ADMIN_FORCE_ADD_KRS',
        'krs',
        v_krs_id,
        jsonb_build_object(
            'npm', p_student_npm,
            'class_code', v_class_code,
            'course_name', v_course_name,
            'surat_dispensasi', p_surat_dispensasi,
            'alasan', p_alasan
        )
    );

    RETURN v_krs_id;
END;
$$;
```

---

## 5. Skema Data & Kueri Database Terkait

### 5.1 Skema Tabel `public.krs` & Trigger Counter Peserta
```sql
-- 1. Tabel Registrasi KRS
CREATE TABLE IF NOT EXISTS public.krs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mahasiswa VARCHAR(10) NOT NULL REFERENCES public.mahasiswa(npm) ON DELETE RESTRICT,
    id_kelas UUID NOT NULL REFERENCES public.kelas(id) ON DELETE RESTRICT,
    status VARCHAR(20) NOT NULL DEFAULT 'AKTIF' 
        CHECK (status IN ('DRAFT', 'MENUNGGU_APPROVAL', 'AKTIF', 'BATAL', 'MENGUNDURKAN_DIRI')),
    disetujui_oleh_pa BOOLEAN NOT NULL DEFAULT false,
    catatan_pa TEXT,
    dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    diperbarui_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_mhs_kelas UNIQUE (id_mahasiswa, id_kelas)
);

-- Indeks Efisiensi Pencarian
CREATE INDEX IF NOT EXISTS idx_krs_mahasiswa ON public.krs(id_mahasiswa);
CREATE INDEX IF NOT EXISTS idx_krs_kelas ON public.krs(id_kelas);
CREATE INDEX IF NOT EXISTS idx_krs_status ON public.krs(status);
```

### 5.2 Trigger Sinkronisasi Counter Jumlah Terdaftar Kelas
```sql
CREATE OR REPLACE FUNCTION public.fn_sync_class_enrolled_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF (TG_OP = 'INSERT' AND NEW.status = 'AKTIF') THEN
        UPDATE public.kelas 
        SET jumlah_terdaftar = jumlah_terdaftar + 1 
        WHERE id = NEW.id_kelas;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.status != 'AKTIF' AND NEW.status = 'AKTIF') THEN
            UPDATE public.kelas 
            SET jumlah_terdaftar = jumlah_terdaftar + 1 
            WHERE id = NEW.id_kelas;
        ELSIF (OLD.status = 'AKTIF' AND NEW.status != 'AKTIF') THEN
            UPDATE public.kelas 
            SET jumlah_terdaftar = GREATEST(jumlah_terdaftar - 1, 0) 
            WHERE id = OLD.id_kelas;
        END IF;
    ELSIF (TG_OP = 'DELETE' AND OLD.status = 'AKTIF') THEN
        UPDATE public.kelas 
        SET jumlah_terdaftar = GREATEST(jumlah_terdaftar - 1, 0) 
        WHERE id = OLD.id_kelas;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_class_enrolled ON public.krs;
CREATE TRIGGER trg_sync_class_enrolled
AFTER INSERT OR UPDATE OR DELETE ON public.krs
FOR EACH ROW
EXECUTE FUNCTION public.fn_sync_class_enrolled_count();
```

---

## 6. Struktur Log Aktivitas & Payload Metadata JSON

```json
{
  "event_timestamp": "2026-09-28T12:00:00+08:00",
  "actor_id": "c1f8a840-7e32-4759-9943-8f0a0d4c9801",
  "actor_name": "Administrator Pusat",
  "aksi": "ADMIN_FORCE_ADD_KRS",
  "entitas": "krs",
  "id_entitas": "7a8bc10b-11aa-4372-9901-0e02b2c3d111",
  "metadata": {
    "npm": "2410010050",
    "student_name": "Nurul Hidayah",
    "class_code": "TI301-A",
    "course_name": "Basis Data Lanjut",
    "quota_before": 40,
    "quota_after": 41,
    "surat_dispensasi": "DISP-KRS/FTI/2026/089",
    "alasan": "Mata Kuliah Wajib Prasyarat Kelulusan",
    "ip_address": "192.168.1.52"
  }
}
```

---

## 7. Penanganan Kasus Khusus (Edge Cases) & Validasi Sistem

| Skenario Kasus Khusus | Risiko Masalah | Solusi Penanganan Sistem |
| :--- | :--- | :--- |
| **Dua mahasiswa klik slot terakhir bersamaan (*race condition*)** | Kelas kelebihan kuota secara liar. | Gunakan transaksi dengan baris terkunci (`SELECT FOR UPDATE`) pada tabel `kelas` saat registrasi mandiri mahasiswa. |
| **Mahasiswa membatalkan mata kuliah setelah jadwal kuliah mulai** | Rekapitulasi absensi dan presensi menjadi cacat. | Pembatalan KRS oleh mahasiswa dibatasi hanya sampai minggu ke-2 semester (KPRS). Setelah minggu ke-2, hanya Admin yang dapat mengubah status menjadi `MENGUNDURKAN_DIRI`. |
| **Pindah kelas tapi jadwal kelas baru bentrok dengan jadwal lain** | Mahasiswa memiliki jadwal tumpang tindih. | Sistem mengecek matriks jadwal kelas baru terhadap seluruh jadwal kelas lain yang telah diambil mahasiswa sebelum perpindahan disahkan. |
| **Keterlambatan pembayaran SPP/UKT** | Mahasiswa tidak berhak registrasi KRS. | Portal KRS memverifikasi flag status keuangan mahasiswa via integrasi data sebelum membuka antarmuka pemilihan kelas. |
