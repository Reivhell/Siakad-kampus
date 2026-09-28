# 10 — Jejak Audit & Keamanan Sistem (Audit Trail & Security Explorer)

> Modul pemantauan jejak audit (*audit trails*) sistemik, inspektur forensik perubahan data berformat JSON diff, mekanisme kekebalan manipulasi (*tamper-proof append-only*), serta analisis anomali keamanan akses.

---

## 1. Tujuan & Ruang Lingkup Fitur

Dalam sistem informasi akademik yang mengelola data penting (nilai mahasiswa, ijazah, status kelulusan, dan hak akses pengguna), integritas data harus dapat dipertanggungjawabkan secara hukum (*non-repudiation*). Modul ini menyediakan rekaman kronologis permanen atas setiap aksi kritis, melacak siapa yang melakukan perubahan (*who*), kapan (*when*), dari perangkat apa (*where*), dan apa yang diubah (*what before & after*).

### Ruang Lingkup Modul:
1. **Penjelajah Log Aktivitas Terpusat (`log_aktivitas`)**:
   - Pencarian cerdas multi-kriteria: rentang tanggal, aktor pengguna, tipe aksi, nama entitas tabel, dan alamat IP.
   - Paginasi berkecepatan tinggi dengan indeks teroptimasi.
2. **Inspektur Metadata JSON & Visual Diff**:
   - Tampilan modal interaktif yang membandingkan keadaan data sebelum perubahan (*old state*) versus sesudah perubahan (*new state*) dengan penanda warna (merah/hijau).
3. **Pemberlakuan Kebijakan WORM (Write Once, Read Many)**:
   - Proteksi keras di level database engine: larangan mutlak atas operasi `UPDATE` dan `DELETE` pada tabel log aktivitas.
4. **Pendeteksi Anomali & Insiden Keamanan**:
   - Pemantauan upaya pembobolan kredensial (*brute-force login attack*).
   - Pelacakan akses administratif di luar jam kerja resmi kampus (misal: perubahan nilai pada jam 02:00 dini hari).
5. **Ekspor Berkas Bukti Kepatuhan Akreditasi**:
   - Generator laporan audit trail berkala berformat CSV dan PDF berpenanda hash SHA-256 untuk pemenuhan instrumen akreditasi BAN-PT/LAM.

---

## 2. Desain Antarmuka Pengguna & Wireframe ASCII

