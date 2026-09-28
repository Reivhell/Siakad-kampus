# 13 — Integrasi Pelaporan PDDIKTI & Ekspor Data Feeder

> Modul validasi kelengkapan data nasional, pra-pemeriksaan anomali (*Pre-Flight Health Check*), generator paket berkas ekspor standar Neo Feeder (CSV/Excel), serta audit konsistensi Aktivitas Kuliah Mahasiswa (AKM).

---

## 1. Tujuan & Ruang Lingkup Fitur

Pelaporan Pangkalan Data Pendidikan Tinggi (PDDIKTI) merupakan kewajiban konstitusional setiap perguruan tinggi di Indonesia. Kegagalan atau keterlambatan pelaporan berdampak pada sanksi administratif kementerian, pemblokiran beasiswa KIP-Kuliah, hingga penolakan penomoran ijazah nasional (PIN). Modul ini menyediakan sistem pra-validasi cerdas guna mendeteksi ketidaksesuaian data sedini mungkin sebelum diunggah ke aplikasi Neo Feeder Kementerian.

### Ruang Lingkup Modul:
1. **Mesin Pra-Pemeriksaan Kepatuhan Data (*Pre-Flight Data Health Check*)**:
   - Skrining kelengkapan data pokok mahasiswa (validasi NIK 16 digit, nama ibu kandung, tanggal lahir).
   - Validasi kepatuhan data penugasan dosen (NIDN terdaftar dan batas beban mengajar).
   - Pengecekan konsistensi transaksi perkuliahan (ketiadaan nilai gantung / `NULL`).
2. **Kalkulasi & Rekapitulasi AKM (Aktivitas Kuliah Mahasiswa)**:
   - Rekap status mahasiswa tiap semester: SKS semester, SKS total, IPS, IPK, dan status keaktifan (`A`=Aktif, `C`=Cuti, `N`=Nonaktif).
3. **Generator Paket Data Standar Neo Feeder**:
   - Pembuatan paket data siap impor terpisah maupun gabungan berformat CSV (berpemisah titik koma `;`) atau Excel:
     - *Paket 1: Mahasiswa Baru & Registrasi Pokok*
     - *Paket 2: Kurikulum & Katalog Mata Kuliah*
     - *Paket 3: Penawaran Kelas & Plotting Dosen*
     - *Paket 4: KRS / Peserta Kelas Kuliah*
     - *Paket 5: Nilai Perkuliahan Semester*
     - *Paket 6: Aktivitas Kuliah Mahasiswa (AKM)*
     - *Paket 7: Kelulusan & Mahasiswa Keluar (DO)*
4. **Pusat Resolusi Anomali Data (*Mismatch Resolution Center*)**:
   - Daftar interaktif data bermasalah yang dapat diperbaiki langsung (*one-click navigation*) oleh staf administrasi.

---

## 2. Desain Antarmuka Pengguna & Wireframe ASCII

