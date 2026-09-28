# ERD.md — Entity Relationship Diagram

> Dokumen ini menjelaskan skema database PostgreSQL untuk proyek Sistem Informasi Akademik (SIA),
> dikelola via Supabase. Mencakup seluruh entitas, atribut, tipe data, constraint, dan relasi

---

## Daftar Isi

1. [Diagram ERD (Mermaid)](#1-diagram-erd-mermaid)
2. [Ringkasan Relasi Antar Entitas](#2-ringkasan-relasi-antar-entitas)
3. [Definisi Tabel](#3-definisi-tabel)
   - [user](#31-user)
   - [role](#32-role)
   - [user_role](#33-user_role)
   - [mahasiswa](#34-mahasiswa)
   - [dosen](#35-dosen)
   - [program_studi](#36-program_studi)
   - [periode_akademik](#37-periode_akademik)
   - [mata_kuliah](#38-mata_kuliah)
   - [kurikulum](#39-kurikulum)
   - [kurikulum_mata_kuliah](#310-kurikulum_mata_kuliah)
   - [ruangan](#311-ruangan)
   - [kelas](#312-kelas)
   - [kelas_dosen](#313-kelas_dosen)
   - [jadwal_kelas](#314-jadwal_kelas)
   - [krs](#315-krs)
   - [nilai](#316-nilai)
   - [presensi](#317-presensi)
   - [rekap_presensi](#318-rekap_presensi)
   - [log_aktivitas](#319-log_aktivitas)
4. [Catatan Implementasi](#4-catatan-implementasi)

---

## 1. Diagram ERD (Mermaid)

```mermaid
erDiagram

    %% ─── PENGGUNA & PERAN ───────────────────────────────────────────────────────
    user {
        uuid   id              PK
        text   email           UK
        text   nama_lengkap
        text   telepon
        text   url_avatar
        bool   aktif
        ts     dibuat_pada
        ts     diperbarui_pada
    }

    role {
        uuid   id    PK
        text   nama  UK
    }

    user_role {
        uuid   id              PK
        uuid   id_user     FK
        uuid   id_role        FK
        ts     ditugaskan_pada
    }

    %% ─── PROFIL SPESIFIK ────────────────────────────────────────────────────────
    mahasiswa {
        text   npm                 PK
        uuid   id_user             FK
        uuid   id_program_studi    FK
        text   nama_lengkap
        int    tahun_masuk
        text   jenis_kelamin
        date   tanggal_lahir
        enum   status = AKTIF/CUTI/LULUS/DO
        ts     dibuat_pada
        ts     diperbarui_pada
    }

    dosen {
        text   nidn                PK
        uuid   id_user             FK
        uuid   id_program_studi    FK
        text   nama_lengkap
        text   gelar_akademik
        text   jenis_kelamin
        date   tanggal_lahir
        enum   status = AKTIF/TIDAK_AKTIF
        ts     dibuat_pada
        ts     diperbarui_pada
    }

    %% ─── PROGRAM STUDI & KURIKULUM ──────────────────────────────────────────────
    program_studi {
        uuid   id              PK
        text   nama            UK
        text   kode            UK
        text   jenjang
        ts     dibuat_pada
        ts     diperbarui_pada
    }

    kurikulum {
        uuid   id                  PK
        uuid   id_program_studi    FK
        text   nama
        int    tahun
        bool   aktif
        ts     dibuat_pada
        ts     diperbarui_pada
    }

    mata_kuliah {
        uuid   id              PK
        text   kode            UK
        text   nama
        int    sks
        int    semester
        text   jenis
        ts     dibuat_pada
        ts     diperbarui_pada
    }

    kurikulum_mata_kuliah {
        uuid   id                    PK
        uuid   id_kurikulum          FK
        uuid   id_mata_kuliah        FK
        int    semester_rekomendasi
    }

    %% ─── PERIODE AKADEMIK ───────────────────────────────────────────────────────
    periode_akademik {
        uuid   id               PK
        text   nama             UK
        text   tahun_akademik
        text   semester
        date   tanggal_mulai
        date   tanggal_selesai
        bool   aktif
        ts     dibuat_pada
        ts     diperbarui_pada
    }

    %% ─── KELAS & JADWAL ─────────────────────────────────────────────────────────
    ruangan {
        uuid   id        PK
        text   kode      UK
        text   nama
        int    kapasitas
        text   gedung
    }

    kelas {
        uuid   id                  PK
        uuid   id_mata_kuliah      FK
        uuid   id_periode_akademik FK
        text   kode                UK
        int    kapasitas
        int    jumlah_terdaftar
        ts     dibuat_pada
        ts     diperbarui_pada
    }

    kelas_dosen {
        uuid   id              PK
        uuid   id_kelas        FK
        text   id_dosen        FK
        bool   pengampu_utama
    }

    jadwal_kelas {
        uuid   id          PK
        uuid   id_kelas    FK
        uuid   id_ruangan  FK
        int    hari
        time   jam_mulai
        time   jam_selesai
    }

    %% ─── KRS & NILAI ─────────────────────────────────────────────────────────────
    krs {
        uuid   id                  PK
        text   id_mahasiswa        FK
        uuid   id_kelas            FK
        uuid   id_periode_akademik FK
        text   status
        ts     terdaftar_pada
        ts     diperbarui_pada
    }

    nilai {
        uuid    id              PK
        uuid    id_krs          FK
        num     nilai_uts
        num     nilai_uas
        num     nilai_tugas
        num     nilai_akhir
        text    huruf_nilai
        bool    sudah_final
        ts      disubmit_pada
        ts      diperbarui_pada
    }

    %% ─── PRESENSI ───────────────────────────────────────────────────────────────
    presensi {
        uuid   id               PK
        uuid   id_kelas         FK
        int    pertemuan_ke
        date   tanggal_pertemuan
        text   topik
        ts     dibuat_pada
        ts     diperbarui_pada
    }

    rekap_presensi {
        uuid   id              PK
        uuid   id_presensi     FK
        uuid   id_krs          FK
        text   status
        text   keterangan
        ts     dicatat_pada
    }

    %% ─── LOG AKTIVITAS ──────────────────────────────────────────────────────────
    log_aktivitas {
        uuid   id           PK
        uuid   id_user      FK
        text   aksi
        text   entitas
        text   id_entitas
        jsonb  metadata
        text   alamat_ip
        ts     dibuat_pada
    }

    %% ─── RELASI ──────────────────────────────────────────────────────────────────
    user         ||--o{ user_role         : "memiliki peran"
    role         ||--o{ user_role         : "diberikan ke"
    user         ||--o|  mahasiswa             : "adalah mahasiswa"
    user         ||--o|  dosen                 : "adalah dosen"
    program_studi    ||--o{ mahasiswa              : "menampung"
    program_studi    ||--o{ dosen                  : "menampung"
    program_studi    ||--o{ kurikulum              : "memiliki kurikulum"
    kurikulum        ||--o{ kurikulum_mata_kuliah  : "memuat"
    mata_kuliah      ||--o{ kurikulum_mata_kuliah  : "termasuk dalam"
    mata_kuliah      ||--o{ kelas                  : "dijalankan sebagai kelas"
    periode_akademik ||--o{ kelas                  : "berlangsung pada"
    periode_akademik ||--o{ krs                    : "berlangsung pada"
    kelas            ||--o{ kelas_dosen            : "diampu oleh"
    dosen            ||--o{ kelas_dosen            : "mengampu"
    kelas            ||--o{ jadwal_kelas           : "memiliki jadwal"
    ruangan          ||--o{ jadwal_kelas           : "digunakan oleh"
    kelas            ||--o{ krs                    : "diikuti melalui KRS"
    mahasiswa        ||--o{ krs                    : "mengambil"
    krs              ||--o|  nilai                 : "mendapat nilai"
    kelas            ||--o{ presensi               : "memiliki pertemuan"
    presensi         ||--o{ rekap_presensi         : "dicatat per mahasiswa"
    krs              ||--o{ rekap_presensi         : "tercatat kehadirannya"
    user             ||--o{ log_aktivitas          : "tercatat aktivitasnya"
```

---

## 2. Ringkasan Relasi Antar Entitas

```
user
 ├── user_role   (many  — satu pengguna dapat memiliki lebih dari satu peran)
 ├── mahasiswa        (one-to-one — jika pengguna adalah mahasiswa)
 └── dosen            (one-to-one — jika pengguna adalah dosen)

role
 └── user_role   (many)

program_studi
 ├── mahasiswa        (one-to-many)
 ├── dosen            (one-to-many)
 └── kurikulum        (one-to-many — satu prodi bisa punya beberapa versi kurikulum)

kurikulum
 └── kurikulum_mata_kuliah  (many — pivot ke mata_kuliah)

mata_kuliah
 ├── kurikulum_mata_kuliah  (many — pivot ke kurikulum)
 └── kelas                  (one-to-many — satu MK bisa punya banyak kelas per periode)

periode_akademik
 ├── kelas  (one-to-many)
 └── krs    (one-to-many)

kelas
 ├── kelas_dosen    (many — bisa diampu lebih dari satu dosen)
 ├── jadwal_kelas   (many — bisa punya lebih dari satu slot jadwal per minggu)
 ├── krs            (many — mahasiswa yang terdaftar di kelas ini)
 └── presensi       (many — satu record per pertemuan)

krs (Kartu Rencana Studi)
 ├── nilai          (one-to-one — satu nilai per KRS)
 └── rekap_presensi (many — kehadiran per pertemuan)

presensi
 └── rekap_presensi (many — satu record per mahasiswa per pertemuan)
```

---

## 3. Definisi Tabel

> **Konvensi Penamaan:**
>
> - Seluruh nama tabel dan kolom menggunakan Bahasa Indonesia dengan format `snake_case`
> - Primary Key: `uuid`, diisi otomatis dengan `gen_random_uuid()`
> - Timestamp: `timestamptz` (timezone-aware), default `now()`
> - Seluruh tabel memiliki kolom `dibuat_pada`; tabel yang bisa diperbarui memiliki `diperbarui_pada`
> - Foreign Key menggunakan `ON DELETE RESTRICT` kecuali disebutkan berbeda

---

### 3.1 `user`

Tabel utama pengguna sistem. Terintegrasi dengan Supabase Auth — kolom `id` merujuk langsung
ke `auth.users.id` milik Supabase.

| Kolom             | Tipe          | Constraint              | Keterangan                        |
| ----------------- | ------------- | ----------------------- | --------------------------------- |
| `id`              | `uuid`        | PK, FK → auth.users     | Sama dengan ID dari Supabase Auth |
| `email`           | `text`        | NOT NULL, UNIQUE        | Alamat email pengguna             |
| `nama_lengkap`    | `text`        | NOT NULL                | Nama lengkap pengguna             |
| `telepon`         | `text`        |                         | Nomor telepon (opsional)          |
| `url_avatar`      | `text`        |                         | URL foto profil                   |
| `aktif`           | `boolean`     | NOT NULL, DEFAULT true  | Status aktif akun                 |
| `dibuat_pada`     | `timestamptz` | NOT NULL, DEFAULT now() | Waktu akun dibuat                 |
| `diperbarui_pada` | `timestamptz` | NOT NULL, DEFAULT now() | Waktu terakhir diperbarui         |

```sql
CREATE TABLE "user" (
    id              uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email           text NOT NULL UNIQUE,
    nama_lengkap    text NOT NULL,
    telepon         text,
    url_avatar      text,
    aktif           boolean NOT NULL DEFAULT true,
    dibuat_pada     timestamptz NOT NULL DEFAULT now(),
    diperbarui_pada timestamptz NOT NULL DEFAULT now()
);
```

---

### 3.2 `role`

Tabel daftar role yang tersedia dalam sistem.

| Kolom  | Tipe   | Constraint       | Keterangan                           |
| ------ | ------ | ---------------- | ------------------------------------ |
| `id`   | `uuid` | PK               |                                      |
| `nama` | `text` | NOT NULL, UNIQUE | Nilai: `ADMIN`, `DOSEN`, `MAHASISWA` |

```sql
CREATE TABLE role (
    id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nama text NOT NULL UNIQUE
        CHECK (nama IN ('ADMIN', 'DOSEN', 'MAHASISWA'))
);
```

---

### 3.3 `user_role`

Tabel pivot — satu pengguna dapat memiliki lebih dari satu peran.

| Kolom             | Tipe          | Constraint              | Keterangan            |
| ----------------- | ------------- | ----------------------- | --------------------- |
| `id`              | `uuid`        | PK                      |                       |
| `id_user`         | `uuid`        | NOT NULL, FK → user     | Akun pengguna         |
| `id_role`         | `uuid`        | NOT NULL, FK → role     | Peran pengguna        |
| `ditugaskan_pada` | `timestamptz` | NOT NULL, DEFAULT now() | Waktu peran diberikan |

```sql
CREATE TABLE user_role (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_user          uuid NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    id_role          uuid NOT NULL REFERENCES role(id),
    ditugaskan_pada  timestamptz NOT NULL DEFAULT now(),
    UNIQUE (id_user, id_role)
);
```

---

### 3.4 `mahasiswa`

Data profil mahasiswa. Menggunakan `npm` (Nomor Pokok Mahasiswa 10 digit) sebagai Primary Key (PK) untuk mendukung sistem login berbasis NPM dan password.

**Format Kode NPM (10 Digit):**

- `xx` (2 digit): Tahun masuk (contoh: `26` untuk angkatan 2026)
- `xxx` (3 digit): Kode Fakultas (contoh : untuk fakultas teknologi informasi kode nya 100)
- `xx` (2 digit): Kode Program Studi (contoh : untuk prodi teknik informatika kodenya 10)
- `xxx` (3 digit): Identitas unik mahasiswa (nomor urut yang berbeda untuk tiap mahasiswa contoh : 001/383/223)

contoh npm lengkap : 261001001

| Kolom              | Tipe          | Constraint                   | Keterangan                       |
| ------------------ | ------------- | ---------------------------- | -------------------------------- |
| `npm`              | `text`        | PK, CHECK (10 digit angka)   | Nomor Pokok Mahasiswa (Login ID) |
| `id_user`          | `uuid`        | UNIQUE, FK → user            | Akun pengguna (Supabase Auth)    |
| `nama_lengkap`     | `text`        | NOT NULL                     | Nama lengkap mahasiswa           |
| `id_program_studi` | `uuid`        | NOT NULL, FK → program_studi | Program studi yang diambil       |
| `tahun_masuk`      | `integer`     | NOT NULL                     | Tahun masuk / angkatan           |
| `jenis_kelamin`    | `text`        | NOT NULL                     | L / P                            |
| `tanggal_lahir`    | `date`        |                              | Tanggal lahir                    |
| `status`           | `text`        | NOT NULL, DEFAULT 'AKTIF'    | AKTIF, CUTI, LULUS, DO           |
| `dibuat_pada`      | `timestamptz` | NOT NULL, DEFAULT now()      | Waktu data dibuat                |
| `diperbarui_pada`  | `timestamptz` | NOT NULL, DEFAULT now()      | Waktu data diperbarui            |

```sql
CREATE TABLE mahasiswa (
    npm              text PRIMARY KEY CHECK (npm ~ '^[0-9]{10}$'),
    id_user          uuid UNIQUE REFERENCES "user"(id) ON DELETE CASCADE,
    nama_lengkap     text NOT NULL,
    id_program_studi uuid NOT NULL REFERENCES program_studi(id),
    tahun_masuk      integer NOT NULL,
    jenis_kelamin    text NOT NULL CHECK (jenis_kelamin IN ('L', 'P')),
    tanggal_lahir    date,
    status           text NOT NULL DEFAULT 'AKTIF'
        CHECK (status IN ('AKTIF', 'CUTI', 'LULUS', 'DO')),
    dibuat_pada      timestamptz NOT NULL DEFAULT now(),
    diperbarui_pada  timestamptz NOT NULL DEFAULT now()
);
```

---

### 3.5 `dosen`

Data profil dosen. Menggunakan `nidn` (Nomor Induk Dosen Nasional) sebagai Primary Key (PK) untuk mendukung sistem login berbasis NIDN dan password.

| Kolom              | Tipe          | Constraint                   | Keterangan                         |
| ------------------ | ------------- | ---------------------------- | ---------------------------------- |
| `nidn`             | `text`        | PK, CHECK (hanya digit)      | Nomor Induk Dosen Nasional (Login) |
| `id_user`          | `uuid`        | UNIQUE, FK → user            | Akun pengguna (Supabase Auth)      |
| `nama_lengkap`     | `text`        | NOT NULL                     | Nama lengkap dosen                 |
| `id_program_studi` | `uuid`        | NOT NULL, FK → program_studi | Program studi asal dosen           |
| `gelar_akademik`   | `text`        |                              | Gelar/jabatan (S.Kom, M.Cs, Dr.)   |
| `jenis_kelamin`    | `text`        | NOT NULL                     | L / P                              |
| `tanggal_lahir`    | `date`        |                              | Tanggal lahir                      |
| `status`           | `text`        | NOT NULL, DEFAULT 'AKTIF'    | AKTIF, TIDAK_AKTIF                 |
| `dibuat_pada`      | `timestamptz` | NOT NULL, DEFAULT now()      | Waktu data dibuat                  |
| `diperbarui_pada`  | `timestamptz` | NOT NULL, DEFAULT now()      | Waktu data diperbarui              |

```sql
CREATE TABLE dosen (
    nidn             text PRIMARY KEY CHECK (nidn ~ '^[0-9]+$'),
    id_user          uuid UNIQUE REFERENCES "user"(id) ON DELETE CASCADE,
    nama_lengkap     text NOT NULL,
    id_program_studi uuid NOT NULL REFERENCES program_studi(id),
    gelar_akademik   text,
    jenis_kelamin    text NOT NULL CHECK (jenis_kelamin IN ('L', 'P')),
    tanggal_lahir    date,
    status           text NOT NULL DEFAULT 'AKTIF'
        CHECK (status IN ('AKTIF', 'TIDAK_AKTIF')),
    dibuat_pada      timestamptz NOT NULL DEFAULT now(),
    diperbarui_pada  timestamptz NOT NULL DEFAULT now()
);
```

---

### 3.6 `program_studi`

Daftar program studi yang tersedia di institusi.

| Kolom             | Tipe          | Constraint              | Keterangan                         |
| ----------------- | ------------- | ----------------------- | ---------------------------------- |
| `id`              | `uuid`        | PK                      |                                    |
| `nama`            | `text`        | NOT NULL, UNIQUE        | Nama lengkap (Teknik Informatika)  |
| `kode`            | `text`        | NOT NULL, UNIQUE        | Kode singkat (TI, SI, MI, dll.)    |
| `jenjang`         | `text`        | NOT NULL                | Jenjang pendidikan: D3, S1, S2, S3 |
| `dibuat_pada`     | `timestamptz` | NOT NULL, DEFAULT now() |                                    |
| `diperbarui_pada` | `timestamptz` | NOT NULL, DEFAULT now() |                                    |

```sql
CREATE TABLE program_studi (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nama            text NOT NULL UNIQUE,
    kode            text NOT NULL UNIQUE,
    jenjang         text NOT NULL
        CHECK (jenjang IN ('D3', 'S1', 'S2', 'S3')),
    dibuat_pada     timestamptz NOT NULL DEFAULT now(),
    diperbarui_pada timestamptz NOT NULL DEFAULT now()
);
```

---

### 3.7 `periode_akademik`

Periode akademik (semester). Hanya boleh ada satu periode dengan `aktif = true` pada satu waktu.

| Kolom             | Tipe          | Constraint              | Keterangan                    |
| ----------------- | ------------- | ----------------------- | ----------------------------- |
| `id`              | `uuid`        | PK                      |                               |
| `nama`            | `text`        | NOT NULL, UNIQUE        | Contoh: `Ganjil 2025/2026`    |
| `tahun_akademik`  | `text`        | NOT NULL                | Contoh: `2025/2026`           |
| `semester`        | `text`        | NOT NULL                | `GANJIL` atau `GENAP`         |
| `tanggal_mulai`   | `date`        | NOT NULL                | Tanggal awal semester         |
| `tanggal_selesai` | `date`        | NOT NULL                | Tanggal akhir semester        |
| `aktif`           | `boolean`     | NOT NULL, DEFAULT false | Semester yang sedang berjalan |
| `dibuat_pada`     | `timestamptz` | NOT NULL, DEFAULT now() |                               |
| `diperbarui_pada` | `timestamptz` | NOT NULL, DEFAULT now() |                               |

```sql
CREATE TABLE periode_akademik (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nama             text NOT NULL UNIQUE,
    tahun_akademik   text NOT NULL,
    semester         text NOT NULL CHECK (semester IN ('GANJIL', 'GENAP')),
    tanggal_mulai    date NOT NULL,
    tanggal_selesai  date NOT NULL,
    aktif            boolean NOT NULL DEFAULT false,
    dibuat_pada      timestamptz NOT NULL DEFAULT now(),
    diperbarui_pada  timestamptz NOT NULL DEFAULT now(),
    CHECK (tanggal_selesai > tanggal_mulai)
);
```

---

### 3.8 `mata_kuliah`

Daftar mata kuliah yang terdaftar di institusi.

| Kolom             | Tipe          | Constraint              | Keterangan                            |
| ----------------- | ------------- | ----------------------- | ------------------------------------- |
| `id`              | `uuid`        | PK                      |                                       |
| `kode`            | `text`        | NOT NULL, UNIQUE        | Kode mata kuliah (TI101, SI202, dll.) |
| `nama`            | `text`        | NOT NULL                | Nama mata kuliah                      |
| `sks`             | `integer`     | NOT NULL, CHECK > 0     | Jumlah Satuan Kredit Semester         |
| `semester`        | `integer`     | NOT NULL, CHECK 1–8     | Semester rekomendasi pengambilan      |
| `jenis`           | `text`        | NOT NULL                | `WAJIB` atau `PILIHAN`                |
| `dibuat_pada`     | `timestamptz` | NOT NULL, DEFAULT now() |                                       |
| `diperbarui_pada` | `timestamptz` | NOT NULL, DEFAULT now() |                                       |

```sql
CREATE TABLE mata_kuliah (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    kode            text NOT NULL UNIQUE,
    nama            text NOT NULL,
    sks             integer NOT NULL CHECK (sks > 0),
    semester        integer NOT NULL CHECK (semester BETWEEN 1 AND 8),
    jenis           text NOT NULL CHECK (jenis IN ('WAJIB', 'PILIHAN')),
    dibuat_pada     timestamptz NOT NULL DEFAULT now(),
    diperbarui_pada timestamptz NOT NULL DEFAULT now()
);
```

---

### 3.9 `kurikulum`

Kurikulum per program studi. Setiap program studi dapat memiliki beberapa versi kurikulum.

| Kolom              | Tipe          | Constraint                   | Keterangan                      |
| ------------------ | ------------- | ---------------------------- | ------------------------------- |
| `id`               | `uuid`        | PK                           |                                 |
| `id_program_studi` | `uuid`        | NOT NULL, FK → program_studi |                                 |
| `nama`             | `text`        | NOT NULL                     | Contoh: `Kurikulum 2020`        |
| `tahun`            | `integer`     | NOT NULL                     | Tahun berlakunya kurikulum      |
| `aktif`            | `boolean`     | NOT NULL, DEFAULT false      | Kurikulum yang berlaku saat ini |
| `dibuat_pada`      | `timestamptz` | NOT NULL, DEFAULT now()      |                                 |
| `diperbarui_pada`  | `timestamptz` | NOT NULL, DEFAULT now()      |                                 |

```sql
CREATE TABLE kurikulum (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_program_studi uuid NOT NULL REFERENCES program_studi(id),
    nama             text NOT NULL,
    tahun            integer NOT NULL,
    aktif            boolean NOT NULL DEFAULT false,
    dibuat_pada      timestamptz NOT NULL DEFAULT now(),
    diperbarui_pada  timestamptz NOT NULL DEFAULT now()
);
```

---

### 3.10 `kurikulum_mata_kuliah`

Tabel pivot — daftar mata kuliah yang termasuk dalam suatu kurikulum tertentu.

| Kolom                  | Tipe      | Constraint                 | Keterangan                   |
| ---------------------- | --------- | -------------------------- | ---------------------------- |
| `id`                   | `uuid`    | PK                         |                              |
| `id_kurikulum`         | `uuid`    | NOT NULL, FK → kurikulum   |                              |
| `id_mata_kuliah`       | `uuid`    | NOT NULL, FK → mata_kuliah |                              |
| `semester_rekomendasi` | `integer` | NOT NULL, CHECK 1–8        | Posisi ideal dalam kurikulum |

```sql
CREATE TABLE kurikulum_mata_kuliah (
    id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_kurikulum         uuid NOT NULL REFERENCES kurikulum(id) ON DELETE CASCADE,
    id_mata_kuliah       uuid NOT NULL REFERENCES mata_kuliah(id),
    semester_rekomendasi integer NOT NULL CHECK (semester_rekomendasi BETWEEN 1 AND 8),
    UNIQUE (id_kurikulum, id_mata_kuliah)
);
```

---

### 3.11 `ruangan`

Daftar ruang kuliah yang tersedia di institusi.

| Kolom       | Tipe      | Constraint       | Keterangan                     |
| ----------- | --------- | ---------------- | ------------------------------ |
| `id`        | `uuid`    | PK               |                                |
| `kode`      | `text`    | NOT NULL, UNIQUE | Kode ruangan (GD-A-201, Lab-1) |
| `nama`      | `text`    | NOT NULL         | Nama ruangan                   |
| `kapasitas` | `integer` | NOT NULL, > 0    | Kapasitas maksimum kursi       |
| `gedung`    | `text`    |                  | Nama gedung                    |

```sql
CREATE TABLE ruangan (
    id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    kode      text NOT NULL UNIQUE,
    nama      text NOT NULL,
    kapasitas integer NOT NULL CHECK (kapasitas > 0),
    gedung    text
);
```

---

### 3.12 `kelas`

Kelas yang dibuka untuk mata kuliah tertentu pada periode akademik tertentu.

| Kolom                 | Tipe          | Constraint                      | Keterangan                       |
| --------------------- | ------------- | ------------------------------- | -------------------------------- |
| `id`                  | `uuid`        | PK                              |                                  |
| `id_mata_kuliah`      | `uuid`        | NOT NULL, FK → mata_kuliah      |                                  |
| `id_periode_akademik` | `uuid`        | NOT NULL, FK → periode_akademik |                                  |
| `kode`                | `text`        | NOT NULL, UNIQUE                | Contoh: `TI101-A`, `TI101-B`     |
| `kapasitas`           | `integer`     | NOT NULL, DEFAULT 30            | Jumlah mahasiswa maksimum        |
| `jumlah_terdaftar`    | `integer`     | NOT NULL, DEFAULT 0             | Jumlah mahasiswa aktif terdaftar |
| `dibuat_pada`         | `timestamptz` | NOT NULL, DEFAULT now()         |                                  |
| `diperbarui_pada`     | `timestamptz` | NOT NULL, DEFAULT now()         |                                  |

```sql
CREATE TABLE kelas (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mata_kuliah      uuid NOT NULL REFERENCES mata_kuliah(id),
    id_periode_akademik uuid NOT NULL REFERENCES periode_akademik(id),
    kode                text NOT NULL UNIQUE,
    kapasitas           integer NOT NULL DEFAULT 30 CHECK (kapasitas > 0),
    jumlah_terdaftar    integer NOT NULL DEFAULT 0 CHECK (jumlah_terdaftar >= 0),
    dibuat_pada         timestamptz NOT NULL DEFAULT now(),
    diperbarui_pada     timestamptz NOT NULL DEFAULT now()
);
```

---

### 3.13 `kelas_dosen`

Tabel pivot — dosen pengampu per kelas. Satu kelas dapat diampu lebih dari satu dosen
(pengampu utama dan co-dosen).

| Kolom            | Tipe      | Constraint             | Keterangan                                  |
| ---------------- | --------- | ---------------------- | ------------------------------------------- |
| `id`             | `uuid`    | PK                     |                                             |
| `id_kelas`       | `uuid`    | NOT NULL, FK → kelas   | Kelas yang diampu                           |
| `id_dosen`       | `text`    | NOT NULL, FK → dosen   | NIDN Dosen pengampu                         |
| `pengampu_utama` | `boolean` | NOT NULL, DEFAULT true | `true` = pengampu utama, `false` = co-dosen |

```sql
CREATE TABLE kelas_dosen (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_kelas       uuid NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
    id_dosen       text NOT NULL REFERENCES dosen(nidn) ON DELETE CASCADE,
    pengampu_utama boolean NOT NULL DEFAULT true,
    UNIQUE (id_kelas, id_dosen)
);
```

---

### 3.14 `jadwal_kelas`

Jadwal pertemuan reguler setiap kelas. Satu kelas dapat memiliki lebih dari satu slot jadwal
(misal: kelas yang bertemu dua kali seminggu).

| Kolom         | Tipe      | Constraint           | Keterangan                          |
| ------------- | --------- | -------------------- | ----------------------------------- |
| `id`          | `uuid`    | PK                   |                                     |
| `id_kelas`    | `uuid`    | NOT NULL, FK → kelas |                                     |
| `id_ruangan`  | `uuid`    | FK → ruangan         | Nullable — ruangan belum ditentukan |
| `hari`        | `integer` | NOT NULL, CHECK 1–7  | 1=Senin, 2=Selasa, ..., 7=Minggu    |
| `jam_mulai`   | `time`    | NOT NULL             | Jam mulai pertemuan                 |
| `jam_selesai` | `time`    | NOT NULL             | Jam selesai pertemuan               |

```sql
CREATE TABLE jadwal_kelas (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_kelas    uuid NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
    id_ruangan  uuid REFERENCES ruangan(id),
    hari        integer NOT NULL CHECK (hari BETWEEN 1 AND 7),
    jam_mulai   time NOT NULL,
    jam_selesai time NOT NULL,
    CHECK (jam_selesai > jam_mulai)
);
```

---

### 3.15 `krs`

Kartu Rencana Studi — pendaftaran mahasiswa ke kelas pada periode akademik tertentu.

| Kolom                 | Tipe          | Constraint                      | Keterangan                           |
| --------------------- | ------------- | ------------------------------- | ------------------------------------ |
| `id`                  | `uuid`        | PK                              |                                      |
| `id_mahasiswa`        | `text`        | NOT NULL, FK → mahasiswa        | NPM Mahasiswa                        |
| `id_kelas`            | `uuid`        | NOT NULL, FK → kelas            |                                      |
| `id_periode_akademik` | `uuid`        | NOT NULL, FK → periode_akademik |                                      |
| `status`              | `text`        | NOT NULL, DEFAULT 'AKTIF'       | AKTIF, DIBATALKAN, MENGUNDURKAN_DIRI |
| `terdaftar_pada`      | `timestamptz` | NOT NULL, DEFAULT now()         | Waktu mahasiswa mengajukan KRS       |
| `diperbarui_pada`     | `timestamptz` | NOT NULL, DEFAULT now()         |                                      |

```sql
CREATE TABLE krs (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mahasiswa        text NOT NULL REFERENCES mahasiswa(npm) ON DELETE CASCADE,
    id_kelas            uuid NOT NULL REFERENCES kelas(id),
    id_periode_akademik uuid NOT NULL REFERENCES periode_akademik(id),
    status              text NOT NULL DEFAULT 'AKTIF'
        CHECK (status IN ('AKTIF', 'DIBATALKAN', 'MENGUNDURKAN_DIRI')),
    terdaftar_pada      timestamptz NOT NULL DEFAULT now(),
    diperbarui_pada     timestamptz NOT NULL DEFAULT now(),
    UNIQUE (id_mahasiswa, id_kelas)
);
```

---

### 3.16 `nilai`

Nilai akademik mahasiswa — satu baris per KRS (satu nilai per kelas per mahasiswa per semester).

| Kolom             | Tipe           | Constraint                 | Keterangan                        |
| ----------------- | -------------- | -------------------------- | --------------------------------- |
| `id`              | `uuid`         | PK                         |                                   |
| `id_krs`          | `uuid`         | NOT NULL, UNIQUE, FK → krs | Relasi one-to-one dengan KRS      |
| `nilai_uts`       | `numeric(5,2)` | CHECK 0–100                | Nilai Ujian Tengah Semester       |
| `nilai_uas`       | `numeric(5,2)` | CHECK 0–100                | Nilai Ujian Akhir Semester        |
| `nilai_tugas`     | `numeric(5,2)` | CHECK 0–100                | Nilai tugas / kuis / praktikum    |
| `nilai_akhir`     | `numeric(5,2)` | CHECK 0–100                | Nilai akhir (hasil pembobotan)    |
| `huruf_nilai`     | `text`         | CHECK enum                 | A, AB, B, BC, C, D, E             |
| `sudah_final`     | `boolean`      | NOT NULL, DEFAULT false    | Terkunci setelah dosen finalisasi |
| `disubmit_pada`   | `timestamptz`  |                            | Waktu finalisasi nilai oleh dosen |
| `diperbarui_pada` | `timestamptz`  | NOT NULL, DEFAULT now()    |                                   |

```sql
CREATE TABLE nilai (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_krs          uuid NOT NULL UNIQUE REFERENCES krs(id) ON DELETE CASCADE,
    nilai_uts       numeric(5,2) CHECK (nilai_uts BETWEEN 0 AND 100),
    nilai_uas       numeric(5,2) CHECK (nilai_uas BETWEEN 0 AND 100),
    nilai_tugas     numeric(5,2) CHECK (nilai_tugas BETWEEN 0 AND 100),
    nilai_akhir     numeric(5,2) CHECK (nilai_akhir BETWEEN 0 AND 100),
    huruf_nilai     text CHECK (huruf_nilai IN ('A', 'AB', 'B', 'BC', 'C', 'D', 'E')),
    sudah_final     boolean NOT NULL DEFAULT false,
    disubmit_pada   timestamptz,
    diperbarui_pada timestamptz NOT NULL DEFAULT now()
);
```

---

### 3.17 `presensi`

Header presensi — satu baris untuk setiap pertemuan kelas yang berlangsung.

| Kolom               | Tipe          | Constraint              | Keterangan                      |
| ------------------- | ------------- | ----------------------- | ------------------------------- |
| `id`                | `uuid`        | PK                      |                                 |
| `id_kelas`          | `uuid`        | NOT NULL, FK → kelas    |                                 |
| `pertemuan_ke`      | `integer`     | NOT NULL, CHECK > 0     | Urutan pertemuan (1, 2, 3, ...) |
| `tanggal_pertemuan` | `date`        | NOT NULL                | Tanggal pertemuan berlangsung   |
| `topik`             | `text`        |                         | Topik / materi pertemuan        |
| `dibuat_pada`       | `timestamptz` | NOT NULL, DEFAULT now() |                                 |
| `diperbarui_pada`   | `timestamptz` | NOT NULL, DEFAULT now() |                                 |

```sql
CREATE TABLE presensi (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_kelas            uuid NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
    pertemuan_ke        integer NOT NULL CHECK (pertemuan_ke > 0),
    tanggal_pertemuan   date NOT NULL,
    topik               text,
    dibuat_pada         timestamptz NOT NULL DEFAULT now(),
    diperbarui_pada     timestamptz NOT NULL DEFAULT now(),
    UNIQUE (id_kelas, pertemuan_ke)
);
```

---

### 3.18 `rekap_presensi`

Detail kehadiran — satu baris per mahasiswa per pertemuan kelas.

| Kolom          | Tipe          | Constraint              | Keterangan                        |
| -------------- | ------------- | ----------------------- | --------------------------------- |
| `id`           | `uuid`        | PK                      |                                   |
| `id_presensi`  | `uuid`        | NOT NULL, FK → presensi |                                   |
| `id_krs`       | `uuid`        | NOT NULL, FK → krs      | Mahasiswa yang terdaftar di kelas |
| `status`       | `text`        | NOT NULL                | HADIR, IZIN, SAKIT, ALPHA         |
| `keterangan`   | `text`        |                         | Catatan tambahan                  |
| `dicatat_pada` | `timestamptz` | NOT NULL, DEFAULT now() | Waktu data direkam                |

```sql
CREATE TABLE rekap_presensi (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_presensi  uuid NOT NULL REFERENCES presensi(id) ON DELETE CASCADE,
    id_krs       uuid NOT NULL REFERENCES krs(id),
    status       text NOT NULL
        CHECK (status IN ('HADIR', 'IZIN', 'SAKIT', 'ALPHA')),
    keterangan   text,
    dicatat_pada timestamptz NOT NULL DEFAULT now(),
    UNIQUE (id_presensi, id_krs)
);
```

---

### 3.19 `log_aktivitas`

Tabel pencatatan event penting untuk keperluan keamanan, debugging, dan akuntabilitas sistem.

| Kolom         | Tipe          | Constraint              | Keterangan                                    |
| ------------- | ------------- | ----------------------- | --------------------------------------------- |
| `id`          | `uuid`        | PK                      |                                               |
| `id_user`     | `uuid`        | FK → user               | Nullable — bisa NULL untuk event otomatis     |
| `aksi`        | `text`        | NOT NULL                | Kode aksi (lihat tabel di bawah)              |
| `entitas`     | `text`        | NOT NULL                | Nama tabel yang menjadi subjek aksi           |
| `id_entitas`  | `text`        |                         | ID baris yang diubah / dibuat / dihapus       |
| `metadata`    | `jsonb`       |                         | Data tambahan (nilai sebelum/sesudah, dll.)   |
| `alamat_ip`   | `text`        |                         | Alamat IP pengguna (terutama untuk jalur web) |
| `dibuat_pada` | `timestamptz` | NOT NULL, DEFAULT now() | Waktu event terjadi                           |

**Daftar kode aksi yang valid:**

| Kode Aksi                   | Keterangan                        |
| --------------------------- | --------------------------------- |
| `ADMIN_BUAT_MAHASISWA`      | Admin membuat akun mahasiswa baru |
| `ADMIN_UBAH_MATA_KULIAH`    | Admin mengubah data mata kuliah   |
| `ADMIN_UBAH_PERAN_PENGGUNA` | Admin mengubah peran pengguna     |
| `ADMIN_BUAT_KELAS`          | Admin membuat kelas baru          |
| `DOSEN_INPUT_NILAI`         | Dosen menginput nilai mahasiswa   |
| `DOSEN_FINALISASI_NILAI`    | Dosen memfinalisasi nilai akhir   |
| `DOSEN_CATAT_PRESENSI`      | Dosen mencatat presensi pertemuan |
| `DOSEN_UBAH_PRESENSI`       | Dosen mengubah data presensi      |
| `MAHASISWA_AJUKAN_KRS`      | Mahasiswa mengajukan KRS          |
| `MAHASISWA_BATALKAN_KRS`    | Mahasiswa membatalkan KRS         |

```sql
CREATE TABLE log_aktivitas (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_user      uuid REFERENCES "user"(id) ON DELETE SET NULL,
    aksi         text NOT NULL,
    entitas      text NOT NULL,
    id_entitas   text,
    metadata     jsonb,
    alamat_ip    text,
    dibuat_pada  timestamptz NOT NULL DEFAULT now()
);

-- Indeks untuk query log per pengguna dan per waktu
CREATE INDEX idx_log_aktivitas_id_user ON log_aktivitas (id_user);
CREATE INDEX idx_log_aktivitas_dibuat_pada  ON log_aktivitas (dibuat_pada DESC);
```

---

## 4. Catatan Implementasi

### Indeks yang Direkomendasikan

```sql
-- Indeks program studi pada mahasiswa & dosen
CREATE INDEX idx_mahasiswa_program_studi ON mahasiswa (id_program_studi);
CREATE INDEX idx_dosen_program_studi ON dosen (id_program_studi);

-- KRS per mahasiswa (NPM) per periode akademik
CREATE INDEX idx_krs_mahasiswa_periode
    ON krs (id_mahasiswa, id_periode_akademik);

-- Jadwal per kelas
CREATE INDEX idx_jadwal_kelas_id_kelas ON jadwal_kelas (id_kelas);

-- Presensi per kelas
CREATE INDEX idx_presensi_id_kelas ON presensi (id_kelas);

-- Rekap presensi per pertemuan
CREATE INDEX idx_rekap_presensi_id_presensi ON rekap_presensi (id_presensi);
```

### Trigger yang Direkomendasikan

```sql
-- Perbarui otomatis jumlah_terdaftar pada tabel kelas
-- setiap kali ada perubahan status KRS
CREATE OR REPLACE FUNCTION perbarui_jumlah_terdaftar()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE kelas
    SET jumlah_terdaftar = (
        SELECT COUNT(*)
        FROM krs
        WHERE id_kelas = COALESCE(NEW.id_kelas, OLD.id_kelas)
          AND status = 'AKTIF'
    )
    WHERE id = COALESCE(NEW.id_kelas, OLD.id_kelas);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_perbarui_jumlah_terdaftar
AFTER INSERT OR UPDATE OR DELETE ON krs
FOR EACH ROW EXECUTE FUNCTION perbarui_jumlah_terdaftar();
```

### Urutan Migration (001 → 021)

```
001_buat_user.sql
002_buat_role.sql
003_buat_user_role.sql
004_buat_program_studi.sql
005_buat_mahasiswa.sql
006_buat_dosen.sql
007_buat_periode_akademik.sql
008_buat_mata_kuliah.sql
009_buat_kurikulum.sql
010_buat_kurikulum_mata_kuliah.sql
011_buat_ruangan.sql
012_buat_kelas.sql
013_buat_kelas_dosen.sql
014_buat_jadwal_kelas.sql
015_buat_krs.sql
016_buat_nilai.sql
017_buat_presensi.sql
018_buat_rekap_presensi.sql
019_buat_log_aktivitas.sql
020_buat_indeks.sql
021_setup_kebijakan_rls.sql
```

### Urutan Pengisian Data Dummy (Seeder)

```
role
→ program_studi
→ user + user_role
→ mahasiswa + dosen
→ periode_akademik
→ mata_kuliah + kurikulum + kurikulum_mata_kuliah
→ ruangan
→ kelas + kelas_dosen + jadwal_kelas
→ krs
→ nilai
→ presensi + rekap_presensi
→ log_aktivitas
```

---

_Lihat juga:_

- _[ARCHITECTURE.md](./ARCHITECTURE.md) — arsitektur sistem secara menyeluruh_
- _[docs/security.md](./docs/security.md) — detail kebijakan RLS per tabel_
- _[docs/roles-permissions.md](./docs/roles-permissions.md) — matriks peran dan hak akses_