### 2.1 Penjelajah Log Aktivitas Sistem (Desktop / Web ≥ 1024 px)
```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 🛡️ PENJELAJAH JEJAK AUDIT & KEAMANAN SISTEM                      [⬇ Ekspor CSV Audit] [⬇ Laporan PDF]  │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 🔍 [Cari ID / Aktor / Keterangan...] │ Aksi: [Semua Aksi ▼] │ Entitas: [Nilai ▼] │ Rentang: [7 Hari ▼] │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ TABEL LOG AUDIT TRANSAKSI (Menampilkan 1 - 20 dari 48.291 Rekaman Log)                                │
├──────────────┬────────────────────────┬──────────────────────┬─────────────┬─────────────┬─────────────┤
│ TIMESTAMP    │ AKTOR PENGGUNA         │ AKSI TRANSAKSI       │ ENTITAS     │ ALAMAT IP   │ INSPEKSI    │
├──────────────┼────────────────────────┼──────────────────────┼─────────────┼─────────────┼─────────────┤
│ 28/09 10:45  │ Dr. Aris Munandar      │ DOSEN_FINALISASI_NIL │ kelas       │ 10.10.2.14  │ [👁 Inspect]│
│ 28/09 10:30  │ Administrator Pusat    │ ADMIN_FORCE_ADD_KRS  │ krs         │ 192.168.1.50│ [👁 Inspect]│
│ 28/09 09:15  │ Siti Nurhaliza (Mhs)   │ MAHASISWA_AJUKAN_KRS │ krs         │ 180.252.1.8 │ [👁 Inspect]│
│ 28/09 03:12  │ SYSTEM_SECURITY_DAEMON │ AUTH_BRUTE_FORCE_LOCK│ user        │ 45.12.89.201│ [⚠️ ANOMALI]│
│ 27/09 16:00  │ Administrator Pusat    │ ADMIN_BUKA_KUNCI_NIL │ nilai       │ 192.168.1.50│ [👁 Inspect]│
├──────────────┴────────────────────────┴──────────────────────┴─────────────┴─────────────┴─────────────┤
│ Halaman: [ < Sebelumnya ] 1  2  3  4 ... 2.415 [ Selanjutnya > ]           Status Basis Log: 🟢 VALID  │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Wireframe Modal Inspeksi JSON Diff (Sebelum vs Sesudah)
```
┌────────────────────────────────────────────────────────────────┐
│ 🔍 DETAIL INSPEKSI METADATA LOG AKTIVITAS              [ X ]   │
├────────────────────────────────────────────────────────────────┤
│ ID Log Event      : 8f12a840-7e32-4759-9943-8f0a0d4c9111       │
│ Waktu Kejadian    : 28 September 2026, 10:45:12 WIB            │
│ Aktor Pelaksana   : Dr. Aris Munandar (NIDN: 0412088501)       │
│ Jenis Aksi        : DOSEN_FINALISASI_NILAI                     │
│ Alamat IP & Agen  : 10.10.2.14 (Mozilla/5.0 - Windows NT 10.0) │
├────────────────────────────────────────────────────────────────┤
│ PERBANDINGAN PERUBAHAN DATA (STATE DIFF INSPECTOR):            │
│                                                                │
│  FIELD            │ NILAI SEBELUMNYA      │ NILAI SESUDAHNYA   │
│ ──────────────────┼───────────────────────┼─────────────────── │
│  sudah_final      │ [ false             ] │ [ true (FINAL)  ]  │
│  huruf_nilai      │ [ D (Skor: 58.00)   ] │ [ B (Skor: 78.50)] │
│  bobot_nilai      │ [ 1.00              ] │ [ 3.00           ] │
│  diperbarui_oleh  │ [ DRAFT_SAVED       ] │ [ DOSEN_COMMIT   ] │
├────────────────────────────────────────────────────────────────┤
│ DOKUMEN PENDUKUNG / BERITA ACARA:                              │
│ "Koreksi nilai ujian susulan resmi BA-REV/2026/012"            │
├────────────────────────────────────────────────────────────────┤
│ [ Tutup Inspeksi ]                         [ Unduh Bukti Log ] │
└────────────────────────────────────────────────────────────────┘
```

---

## 3. Taksonomi Aksi Audit Sistemik

Daftar kode aksi baku yang wajib dipertahankan konsistensinya di seluruh lapisan aplikasi:

| Kategori | Kode Aksi (`aksi`) | Deskripsi Kejadian Akademik |
| :--- | :--- | :--- |
| **Administratif** | `ADMIN_BUAT_PENGGUNA` | Administrator membuat akun pengguna baru. |
| | `ADMIN_UBAH_PERAN_PENGGUNA` | Administrator menambah/mencabut peran akun. |
| | `ADMIN_SWITCH_PERIODE` | Penggantian periode semester aktif kampus. |
| | `ADMIN_BUKA_KELAS` | Pembukaan rombongan belajar baru pada semester berjalan. |
| | `ADMIN_BUAT_JADWAL_KELAS` | Alokasi ruang kuliah dan jam jadwal baru. |
| | `ADMIN_FORCE_ADD_KRS` | Intervensi administratif memasukkan mahasiswa ke kelas penuh. |
| | `ADMIN_BUKA_KUNCI_NILAI` | Pembukaan kembali status finalisasi nilai kelas dosen. |
| | `ADMIN_MUTASI_STATUS_MHS` | Perubahan status mahasiswa (Aktif, Cuti, DO, Lulus). |
| **Dosen** | `DOSEN_INPUT_NILAI` | Dosen menginput atau menyunting draf komponen nilai. |
| | `DOSEN_FINALISASI_NILAI` | Dosen mengesahkan nilai akhir (mengunci form nilai). |
| | `DOSEN_CATAT_PRESENSI` | Dosen membuka sesi perkuliahan dan mencatat daftar hadir. |
| | `DOSEN_APPROVAL_KRS` | Dosen Wali menyetujui atau menolak rencana studi mahasiswa asuhan. |
| **Mahasiswa** | `MAHASISWA_AJUKAN_KRS` | Mahasiswa memilih mata kuliah dan mengunci formulir KRS. |
| | `MAHASISWA_BATALKAN_KRS` | Mahasiswa membatalkan mata kuliah pada masa perubahan KRS. |
| **Keamanan** | `AUTH_LOGIN_SUCCESS` | Pengguna berhasil masuk ke sistem. |
| | `AUTH_LOGIN_FAILED_LOCKOUT` | Akun terkunci sementara akibat salah password berulang. |
| | `SECURITY_UNAUTHORIZED_TRY` | Percobaan eksekusi kueri di luar wewenang peran RLS. |

---

## 4. Mekanisme Keamanan Anti-Manipulasi (Tamper-Proofing)

### 4.1 Kebijakan Database Append-Only WORM
Tabel `log_aktivitas` dirancang tanpa celah modifikasi. Trigger database secara eksplisit menolak perintah `UPDATE` atau `DELETE` bahkan jika dijalankan oleh pengguna superuser aplikasi:
```sql
CREATE OR REPLACE FUNCTION public.fn_prevent_audit_log_tampering()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Pelanggaran Keamanan: Rekaman jejak audit bersifat Append-Only dan dilarang diubah atau dihapus!';
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_audit_log ON public.log_aktivitas;
CREATE TRIGGER trg_protect_audit_log
BEFORE UPDATE OR DELETE ON public.log_aktivitas
FOR EACH ROW
EXECUTE FUNCTION public.fn_prevent_audit_log_tampering();
```

### 4.2 Penandatanganan Hash Rantai Integritas (Audit Hash Chaining)
Untuk menjamin bukti audit tidak dapat disisipkan atau diubah secara manual di level filesystem storage:
- Setiap baris log memiliki `hash_integritas` yang dihasilkan dari:
  $$\text{Hash}_n = \text{SHA-256}(\text{ID}_n + \text{Timestamp}_n + \text{Aksi}_n + \text{Metadata}_n + \text{Hash}_{n-1})$$
- Jika satu baris dihapus atau dimanipulasi, rantai hash akan terputus dan sistem memicu peringatan integritas (*tamper alarm*).

---

## 5. Skema Data & Kueri Database Terkait

### 5.1 Skema Tabel `public.log_aktivitas`
```sql
CREATE TABLE IF NOT EXISTS public.log_aktivitas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_user UUID REFERENCES public."user"(id) ON DELETE SET NULL,
    aksi VARCHAR(100) NOT NULL,
    entitas VARCHAR(50) NOT NULL,
    id_entitas TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    alamat_ip VARCHAR(50),
    user_agent TEXT,
    hash_sebelumnya TEXT,
    hash_integritas TEXT,
    dibuat_pada TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indeks Teroptimasi untuk Pencarian Multidimensi
