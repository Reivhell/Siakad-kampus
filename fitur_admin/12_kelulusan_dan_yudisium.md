# 12 — Kelulusan, Yudisium, & Penomoran Ijazah Nasional

> Modul audit syarat kelulusan otomatis (*Automated Degree Audit Engine*), manajemen sidang yudisium, formula penentuan predikat kelulusan (*Cum Laude*), Penomoran Ijazah Nasional (PIN/NINA), dan penerbitan Surat Keterangan Pendamping Ijazah (SKPI).

---

## 1. Tujuan & Ruang Lingkup Fitur

Kelulusan adalah kulminasi dari seluruh perjalanan akademik mahasiswa. Kesalahan verifikasi kelulusan berisiko hukum tinggi terhadap legalitas ijazah institusi. Modul ini menyediakan mesin verifikasi kelayakan otomatis yang memeriksa pemenuhan kurikulum hingga bebas tanggungan kampus, mengotomatisasi penetapan predikat kelulusan, serta mengintegrasikan nomor ijazah nasional resmi dari Kementerian.

### Ruang Lingkup Modul:
1. **Mesin Audit Kelayakan Kelulusan (*Degree Audit Engine*)**:
   - Pengecekan ambang batas minimal SKS lulus (S1: 144 SKS, D3: 108 SKS).
   - Validasi ketiadaan nilai `E` dan pembatasan maksimal nilai `D` ($\le 6$ SKS, non-MK Wajib Nasional).
   - Validasi kelulusan seluruh mata kuliah berstatus `WAJIB` (minimal nilai `C`).
   - Verifikasi kliring bebas tanggungan (Perpustakaan, Keuangan UKT, dan Laboratorium).
2. **Manajemen Periode Sidang Yudisium (`yudisium`)**:
   - Pendaftaran gelombang yudisium per semester dan input Nomor SK Yudisium Dekan/Rektor.
   - Perubahan status mahasiswa secara massal dari `AKTIF` menjadi `LULUS` saat SK disahkan.
3. **Formula Otomatis Predikat Kelulusan**:
   - Standarisasi penentuan predikat: *Dengan Pujian (Cum Laude)*, *Sangat Memuaskan*, dan *Memuaskan*.
4. **Penerbitan Dokumen Akhir & Sertifikasi**:
   - Pencatatan Penomoran Ijazah Nasional (PIN/NINA) dan Nomor Seri Transkrip Final.
   - Generator Transkrip Akademik Final Resmi Dwibahasa (Bilingual ID/EN) berstempel kode QR.
   - Manajemen capaian SKPI (*Diploma Supplement*) sesuai standar Kerangka Kualifikasi Nasional Indonesia (KKNI).

---

## 2. Desain Antarmuka Pengguna & Wireframe ASCII

