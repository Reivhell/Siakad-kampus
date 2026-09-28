# 09 — Monitoring Presensi Perkuliahan & Ambang Batas Kehadiran

> Modul pengawasan pemenuhan standar 16 pertemuan perkuliahan, audit jurnal topik pembelajaran dosen, rekapitulasi kehadiran mahasiswa, serta penegakan ambang batas minimal kehadiran 75% sebagai syarat kepesertaan Ujian Akhir Semester (UAS).

---

## 1. Tujuan & Ruang Lingkup Fitur

Presensi perkuliahan mencerminkan kedisiplinan akademik dan kepatuhan terhadap standar mutu pembelajaran nasional (Permendikbudristek). Modul ini menyediakan instrumen pengawasan bagi Administrator untuk memantau kelas-kelas yang tertinggal materi, mendeteksi dosen yang jarang mengajar, serta menyaring secara otomatis mahasiswa yang tidak memenuhi ambang batas kehadiran minimum sebelum pelaksanaan UAS.

### Ruang Lingkup Modul:
1. **Monitoring Ketercapaian Pertemuan Dosen (Target 16 Sesi)**:
   - Pemantauan realisasi jumlah sesi perkuliahan per kelas (14 pertemuan tatap muka + 1 UTS + 1 UAS).
   - Audit jurnal perkuliahan: topik materi, tanggal realisasi, metode (luring/daring), dan catatan kelas.
   - Deteksi dini kelas tertinggal (*Behind-Schedule Alert*) untuk penjadwalan kuliah pengganti (*make-up class*).
2. **Rekapitulasi Kehadiran Mahasiswa**:
   - Pencatatan status per sesi: `HADIR`, `IZIN`, `SAKIT`, dan `ALPHA`.
   - Perhitungan persentase kehadiran kumulatif mahasiswa per mata kuliah.
3. **Mesin Penegakan Ambang Batas Kehadiran (< 75%)**:
   - Skrining otomatis mahasiswa dengan kehadiran $< 75\%$ menjelang minggu tenang ujian.
   - Penguncian otomatis (*blocklist*) cetak Kartu Ujian UAS bagi mahasiswa yang tidak memenuhi syarat.
4. **Fasilitas Dispensasi Khusus Admin**:
   - Pemberian dispensasi kehadiran resmi untuk mahasiswa utusan lomba/konferensi kampus atau rawat inap medis.
5. **Pencetakan Berita Acara Perkuliahan (BAP)**:
   - Pembuatan dokumen BAP dan Daftar Hadir Mahasiswa (DHM) resmi berformat PDF/Excel untuk arsip akreditasi program studi.

---

## 2. Desain Antarmuka Pengguna & Wireframe ASCII

