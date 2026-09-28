# 08 — Monitoring Penilaian & Evaluasi Akademik

> Modul pengawasan kepatuhan penginputan nilai dosen, audit perhitungan nilai akhir otomatis, formula konversi huruf mutu, kalkulasi IPS/IPK kumulatif, penerbitan KHS/Transkrip, serta mekanisme buka kunci nilai berizin (*Unlock Grade Workflow*).

---

## 1. Tujuan & Ruang Lingkup Fitur

Penilaian akademik menentukan nasib studi mahasiswa, evaluasi kelulusan, dan akreditasi perguruan tinggi. Modul ini menyediakan visibilitas penuh bagi Administrator atas progres penginputan nilai oleh dosen pengampu, memastikan integritas formula pembobotan nilai, mengotomatisasi perhitungan indeks prestasi, serta menegakkan tata kelola perubahan nilai pasca-finalisasi.

### Ruang Lingkup Modul:
1. **Monitoring Kepatuhan Penginputan Nilai Dosen**:
   - Tinjauan status penilaian per kelas: *Belum Diinput (0%)*, *Draft / Sebagian*, *Siap Disahkan*, dan *Sudah Final (Terkunci)*.
   - Peringatan batas akhir (*deadline countdown*) dan otomatisasi pengiriman reminder ke dosen.
2. **Formula & Standarisasi Konversi Nilai Akhir**:
   - Komposisi pembobotan fleksibel (Tugas, Kuis, Presensi, UTS, UAS).
   - Konversi standar nilai angka (0–100) ke nilai huruf (A s.d. E) dan bobot mutu (0.00 s.d. 4.00).
3. **Kalkulasi Otomatis IPS & IPK Kumulatif**:
   - Perhitungan Indeks Prestasi Semester (IPS) dan Indeks Prestasi Kumulatif (IPK) dengan penanganan mata kuliah mengulang (*course retake policy*).
4. **Kebijakan Buka Kunci Nilai (Unlock Grade Policy)**:
   - Prosedur ketat pembukaan kembali status finalisasi nilai atas dasar Berita Acara Perbaikan Nilai resmi.
   - Fitur *Auto-Relock Window* (akses perbaikan otomatis terkunci kembali setelah 48 jam).
5. **Pencetakan Dokumen Akademik Resmi**:
   - Pembuatan lembar Kartu Hasil Studi (KHS) per semester dan Transkrip Akademik Sementara berstempel QR-Code.

---

## 2. Desain Antarmuka Pengguna & Wireframe ASCII

