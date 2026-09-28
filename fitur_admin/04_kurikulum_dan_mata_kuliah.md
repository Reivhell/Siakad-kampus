# 04 — Kurikulum & Manajemen Mata Kuliah

> Modul pengelolaan bank mata kuliah institusi, manajemen versi kurikulum per program studi, pemetaan matriks semester 1 s.d. 8, serta mesin validasi prasyarat mata kuliah (*course prerequisite engine*).

---

## 1. Tujuan & Ruang Lingkup Fitur

Kurikulum adalah pedoman akademik institusional yang menentukan struktur mata kuliah yang wajib ditempuh mahasiswa untuk mencapai profil kompetensi lulusan. Modul ini menyediakan sarana perancangan kurikulum adaptif (termasuk kurikulum Merdeka Belajar / MBKM), pencegahan pelanggaran prasyarat pengambilan mata kuliah, serta menjaga akuntabilitas rekod kurikulum lintas angkatan.

### Ruang Lingkup Modul:
1. **Bank Mata Kuliah Global (`mata_kuliah`)**: Katalog sentral mata kuliah di seluruh program studi, penentuan bobot SKS (teori, praktikum, lapangan), dan klasifikasi jenis.
2. **Edisi Kurikulum Program Studi (`kurikulum`)**: Pembuatan versi kurikulum per prodi (misal: Kurikulum 2020, Kurikulum 2024 MBKM), penetapan masa berlaku angkatan mahasiswa, serta penetapan batas minimum SKS kelulusan.
3. **Matriks Struktur Semester (`kurikulum_mata_kuliah`)**: Pemetaan mata kuliah ke semester rekomendasi (Semester 1 s.d. 8) dengan visualisasi beban SKS terdistribusi.
4. **Mesin Prasyarat Mata Kuliah (*Prerequisite Engine*)**: Konfigurasi syarat kelulusan mata kuliah terdahulu (*hard prerequisite*), syarat paralel (*co-requisite*), atau syarat minimal SKS kumulatif yang telah ditempuh sebelum dapat mengambil mata kuliah tertentu (misal: Seminar Proposal / Skripsi).

---

## 2. Desain Antarmuka Pengguna & Wireframe ASCII