### 2.1 Tampilan Pengawasan Presensi Kelas (Desktop / Web ≥ 1024 px)
```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 📋 MONITORING PRESENSI & JURNAL PERKULIAHAN                      [⬇ Unduh Rekap BAP]  [⚡ Kirim Reminder]│
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Semester: [ Ganjil 2025/2026 ● AKTIF ]   Minggu Berjalan: Minggu Ke-11 dari 16 Minggu Perkuliahan      │
│ Rata-rata Ketercapaian Institusi: 9.8 Pertemuan / Kelas (Status: 🟢 Sesuai Target Kalender Akademik)  │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 🔍 [Cari Mata Kuliah / Dosen...] │ Prodi: [S1 Teknik Informatika ▼] │ Status: [Kelas Tertinggal ▼]    │
├──────┬──────────┬──────────────────────────┬──────────────────────┬──────────┬───────────┬─────────────┤
│ NO   │ KODE     │ MATA KULIAH              │ DOSEN PENGAMPU       │ REALISASI│ PROGRES   │ SKRINING MHS│
├──────┼──────────┼──────────────────────────┼──────────────────────┼──────────┼───────────┼─────────────┤
│ 01   │ TI101-A  │ Algoritma & Pemrog. I    │ Dr. Aris Munandar    │ 11 / 16  │ [■■■■■■■□]│ 2 Mhs < 75% │
│ 02   │ TI202-B  │ Basis Data Lanjut        │ Hendra W., M.Eng.    │ 10 / 16  │ [■■■■■■□□]│ 0 Mhs < 75% │
│ 03   │ TI304-A  │ Jaringan Komputer Lanjut │ Budi Santoso, M.T.   │ 6 / 16   │ [■■■□□□□□]│ ⚠️ KELAS    │
│      │          │                          │                      │ ⚠️ TERTINGGAL!     │ TERTINGGAL  │
│ 04   │ TI401-A  │ Rekayasa Perangkat Lunak │ Dr. Siti Nurhaliza   │ 11 / 16  │ [■■■■■■■□]│ 1 Mhs < 75% │
├──────┴──────────┴──────────────────────────┴──────────────────────┴──────────┴───────────┴─────────────┤
│ 💡 Total Mahasiswa Terancam Gugur UAS di Semester Berjalan: 14 Mahasiswa (Dapat Diberi Dispensasi)     │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Wireframe Modal Dispensasi Kehadiran Mahasiswa
```
┌────────────────────────────────────────────────────────────────┐
│ 🛡️ FORMULIR DISPENSASI PRESENSI MAHASISWA              [ X ]   │
├────────────────────────────────────────────────────────────────┤
│ Mahasiswa Sasaran  : [2410010012] Dimas Surya Nugraha          │
│ Kelas Perkuliahan  : [TI101-A] Algoritma & Pemrograman I       │
│ Kondisi Saat Ini   : Hadir 7 dari 11 Sesi (Kehadiran: 63.6%)   │
│ Status Syarat UAS  : 🔴 TIDAK MEMENUHI SYARAT UAS (< 75%)      │
├────────────────────────────────────────────────────────────────┤
│ DOKUMEN & ALASAN DISPENSASI ADMIN:                             │
│ Jenis Dispensasi * : (o) Delegasi Lomba / Riset Resmi Kampus   │
│                      ( ) Rawat Inap Rumah Sakit (Surat Dokter) │
│                      ( ) Musibah Bencana Alam / Duka Cita      │
│ Nomor Surat Tugas *: [ ST-KEMAHASISWAAN/FTI/2026/044         ] │
│ Jumlah Sesi Dimaafkan: [ 2 ] Sesi Perkuliahan (Sesi 8 & Sesi 9)│
│ Proyeksi Kehadiran : 9 dari 11 Sesi -> 81.8% (🟢 BERHAK UAS)   │
├────────────────────────────────────────────────────────────────┤
│ [ Batalkan ]                             [ Sahkan Dispensasi ] │
└────────────────────────────────────────────────────────────────┘
```

---

## 3. Rincian Fitur & Aturan Bisnis

### 3.1 Standar Beban 16 Pertemuan Perkuliahan
- Peraturan institusi menetapkan bahwa setiap kelas berbobot SKS apapun wajib menyelenggarakan total **16 sesi perkuliahan** dalam satu semester aktif:
  - Sesi 1 s.d. 7: Tatap muka materi perkuliahan bagian pertama.
  - Sesi 8: Ujian Tengah Semester (UTS).
  - Sesi 9 s.d. 15: Tatap muka materi perkuliahan bagian kedua.
  - Sesi 16: Ujian Akhir Semester (UAS).
- **Indikator Keterlambatan Kelas**:
  - Jika minggu akademik berjalan telah mencapai Minggu ke-10, namun realisasi sesi perkuliahan $< 8$ kali, kelas otomatis diberi flag `TERTINGGAL`.
  - Sistem menyarankan dosen untuk mengajukan jadwal kuliah pengganti (*make-up class*) pada hari Sabtu atau slot kosong.

### 3.2 Rumus Perhitungan Persentase Kehadiran Mahasiswa
Persentase kehadiran mahasiswa pada suatu kelas dihitung berdasarkan formula baku:
$$\% \text{Kehadiran} = \frac{\text{Total Hadir} + (\text{Dispensasi Resmi})}{\text{Total Sesi Terlaksana}} \times 100\%$$

- Bobot Status Kehadiran:
  - `HADIR`: Terhitung 1.0 (hadir penuh).
  - `IZIN` (dengan surat): Terhitung 0.5 atau dimaafkan sesuai regulasi fakultas.
  - `SAKIT` (surat dokter): Terhitung 0.5 atau dimaafkan.
  - `ALPHA` (tanpa kabar): Terhitung 0.0 (gugur kehadiran).

### 3.3 Penegakan Ambang Batas 75% & Pemblokiran Kartu UAS
1. Pada H-7 sebelum Ujian Akhir Semester dimulai, sistem mengeksekusi mesin pra-pemeriksaan kelayakan ujian (*UAS Eligibility Checker*).
2. Mahasiswa yang memiliki persentase kehadiran kumulatif $< 75.00\%$ secara otomatis:
   - Diberi status `TIDAK_BERHAK_UAS` pada kelas terkait.
   - Modul cetak Kartu Ujian Mahasiswa memunculkan tanda watermark merah: *"KULIAH TI101-A TIDAK BERHAK UAS KARENA PRESENSI KURANG DARI 75%"*.
   - Nilai UAS mahasiswa tersebut otomatis dikunci pada angka 0 oleh sistem.
3. Hanya dispensasi resmi yang disetujui Admin/Dekanat yang dapat memulihkan hak kepesertaan ujian.

---

## 4. Logika Bisnis & Algoritma Penunjang

### 4.1 Algoritma Evaluasi Kelayakan Kepesertaan UAS (Dart)
```dart
class AttendanceEligibilityEvaluator {
  static const double minimumRequiredPercentage = 75.0;