### 2.1 Tampilan Pengawasan Nilai per Kelas (Desktop / Web ≥ 1024 px)
```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 📊 MONITORING PENILAIAN AKADEMIK DOSEN                           [⚡ Kirim Reminder Massal]  [⬇ Rekap]  │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Semester: [ Ganjil 2025/2026 ● AKTIF ]  Batas Akhir Finalisasi: 28 Januari 2026 (Sisa: 6 Hari 12 Jam) │
│ Keterisian Kampus: [■■■■■■■■■■■■■■■□□□□□] 74.2% Kelas Telah Finalisasi Nilai                          │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 🔍 [Cari Mata Kuliah / Dosen...] │ Prodi: [S1 Teknik Informatika ▼] │ Status: [Belum Finalisasi ▼]    │
├──────┬──────────┬──────────────────────────┬──────────────────────┬─────────┬───────────┬──────────────┤
│ NO   │ KODE     │ MATA KULIAH              │ DOSEN PENGAMPU UTAMA │ PESERTA │ STATUS    │ AKSI         │
├──────┼──────────┼──────────────────────────┼──────────────────────┼─────────┼───────────┼──────────────┤
│ 01   │ TI101-A  │ Algoritma & Pemrog. I    │ Dr. Aris Munandar    │ 40 Mhs  │ 🟢 FINAL  │ [Buka Kunci] │
│ 02   │ TI202-B  │ Basis Data Terdistribusi │ Hendra W., M.Eng.    │ 38 Mhs  │ 🟡 DRAFT  │ [Kirim Pesan]│
│ 03   │ TI304-A  │ Jaringan Komputer Lanjut │ Budi Santoso, M.T.   │ 35 Mhs  │ 🔴 KOSONG │ [Kirim Surat]│
│ 04   │ TI401-A  │ Rekayasa Perangkat Lunak │ Dr. Siti Nurhaliza   │ 32 Mhs  │ 🔓 TERBUKA│ [Pantau Revis│
├──────┴──────────┴──────────────────────────┴──────────────────────┴─────────┴───────────┴──────────────┤
│ ⚠️ 8 Kelas terancam melewati batas akhir penilaian! Dosen pengampu telah dikirimi notifikasi.          │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Wireframe Modal Buka Kunci Nilai (Unlock Grade Request)
```
┌────────────────────────────────────────────────────────────────┐
│ 🔓 OTORISASI BUKA KUNCI NILAI KELAS (UNLOCK GRADE)     [ X ]   │
├────────────────────────────────────────────────────────────────┤
│ Kelas Kuliah      : [TI101-A] Algoritma & Pemrograman I        │
│ Dosen Pengampu    : Dr. Aris Munandar (NIDN: 0412088501)       │
│ Waktu Finalisasi  : 20 Januari 2026, 14:22 WIB                 │
├────────────────────────────────────────────────────────────────┤
│ DOKUMEN REVISI NILAI RESMI:                                    │
│ Nomor Berita Acara*: [ BA-REV-NILAI/FTI/2026/012             ] │
│ Alasan Pembukaan  *: (o) Kesalahan Koreksi Nilai UAS Mahasiswa │
│                      ( ) Tugas Susulan dengan Izin Medis Sah   │
│                      ( ) Koreksi Rekapitulasi Presensi         │
│ Mahasiswa Terdampak: [ 2 Mahasiswa (NPM: 2410010012, 2410010045)│
│                                                                │
│ PENGATURAN DURASI BUKA KUNCI:                                  │
│ Jendela Waktu      : [ 48 Jam (Berakhir: 30 Jan 2026 12:00) ▼ ]│
│ [X] Kunci kembali otomatis saat batas waktu jendela berakhir   │
├────────────────────────────────────────────────────────────────┤
│ [ Batalkan ]                             [ Setujui & Buka Kunci│
└────────────────────────────────────────────────────────────────┘
```

---

## 3. Rincian Fitur & Aturan Bisnis

### 3.1 Skala Konversi Standar Nilai Huruf & Bobot Mutu
Sistem menggunakan standar penilaian baku 7 tingkat (Skala 4.00) sesuai pedoman Kementerian:

| Rentang Nilai Angka (0–100) | Nilai Huruf | Bobot Angka (Bobot Mutu) | Kategori Predikat |
| :---: | :---: | :---: | :--- |
| **85.00 – 100.00** | **A** | **4.00** | Sangat Baik / Istimewa |
| **80.00 – 84.99** | **AB** | **3.50** | Antara Sangat Baik & Baik |
| **75.00 – 79.99** | **B** | **3.00** | Baik |
| **70.00 – 74.99** | **BC** | **2.50** | Cukup Baik |
| **65.00 – 69.99** | **C** | **2.00** | Cukup (Batas Minimal Lulus MK Wajib) |
| **50.00 – 64.99** | **D** | **1.00** | Kurang (Hanya dapat diakui untuk MK Pilihan tertentu) |
| **0.00 – 49.99** | **E** | **0.00** | Tidak Lulus (Wajib Mengulang) |

### 3.2 Rumus Perhitungan Nilai Akhir (NA)
Nilai Akhir dihitung dari gabungan komponen evaluasi dengan total bobot wajib 100%:
$$\text{NA} = (w_{\text{tugas}} \times \text{Tugas}) + (w_{\text{kuis}} \times \text{Kuis}) + (w_{\text{uts}} \times \text{UTS}) + (w_{\text{uas}} \times \text{UAS}) + (w_{\text{presensi}} \times \text{Presensi})$$
Contoh pembobotan umum: Tugas (20%), UTS (30%), UAS (40%), Presensi (10%).

### 3.3 Formula Indeks Prestasi Semester (IPS) & Kumulatif (IPK)
- **Indeks Prestasi Semester (IPS)**:
  $$\text{IPS} = \frac{\sum_{i=1}^{n} (\text{SKS}_i \times \text{BobotMutu}_i)}{\sum_{i=1}^{n} \text{SKS}_i}$$
  Di mana $n$ adalah jumlah mata kuliah yang ditempuh pada semester tersebut.
- **Indeks Prestasi Kumulatif (IPK)**:
  $$\text{IPK} = \frac{\sum_{j=1}^{m} (\text{SKS}_j \times \text{BobotMutu Terbaik}_j)}{\sum_{j=1}^{m} \text{SKS}_j}$$
  - **Kebijakan Mata Kuliah Mengulang (*Retake Policy*)**: Jika mahasiswa menempuh mata kuliah yang sama lebih dari satu kali, sistem secara otomatis memilih **nilai tertinggi** (*Best Grade Policy*) atau nilai terkini untuk perhitungan IPK kumulatif.

### 3.4 Kebijakan Buka Kunci Nilai (Unlock Grade)
1. Setelah Dosen Utama mengesahkan nilai (`sudah_final = true`), form nilai menjadi *read-only*. Dosen tidak dapat lagi menyunting data.
2. Jika ditemukan kekeliruan administrasi, Dosen wajib mengunggah Berita Acara Perbaikan Nilai kepada Admin / Dekanat.
3. Admin mengaktifkan status unlock (`sudah_final = false`) dengan menetapkan batas waktu maksimal 48 jam.
4. Cron job otomatis mengunci kembali nilai jika batas waktu terlewati tanpa ada aksi finalisasi ulang dari dosen.

---

## 4. Logika Bisnis & Algoritma Penunjang

### 4.1 Algoritma Konversi Nilai Angka ke Nilai Huruf & Bobot (Dart)
```dart
class GradeConverter {
  static GradeResult convert(double score) {
    assert(score >= 0.0 && score <= 100.0, 'Skor nilai harus berada dalam rentang 0 - 100');

    if (score >= 85.0) return const GradeResult(huruf: 'A', bobot: 4.00, predikat: 'Sangat Baik');
    if (score >= 80.0) return const GradeResult(huruf: 'AB', bobot: 3.50, predikat: 'Antara Sangat Baik dan Baik');
    if (score >= 75.0) return const GradeResult(huruf: 'B', bobot: 3.00, predikat: 'Baik');
    if (score >= 70.0) return const GradeResult(huruf: 'BC', bobot: 2.50, predikat: 'Cukup Baik');
    if (score >= 65.0) return const GradeResult(huruf: 'C', bobot: 2.00, predikat: 'Cukup');
    if (score >= 50.0) return const GradeResult(huruf: 'D', bobot: 1.00, predikat: 'Kurang');
    return const GradeResult(huruf: 'E', bobot: 0.00, predikat: 'Tidak Lulus');
  }
}
```

### 4.2 Prosedur Buka Kunci Nilai Atomik
```sql
CREATE OR REPLACE FUNCTION public.fn_admin_unlock_class_grades(
    p_class_id UUID,
    p_nomor_berita_acara VARCHAR(100),
    p_alasan TEXT,
    p_durasi_jam INTEGER,
    p_actor_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_class_code TEXT;
    v_course_name TEXT;
    v_expiry_time TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Validasi wewenang Admin
    IF NOT EXISTS (
        SELECT 1 FROM public.user_role ur
        JOIN public.role r ON ur.id_role = r.id
        WHERE ur.id_user = p_actor_id AND r.nama = 'ADMIN'
    ) THEN
        RAISE EXCEPTION 'Akses Ditolak: Hanya Administrator yang berwenang membuka kunci nilai.';
    END IF;

    -- Hitung masa kedaluwarsa buka kunci
    v_expiry_time := NOW() + (p_durasi_jam || ' hours')::INTERVAL;

    -- Update status nilai pada seluruh record nilai kelas target
    UPDATE public.nilai
    SET sudah_final = false,
        kunci_terbuka_hingga = v_expiry_time,
        diperbarui_pada = NOW()
    WHERE id_kelas = p_class_id;

    -- Ambil metadata kelas untuk audit log
    SELECT k.kode, mk.nama INTO v_class_code, v_course_name
    FROM public.kelas k
    JOIN public.mata_kuliah mk ON k.id_mata_kuliah = mk.id
    WHERE k.id = p_class_id;

    -- Catat log aktivitas
    INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
    VALUES (
        p_actor_id,
        'ADMIN_BUKA_KUNCI_NILAI',
        'nilai',
        p_class_id,
        jsonb_build_object(
            'class_code', v_class_code,
            'course_name', v_course_name,
            'nomor_berita_acara', p_nomor_berita_acara,
            'alasan', p_alasan,
            'unlocked_until', v_expiry_time
        )
    );
END;
$$;
```

---

## 5. Skema Data & Kueri Database Terkait

### 5.1 Skema Tabel `public.nilai`
```sql
CREATE TABLE IF NOT EXISTS public.nilai (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mahasiswa VARCHAR(10) NOT NULL REFERENCES public.mahasiswa(npm) ON DELETE RESTRICT,
    id_kelas UUID NOT NULL REFERENCES public.kelas(id) ON DELETE RESTRICT,
    nilai_tugas NUMERIC(5,2) CHECK (nilai_tugas >= 0 AND nilai_tugas <= 100),
    nilai_uts NUMERIC(5,2) CHECK (nilai_uts >= 0 AND nilai_uts <= 100),
    nilai_uas NUMERIC(5,2) CHECK (nilai_uas >= 0 AND nilai_uas <= 100),
    nilai_akhir NUMERIC(5,2) CHECK (nilai_akhir >= 0 AND nilai_akhir <= 100),
    huruf_nilai VARCHAR(5) CHECK (huruf_nilai IN ('A', 'AB', 'B', 'BC', 'C', 'D', 'E')),
    bobot_nilai NUMERIC(3,2) CHECK (bobot_nilai >= 0.00 AND bobot_nilai <= 4.00),
    sudah_final BOOLEAN NOT NULL DEFAULT false,
    kunci_terbuka_hingga TIMESTAMP WITH TIME ZONE,
    dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    diperbarui_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_nilai_mhs_kelas UNIQUE (id_mahasiswa, id_kelas)
);

CREATE INDEX IF NOT EXISTS idx_nilai_mahasiswa ON public.nilai(id_mahasiswa);
CREATE INDEX IF NOT EXISTS idx_nilai_kelas ON public.nilai(id_kelas);
```

### 5.2 Database View: Monitoring Rekap Nilai per Kelas
```sql
CREATE OR REPLACE VIEW public.v_monitoring_nilai_kelas AS
SELECT 
    k.id AS id_kelas,
    k.kode AS kode_kelas,
    mk.kode AS kode_mk,
    mk.nama AS nama_mk,
    mk.sks,
    d.nama_lengkap AS nama_dosen_utama,
    d.nidn AS nidn_dosen_utama,
    COUNT(n.id) AS total_peserta_terdaftar,
    COUNT(CASE WHEN n.nilai_akhir IS NOT NULL THEN 1 END) AS jumlah_terisi,
    BOOL_AND(n.sudah_final) AS is_all_finalized,
    MAX(n.diperbarui_pada) AS update_terakhir
FROM public.kelas k
JOIN public.mata_kuliah mk ON k.id_mata_kuliah = mk.id
LEFT JOIN public.kelas_dosen kd ON k.id = kd.id_kelas AND kd.pengampu_utama = true
LEFT JOIN public.dosen d ON kd.id_dosen = d.nidn
LEFT JOIN public.nilai n ON k.id = n.id_kelas
GROUP BY k.id, k.kode, mk.kode, mk.nama, mk.sks, d.nama_lengkap, d.nidn;
```

---

## 6. Struktur Log Aktivitas & Payload Metadata JSON

```json
{
  "event_timestamp": "2026-09-28T12:15:00+08:00",
  "actor_id": "c1f8a840-7e32-4759-9943-8f0a0d4c9801",
  "actor_name": "Administrator Pusat",
  "aksi": "ADMIN_BUKA_KUNCI_NILAI",
  "entitas": "nilai",
  "id_entitas": "3f12a840-9921-4b12-9901-8f0a0d4c9888",
  "metadata": {
    "class_code": "TI101-A",
    "course_name": "Algoritma & Pemrograman I",
    "nomor_berita_acara": "BA-REV-NILAI/FTI/2026/012",
    "alasan": "Koreksi Nilai UAS Mahasiswa atas nama Aditya Pratama",
    "unlocked_duration_hours": 48,
    "unlocked_until": "2026-09-30T12:15:00+08:00"
  }
}
```

---

## 7. Penanganan Kasus Khusus (Edge Cases) & Validasi Sistem

| Skenario Kasus Khusus | Risiko Masalah | Solusi Penanganan Sistem |
| :--- | :--- | :--- |
| **Dosen belum finalisasi nilai saat deadline berakhir** | Mahasiswa tidak dapat melihat KHS dan terhambat registrasi semester depan. | Admin dapat mengirim surat teguran formal atau mengambil alih wewenang finalisasi massal (*Administrative Force-Finalize*) atas persetujuan Senat Akademik. |
| **Mahasiswa mengulang mata kuliah yang sama** | IPK kumulatif terhitung ganda dan salah beban total SKS. | Kueri kalkulasi IPK menggunakan klausul `DISTINCT ON (mk.id)` yang diurutkan berdasarkan `bobot_nilai DESC` untuk hanya menyertakan nilai tertinggi. |
| **Masa unlock terlewat tanpa finalisasi ulang dosen** | Nilai menggantung dalam status draft tak terkunci. | Scheduled task otomatis menjalankan `UPDATE nilai SET sudah_final = true WHERE kunci_terbuka_hingga < NOW()`. |
| **Dosen memberikan nilai > 100 atau < 0** | Kesalahan input skor merusak rumus IPK. | Database check constraints `CHECK (nilai >= 0 AND nilai <= 100)` menolak input secara keras di level SQL. |