CREATE INDEX IF NOT EXISTS idx_log_aktivitas_waktu ON public.log_aktivitas(dibuat_pada DESC);
CREATE INDEX IF NOT EXISTS idx_log_aktivitas_aksi ON public.log_aktivitas(aksi);
CREATE INDEX IF NOT EXISTS idx_log_aktivitas_entitas ON public.log_aktivitas(entitas, id_entitas);
CREATE INDEX IF NOT EXISTS idx_log_aktivitas_user ON public.log_aktivitas(id_user);
CREATE INDEX IF NOT EXISTS idx_log_aktivitas_metadata_gin ON public.log_aktivitas USING GIN (metadata);
```

### 5.2 Kebijakan Row Level Security (RLS) Audit Log
```sql
ALTER TABLE public.log_aktivitas ENABLE ROW LEVEL SECURITY;

-- Hanya Administrator yang berhak membaca jejak audit
CREATE POLICY "admin_read_audit_logs"
ON public.log_aktivitas
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.user_role ur
        JOIN public.role r ON ur.id_role = r.id
        WHERE ur.id_user = auth.uid() AND r.nama = 'ADMIN'
    )
);

-- Seluruh sistem/fungsi terotentikasi dapat menginjeksi log (Insert-Only)
CREATE POLICY "system_insert_audit_logs"
ON public.log_aktivitas
FOR INSERT
WITH CHECK (true);
```

---

## 6. Struktur Payload Metadata JSON Komprehensif

Contoh rekaman audit saat terjadi koreksi nilai akademik oleh Dosen:
```json
{
  "event_timestamp": "2026-09-28T10:45:12+08:00",
  "actor_id": "c1f8a840-7e32-4759-9943-8f0a0d4c9801",
  "actor_name": "Dr. Aris Munandar",
  "actor_role": "DOSEN",
  "aksi": "DOSEN_UBAH_NILAI",
  "entitas": "nilai",
  "id_entitas": "4f12a840-9921-4b12-9901-8f0a0d4c9123",
  "metadata": {
    "student_npm": "2410010012",
    "student_name": "Dimas Surya Nugraha",
    "course_code": "TI101",
    "course_name": "Algoritma & Pemrograman I",
    "state_before": {
      "nilai_uts": 60.00,
      "nilai_uas": 55.00,
      "nilai_akhir": 58.00,
      "huruf_nilai": "D",
      "bobot_nilai": 1.00
    },
    "state_after": {
      "nilai_uts": 60.00,
      "nilai_uas": 85.00,
      "nilai_akhir": 78.50,
      "huruf_nilai": "B",
      "bobot_nilai": 3.00
    },
    "reason": "Ujian Susulan yang disahkan Dekanat Nomor BA-REV/2026/012",
    "ip_address": "10.10.2.14",
    "user_agent": "Flutter-Desktop/Windows (x86_64)"
  }
}
```

---

## 7. Penanganan Kasus Khusus & Optimalisasi Performa Log

| Skenario Kasus Khusus | Risiko Teknis | Solusi Pencegahan Sistem |
| :--- | :--- | :--- |
| **Volume data log membengkak (> 10 juta baris)** | Kueri dashboard admin menjadi lambat. | Terapkan *PostgreSQL Table Partitioning* berbasis rentang bulan/tahun (`PARTITION BY RANGE (dibuat_pada)`) sehingga kueri hanya memindai partisi semester berjalan. |
| **Aksi sistem anonim (misal: bot brute force)** | `id_user` bernilai NULL. | Field `id_user` bersifat nullable (`ON DELETE SET NULL`), namun `alamat_ip` dan `user_agent` wajib tersimpan untuk pelacakan IP ban/firewall. |
| **Admin nakal mencoba truncate tabel log** | Menghapus rekam jejak kecurangan nilai. | Hak perintah `TRUNCATE` dan `DROP TABLE` dicabut dari peran database aplikasi (`REVOKE TRUNCATE ON public.log_aktivitas FROM PUBLIC`). |
| **Ekspor log ukuran masif (PDF ribuan lembar)** | Kehabisan memori server (*Out of Memory*). | Ekspor dijalankan via streaming *Cursor Pagination* atau menghasilkan arsip berformat kompresi CSV/ZIP di latar belakang (*background job*). |
