# 06 — Kelas Perkuliahan & Penjadwalan Bebas Bentrok

> Modul operasional inti pembukaan rombongan belajar (kelas), penugasan dosen pengampu (*team teaching*), alokasi slot ruang kuliah, serta mesin deteksi bentrok jadwal otomatis (*Conflict-Free Scheduling Engine*).

---

## 1. Tujuan & Ruang Lingkup Fitur

Penjadwalan perkuliahan merupakan salah satu tugas terberat Administrator Akademik setiap awal semester. Modul ini menyediakan sistem penawaran kelas terstruktur, penugasan dosen utama dan pendamping, serta mesin validasi matematis yang menjamin tidak adanya tumpang tindih penggunaan ruangan (*room clash*) maupun jadwal mengajar dosen (*lecturer clash*).

### Ruang Lingkup Modul:
1. **Manajemen Rombel / Kelas Perkuliahan (`kelas`)**:
   - Pembukaan kelas mata kuliah pada periode akademik aktif.
   - Penetapan kapasitas daya tampung dan monitoring keterisian mahasiswa secara real-time.
   - Generator kelas paralel otomatis (*Batch Parallel Class Generator*: A, B, C, dst.).
2. **Plotting Dosen Pengampu (`kelas_dosen`)**:
   - Penetapan dosen penanggung jawab utama (*lead lecturer*) dan dosen anggota (*co-lecturer / team teaching*).
   - Pengaturan proporsi tim ajar untuk penilaian dan presensi.
3. **Alokasi Slot Waktu & Tempat (`jadwal_kelas`)**:
   - Penetapan hari (1=Senin s.d. 7=Minggu) dan rentang jam kuliah (`jam_mulai` s.d. `jam_selesai`).
   - Pemilihan ruangan yang sesuai dari master `ruangan`.
4. **Mesin Deteksi Bentrok Jadwal (*Conflict Detection Engine*)**:
   - Validasi irisan waktu (*interval intersection*) secara instan sebelum jadwal disimpan ke basis data.
5. **Visualisasi Jadwal Mingguan (*Weekly Timetable Matrix*)**:
   - Kalender visual interaktif matriks Hari vs Jam untuk memantau slot ruang dan jadwal dosen.

---

## 2. Desain Antarmuka Pengguna & Wireframe ASCII

### 2.1 Matriks Kalender Jadwal Mingguan (Timetable View)
```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ 📅 KALENDER PERKULIAHAN BEBAS BENTROK                           [+ Buka Kelas Baru]  [⚡ Cek Bentrok]  │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Semester: [ Ganjil 2025/2026 ● AKTIF ▼ ]  Tinjauan: (o) Ruangan  ( ) Dosen  ( ) Program Studi          │
│ Filter: [ Ruang LAB-KOMP-1 (Kapasitas: 40 Kursi) ▼ ]   Hari: [ Semua Hari ▼ ]   [⬇ Cetak Jadwal PDF]   │
├─────────────┬──────────────────────────┬──────────────────────────┬────────────────────────────────────┤
│ JAM / HARI  │ SENIN                    │ SELASA                   │ RABU ...                           │
├─────────────┼──────────────────────────┼──────────────────────────┼────────────────────────────────────┤
│ 08:00-09:40 │ [TI101-A] Algoritma I    │ [TI202-A] Basis Data     │ [ KOSONG / TERSEDIA ]              │
│ (2 SKS)     │ Dosen: Dr. Aris M.       │ Dosen: Hendra W., M.Eng. │ (Klik untuk jadwalkan kelas)       │
│             │ Mahasiswa: 38/40         │ Mahasiswa: 40/40 (PENUH) │                                    │
├─────────────┼──────────────────────────┼──────────────────────────┼────────────────────────────────────┤
│ 10:00-12:30 │ [TI301-B] Jaringan Komp  │ ⚠️ TERDETEKSI BENTROK!   │ [TI402-A] Rekayasa Perangkat Lunak │
│ (3 SKS)     │ Dosen: Budi Santoso, M.T.│ [TI102-B] vs [SI201-A]   │ Dosen: Dr. Siti Nurhaliza          │
│             │ Mahasiswa: 35/40         │ (Perbaiki Alokasi Ruang) │ Mahasiswa: 30/40                   │
├─────────────┼──────────────────────────┼──────────────────────────┼────────────────────────────────────┤
│ 13:00-15:30 │ [ KOSONG / TERSEDIA ]    │ [TI405-A] Kecerdasan B.  │ [TI303-A] Pemrograman Web         │
│ (3 SKS)     │                          │ Dosen: Dr. Aris M.       │ Dosen: Budi Santoso, M.T.          │
└─────────────┴──────────────────────────┴──────────────────────────┴────────────────────────────────────┘
```