### 2.1 Matriks Visual Kurikulum Semester 1 s.d. 8 (Desktop / Web ≥ 1024 px)
```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 📚 MANAJEMEN KURIKULUM & MATA KULIAH                                                                   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Prodi: [ S1 Teknik Informatika ▼ ]  Edisi: [ Kurikulum 2024 (MBKM) ● AKTIF ▼ ]  [+ Tambah MK ke Paket]│
│ Ringkasan: Total MK: 52 Mata Kuliah │ Total SKS Paket: 144 SKS (Wajib: 124 SKS | Pilihan: 20 SKS)     │
├───────────────────┬───────────────────┬───────────────────┬───────────────────┬────────────────────┤
│ SEMESTER 1 (20 SKS│ SEMESTER 2 (20 SKS│ SEMESTER 3 (19 SKS│ SEMESTER 4 (18 SKS│ ... SEMESTER 7-8   │
├───────────────────┼───────────────────┼───────────────────┼───────────────────┼────────────────────┤
│ [TI101] Algoritma │ [TI201] Struktur  │ [TI301] Basis Data│ [TI401] Rekayasa  │ [TI701] MBKM       │
│ & Pemrograman I   │ Data (3 SKS)      │ Lanjut (3 SKS)    │ Perangkat Lunak   │ Magang / Proyek    │
│ (3 SKS) [WAJIB]   │ Prasyarat: TI101  │ Prasyarat: TI202  │ (3 SKS) [WAJIB]   │ (20 SKS) [PILIHAN] │
│ ───────────────   │ ───────────────   │ ───────────────   │ ───────────────   │ ────────────────   │
│ [TI102] Matematika│ [TI202] Basis Data│ [TI302] Pemrog.   │ [TI402] Jaringan  │ [TI801] Skripsi /  │
│ Diskrit (3 SKS)   │ Dasar (3 SKS)     │ Berorientasi Objek│ Komputer (3 SKS)  │ Tugas Akhir        │
│ [WAJIB]           │ [WAJIB]           │ (3 SKS)           │ [WAJIB]           │ (6 SKS) [WAJIB]    │
│ ───────────────   │ ───────────────   │ ───────────────   │ ───────────────   │ Syarat: Min 120 SKS│
│ [TI103] Kalkulus I│ [TI203] Arsitektur│ [TI303] Pemrog.   │ [TI403] Grafika   │                    │
│ (3 SKS) [WAJIB]   │ Komputer (3 SKS)  │ Web (3 SKS)       │ Komputer (3 SKS)  │                    │
├───────────────────┴───────────────────┴───────────────────┴───────────────────┴────────────────────┤
│ Aksi: [⬇ Unduh Matriks Kurikulum PDF] | [⟳ Kloning ke Kurikulum Baru] | [⚙ Atur Aturan Prasyarat]     │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Wireframe Modal Konfigurasi Prasyarat Mata Kuliah
```
┌────────────────────────────────────────────────────────────────┐
│ ⚙️ PENGATURAN ATURAN PRASYARAT MATA KULIAH              [ X ]  │
├────────────────────────────────────────────────────────────────┤
│ Mata Kuliah Target : [TI801] Skripsi / Tugas Akhir (6 SKS)     │
│ Program Studi      : S1 Teknik Informatika (Kurikulum 2024)    │
├────────────────────────────────────────────────────────────────┤
│ 1. PRASYARAT SKS KUMULATIF MINIMAL                             │
│    Mahasiswa wajib telah menyelesaikan minimal: [ 120 ] SKS    │
│                                                                │
│ 2. PRASYARAT KELULUSAN MATA KULIAH (HARD PREREQUISITE)         │
│    Daftar Mata Kuliah yang Wajib Lulus Terlebih Dahulu:        │
│    • [TI601] Metodologi Penelitian    (Nilai Minimal: [ C ▼ ]) │
│    • [TI401] Rekayasa Perangkat Lunak (Nilai Minimal: [ C ▼ ]) │
│    [+ Tambah MK Prasyarat Lain]                                │
│                                                                │
│ 3. PRASYARAT PARALEL (CO-REQUISITE)                            │
│    Mata kuliah yang dapat diambil bersamaan pada semester sama:│
│    • [TI702] Seminar Proposal Skripsi                          │
│                                                                │
│ 4. TOLERANSI NILAI E & D                                       │
│    [X] Tidak boleh memiliki nilai E pada riwayat akademik      │
├────────────────────────────────────────────────────────────────┤
│ [ Batal ]                                    [ Simpan Aturan ] │
└────────────────────────────────────────────────────────────────┘
```

---

## 3. Rincian Fitur & Aturan Bisnis

### 3.1 Master Mata Kuliah (`mata_kuliah`)
- **Struktur Atribut Pokok**:
  - `id`: UUID Primary Key.
  - `kode`: Kode alfanumerik unik (contoh: `TI101`, `SI204`, `UNV001`). Format standar: 2–3 digit kode departemen + 3 digit angka tingkatan.
  - `nama`: Nama resmi mata kuliah (contoh: "Struktur Data & Algoritma"). Wajib & Unik.
  - `nama_en`: Nama mata kuliah dalam Bahasa Inggris untuk pencetakan transkrip bilingual resmi.
  - `sks`: Bobot total SKS (1 s.d. 6 SKS).
  - `sks_teori`: Bobot SKS tatap muka teori (1 SKS teori = 50 menit tatap muka + 60 menit tugas terstruktur + 60 menit belajar mandiri / minggu).
  - `sks_praktikum`: Bobot SKS laboratorium praktikum (1 SKS praktikum = 170 menit kegiatan lab / minggu).
  - `semester_default`: Semester rujukan dasar (1–8).
  - `jenis`: Enum (`WAJIB_NASIONAL`, `WAJIB_PRODI`, `PILIHAN`, `TUGAS_AKHIR`, `MBKM`).
  - `deskripsi`: Ringkasan silabus atau capaian pembelajaran mata kuliah (CPMK).
- **Aturan Integritas**:
  - `CHECK (sks = sks_teori + sks_praktikum)`: Menjamin konsistensi pembagian beban pembelajaran.
  - Mata kuliah yang telah digunakan dalam kelas aktif tidak boleh diubah kode atau bobot SKS-nya.

### 3.2 Versi Kurikulum Institusi (`kurikulum`)
- **Aturan Edisi Kurikulum**:
  - Setiap program studi dapat memiliki banyak kurikulum historis untuk melayani mahasiswa dari angkatan berbeda.
  - Namun, untuk penerimaan mahasiswa baru, hanya ada **tepat satu kurikulum aktif per program studi** (`aktif = true`).
  - Mahasiswa baru yang terdaftar pada tahun masuk tertentu otomatis dikaitkan ke kurikulum aktif prodi pada tahun tersebut.
- **Standar Beban SKS Lulus**:
  - Program Sarjana (S1): 144 – 146 SKS.
  - Program Diploma Tiga (D3): 108 – 112 SKS.
  - Program Magister (S2): 36 – 40 SKS.

### 3.3 Pemetaan Mata Kuliah Kurikulum (`kurikulum_mata_kuliah`)
- **Atribut Pivot**:
  - `id_kurikulum`: Relasi ke kurikulum induk.
  - `id_mata_kuliah`: Relasi ke mata kuliah master.
  - `semester_rekomendasi`: Angka 1 s.d. 8.
  - `sifat`: Enum status penawaran (`WAJIB` / `PILIHAN`).
- **Validasi Komposisi SKS per Semester**:
  - Total SKS rekomendasi pada Semester 1 dan Semester 2 tidak boleh melebihi 20 SKS per semester (kebijakan paket dasar mahasiswa baru).

---

## 4. Mesin Validasi Prasyarat Mata Kuliah (Prerequisite Engine)

Mesin ini dieksekusi secara otomatis saat mahasiswa memilih mata kuliah pada modul registrasi KRS atau saat Admin melakukan verifikasi KRS.

### 4.1 Jenis Hubungan Prasyarat
1. **Hard Prerequisite (Wajib Lulus Sebelumnya)**:
   - Mahasiswa harus sudah memiliki nilai pada mata kuliah prasyarat dengan batas huruf minimum yang ditetapkan (standar: minimal huruf `C` atau bobot angka `2.00`).
2. **Co-Requisite (Boleh Diambil Bersamaan)**:
   - Mata kuliah yang dapat diambil pada semester yang sama (contoh: Praktikum Basis Data harus diambil bersamaan dengan Teori Basis Data).
3. **Cumulative SKS Prerequisite**:
   - Mensyaratkan total SKS lulus kumulatif mahasiswa telah mencapai ambang batas (contoh: Kerja Praktik ≥ 80 SKS, Tugas Akhir / Skripsi ≥ 120 SKS).

### 4.2 Algoritma Evaluasi Kelayakan Prasyarat
```dart
class PrerequisiteEvaluator {
  final StudentAcademicRecord studentRecord;