  static EligibilityResult evaluate({
    required int totalSessionsHeld,
    required int attendedCount,
    required int excusedDispensationCount,
  }) {
    if (totalSessionsHeld == 0) {
      return const EligibilityResult(isEligible: true, percentage: 100.0);
    }

    final effectiveAttendance = attendedCount + excusedDispensationCount;
    final percentage = (effectiveAttendance / totalSessionsHeld) * 100.0;

    final isEligible = percentage >= minimumRequiredPercentage;
    return EligibilityResult(
      isEligible: isEligible,
      percentage: double.parse(percentage.toStringAsFixed(2)),
      reason: isEligible
          ? 'Memenuhi syarat minimal kehadiran UAS (>= 75%)'
          : 'Kehadiran hanya ${percentage.toStringAsFixed(1)}%, tidak berhak mengikuti UAS!',
    );
  }
}
```

### 4.2 Prosedur Dispensasi Kehadiran Mahasiswa
```sql
CREATE OR REPLACE FUNCTION public.fn_admin_grant_attendance_dispensation(
    p_student_npm VARCHAR(10),
    p_class_id UUID,
    p_nomor_surat_tugas VARCHAR(100),
    p_jumlah_sesi_dispensasi INTEGER,
    p_alasan TEXT,
    p_actor_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Validasi wewenang Admin
    IF NOT EXISTS (
        SELECT 1 FROM public.user_role ur
        JOIN public.role r ON ur.id_role = r.id
        WHERE ur.id_user = p_actor_id AND r.nama = 'ADMIN'
    ) THEN
        RAISE EXCEPTION 'Akses Ditolak: Hanya Administrator yang berwenang memberikan dispensasi presensi.';
    END IF;

    -- Catat dispensasi pada tabel krs_dispensasi
    INSERT INTO public.krs (id_mahasiswa, id_kelas, status)
    VALUES (p_student_npm, p_class_id, 'AKTIF')
    ON CONFLICT (id_mahasiswa, id_kelas) DO NOTHING;

    -- Catat jejak audit
    INSERT INTO public.log_aktivitas (id_user, aksi, entitas, id_entitas, metadata)
    VALUES (
        p_actor_id,
        'ADMIN_BERI_DISPENSASI_PRESENSI',
        'presensi',
        p_class_id,
        jsonb_build_object(
            'npm', p_student_npm,
            'nomor_surat_tugas', p_nomor_surat_tugas,
            'sesi_dimaafkan', p_jumlah_sesi_dispensasi,
            'alasan', p_alasan
        )
    );
END;
$$;
```

---

## 5. Skema Data & Kueri Database Terkait

### 5.1 Skema Tabel `public.presensi` & `public.detail_presensi`
```sql
-- 1. Header Pertemuan Presensi Kelas
CREATE TABLE IF NOT EXISTS public.presensi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_kelas UUID NOT NULL REFERENCES public.kelas(id) ON DELETE CASCADE,
    pertemuan_ke INTEGER NOT NULL CHECK (pertemuan_ke >= 1 AND pertemuan_ke <= 16),
    tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
    jam_mulai TIME NOT NULL,
    jam_selesai TIME NOT NULL,
    topik TEXT NOT NULL,
    metode VARCHAR(20) NOT NULL DEFAULT 'LURING' CHECK (metode IN ('LURING', 'DARING', 'HYBRID')),
    id_dosen_pengajar VARCHAR(20) NOT NULL REFERENCES public.dosen(nidn) ON DELETE RESTRICT,
    dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_kelas_pertemuan UNIQUE (id_kelas, pertemuan_ke)
);

-- 2. Detail Presensi Kehadiran Tiap Mahasiswa
CREATE TABLE IF NOT EXISTS public.detail_presensi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_presensi UUID NOT NULL REFERENCES public.presensi(id) ON DELETE CASCADE,
    id_mahasiswa VARCHAR(10) NOT NULL REFERENCES public.mahasiswa(npm) ON DELETE RESTRICT,
    status_kehadiran VARCHAR(10) NOT NULL DEFAULT 'HADIR' 
        CHECK (status_kehadiran IN ('HADIR', 'IZIN', 'SAKIT', 'ALPHA', 'DISPENSASI')),
    waktu_presensi TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    catatan TEXT,
    CONSTRAINT uq_presensi_mahasiswa UNIQUE (id_presensi, id_mahasiswa)
);