### 2.1 Dashboard Kesiapan Pelaporan PDDIKTI (Desktop / Web ≥ 1024 px)
```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 🇮🇩 PUSAT PELAPORAN PDDIKTI & NEO FEEDER                          [⚡ Jalankan Uji Diagnostik] [⬇ Unduh] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Semester Pelaporan: [ Ganjil 2025/2026 ● AKTIF ▼ ]  Tenggat Kementerian: 31 Maret 2026 (Sisa: 42 Hari) │
│ Skor Kesiapan Data: [■■■■■■■■■■■■■■■■■■□□] 94.8% SIAP LAPOR (1.346 Valid | ⚠️ 74 Butuh Perbaikan)      │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ STATUS 7 PAKET DATA FEEDER:                                                                            │
│ 1. Biodata Mahasiswa Baru : 🟢 100% SIAP (350 Data)   5. Nilai Perkuliahan : 🟡 91.2% (12 Belum Final) │
│ 2. Kurikulum & Matakuliah : 🟢 100% SIAP (52 MK)      6. Aktivitas Kuliah  : 🟢 98.5% (AKM Lengkap)    │
│ 3. Kelas & Penjadwalan    : 🟢 100% SIAP (112 Kelas)  7. Kelulusan & DO    : 🟢 100% SIAP (38 Yudisium)│
│ 4. KRS & Peserta Kuliah   : 🟢 100% SIAP (4.210 Relasi)                                                │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 🚨 DAFTAR ANOMALI DATA YANG WAJIB DIPERBAIKI SEBELUM EKSPOR (74 Kasus):                                │
│ [!] 12 Mahasiswa Baru : NIK KTP tidak valid (< 16 Digit atau terdapat karakter alfabet) [Perbaiki ➔]   │
│ [!]  8 Mahasiswa      : Nama Ibu Kandung masih kosong / terisi tanda strip '-'          [Perbaiki ➔]   │
│ [!]  4 Dosen          : NIDN belum disinkronisasi dengan pangkalan data Dikti            [Perbaiki ➔]   │
│ [!] 50 Baris Nilai    : Nilai berstatus DRAFT belum difinalisasi dosen pengampu         [Perbaiki ➔]   │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ [⬇ Ekspor Paket CSV Terpadu (ZIP)]   [⬇ Unduh Template Excel Neo Feeder]   [⟳ Sinkronisasi Ulang]       │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Rincian Fitur & Standar Kepatuhan Data

### 3.1 Aturan Validasi Pra-Pelaporan (Pre-Flight Rules)
Mesin diagnostik mengeksekusi validasi deterministik terhadap regulasi baku PDDIKTI:

| Entitas Data | Aturan Validasi Kepatuhan | Dampak Jika Gagal / Invalid |
| :--- | :--- | :--- |
| **Mahasiswa.NIK** | Wajib tepat 16 digit angka (`CHECK (nik ~ '^[0-9]{16}$')`). | Ditolak oleh Neo Feeder (*Error Code: INVALID_NIK*). |
| **Mahasiswa.Ibu** | Nama ibu kandung tidak boleh bernilai NULL, kosong, atau karakter placeholder (`-`, `.`). | Ditolak oleh Neo Feeder (*Error Code: INVALID_MOTHER_NAME*). |
| **Dosen.NIDN** | Wajib berstatus aktif di forlap Dikti dan sesuai dengan homebase program studi. | Dosen tidak diakui dalam penugasan kelas semester. |
| **Kelas.Dosen** | Setiap kelas perkuliahan wajib memiliki minimal 1 Dosen Pengampu Utama. | Kelas dianggap fiktif dan ditolak sistem feeder. |
| **Nilai Perkuliahan**| Tidak boleh ada baris nilai yang bernilai NULL setelah masa semester berakhir. | AKM mahasiswa berstatus menggantung / IPS tidak terhitung. |
| **Aktivitas Kuliah** | Mahasiswa yang mengambil SKS $\ge 1$ wajib berstatus `A` (Aktif). | Pelanggaran sinkronisasi status keaktifan mahasiswa. |

### 3.2 Struktur Kolom Ekspor Paket Data Standar Neo Feeder (CSV)
Setiap paket diekspor dengan format encoding `UTF-8` dan pemisah titik-koma (`;`):
1. **Paket AKM (`akm.csv`)**:
   - Kolom: `id_registrasi_mahasiswa;npm;id_periode;ips;ipk;sks_semester;total_sks;status_mahasiswa`
2. **Paket Nilai (`nilai_kuliah.csv`)**:
   - Kolom: `npm;kode_kelas;kode_mk;nilai_angka;nilai_huruf;bobot_indeks`
3. **Paket Penugasan Dosen (`dosen_ajar.csv`)**:
   - Kolom: `nidn;kode_kelas;kode_mk;sks_substansi;rencana_pertemuan;realisasi_pertemuan`

---

## 4. Logika Bisnis & Algoritma Penunjang

### 4.1 Mesin Pre-Flight Health Check Diagnostik (Dart)
```dart
class FeederPreFlightValidator {
  static Future<DiagnosticReport> runDiagnostic(DatabaseConnection db) async {
    final report = DiagnosticReport();

    // 1. Periksa Integritas NIK Mahasiswa
    final invalidNikStudents = await db.query(
      "SELECT npm, nama_lengkap, nik FROM mahasiswa WHERE nik IS NULL OR LENGTH(nik) != 16 OR nik !~ '^[0-9]{16}$'",
    );
    for (final row in invalidNikStudents) {
      report.addIssue(
        category: 'BIODATA_MAHASISWA',
        identifier: row['npm'],
        name: row['nama_lengkap'],
        issue: 'NIK (${row['nik']}) tidak memenuhi format 16 digit angka.',
        resolutionAction: '/admin/civitas/mahasiswa/${row['npm']}',
      );
    }

    // 2. Periksa Kelas Tanpa Dosen
    final classesWithoutLecturer = await db.query(
      "SELECT k.id, k.kode, mk.nama FROM kelas k JOIN mata_kuliah mk ON k.id_mata_kuliah = mk.id "
      "LEFT JOIN kelas_dosen kd ON k.id = kd.id_kelas WHERE kd.id IS NULL",
    );
    for (final row in classesWithoutLecturer) {
      report.addIssue(
        category: 'PENUGASAN_DOSEN',
        identifier: row['kode'],
        name: row['nama'],
        issue: 'Kelas perkuliahan belum memiliki dosen pengampu terdaftar.',
        resolutionAction: '/admin/perkuliahan/kelas/${row['id']}',
      );
    }

    return report;
  }
}
```

---

## 5. Skema Data & Kueri Database Terkait

### 5.1 Database View: Agregasi Aktivitas Kuliah Mahasiswa (AKM)
Kueri penyiapan data AKM otomatis untuk seluruh mahasiswa aktif pada semester berjalan:
```sql
CREATE OR REPLACE VIEW public.v_pddikti_akm_semester AS
WITH sks_semester_ini AS (
    SELECT 
        krs.id_mahasiswa,
        SUM(mk.sks) AS sks_smt,
        ROUND(SUM(mk.sks * n.bobot_nilai)::NUMERIC / NULLIF(SUM(mk.sks), 0), 2) AS ips_smt
    FROM public.krs
    JOIN public.kelas k ON krs.id_kelas = k.id
    JOIN public.mata_kuliah mk ON k.id_mata_kuliah = mk.id
    LEFT JOIN public.nilai n ON krs.id_mahasiswa = n.id_mahasiswa AND krs.id_kelas = n.id_kelas
    WHERE k.id_periode_akademik = (SELECT id FROM public.periode_akademik WHERE aktif = true)
      AND krs.status = 'AKTIF'
    GROUP BY krs.id_mahasiswa
),
sks_kumulatif AS (
    SELECT 
        n.id_mahasiswa,
        SUM(mk.sks) AS total_sks_kumulatif,
        ROUND(AVG(n.bobot_nilai), 2) AS ipk_kumulatif
    FROM public.nilai n
    JOIN public.kelas k ON n.id_kelas = k.id
    JOIN public.mata_kuliah mk ON k.id_mata_kuliah = mk.id
    WHERE n.sudah_final = true
    GROUP BY n.id_mahasiswa
)
SELECT 
    m.npm,
    m.nama_lengkap,
    ps.kode AS kode_prodi,
    pa.nama AS nama_semester,
    m.status AS status_mahasiswa,
    COALESCE(ssi.sks_smt, 0) AS sks_semester,
    COALESCE(ssi.ips_smt, 0.00) AS ips,
    COALESCE(sk.total_sks_kumulatif, 0) AS total_sks,
    COALESCE(sk.ipk_kumulatif, 0.00) AS ipk