  PrerequisiteEvaluator(this.studentRecord);

  PrerequisiteResult checkEligibility({
    required Course targetCourse,
    required List<CoursePrerequisiteRule> rules,
  }) {
    for (final rule in rules) {
      // 1. Validasi Batas Minimal SKS Kumulatif
      if (rule.minCumulativeCredits > 0) {
        if (studentRecord.totalEarnedCredits < rule.minCumulativeCredits) {
          return PrerequisiteResult.ineligible(
            'Beban SKS kumulatif Anda (${studentRecord.totalEarnedCredits} SKS) belum memenuhi syarat minimal ${rule.minCumulativeCredits} SKS untuk mengambil ${targetCourse.nama}.',
          );
        }
      }

      // 2. Validasi Kelulusan Mata Kuliah Prasyarat
      for (final prereqCourseId in rule.requiredCourseIds) {
        final grade = studentRecord.getBestGradeFor(prereqCourseId);
        if (grade == null) {
          return PrerequisiteResult.ineligible(
            'Anda belum pernah menempuh mata kuliah prasyarat: ${rule.getCourseName(prereqCourseId)}.',
          );
        }
        if (grade.bobot < rule.minGradePoint) {
          return PrerequisiteResult.ineligible(
            'Nilai Anda untuk ${rule.getCourseName(prereqCourseId)} (${grade.huruf}) belum memenuhi batas minimal ${rule.minGradeLetter}.',
          );
        }
      }
    }

    return PrerequisiteResult.eligible();
  }
}
```

---

## 5. Skema Data & Kueri Database Terkait

### 5.1 Skema Tabel Kurikulum & Mata Kuliah
```sql
-- 1. Tabel Master Mata Kuliah
CREATE TABLE IF NOT EXISTS public.mata_kuliah (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kode VARCHAR(20) NOT NULL UNIQUE,
    nama VARCHAR(150) NOT NULL,
    nama_en VARCHAR(150),
    sks INTEGER NOT NULL CHECK (sks > 0 AND sks <= 10),
    sks_teori INTEGER NOT NULL DEFAULT 0 CHECK (sks_teori >= 0),
    sks_praktikum INTEGER NOT NULL DEFAULT 0 CHECK (sks_praktikum >= 0),
    semester INTEGER NOT NULL CHECK (semester >= 1 AND semester <= 8),
    jenis VARCHAR(50) NOT NULL DEFAULT 'WAJIB_PRODI',
    deskripsi TEXT,
    dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    diperbarui_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT ck_sks_composition CHECK (sks = sks_teori + sks_praktikum)
);