### 2.1 Tampilan Antrean Calon Yudisium & Hasil Degree Audit (Desktop / Web ≥ 1024 px)
```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 🎓 PUSAT KELULUSAN & YUDISIUM MAHASISWA                           [+ Buka Periode Yudisium] [⬇ Laporan] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Periode Yudisium: [ Periode Yudisium Genap 2025/2026 ● TAHAP VERIFIKASI ▼ ]  SK: [ SK-YUD/FTI/2026/08 ]│
│ Status Kelayakan: 42 Calon Terdaftar (🟢 38 Lolos Audit Otomatis | 🔴 4 Terkendala Syarat Akademik)   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 🔍 [Cari NPM / Nama Mahasiswa...] │ Prodi: [S1 Teknik Informatika ▼] │ Status: [Semua Calon ▼]        │
├──────┬────────────┬────────────────────────┬─────────┬────────┬───────┬────────────┬──────────┬────────┤
│ NO   │ NPM        │ NAMA MAHASISWA         │ SKS LLS │ IPK    │ SMT   │ AUDIT STATUS│ PREDIKAT │ AKSI   │
├──────┼────────────┼────────────────────────┼─────────┼────────┼───────┼────────────┼──────────┼────────┤
│ 01   │ 2210010001 │ Aditya Pratama         │ 144 SKS │ 3.88   │ 8 Smt │ 🟢 MEMENUHI│ CUMLAUDE │ [Audit]│
│ 02   │ 2210010014 │ Amanda Putri Lestari   │ 146 SKS │ 3.65   │ 8 Smt │ 🟢 MEMENUHI│ CUMLAUDE │ [Audit]│
│ 03   │ 2110010045 │ Bagas Wicaksono        │ 144 SKS │ 3.20   │ 10 Smt│ 🟢 MEMENUHI│ SGT MEMUAS [Audit]│
│ 04   │ 2110010089 │ Hendra Saputra         │ 140 SKS │ 2.85   │ 10 Smt│ 🔴 KURANG  │ -        │ [Rincian│
│      │            │                        │         │        │       │ 4 SKS MK Wajib        │ Syarat]│
├──────┴────────────┴────────────────────────┴─────────┴────────┴───────┴────────────┴──────────┴────────┤
│ [⚡ Sahkan Yudisium & Terbitkan SK] (Hanya calon berstatus 🟢 MEMENUHI yang akan diproses LULUS)       │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Wireframe Modal Laporan Rinci Audit Kelayakan (Degree Audit Modal)
```
┌────────────────────────────────────────────────────────────────┐
│ 📋 HASIL AUDIT KELAYAKAN KELULUSAN (DEGREE AUDIT)      [ X ]   │
├────────────────────────────────────────────────────────────────┤
│ Mahasiswa : [2210010001] Aditya Pratama (S1 Teknik Informatika)│
│ Angkatan  : 2022 | Masa Studi: 8 Semester (Tepat Waktu)        │
├────────────────────────────────────────────────────────────────┤
│ STATUS 7 PARAMETER KELAYAKAN KELULUSAN:                        │
│ [✓] 1. Beban SKS Lulus   : 144 / 144 SKS (Lengkap)             │
│ [✓] 2. Batas Minimal IPK : 3.88 (Syarat Minimal: >= 2.00)      │
│ [✓] 3. Bebas Nilai E     : 0 Mata Kuliah bernilai E (Lolos)    │
│ [✓] 4. Toleransi Nilai D : 0 SKS bernilai D (Maksimal: 6 SKS)  │
│ [✓] 5. MK Wajib & Skripsi: Lulus Lengkap (Nilai Skripsi: A)   │
│ [✓] 6. Bebas Perpustakaan: Surat Bebas Pustaka Terverifikasi   │
│ [✓] 7. Bebas Keuangan    : Pembayaran UKT Lunas (0 Tunggakan)  │
├────────────────────────────────────────────────────────────────┤
│ HASIL PENETAPAN PREDIKAT KELULUSAN OTOMATIS:                   │
│ Predikat Disarankan: 🏆 DENGAN PUJIAN (CUM LAUDE)              │
│ Alasan: IPK >= 3.51, Masa Studi <= 4 Tahun, Bebas Nilai Ulang. │
├────────────────────────────────────────────────────────────────┤
│ Nomor Ijazah Nasional (PIN): [ 132012026000145               ] │
│ [ Batalkan ]                           [ Tetapkan Lolos Audit ]│
└────────────────────────────────────────────────────────────────┘
```

---

## 3. Rincian Fitur & Aturan Bisnis

### 3.1 Parameter Baku Audit Kelulusan Sarjana (S1)
Mesin verifikasi memvalidasi 7 parameter mutlak:
1. **Total SKS Lulus**: Minimal **144 SKS** (mata kuliah bernilai A s.d. D).
2. **Ketiadaan Nilai E**: Mahasiswa tidak boleh memiliki nilai `E` yang belum diperbaiki pada seluruh riwayat studi.
3. **Ambang Batas Nilai D**:
   - Total mata kuliah bernilai `D` maksimal **6 SKS** (atau 2 mata kuliah).
   - Mata kuliah bernilai `D` **tidak boleh** merupakan Mata Kuliah Wajib Kurikulum Nasional: *Pendidikan Agama, Pancasila, Kewarganegaraan, dan Bahasa Indonesia*.
4. **Mata Kuliah Wajib & Tugas Akhir**:
   - Seluruh mata kuliah berjenis `WAJIB` dan `TUGAS_AKHIR` wajib memperoleh nilai minimal `C` (bobot 2.00).
5. **Indeks Prestasi Kumulatif**:
   - Standar institusi mewajibkan $\text{IPK} \ge 2.00$.
6. **Kliring Administrasi Kampus**:
   - Bebas tunggakan SPP/UKT dari Biro Keuangan.
   - Surat Bebas Pustaka (tidak ada tanggungan pinjaman buku).

### 3.2 Algoritma Penentuan Predikat Kelulusan Baku
Predikat kelulusan ditetapkan secara deterministik berdasarkan capaian IPK dan rekam jejak studi:

$$\text{Predikat} = \begin{cases} 
\textbf{Dengan Pujian (Cum Laude)}, & \text{jika } \text{IPK} \ge 3.51 \land \text{Masa Studi} \le 8 \text{ Smt} \land \text{Bebas MK Mengulang} \\
\textbf{Sangat Memuaskan}, & \text{jika } 3.01 \le \text{IPK} \le 3.50 \lor (\text{IPK} \ge 3.51 \land \text{Masa Studi} > 8 \text{ Smt}) \\
\textbf{Memuaskan}, & \text{jika } 2.76 \le \text{IPK} \le 3.00 \\
\textbf{Cukup}, & \text{jika } 2.00 \le \text{IPK} \le 2.75 
\end{cases}$$

### 3.3 Alur Pengesahan SK Yudisium Massal
1. Admin memeriksa daftar calon wisudawan yang telah dinyatakan lolos audit kelayakan.
2. Admin menginput Nomor Surat Keputusan (SK) Yudisium Dekan dan tanggal penetapan kelulusan resmi.
3. Sistem menjalankan stored procedure atomik yang:
   - Mengubah status mahasiswa terpilih dari `AKTIF` menjadi `LULUS` pada tabel `mahasiswa`.
   - Mengisi tanggal kelulusan dan nomor PIN ijazah.
   - Mengunci seluruh akun mahasiswa menjadi status *Read-Only* (Arsip Alumni).
   - Menghasilkan event log `ADMIN_PENGESAHAN_YUDISIUM`.

---

## 4. Logika Bisnis & Algoritma Penunjang

### 4.1 Mesin Degree Audit Kelulusan Mahasiswa (Dart)
```dart
class DegreeAuditEngine {
  static DegreeAuditResult evaluate({
    required List<StudentCourseGrade> grades,
    required int totalSemestersEnrolled,
    required bool hasLibraryClearance,
    required bool hasFinancialClearance,
  }) {
    // 1. Hitung Total SKS Lulus (A, AB, B, BC, C, D)
    final passingGrades = grades.where((g) => g.huruf != 'E').toList();
    final totalPassedCredits = passingGrades.fold<int>(0, (sum, g) => sum + g.sks);

    if (totalPassedCredits < 144) {
      return DegreeAuditResult.failed('Total SKS lulus ($totalPassedCredits SKS) kurang dari syarat minimal 144 SKS.');
    }

    // 2. Cek Ketiadaan Nilai E
    if (grades.any((g) => g.huruf == 'E')) {
      return DegreeAuditResult.failed('Masih terdapat nilai E pada riwayat studi yang belum diperbaiki.');
    }

    // 3. Cek Batas Toleransi Nilai D
    final dGrades = grades.where((g) => g.huruf == 'D').toList();
    final totalDCredits = dGrades.fold<int>(0, (sum, g) => sum + g.sks);
    if (totalDCredits > 6) {
      return DegreeAuditResult.failed('Total nilai D ($totalDCredits SKS) melampaui batas toleransi maksimal 6 SKS.');
    }

    // 4. Cek Bebas Tanggungan
    if (!hasLibraryClearance) return DegreeAuditResult.failed('Belum mendapatkan Surat Bebas Pinjaman Perpustakaan.');
    if (!hasFinancialClearance) return DegreeAuditResult.failed('Masih memiliki tunggakan administrasi keuangan kampus.');

    // 5. Kalkulasi Predikat Kelulusan
    final ipk = calculateIpk(grades);
    final hasRetakenCourses = grades.any((g) => g.isRetake);
    String honors = 'MEMUASKAN';

    if (ipk >= 3.51 && totalSemestersEnrolled <= 8 && !hasRetakenCourses) {
      honors = 'DENGAN PUJIAN (CUM LAUDE)';
    } else if (ipk >= 3.01) {
      honors = 'SANGAT MEMUASKAN';
    } else if (ipk >= 2.76) {
      honors = 'MEMUASKAN';
    } else {
      honors = 'CUKUP';
    }

    return DegreeAuditResult.passed(ipk: ipk, predicate: honors);
  }
}
```

### 4.2 Prosedur Pengesahan Yudisium Massal Atomik
```sql
CREATE OR REPLACE FUNCTION public.fn_admin_finalize_yudisium(
    p_yudisium_id UUID,
    p_nomor_sk VARCHAR(100),
    p_tanggal_lulus DATE,
    p_actor_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_processed_count INTEGER := 0;
    v_rec RECORD;
BEGIN
    -- Validasi wewenang Admin
    IF NOT EXISTS (
        SELECT 1 FROM public.user_role ur
        JOIN public.role r ON ur.id_role = r.id
        WHERE ur.id_user = p_actor_id AND r.nama = 'ADMIN'
    ) THEN
        RAISE EXCEPTION 'Akses Ditolak: Hanya Administrator yang berwenang mengesahkan Yudisium.';
    END IF;

    -- Update status tabel yudisium induk
    UPDATE public.yudisium
    SET nomor_sk = p_nomor_sk,
        tanggal_sk = p_tanggal_lulus,
        status = 'DISAHKAN',
        diperbarui_pada = NOW()
    WHERE id = p_yudisium_id;

    -- Loop mahasiswa yang lolos audit pada periode yudisium ini
    FOR v_rec IN (
        SELECT id_mahasiswa 
        FROM public.peserta_yudisium 
        WHERE id_yudisium = p_yudisium_id AND status_audit = 'MEMENUHI'
    )
    LOOP
        -- Ubah status mahasiswa menjadi LULUS
        UPDATE public.mahasiswa
        SET status = 'LULUS',
            diperbarui_pada = NOW()
        WHERE npm = v_rec.id_mahasiswa;

        v_processed_count := v_processed_count + 1;
    END LOOP;

    -- Catat log aktivitas
    INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
    VALUES (
        p_actor_id,
        'ADMIN_PENGESAHAN_YUDISIUM',
        'yudisium',
        p_yudisium_id,
        jsonb_build_object(
            'nomor_sk', p_nomor_sk,
            'tanggal_lulus', p_tanggal_lulus,
            'total_lulusan', v_processed_count
        )
    );

    RETURN v_processed_count;
END;
$$;
```

---

## 5. Skema Data & Kueri Database Terkait

### 5.1 Skema Tabel `public.yudisium` & `public.peserta_yudisium`
```sql
-- 1. Tabel Periode Gelombang Yudisium
CREATE TABLE IF NOT EXISTS public.yudisium (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_periode_akademik UUID NOT NULL REFERENCES public.periode_akademik(id) ON DELETE RESTRICT,
    nama_periode VARCHAR(100) NOT NULL, -- Contoh: "Yudisium Periode Genap 2025/2026 Gelombang I"
    nomor_sk VARCHAR(100),
    tanggal_sk DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'DIBUKA' CHECK (status IN ('DIBUKA', 'VERIFIKASI', 'DISAHKAN')),
    dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    diperbarui_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tabel Peserta Calon Lulusan Yudisium
CREATE TABLE IF NOT EXISTS public.peserta_yudisium (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_yudisium UUID NOT NULL REFERENCES public.yudisium(id) ON DELETE CASCADE,
    id_mahasiswa VARCHAR(10) NOT NULL REFERENCES public.mahasiswa(npm) ON DELETE RESTRICT,
    total_sks_lulus INTEGER NOT NULL,
    ipk_akhir NUMERIC(3,2) NOT NULL,
    predikat_kelulusan VARCHAR(50) NOT NULL, -- 'DENGAN PUJIAN', 'SANGAT MEMUASKAN', 'MEMUASKAN'
    nomor_ijazah_nasional VARCHAR(50),
    nomor_seri_transkrip VARCHAR(50),
    status_audit VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status_audit IN ('PENDING', 'MEMENUHI', 'DITOLAK')),
    catatan_audit TEXT,
    CONSTRAINT uq_yudisium_mhs UNIQUE (id_yudisium, id_mahasiswa)
);

CREATE INDEX IF NOT EXISTS idx_peserta_yudisium_mhs ON public.peserta_yudisium(id_mahasiswa);
```

---

## 6. Struktur Log Aktivitas & Payload Metadata JSON

```json
{
  "event_timestamp": "2026-09-28T13:00:00+08:00",
  "actor_id": "c1f8a840-7e32-4759-9943-8f0a0d4c9801",
  "actor_name": "Administrator Pusat",
  "aksi": "ADMIN_PENGESAHAN_YUDISIUM",
  "entitas": "yudisium",
  "id_entitas": "2c12a840-4421-4b12-9901-8f0a0d4c9777",
  "metadata": {
    "nama_periode": "Yudisium Periode Genap 2025/2026 Gelombang I",
    "nomor_sk": "SK-YUD/FTI/2026/08",
    "tanggal_lulus": "2026-08-30",
    "total_lulusan": 38,
    "rincian_predikat": {
      "cum_laude": 12,
      "sangat_memuaskan": 22,
      "memuaskan": 4
    }
  }
}
```

---

## 7. Penanganan Kasus Khusus (Edge Cases) & Validasi Sistem

| Skenario Kasus Khusus | Risiko Masalah | Solusi Penanganan Sistem |
| :--- | :--- | :--- |
| **Mahasiswa punya nilai D pada MK Agama** | Lolos audit padahal melanggar aturan nasional. | Mesin audit secara khusus mengecek kode MK berkategori `WAJIB_NASIONAL` dan menolak kelulusan jika nilainya $< \text{C}$. |
| **Penomoran Ijazah ganda (*duplicate PIN*)** | Ijazah cacat hukum dan ditolak Kementerian. | Database constraint unik `UNIQUE (nomor_ijazah_nasional)` dan format regex validasi PIN Kemendikbudristek. |
| **Koreksi nilai setelah mahasiswa disahkan Lulus** | Status kelulusan dan predikat menjadi tidak sinkron. | Seluruh form nilai bagi mahasiswa berstatus `LULUS` dikunci permanen (*immutable frozen records*). Pembatalan hanya dapat dilakukan melalui Sidang Pembatalan Yudisium resmi. |
| **Pencetakan transkrip ijazah palsu oleh oknum** | Pemalsuan dokumen akademik kampus. | Setiap transkrip final dicetak dengan stempel kode QR yang mengarah ke portal verifikasi publik resmi institusi yang menampilkan data otentik secara real-time. |