### 2.2 Wireframe Modal Alokasi Jadwal & Deteksi Bentrok Real-Time
```
┌────────────────────────────────────────────────────────────────┐
│ 🕒 ALOKASI JADWAL & RUANGAN KELAS                      [ X ]   │
├────────────────────────────────────────────────────────────────┤
│ Kelas Kuliah      : [TI101-A] Algoritma & Pemrograman I        │
│ Mata Kuliah       : Algoritma I (3 SKS: 2 Teori, 1 Praktikum)  │
│ Dosen Pengampu    : Dr. Aris Munandar (NIDN: 0412088501)       │
│ Kapasitas Kelas   : 40 Mahasiswa                               │
├────────────────────────────────────────────────────────────────┤
│ 1. PENGATURAN SLOT WAKTU                                       │
│    Hari Perkuliahan * : [ Selasa                             ▼]│
│    Jam Mulai *        : [ 08:00 ] WIB                          │
│    Jam Selesai *      : [ 10:30 ] WIB (Durasi: 150 Menit)      │
│                                                                │
│ 2. PEMILIHAN RUANG KULIAH                                      │
│    Gedung             : [ Gedung Laboratorium Terpadu       ▼ ]│
│    Ruangan *          : [ LAB-KOMP-1 (Kapasitas: 40 Kursi)  ▼ ]│
├────────────────────────────────────────────────────────────────┤
│ 🛡️ STATUS PEMERIKSAAN BENTROK (LIVE CONFLICT CHECKER):         │
│ 🟢 Ruangan LAB-KOMP-1 KOSONG pada hari Selasa 08:00 - 10:30 WIB│
│ 🟢 Dosen Dr. Aris Munandar TIDAK MEMILIKI JADWAL MENGAJAR LAIN │
│ 🟢 Kapasitas Ruang (40 Kursi) MENCUKUPI Kapasitas Kelas (40)   │
├────────────────────────────────────────────────────────────────┤
│ [ Batal ]                                    [ Simpan Jadwal ] │
└────────────────────────────────────────────────────────────────┘
```

---

## 3. Rincian Fitur & Aturan Bisnis

### 3.1 Pembukaan Kelas Perkuliahan (`kelas`)
- **Struktur Atribut Pokok**:
  - `id`: UUID Primary Key.
  - `id_mata_kuliah`: Mata kuliah yang ditawarkan dari katalog master.
  - `id_periode_akademik`: Terkunci otomatis ke periode akademik aktif (`aktif = true`).
  - `kode`: Kode pengenal kelas (contoh: `TI101-A`, `TI101-B`, `TI201-PAGI`). Wajib unik dalam satu periode akademik per mata kuliah.
  - `kapasitas`: Daya tampung maksimum peserta kelas (standar default 30–40 mahasiswa, `CHECK kapasitas > 0`).
  - `jumlah_terdaftar`: Counter otomatis jumlah mahasiswa yang telah mengunci KRS pada kelas ini (`DEFAULT 0`).
- **Batch Parallel Class Generator**:
  - Admin dapat membuka beberapa rombel sekaligus (misal: Mata Kuliah Algoritma I dibuka sebanyak 3 kelas: Kelas A, Kelas B, dan Kelas C masing-masing kapasitas 40).