FROM public.mahasiswa m
JOIN public.program_studi ps ON m.id_program_studi = ps.id
CROSS JOIN (SELECT id, nama FROM public.periode_akademik WHERE aktif = true) pa
LEFT JOIN sks_semester_ini ssi ON m.npm = ssi.id_mahasiswa
LEFT JOIN sks_kumulatif sk ON m.npm = sk.id_mahasiswa;
```

---

## 6. Struktur Log Aktivitas & Payload Metadata JSON

```json
{
  "event_timestamp": "2026-09-28T13:15:00+08:00",
  "actor_id": "c1f8a840-7e32-4759-9943-8f0a0d4c9801",
  "actor_name": "Administrator Pusat",
  "aksi": "ADMIN_EKSPOR_DATA_PDDIKTI",
  "entitas": "pddikti_export",
  "id_entitas": "2025/2026-GANJIL",
  "metadata": {
    "academic_period": "Ganjil 2025/2026",
    "exported_packages": ["MAHASISWA", "KURIKULUM", "KELAS", "KRS", "NILAI", "AKM"],
    "total_records_exported": 6840,
    "unresolved_anomalies_count": 0,
    "format": "CSV_ZIP_NEO_FEEDER",
    "ip_address": "192.168.1.50"
  }
}
```

---

## 7. Penanganan Kasus Khusus (Edge Cases) & Validasi Sistem

| Skenario Kasus Khusus | Risiko Masalah | Solusi Penanganan Sistem |
| :--- | :--- | :--- |
| **Mahasiswa Cuti terhitung SKS $\ge 1$** | Status keaktifan bentrok di pangkalan kementerian. | Sistem otomatis memblokir mahasiswa berstatus `CUTI` dari seluruh relasi KRS aktif sebelum ekspor dijalankan. |
| **Nilai mata kuliah diinput huruf T (Tunda)** | Feeder menolak nilai huruf selain standar A s.d. E. | Konverter otomatis mengonversi huruf internal sebelum diekspor atau memunculkan peringatan wajib finalisasi. |
| **Beda format separator (koma `,` vs titik koma `;`)** | Kolom CSV bergeser dan gagal diparsing oleh aplikasi Neo Feeder. | Sistem secara ketat menggunakan separator titik koma `;` standar Indonesia dan encoding `UTF-8 without BOM`. |
| **Nama mahasiswa mengandung karakter kutip atau apostrof** | Syntax error saat import database Feeder. | Generator CSV membungkus seluruh field teks dalam tanda kutip ganda (`"..."`) dan meng-escape karakter petik (`""`). |