CREATE INDEX IF NOT EXISTS idx_detail_presensi_mhs ON public.detail_presensi(id_mahasiswa);
```

### 5.2 Database View: Skrining Mahasiswa Terancam Gugur UAS (< 75%)
```sql
CREATE OR REPLACE VIEW public.v_skrining_kehadiran_uas AS
WITH rekap_kelas AS (
    SELECT id_kelas, COUNT(id) AS total_sesi_terlaksana
    FROM public.presensi
    GROUP BY id_kelas
),
rekap_mhs AS (
    SELECT 
        p.id_kelas,
        dp.id_mahasiswa,
        COUNT(CASE WHEN dp.status_kehadiran IN ('HADIR', 'DISPENSASI') THEN 1 END) AS total_hadir
    FROM public.presensi p
    JOIN public.detail_presensi dp ON p.id = dp.id_presensi
    GROUP BY p.id_kelas, dp.id_mahasiswa
)
SELECT 
    k.id AS id_kelas,
    k.kode AS kode_kelas,
    mk.nama AS nama_mk,
    m.npm,
    m.nama_lengkap AS nama_mahasiswa,
    rk.total_sesi_terlaksana,
    COALESCE(rm.total_hadir, 0) AS total_hadir,
    ROUND((COALESCE(rm.total_hadir, 0)::NUMERIC / rk.total_sesi_terlaksana) * 100, 2) AS persentase_kehadiran,
    CASE 
        WHEN ROUND((COALESCE(rm.total_hadir, 0)::NUMERIC / rk.total_sesi_terlaksana) * 100, 2) >= 75.00 THEN true
        ELSE false 
    END AS berhak_mengikuti_uas
FROM public.kelas k
JOIN public.mata_kuliah mk ON k.id_mata_kuliah = mk.id
JOIN rekap_kelas rk ON k.id = rk.id_kelas
JOIN public.krs ON k.id = krs.id_kelas AND krs.status = 'AKTIF'
JOIN public.mahasiswa m ON krs.id_mahasiswa = m.npm
LEFT JOIN rekap_mhs rm ON k.id = rm.id_kelas AND m.npm = rm.id_mahasiswa
WHERE rk.total_sesi_terlaksana >= 10; -- Skrining aktif setelah minimal 10 pertemuan
```

---

## 6. Struktur Log Aktivitas & Payload Metadata JSON

```json
{
  "event_timestamp": "2026-09-28T12:30:00+08:00",
  "actor_id": "c1f8a840-7e32-4759-9943-8f0a0d4c9801",
  "actor_name": "Administrator Pusat",
  "aksi": "ADMIN_BERI_DISPENSASI_PRESENSI",
  "entitas": "presensi",
  "id_entitas": "5a12a840-7721-4b12-9901-8f0a0d4c9444",
  "metadata": {
    "npm": "2410010012",
    "student_name": "Dimas Surya Nugraha",
    "class_code": "TI101-A",
    "nomor_surat_tugas": "ST-KEMAHASISWAAN/FTI/2026/044",
    "sesi_dimaafkan": 2,
    "previous_percentage": 63.6,
    "new_projected_percentage": 81.8,
    "alasan": "Delegasi resmi Kompetisi Pemrograman Nasional Gemastik"
  }
}
```

---

## 7. Penanganan Kasus Khusus (Edge Cases) & Validasi Sistem

| Skenario Kasus Khusus | Risiko Masalah | Solusi Penanganan Sistem |
| :--- | :--- | :--- |
| **Dosen menyelenggarakan kuliah pengganti di hari libur** | Mahasiswa berhalangan hadir dicatat Alpha secara tidak adil. | Kuliah pengganti wajib mendapatkan persetujuan Kaprodi/Admin dan absensi pada sesi pengganti tidak boleh menggugurkan kehadiran mahasiswa yang berhalangan hadir dengan alasan sah. |
| **Dosen lupa menginput presensi selama 3 minggu** | Mahasiswa tampak tidak hadir dalam sistem. | Sistem secara otomatis mengirim push notification dan surel reminder berkala ke dosen pengampu setiap kali jam jadwal perkuliahan berakhir. |
| **Presensi ganda pada pertemuan yang sama** | Statistik pertemuan melebihi batas 16 sesi. | Database constraint unik `UNIQUE (id_kelas, pertemuan_ke)` menjamin tidak ada duplikasi nomor sesi dalam satu kelas. |
| **Mahasiswa baru terdaftar via Force-Add di tengah semester** | Mahasiswa otomatis tercatat Alpha pada pertemuan sesi 1 s.d. 3. | Prosedur Force-Add Admin secara otomatis menandai status kehadiran sesi sebelum tanggal pendaftaran sebagai `DISPENSASI_REGISTRASI`. |