### 3.2 Penugasan Dosen Pengampu & Team Teaching (`kelas_dosen`)
- **Struktur Atribut Pokok**:
  - `id`: UUID Primary Key.
  - `id_kelas`: Relasi ke kelas perkuliahan.
  - `id_dosen`: Relasi ke NIDN dosen pengampu.
  - `pengampu_utama`: Boolean penanda koordinator mata kuliah (`true` = Dosen Utama / Koordinator, `false` = Anggota / Team Teaching).
- **Aturan Otoritas Penilaian**:
  - Hanya Dosen dengan status `pengampu_utama = true` yang memiliki wewenang untuk menekan tombol **Finalisasi Nilai Akhir** pada modul penilaian. Co-dosen hanya berwenang mengisi draft nilai dan absensi.
  - Satu kelas wajib memiliki tepat **satu dosen pengampu utama**.

### 3.3 Penjadwalan & Alokasi Ruang (`jadwal_kelas`)
- **Struktur Atribut Pokok**:
  - `id`: UUID Primary Key.
  - `id_kelas`: Kelas perkuliahan yang dijadwalkan.
  - `id_ruangan`: Ruangan dari master `ruangan`.
  - `hari`: Nilai integer 1 s.d. 7 (1=Senin, 2=Selasa, 3=Rabu, 4=Kamis, 5=Jumat, 6=Sabtu, 7=Minggu).
  - `jam_mulai`: Waktu mulai kuliah tipe `TIME` (contoh: `08:00:00`).
  - `jam_selesai`: Waktu selesai kuliah tipe `TIME` (contoh: `10:30:00`).
  - Constraint: `CHECK (jam_selesai > jam_mulai)`.
- **Kesesuaian Durasi SKS**:
  - Durasi perkuliahan dihitung berdasarkan bobot SKS:
    $$\text{Durasi Minimal} = \text{SKS} \times 50\text{ menit}$$
  - Contoh: 3 SKS = minimal 150 menit waktu tatap muka.

---

## 4. Mesin Deteksi Bentrok Otomatis (Conflict Detection Engine)

Mesin validasi dijalankan secara pre-flight pada form UI dan diverifikasi ulang secara keras (*hard constraint*) pada level database stored function sebelum data jadwal di-commit.

### 4.1 Rumus Matematika Irisan Waktu (Time Overlap Logic)
Dua jadwal perkuliahan pada hari yang sama dianggap **bentrok** jika dan hanya jika:
$$\text{Hari}_1 = \text{Hari}_2 \quad \land \quad \max(\text{Mulai}_1, \text{Mulai}_2) < \min(\text{Selesai}_1, \text{Selesai}_2)$$
Atau secara ekspresi perbandingan rentang:
$$(\text{Mulai}_1 < \text{Selesai}_2) \quad \land \quad (\text{Selesai}_1 > \text{Mulai}_2)$$

### 4.2 Skenario Deteksi Bentrok
1. **Deteksi Bentrok Ruangan (Room Collision)**:
   - Tidak boleh ada dua kelas berbeda yang menggunakan `id_ruangan` yang sama pada `hari` yang sama dengan rentang waktu yang beririsan.
2. **Deteksi Bentrok Dosen (Lecturer Double-Booking)**:
   - Dosen yang mengajar di kelas target tidak boleh sedang dijadwalkan mengajar di kelas lain pada hari dan rentang jam yang beririsan.
3. **Deteksi Pelanggaran Kapasitas Ruang (Capacity Overload)**:
   - `kelas.kapasitas` tidak boleh melebihi `ruangan.kapasitas`. Jika ruangan hanya berkapasitas 30 kursi, kelas berdaya tampung 40 mahasiswa ditolak.

### 4.3 Kode Algoritma Deteksi Bentrok (Dart Service)
```dart
class ScheduleConflictChecker {
  static ConflictResult check({
    required TimeOfDay startA,
    required TimeOfDay endA,
    required TimeOfDay startB,
    required TimeOfDay endB,
  }) {
    final startMinA = startA.hour * 60 + startA.minute;
    final endMinA = endA.hour * 60 + endA.minute;
    final startMinB = startB.hour * 60 + startB.minute;
    final endMinB = endB.hour * 60 + endB.minute;

    // Interval overlap condition
    final isOverlap = (startMinA < endMinB) && (endMinA > startMinB);
    return isOverlap ? ConflictResult.conflict() : ConflictResult.clear();
  }
}
```

