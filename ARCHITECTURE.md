# ARCHITECTURE.md — Sistem Informasi Akademik (SIA)

> Dokumen ini menjelaskan arsitektur repositori, arsitektur teknis, dan keputusan desain utama
> untuk proyek Sistem Informasi Akademik (SIA) multiplatform berbasis Flutter + Dart.

---

## Daftar Isi

1. [Gambaran Proyek](#1-gambaran-proyek)
2. [Arsitektur Tingkat Tinggi](#2-arsitektur-tingkat-tinggi)
3. [Struktur Repositori](#3-struktur-repositori)
4. [Penjelasan Setiap Komponen](#4-penjelasan-setiap-komponen)
5. [Arsitektur Frontend — Flutter](#5-arsitektur-frontend--flutter)
6. [Arsitektur Backend / Business Layer — Dart](#6-arsitektur-backend--business-layer--dart)
7. [Arsitektur Database](#7-arsitektur-database)
8. [Alur Komunikasi Antar Layer](#8-alur-komunikasi-antar-layer)
9. [Keamanan & Authorization](#9-keamanan--authorization)
10. [Distribusi & Deployment](#10-distribusi--deployment)
11. [Dependency & Tech Stack](#11-dependency--tech-stack)
12. [Keputusan Arsitektur (ADR)](#12-keputusan-arsitektur-adr)

---

## 1. Gambaran Proyek

**SIA** adalah sistem informasi akademik multiplatform yang mendukung tiga role utama:

| Role      |
|-----------|
| Admin     |
| Dosen     |
| Mahasiswa |

Ketiga role dapat mengakses aplikasi dari platform manapun (Android, Web, maupun Windows) — tidak ada pembatasan role terhadap platform tertentu. Inilah salah satu alasan utama memilih satu codebase Flutter untuk seluruh target: siapapun rolenya, pengalaman aplikasi tersedia penuh di ketiga platform.

**Karakteristik utama:**

- Satu database terpusat (PostgreSQL via Supabase) — seluruh device mengakses data yang sama.
- Satu codebase Flutter untuk Android, Web, dan Windows.
- Satu bahasa (Dart) dari UI hingga business layer — tanpa FFI atau cross-compilation.
- Business logic **terpisah** dari UI, dijalankan sebagai Dart Isolate (mobile/desktop) atau Dart Server
  via `dart_frog` (web).
- Distribusi sebagai **satu APK** (Android) dan **satu installer** (Windows) — tidak membutuhkan
  instalasi backend oleh pengguna.

---

## 2. Arsitektur Tingkat Tinggi

```
┌────────────────────────────────────────────────────────────────────┐
│                              CLIENTS                               │
│                                                                    │
│  ┌─────────────────┐   ┌──────────────────┐   ┌────────────────┐  │
│  │   Android APK   │   │Windows Installer │   │  Flutter Web   │  │
│  │                 │   │                  │   │                │  │
│  │  Flutter UI     │   │  Flutter UI      │   │  Flutter UI    │  │
│  │     ↕ IPC       │   │     ↕ IPC        │   │      │         │  │
│  │  Dart Isolate   │   │  Dart Isolate    │   │      ↓         │  │
│  │ (business logic)│   │ (business logic) │   │  Dart Server   │  │
│  └────────┬────────┘   └───────┬──────────┘   │  (dart_frog)  │  │
│           │                   │               └──────┬─────────┘  │
└───────────┼───────────────────┼──────────────────────┼────────────┘
            │        HTTPS / Internet                  │
            └──────────────────┬───────────────────────┘
                               ▼
               ┌──────────────────────────────┐
               │           Supabase           │
               │  ┌────────────────────────┐  │
               │  │   Supabase Auth        │  │
               │  │   (JWT / Session)      │  │
               │  ├────────────────────────┤  │
               │  │   Supabase API         │  │
               │  │   (PostgREST)          │  │
               │  ├────────────────────────┤  │
               │  │   Row Level Security   │  │
               │  │        (RLS)           │  │
               │  └────────────────────────┘  │
               └──────────────┬───────────────┘
                              ▼
               ┌──────────────────────────────┐
               │     PostgreSQL Database      │
               │     (Cloud, Centralized)     │
               └──────────────────────────────┘
```

---

## 3. Struktur Repositori

Repositori menggunakan pola **Monorepo** dengan pemisahan jelas antara frontend, backend, database,
dan dokumentasi.

```
sia/                                        ← root repositori
│
├── frontend/                               ← Flutter project (Android, Web, Windows)
│   ├── lib/
│   │   ├── app/                            ← konfigurasi app, router, theme
│   │   │   ├── app.dart
│   │   │   ├── router.dart
│   │   │   └── theme.dart
│   │   │
│   │   ├── core/                           ← fondasi teknis lintas fitur
│   │   │   ├── network/                    ← HTTP client config (Flutter Web)
│   │   │   ├── storage/                    ← secure storage, session
│   │   │   ├── error/                      ← failure types, error model
│   │   │   └── utils/                      ← helper, formatter, validator
│   │   │
│   │   ├── shared/                         ← komponen UI reusable
│   │   │   ├── widgets/                    ← Button, TextField, Badge, dll
│   │   │   └── components/                 ← DataTable, FormCard, dll
│   │   │
│   │   └── features/                       ← satu folder per domain/fitur
│   │       ├── auth/
│   │       │   ├── presentation/
│   │       │   ├── providers/
│   │       │   └── repositories/
│   │       ├── dashboard/
│   │       ├── mahasiswa/
│   │       ├── dosen/
│   │       ├── admin/
│   │       ├── krs/
│   │       ├── jadwal/
│   │       ├── nilai/
│   │       ├── presensi/
│   │       └── profile/
│   │
│   ├── android/
│   ├── windows/
│   ├── web/
│   ├── test/
│   └── pubspec.yaml
│
├── backend/
│   │
│   ├── sia_backend_core/                   ← Dart package: business logic bersama
│   │   ├── lib/
│   │   │   ├── services/                   ← auth, krs, nilai, jadwal, presensi
│   │   │   │   ├── auth_service.dart
│   │   │   │   ├── krs_service.dart
│   │   │   │   ├── nilai_service.dart
│   │   │   │   ├── jadwal_service.dart
│   │   │   │   └── presensi_service.dart
│   │   │   ├── repositories/              ← abstraksi akses data ke Supabase
│   │   │   ├── models/                    ← domain model / entity
│   │   │   ├── exceptions/               ← custom error/failure types
│   │   │   └── supabase_client.dart      ← singleton Supabase client
│   │   └── pubspec.yaml
│   │
│   ├── isolate_entry/                      ← entry point Dart Isolate (mobile/desktop)
│   │   ├── lib/
│   │   │   ├── isolate_handler.dart        ← message dispatcher
│   │   │   └── message_protocol.dart       ← kontrak IsolateRequest / IsolateResponse
│   │   └── pubspec.yaml
│   │
│   └── web_server/                         ← dart_frog project (web, localhost)
│       ├── routes/
│       │   ├── auth/
│       │   ├── krs/
│       │   ├── nilai/
│       │   ├── jadwal/
│       │   └── presensi/
│       ├── middleware/
│       └── pubspec.yaml
│
├── database/
│   ├── migrations/                         ← SQL sequential, version-controlled
│   │   ├── 001_create_users.sql
│   │   ├── 002_create_students.sql
│   │   ├── 003_create_lecturers.sql
│   │   ├── 004_create_study_programs.sql
│   │   ├── 005_create_courses.sql
│   │   ├── 006_create_curriculums.sql
│   │   ├── 007_create_classes.sql
│   │   ├── 008_create_enrollments.sql
│   │   ├── 009_create_grades.sql
│   │   ├── 010_create_attendance.sql
│   │   ├── 011_create_audit_logs.sql
│   │   └── 012_setup_rls_policies.sql
│   │
│   └── seed/                               ← data dummy realistis untuk dev/demo
│       ├── seed_users.sql
│       ├── seed_academic_data.sql
│       └── README.md
│
├── docs/
│   ├── ARCHITECTURE.md                     ← dokumen ini
│   ├── database.md                         ← ERD, skema tabel, relasi
│   ├── security.md                         ← RLS policy, auth flow, credential policy
│   ├── roles-permissions.md               ← matriks role & permission
│   └── api.md                             ← kontrak API (IPC protocol & HTTP web)
│
├── .github/
│   └── workflows/
│       ├── flutter_test.yml
│       └── dart_analyze.yml
│
└── README.md                               ← onboarding, cara menjalankan project
```

---

## 4. Penjelasan Setiap Komponen

### `frontend/`

Flutter project tunggal yang menghasilkan tiga artefak distribusi dari satu codebase:

| Target   | Build Command                       | Output                            |
|----------|-------------------------------------|-----------------------------------|
| Android  | `flutter build apk --release`       | `app-release.apk`                 |
| Windows  | `flutter build windows --release`   | folder exe + DLL → dibundel jadi installer |
| Web      | `flutter build web`                 | folder `build/web/`               |

**Prinsip internal:**
- Flutter hanya menangani **presentation, interaction, state, navigation**.
- Tidak memanggil Supabase langsung dari widget.
- Seluruh data access dimediasi melalui Repository → Backend Layer.

---

### `backend/sia_backend_core/`

Package Dart murni yang berisi seluruh business logic. Tidak bergantung pada framework Flutter.

**Digunakan oleh dua konsumen:**
1. `isolate_entry/` — di-import dan dijalankan dalam Dart Isolate (mobile/desktop).
2. `web_server/` — di-import dan dipanggil oleh route handler `dart_frog` (web).

> Business logic **ditulis sekali**, dipakai dua jalur — tidak ada duplikasi implementasi.

---

### `backend/isolate_entry/`

Entry point yang di-spawn oleh Flutter sebagai Dart Isolate saat aplikasi mobile/desktop berjalan.

- Menerima pesan dari main isolate via `ReceivePort`.
- Mendispatch ke service yang tepat dari `sia_backend_core`.
- Mengirim response balik via `SendPort`.
- **Tidak membuka HTTP port** — komunikasi sepenuhnya in-process.

---

### `backend/web_server/`

Dart server menggunakan `dart_frog`, berjalan di `localhost:8080` saat development dan presentasi web.

- Route handler memanggil service dari `sia_backend_core`.
- Flutter Web berkomunikasi dengan server ini via HTTP ke localhost.
- Untuk production, server ini dapat di-deploy ke platform seperti Fly.io, Railway, atau Render.

---

### `database/`

Migration SQL dan seed data dikelola terpisah dari kode aplikasi agar evolusi skema database
tetap eksplisit dan version-controlled.

- **`migrations/`** — file SQL sequential, satu migration per operasi schema.
- **`seed/`** — data dummy realistis untuk development dan demo.

---

## 5. Arsitektur Frontend — Flutter

### Pola Alur Data per Fitur

```
Widget / Page
      ↓
Provider / Controller     (Riverpod — mengelola state: loading, data, error)
      ↓
Repository                (interface — abstraksi sumber data)
      ↓
Backend Channel           (Isolate IPC  |  HTTP ke Dart server)
      ↓
sia_backend_core          (business logic, validasi, rules, authorization check)
      ↓
Supabase Client           (query via PostgREST + Auth)
      ↓
PostgreSQL
```

### Responsive Layout

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600)  return const MobileLayout();
    if (constraints.maxWidth < 1024) return const TabletLayout();
    return const DesktopLayout();
  },
);
```

| Breakpoint      | Target                                           |
|-----------------|--------------------------------------------------|
| `< 600 px`      | Android phone, browser viewport mobile           |
| `600–1023 px`   | Android tablet, browser viewport tablet          |
| `>= 1024 px`    | Flutter Web desktop, Windows desktop             |

### Routing per Role (GoRouter)

```
/login

/admin
  /admin/users
  /admin/mahasiswa
  /admin/dosen
  /admin/mata-kuliah
  /admin/kurikulum
  /admin/jadwal
  /admin/periode-akademik

/dosen
  /dosen/kelas
  /dosen/nilai
  /dosen/presensi

/mahasiswa
  /mahasiswa/krs
  /mahasiswa/jadwal
  /mahasiswa/nilai
  /mahasiswa/presensi
  /mahasiswa/profil
```

> **Catatan:** Route guard di Flutter hanya mengontrol navigasi UI.
> Authorization final tetap ditegakkan di sisi RLS Supabase.

---

## 6. Arsitektur Backend / Business Layer — Dart

### Package `sia_backend_core` — Shared Business Logic

```
sia_backend_core/lib/
├── services/
│   ├── auth_service.dart         ← login, logout, refresh session
│   ├── krs_service.dart          ← ambil KRS, validasi beban SKS, submit KRS
│   ├── nilai_service.dart        ← input nilai, validasi kewenangan dosen
│   ├── jadwal_service.dart       ← query jadwal kelas, jadwal mengajar dosen
│   └── presensi_service.dart     ← rekap presensi, update kehadiran
│
├── repositories/
│   ├── user_repository.dart
│   ├── student_repository.dart
│   ├── course_repository.dart
│   ├── class_repository.dart
│   └── grade_repository.dart
│
├── models/
│   ├── user.dart
│   ├── student.dart
│   ├── lecturer.dart
│   ├── course.dart
│   ├── enrollment.dart
│   ├── grade.dart
│   └── attendance.dart
│
├── exceptions/
│   ├── auth_exception.dart
│   ├── validation_exception.dart
│   └── permission_exception.dart
│
└── supabase_client.dart          ← singleton Supabase client, config dari env/constants
```

### Jalur Mobile / Desktop — Dart Isolate

```
main.dart (Flutter — main isolate)
  │
  ├── Isolate.spawn(isolateEntryPoint, receivePort.sendPort)
  │
  └── main isolate  ←── SendPort / ReceivePort ──→  backend isolate
                                                          │
                                                   sia_backend_core
                                                          │
                                                      Supabase
```

**Protokol pesan IPC (kontrak `message_protocol.dart`):**

```dart
// Request dari main isolate ke backend isolate
class IsolateRequest {
  final String action;              // e.g. 'krs.getByStudent', 'nilai.submit'
  final Map<String, dynamic> payload;
  final String requestId;           // untuk matching async response
}

// Response dari backend isolate ke main isolate
class IsolateResponse {
  final String requestId;
  final bool success;
  final dynamic data;
  final String? errorCode;
  final String? errorMessage;
}
```

### Jalur Web — Dart Server (dart_frog)

```
Flutter Web  →  HTTP (Dio)  →  localhost:8080
                                    │
                             dart_frog Route Handler
                                    │
                             sia_backend_core Service
                                    │
                               Supabase (HTTPS)
                                    │
                               PostgreSQL
```

Route handler memanggil `KrsService`, `NilaiService`, dll dari `sia_backend_core` — **identik**
dengan yang berjalan di Isolate. Perbedaannya hanya di lapisan transport.

---

## 7. Arsitektur Database

### Platform & Hosting

| Komponen         | Teknologi              |
|------------------|------------------------|
| Database Engine  | PostgreSQL             |
| Hosting          | Supabase               |
| Authentication   | Supabase Auth          |
| Authorization    | Row Level Security (RLS) |
| API Layer        | PostgREST (via Supabase) |

### Relasi Entity Utama

```
users  (Supabase Auth + profil)
  ├── students            ← data spesifik mahasiswa
  └── lecturers           ← data spesifik dosen

study_programs
  ├── students
  └── lecturers

academic_periods          ← semester / tahun akademik

courses                   ← mata kuliah
curriculums               ← kurikulum per program studi
curriculum_courses        ← pivot: kurikulum ↔ mata kuliah

classes                   ← kelas mata kuliah per semester
  ├── class_lecturers     ← dosen pengampu
  ├── class_schedules     ← jadwal & ruangan
  └── enrollments (KRS)  ← mahasiswa terdaftar

enrollments
  ├── grades              ← nilai per mahasiswa per kelas
  └── attendance          ← header presensi

attendance_records        ← detail kehadiran per pertemuan

rooms                     ← ruang kuliah

audit_logs                ← log event penting: submit KRS, input nilai, dll
```

### Migration Strategy

Setiap migration file:
- Diberi nomor urut prefix (`001_`, `002_`, dst.) agar urutan eksekusi deterministik.
- Berisi satu operasi logis (`CREATE TABLE`, `ALTER TABLE`, atau `CREATE POLICY`).
- Dijalankan melalui Supabase CLI (`supabase db push`) atau Supabase Dashboard.

---

## 8. Alur Komunikasi Antar Layer

### Android / Windows — End-to-End

```
User Action (tap/klik)
       ↓
   Flutter Widget
       ↓
   Riverpod Provider          state: loading
       ↓
   Repository.fetchData()
       ↓
   IsolateChannel.send()      [IsolateRequest via SendPort]
       ↓                      ── in-process, tanpa network lokal ──
   Backend Isolate
       ↓
   sia_backend_core Service
       ↓
   Supabase Client            HTTPS → Supabase cloud
       ↓
   PostgreSQL                 RLS diterapkan
       ↓
   data response
       ↓                      ── ReceivePort, balik ke main isolate ──
   Repository                 parse IsolateResponse
       ↓
   Riverpod Provider          state: data / error
       ↓
   Widget rebuild
```

### Web — End-to-End

```
User Action
       ↓
   Flutter Widget
       ↓
   Riverpod Provider          state: loading
       ↓
   Repository.fetchData()
       ↓
   Dio HTTP Client            GET/POST → localhost:8080
       ↓                      ── HTTP lokal ──
   dart_frog Route Handler
       ↓
   sia_backend_core Service
       ↓
   Supabase Client            HTTPS → Supabase cloud
       ↓
   PostgreSQL                 RLS diterapkan
       ↓
   JSON response
       ↓
   Repository                 parse
       ↓
   Riverpod Provider          state: data / error
       ↓
   Widget rebuild
```

---

## 9. Keamanan & Authorization

### Prinsip Utama

```
Client (Flutter + Dart Isolate / Dart Server)
   │  ← TIDAK DIPERCAYA sebagai trusted boundary
   ↓
Supabase Auth  →  JWT (berisi role claim)
   ↓
Supabase API (PostgREST)
   ↓
Row Level Security (RLS)  ← authorization final ada di sini
   ↓
PostgreSQL
```

### Credential Policy

| Item                           | Status                                       |
|--------------------------------|----------------------------------------------|
| PostgreSQL password            | ❌ Tidak boleh ada di APK / installer         |
| Supabase service key (secret)  | ❌ Tidak boleh ada di APK / installer         |
| Supabase anon key (public)     | ✅ Aman untuk distribusi client               |
| JWT dari Supabase Auth         | ✅ Disimpan di secure storage device          |

### Contoh RLS

```sql
-- Mahasiswa hanya dapat membaca enrollment miliknya sendiri
CREATE POLICY "mahasiswa_read_own_enrollment"
ON enrollments FOR SELECT
USING (
  student_id = (
    SELECT id FROM students WHERE user_id = auth.uid()
  )
);

-- Dosen hanya dapat update nilai untuk kelas yang diampu
CREATE POLICY "dosen_update_own_class_grades"
ON grades FOR UPDATE
USING (
  class_id IN (
    SELECT class_id FROM class_lecturers
    WHERE lecturer_id = (
      SELECT id FROM lecturers WHERE user_id = auth.uid()
    )
  )
);
```

### Audit Log

Tabel `audit_logs` mencatat event penting:

| Action                    | Keterangan                            |
|---------------------------|---------------------------------------|
| `ADMIN_CREATED_STUDENT`   | Admin membuat akun mahasiswa baru     |
| `ADMIN_UPDATED_COURSE`    | Admin mengubah data mata kuliah       |
| `DOSEN_SUBMITTED_GRADE`   | Dosen menginput nilai akhir           |
| `DOSEN_UPDATED_ATTENDANCE`| Dosen mengubah data presensi          |
| `STUDENT_SUBMITTED_KRS`   | Mahasiswa mengajukan KRS              |
| `ADMIN_CHANGED_USER_ROLE` | Admin mengubah role pengguna          |

---

## 10. Distribusi & Deployment

### Android

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

APK berisi: Flutter UI + Dart Isolate business layer (embedded).
**Tidak memerlukan:** Docker, backend server terpisah, PostgreSQL lokal.

### Windows

```bash
flutter build windows --release
# Bundel dengan Inno Setup atau:
flutter pub add msix && flutter pub run msix:create
```

### Web — Development & Presentasi (dua proses bersamaan)

```bash
# Terminal 1 — backend (business layer)
cd backend/web_server
dart_frog dev
# → localhost:8080

# Terminal 2 — frontend
cd frontend
flutter run -d chrome
# → localhost:<random_port>, memanggil backend di :8080
```

### Web — Production (Opsional)

| Komponen     | Hosting yang Direkomendasikan           |
|--------------|-----------------------------------------|
| Flutter Web  | Vercel, Netlify, Firebase Hosting       |
| Dart Server  | Fly.io, Railway, Render                 |

---

## 11. Dependency & Tech Stack

| Layer               | Teknologi                          | Keterangan                                  |
|---------------------|------------------------------------|---------------------------------------------|
| UI Framework        | Flutter (Dart)                     | Android, Web, Windows dari satu codebase    |
| State Management    | Riverpod                           | Reactive state, dependency injection        |
| Routing             | GoRouter                           | Declarative routing, route guard per role   |
| HTTP Client         | Dio / http                         | Flutter Web → Dart server lokal             |
| Backend Framework   | dart_frog                          | Dart server untuk jalur web                 |
| Business Logic      | sia_backend_core (Dart package)    | Shared, tidak bergantung Flutter            |
| IPC (mobile/desktop)| Dart Isolate (SendPort/ReceivePort)| In-process, tanpa overhead HTTP lokal       |
| Database            | PostgreSQL                         | Relational, cloud-hosted                    |
| DB Hosting          | Supabase                           | Auth, API, RLS, Dashboard, free tier        |
| Authentication      | Supabase Auth                      | JWT, session, refresh token                 |
| Authorization       | Row Level Security (RLS)           | Policy di level database, tidak di client   |
| Packaging Android   | Flutter APK                        | Single APK                                  |
| Packaging Windows   | MSIX / Inno Setup                  | Single installer                            |

---

## 12. Keputusan Arsitektur (ADR)

### ADR-001 — Monorepo

**Keputusan:** Seluruh kode (frontend, backend, database, docs) dalam satu repositori.

**Alasan:**
- Tim kecil (solo / tim kecil) — monorepo jauh lebih sederhana dari multi-repo.
- `sia_backend_core` di-consume oleh `isolate_entry` dan `web_server` — path dependency lokal
  lebih mudah dikelola dalam satu repo.
- Satu `git log`, satu PR, satu pipeline CI.
- Perubahan lintas komponen dapat di-commit secara atomik.

---

### ADR-002 — Dart sebagai Bahasa Backend

**Keputusan:** Gunakan Dart (bukan Go / Rust / Node.js) untuk business layer.

**Alasan:**
- Eliminasi FFI / cross-compilation — tidak ada native library per ABI.
- Beban kerja SIA bersifat I/O-bound — selisih performa mentah antar bahasa tidak terasa
  pada skala ini; bottleneck ada di latency jaringan ke Supabase.
- Satu bahasa dari UI hingga business layer — debugging, stack trace, dan tooling konsisten.
- Waktu development jauh lebih singkat untuk skala proyek mahasiswa.

---

### ADR-003 — Dart Isolate (bukan HTTP server lokal) untuk Mobile/Desktop

**Keputusan:** Business logic di mobile/desktop dijalankan sebagai Dart Isolate, bukan server localhost.

**Alasan:**
- Tidak membuka port jaringan di device — lebih aman.
- Tidak memerlukan instalasi runtime tambahan oleh pengguna.
- Komunikasi in-process lebih efisien dari HTTP lokal.
- APK / installer tetap satu file; user experience install-and-run terjaga penuh.

---

### ADR-004 — Supabase sebagai Database Platform

**Keputusan:** Gunakan Supabase (PostgreSQL hosted) sebagai satu-satunya database.

**Alasan:**
- PostgreSQL sangat cocok untuk data relasional SIA (foreign key, constraint, agregasi, reporting).
- Free tier cukup untuk skala demo / development.
- Auth, RLS, API layer, dan dashboard tersedia — mengurangi infrastruktur yang harus dikelola.
- Tidak perlu mengelola PostgreSQL server sendiri.

---

### ADR-005 — Modular Monolith (bukan Microservices)

**Keputusan:** Gunakan arsitektur Modular Monolith, bukan Microservices.

**Alasan:**
- Microservices menambah kompleksitas orkestrasi yang tidak sepadan dengan skala proyek ini.
- Modular Monolith memberikan pemisahan concern yang cukup jelas (per feature / domain)
  tanpa overhead deployment terpisah.
- Sesuai tujuan: proyek serius namun tetap sederhana untuk tim kecil.

---

### ADR-006 — Tidak Ada Local Database sebagai Database Utama

**Keputusan:** SQLite tidak digunakan sebagai database utama.

**Alasan:**
- Data akademik harus terpusat — semua device mengakses data yang sama.
- SQLite hanya dapat dipertimbangkan sebagai local cache / offline cache di masa depan,
  apabila fitur tersebut memang dibutuhkan.

---

*Dokumen ini adalah living document. Perbarui setiap kali ada keputusan arsitektur baru
atau perubahan signifikan pada struktur proyek.*