-- 2. Tabel Master Kurikulum
CREATE TABLE IF NOT EXISTS public.kurikulum (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_program_studi UUID NOT NULL REFERENCES public.program_studi(id) ON DELETE RESTRICT,
    nama VARCHAR(100) NOT NULL, -- Misal: "Kurikulum 2024 - MBKM"
    tahun INTEGER NOT NULL CHECK (tahun >= 2000 AND tahun <= 2100),
    total_sks_lulus INTEGER NOT NULL DEFAULT 144 CHECK (total_sks_lulus >= 100),
    aktif BOOLEAN NOT NULL DEFAULT false,
    dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    diperbarui_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Tabel Pivot Kurikulum - Mata Kuliah
CREATE TABLE IF NOT EXISTS public.kurikulum_mata_kuliah (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_kurikulum UUID NOT NULL REFERENCES public.kurikulum(id) ON DELETE CASCADE,
    id_mata_kuliah UUID NOT NULL REFERENCES public.mata_kuliah(id) ON DELETE RESTRICT,
    semester_rekomendasi INTEGER NOT NULL CHECK (semester_rekomendasi >= 1 AND semester_rekomendasi <= 8),
    sifat VARCHAR(20) NOT NULL DEFAULT 'WAJIB' CHECK (sifat IN ('WAJIB', 'PILIHAN')),
    CONSTRAINT uq_kurikulum_mk UNIQUE (id_kurikulum, id_mata_kuliah)
);

-- 4. Tabel Aturan Prasyarat Mata Kuliah
CREATE TABLE IF NOT EXISTS public.prasyarat_mata_kuliah (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_kurikulum UUID NOT NULL REFERENCES public.kurikulum(id) ON DELETE CASCADE,
    id_mata_kuliah UUID NOT NULL REFERENCES public.mata_kuliah(id) ON DELETE CASCADE,
    id_mata_kuliah_syarat UUID REFERENCES public.mata_kuliah(id) ON DELETE RESTRICT,
    min_nilai_huruf VARCHAR(5) DEFAULT 'C',
    min_sks_kumulatif INTEGER DEFAULT 0 CHECK (min_sks_kumulatif >= 0),
    tipe_prasyarat VARCHAR(20) NOT NULL DEFAULT 'HARD_PREREQUISITE' 
        CHECK (tipe_prasyarat IN ('HARD_PREREQUISITE', 'CO_REQUISITE', 'CREDIT_THRESHOLD')),
    CONSTRAINT uq_prasyarat_mk UNIQUE (id_kurikulum, id_mata_kuliah, id_mata_kuliah_syarat)
);
```

### 5.2 Kueri Rekapitulasi SKS per Semester Kurikulum (View Database)
```sql
CREATE OR REPLACE VIEW public.v_rekap_kurikulum_semester AS
SELECT 
    k.id AS id_kurikulum,
    k.nama AS nama_kurikulum,
    ps.nama AS nama_prodi,
    kmk.semester_rekomendasi,
    COUNT(mk.id) AS jumlah_mk,
    SUM(mk.sks) AS total_sks_semester,
    SUM(CASE WHEN kmk.sifat = 'WAJIB' THEN mk.sks ELSE 0 END) AS sks_wajib,
    SUM(CASE WHEN kmk.sifat = 'PILIHAN' THEN mk.sks ELSE 0 END) AS sks_pilihan
FROM public.kurikulum k
JOIN public.program_studi ps ON k.id_program_studi = ps.id
JOIN public.kurikulum_mata_kuliah kmk ON k.id = kmk.id_kurikulum
JOIN public.mata_kuliah mk ON kmk.id_mata_kuliah = mk.id
GROUP BY k.id, k.nama, ps.nama, kmk.semester_rekomendasi
ORDER BY kmk.semester_rekomendasi ASC;
```

---

## 6. Struktur Log Aktivitas & Payload Metadata JSON

```json
{
  "event_timestamp": "2026-09-28T11:15:00+08:00",
  "actor_id": "c1f8a840-7e32-4759-9943-8f0a0d4c9801",
  "actor_name": "Administrator Pusat",
  "aksi": "ADMIN_UBAH_KURIKULUM_MATA_KULIAH",
  "entitas": "kurikulum_mata_kuliah",
  "id_entitas": "4a7bc10b-68dd-4372-b567-0e02b2c3d990",
  "metadata": {
    "kurikulum_name": "Kurikulum 2024 - MBKM",
    "prodi": "S1 Teknik Informatika",
    "course_code": "TI801",
    "course_name": "Skripsi / Tugas Akhir",
    "action": "UPDATE_PREREQUISITE",
    "previous_rules": {
      "min_sks_kumulatif": 110
    },
    "new_rules": {
      "min_sks_kumulatif": 120,
      "required_courses": ["TI601"]
    }
  }
}
```

---

## 7. Penanganan Kasus Khusus (Edge Cases) & Validasi Sistem

| Skenario Kasus Khusus | Potensi Anomali | Solusi Penanganan Sistem |
| :--- | :--- | :--- |
| **Prasyarat Melingkar (*Circular Prerequisite*)** | MK A mensyaratkan MK B, dan MK B mensyaratkan MK A (Deadlock KRS). | Algoritma *Cycle Detection* (graf berarah berbasis DFS) dijalankan sebelum aturan prasyarat baru disimpan ke database. |
| **MK dihapus saat masih terdaftar di kurikulum aktif** | Nilai dan KRS mahasiswa putus relasi. | Database Foreign Key menggunakan `ON DELETE RESTRICT`. Tombol hapus diblokir jika MK tertaut kurikulum atau kelas. |
| **Kloning kurikulum untuk edisi baru** | Admin harus menginput ulang puluhan mata kuliah dari nol. | Disediakan fitur *"Kloning Kurikulum"* yang secara otomatis menduplikasi seluruh relasi `kurikulum_mata_kuliah` dan aturan prasyarat ke edisi tahun baru. |
| **Perubahan bobot SKS di tengah berjalannya semester** | Perhitungan IPS/IPK mahasiswa menjadi berubah mendadak. | Bobot SKS di-lock begitu ada kelas yang dibuka menggunakan mata kuliah tersebut pada periode akademik berjalan. |