---

## 5. Skema Data & Kueri Database Terkait

### 5.1 Skema Tabel Kelas, Dosen Pengampu, & Jadwal
```sql
-- 1. Tabel Kelas Kuliah
CREATE TABLE IF NOT EXISTS public.kelas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mata_kuliah UUID NOT NULL REFERENCES public.mata_kuliah(id) ON DELETE RESTRICT,
    id_periode_akademik UUID NOT NULL REFERENCES public.periode_akademik(id) ON DELETE RESTRICT,
    kode VARCHAR(50) NOT NULL, -- Contoh: "TI101-A"
    kapasitas INTEGER NOT NULL DEFAULT 30 CHECK (kapasitas > 0),
    jumlah_terdaftar INTEGER NOT NULL DEFAULT 0 CHECK (jumlah_terdaftar >= 0),
    dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_kelas_periode UNIQUE (id_mata_kuliah, id_periode_akademik, kode)
);

-- 2. Tabel Dosen Pengampu (Team Teaching)
CREATE TABLE IF NOT EXISTS public.kelas_dosen (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_kelas UUID NOT NULL REFERENCES public.kelas(id) ON DELETE CASCADE,
    id_dosen VARCHAR(20) NOT NULL REFERENCES public.dosen(nidn) ON DELETE RESTRICT,
    pengampu_utama BOOLEAN NOT NULL DEFAULT false,
    ditugaskan_pada TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_kelas_dosen UNIQUE (id_kelas, id_dosen)
);

-- 3. Tabel Jadwal Kelas
CREATE TABLE IF NOT EXISTS public.jadwal_kelas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_kelas UUID NOT NULL REFERENCES public.kelas(id) ON DELETE CASCADE,
    id_ruangan UUID NOT NULL REFERENCES public.ruangan(id) ON DELETE RESTRICT,
    hari INTEGER NOT NULL CHECK (hari >= 1 AND hari <= 7), -- 1=Senin s.d. 7=Minggu
    jam_mulai TIME NOT NULL,
    jam_selesai TIME NOT NULL,
    CONSTRAINT ck_jam_jadwal CHECK (jam_selesai > jam_mulai)
);
```

### 5.2 Stored Function: Pencegahan Bentrok Atomik (Database Function)
```sql
CREATE OR REPLACE FUNCTION public.fn_validate_schedule_conflict()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_conflict_room_class TEXT;
    v_conflict_lecturer_class TEXT;
    v_lecturer_nidn VARCHAR(20);
    v_class_capacity INTEGER;
    v_room_capacity INTEGER;
BEGIN
    -- 1. Validasi Kapasitas Ruangan vs Kelas
    SELECT k.kapasitas, r.kapasitas INTO v_class_capacity, v_room_capacity
    FROM public.kelas k, public.ruangan r
    WHERE k.id = NEW.id_kelas AND r.id = NEW.id_ruangan;

    IF v_class_capacity > v_room_capacity THEN
        RAISE EXCEPTION 'Kapasitas ruangan (%) lebih kecil dari kapasitas kelas (%)!',
            v_room_capacity, v_class_capacity;
    END IF;

    -- 2. Deteksi Bentrok Ruangan
    SELECT k.kode INTO v_conflict_room_class
    FROM public.jadwal_kelas jk
    JOIN public.kelas k ON jk.id_kelas = k.id
    WHERE jk.id_ruangan = NEW.id_ruangan
      AND jk.hari = NEW.hari
      AND jk.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID)
      AND (jk.jam_mulai < NEW.jam_selesai AND jk.jam_selesai > NEW.jam_mulai)
    LIMIT 1;

    IF v_conflict_room_class IS NOT NULL THEN
        RAISE EXCEPTION 'Bentrok Ruangan: Ruangan ini telah terpakai oleh Kelas "%" pada rentang jam tersebut!',
            v_conflict_room_class;
    END IF;

    -- 3. Deteksi Bentrok Dosen
    FOR v_lecturer_nidn IN (SELECT id_dosen FROM public.kelas_dosen WHERE id_kelas = NEW.id_kelas)
    LOOP
        SELECT k.kode INTO v_conflict_lecturer_class
        FROM public.jadwal_kelas jk
        JOIN public.kelas k ON jk.id_kelas = k.id
        JOIN public.kelas_dosen kd ON k.id = kd.id_kelas
        WHERE kd.id_dosen = v_lecturer_nidn
          AND jk.hari = NEW.hari
          AND jk.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID)
          AND (jk.jam_mulai < NEW.jam_selesai AND jk.jam_selesai > NEW.jam_mulai)
        LIMIT 1;

        IF v_conflict_lecturer_class IS NOT NULL THEN
            RAISE EXCEPTION 'Bentrok Dosen: Dosen dengan NIDN % telah memiliki jadwal mengajar di Kelas "%" pada jam tersebut!',
                v_lecturer_nidn, v_conflict_lecturer_class;
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$;

-- Pasang Trigger Validasi Otomatis
DROP TRIGGER IF EXISTS trg_check_schedule_conflict ON public.jadwal_kelas;
CREATE TRIGGER trg_check_schedule_conflict
BEFORE INSERT OR UPDATE ON public.jadwal_kelas
FOR EACH ROW
EXECUTE FUNCTION public.fn_validate_schedule_conflict();
```

---

## 6. Struktur Log Aktivitas & Payload Metadata JSON

```json
{
  "event_timestamp": "2026-09-28T11:45:00+08:00",
  "actor_id": "c1f8a840-7e32-4759-9943-8f0a0d4c9801",
  "actor_name": "Administrator Pusat",
  "aksi": "ADMIN_BUAT_JADWAL_KELAS",
  "entitas": "jadwal_kelas",
  "id_entitas": "9b12a840-3321-4b12-9901-8f0a0d4c9111",
  "metadata": {
    "class_code": "TI101-A",
    "course_name": "Algoritma & Pemrograman I",
    "day": 2,
    "day_name": "Selasa",
    "start_time": "08:00:00",
    "end_time": "10:30:00",
    "room_code": "LAB-KOMP-1",
    "room_capacity": 40,
    "assigned_lecturers": ["0412088501"]
  }
}
```

---

## 7. Penanganan Kasus Khusus (Edge Cases) & Validasi Sistem

| Skenario Kasus Khusus | Potensi Masalah | Solusi Penanganan Sistem |
| :--- | :--- | :--- |
| **Satu kelas memiliki 2 sesi jadwal berbeda (Teori & Praktikum)** | Sistem menolak jika jadwal dianggap duplikat. | Tabel `jadwal_kelas` berelasi `1:N` terhadap `kelas`. Satu kelas diperbolehkan memiliki multi-slot waktu (misal: Teori di Gedung A Selasa, Lab di Gedung B Kamis). |
| **Dosen pengganti sementara (ad-hoc replacement)** | Jadwal dosen pengampu asli bentrok dengan urusan dinas. | Fasilitas penugasan co-dosen sementara tanpa mengubah struktur dosen pengampu utama kelas. |
| **Perubahan kapasitas kelas setelah mahasiswa mendaftar** | Admin menurunkan kapasitas di bawah jumlah mahasiswa yang sudah terlanjur daftar. | Validasi sistem menolak perubahan jika `kapasitas_baru < jumlah_terdaftar`. Admin wajib memindahkan sebagian mahasiswa terlebih dahulu. |
| **Jadwal kuliah menabrak waktu ibadah (Jumat 11:30–13:00)** | Pelanggaran norma kenyamanan civitas kampus. | Fitur *Blackout Period*: Jam 11:30 s.d. 13:00 di hari Jumat ditandai sebagai slot terproteksi yang memunculkan peringatan khusus saat dijadwalkan. |
