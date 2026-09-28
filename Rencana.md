Sistem Informasi Akademik (SIA)

---

1. Gambaran Umum

Proyek ini adalah Sistem Informasi Akademik (SIA), aplikasi akademik terpusat dengan dukungan beberapa jenis pengguna:

- Admin
- Dosen
- Mahasiswa
- Opsional: Kaprodi / role akademik tambahan

Aplikasi dapat digunakan dari:

- Android
- Web
- Windows

Frontend menggunakan Flutter untuk seluruh platform. Backend/business logic menggunakan Dart, dijalankan secara embedded (bukan HTTP server terpisah) untuk mobile dan desktop. Database menggunakan PostgreSQL terkelola melalui Supabase.

Karakteristik utama sistem:

- Satu sumber data terpusat
- Multi-role
- Authentication dan authorization
- Business logic terstruktur, terpisah dari UI
- Responsive/adaptive UI
- Mobile, Web, dan Windows dari satu basis kode Flutter
- Satu bahasa (Dart) untuk frontend maupun backend/business layer
- Tidak membutuhkan database lokal sebagai database utama
- Mobile application didistribusikan sebagai satu APK
- Windows didistribusikan sebagai satu installer
- Aplikasi membutuhkan koneksi internet untuk mengakses data akademik cloud

---

2. Tujuan Arsitektur

1. Tetap sederhana untuk dikembangkan sebagai proyek mahasiswa, idealnya solo/tim kecil.
1. Memiliki struktur yang cukup serius untuk dipresentasikan sebagai software engineering project.
1. Memiliki database terpusat sehingga seluruh device menggunakan data yang sama.
1. Tidak mengharuskan pengguna meng-install backend secara manual.
1. Mobile didistribusikan sebagai satu APK, Windows sebagai satu installer.
1. Web dan Windows dibuild dari basis kode Flutter yang sama.
1. Business logic tidak bercampur dengan widget/UI Flutter.
1. Database tidak pernah diakses menggunakan credential privileged yang ditanam langsung dalam APK/installer.
1. Menghindari kompleksitas teknis yang tidak sepadan dengan manfaatnya (FFI lintas bahasa, native cross-compilation) selama beban kerja aplikasi bersifat I/O-bound, bukan CPU-bound.

---

3. Keputusan Teknologi Utama

Frontend

Flutter (Dart)

Target: Android, Web, Windows.

Keuntungan:

- Satu codebase utama
- Responsive/adaptive UI
- Komponen UI dapat digunakan lintas platform
- Sangat sesuai untuk aplikasi akademik dengan banyak form, tabel, dashboard, dan navigation flow

Backend / Business Layer

Dart (Isolate untuk mobile & desktop, server Dart untuk web development)

Alasan memilih Dart dibanding Go/Rust/Node.js sebagai bahasa backend:

- Satu bahasa untuk seluruh stack — tidak butuh FFI, native binding, atau cross-compilation per platform
- Beban kerja SIA bersifat I/O-bound (query, validasi, panggil Supabase), bukan CPU-bound — perbedaan performa mentah antar bahasa tidak terasa secara praktis pada skala proyek ini
- Waktu development jauh lebih singkat dan risiko kegagalan teknis jauh lebih rendah dibanding pendekatan native embedded (Go/Rust)
- Stack trace dan debugging konsisten satu bahasa dari UI sampai business logic
- Tetap mendapat pemisahan business logic dari UI tanpa kompleksitas boundary bahasa

Database

PostgreSQL, di-host melalui Supabase.

Tech Stack Lanjutan

-
-
- ***

4. Responsive Design

UI dibagi menjadi tiga kategori: Mobile, Tablet, Desktop.

Breakpoint awal:

< 600 px → Mobile
600–1023 px → Tablet

> = 1024 px → Desktop

Desktop layout digunakan untuk Flutter Web desktop dan Windows dekstop.
Mobile layout digunakan untuk Android phone dan browser viewport mobile.
Tablet layout menangani Android tablet, browser viewport tablet, dan ukuran intermediate lainnya.

Contoh konsep:

LayoutBuilder(
builder: (context, constraints) {
if (constraints.maxWidth < 600) {
return const MobileLayout();
}

    if (constraints.maxWidth < 1024) {
      return const TabletLayout();
    }

    return const DesktopLayout();

},
);

Breakpoint adalah starting point, bukan angka sakral. Layout mengikuti kebutuhan komponen.

---

5. Embedded Backend (Dart Isolate)

Keputusan utama

Untuk mobile dan desktop, proyek menggunakan konsep:

Flutter

- Dart Isolate (Embedded Backend / Business Layer)
- Supabase

Backend tidak berjalan sebagai HTTP server lokal yang membuka port seperti localhost:8080. Business logic dijalankan sebagai Isolate — thread terpisah dalam proses Dart VM yang sama dengan Flutter, berkomunikasi lewat message passing (SendPort/ReceivePort), bukan HTTP request.

Konsep mobile/desktop:

APK / Installer
├── Flutter (main isolate)
└── Backend Isolate (business logic)
│
│ SendPort / ReceivePort (dalam proses yang sama)
▼
Backend Isolate memanggil Supabase
│
▼
Internet
│
▼
Supabase
│
▼
PostgreSQL

Dengan demikian, ketika aplikasi didistribusikan:

User
↓
Install APK / Installer
↓
Jalankan aplikasi
↓
Login
↓
Internet
↓
Akses Supabase

Tidak diperlukan:

Instalasi bahasa/runtime tambahan oleh user
Docker installation
Local PostgreSQL
VPS milik pengguna
Laptop sebagai server (untuk mobile/desktop)

---

6. Web: Server Dart di Localhost (Development & Presentasi)

Karena browser tidak mendukung Isolate native dengan model yang sama seperti Dart VM di mobile/desktop, business layer untuk Flutter Web dijalankan sebagai server Dart terpisah menggunakan dart_frog (atau shelf), diakses melalui localhost saat development maupun presentasi.

Flutter Web
│ HTTPS ke localhost
▼
Dart Server (dart_frog) — localhost
│ HTTPS
▼
Supabase
│
▼
PostgreSQL

Alur presentasi web (dua proses berjalan bersamaan):

Terminal 1: dart_frog dev → localhost:8080 (backend)
Terminal 2: flutter run -d chrome → localhost:xxxxx (frontend, memanggil backend di :8080)

Business logic yang ditulis untuk server Dart ini menggunakan kode/struktur yang sama (shared package) dengan logic yang dijalankan di Dart Isolate pada mobile/desktop, untuk menghindari duplikasi implementasi.

---

7. Backend Tidak Berarti Database Berada di Device

Backend/logic dan database adalah dua hal berbeda. Database tetap berada di cloud (Supabase/PostgreSQL) untuk seluruh platform.

┌──────────────── APK / Installer ────────────────┐
│ │
│ Flutter (main isolate) │
│ │
│ Dart Isolate (Embedded Backend / Business Layer)│
│ │
└─────────────────────┬────────────────────────────┘
│
│ HTTPS / Internet
▼
┌───────────────┐
│ Supabase │
│ PostgreSQL DB │
└───────────────┘

HP A dan HP B mengakses database yang sama:

HP A ─────┐
│
├──── Internet ──── Supabase PostgreSQL
│
HP B ─────┘

Bukan:

HP A → Database A
HP B → Database B

---

8. Mengapa Supabase

Database utama: PostgreSQL, hosted menggunakan Supabase.

Alasan:

- PostgreSQL relational sangat cocok untuk SIA dengan banyak relasi antar entitas
- Free tier cukup untuk data development/demo berskala kecil
- Dashboard database memudahkan development
- Authentication tersedia
- Row Level Security tersedia
- API layer tersedia
- Tidak perlu mengelola PostgreSQL server sendiri

Estimasi data untuk project development:

Admin : 2–3 user
Dosen : 2–3 user
Mahasiswa : 2–3 user
Role lain : 2–3 user

Ditambah data dummy: Mahasiswa, Dosen, Program Studi, Mata Kuliah, Kurikulum, Kelas, KRS, Jadwal, Nilai, Presensi, Academic Period, dan sebagainya.

Storage database bukan perhatian utama. Yang lebih penting: free-tier compute limitation, connection limits, pause/sleep behavior, authentication, security rules, backup/recovery, availability saat demo.

---

9. Mengapa PostgreSQL

SIA memiliki struktur data yang sangat relational.

Program Studi
│
▼
Mahasiswa
│
▼
KRS
│
▼
Mata Kuliah
│
▼
Kelas
│
▼
Jadwal
│
▼
Presensi

PostgreSQL cocok untuk: foreign key, transaction, constraint, indexing, relational queries, aggregation, consistency, reporting akademik.

SQLite tidak digunakan sebagai database utama. SQLite hanya mungkin digunakan kemudian sebagai local cache, offline cache, atau temporary storage, jika fitur tersebut memang dibutuhkan.

---

10. Perbandingan Performa & Pertimbangan Bahasa Backend

Beban kerja SIA (KRS, nilai, presensi, jadwal) bersifat I/O-bound — mayoritas waktu dihabiskan menunggu response Supabase (network call), bukan komputasi berat lokal. Perbandingan berikut menjadi dasar keputusan memilih Dart:

Aspek | Dart Isolate | Go (native lib) | Rust (native lib) | Node.js embedded
Startup time | Sangat cepat | Cepat | Sangat cepat | Lambat
Memory footprint | Sedang | Rendah | Paling rendah | Tinggi
CPU-intensive tasks | Sedang | Baik | Terbaik | Kurang cocok
Concurrency I/O (query DB, HTTP) | Baik | Sangat baik | Sangat baik | Baik
Ukuran tambahan ke bundle | Nol tambahan | +beberapa MB per ABI | +beberapa MB per ABI | +puluhan MB
Battery impact (mobile) | Rendah | Rendah | Paling rendah | Tinggi
Waktu development (solo/tim kecil) | Tercepat | Sedang | Paling lambat | Sedang
Risiko kegagalan teknis (FFI/WASM) | Rendah | Sedang | Tinggi | Rendah (tapi jarang dipakai mobile)
Kemudahan debug lintas layer | Mudah | Sulit | Sulit | Mudah

Kesimpulan: untuk skala SIA sebagai proyek mahasiswa dengan beban kerja I/O-bound, selisih performa mentah antar bahasa backend tidak terasa di real-world usage. Bottleneck utama tetap berada pada latency jaringan ke Supabase, bukan kecepatan eksekusi bahasa. Dart dipilih karena menghilangkan kompleksitas FFI/cross-compilation sambil tetap mempertahankan pemisahan business logic dari UI.

Rust/Go akan lebih unggul hanya jika muncul kebutuhan komputasi berat di lokal (enkripsi kompleks, constraint solving untuk generate jadwal otomatis, pemrosesan data besar) — belum menjadi kebutuhan pada cakupan SIA saat ini.

---

11. Catatan Keamanan Embedded Backend

Embedded logic tidak boleh dianggap sebagai trusted server. Seluruh isi APK/installer pada dasarnya dapat dianalisis oleh pihak yang memiliki filenya.

Karena itu, jangan pernah menyimpan di dalam APK/installer:

- PostgreSQL password
- Supabase secret/service key
- Privileged server credential

Yang digunakan aplikasi harus berupa credential/client key yang memang aman untuk distribusi client, dengan authorization tetap ditegakkan di sisi Supabase.

Prinsip keamanan:

APK / Installer
↓
Authentication
↓
Session/JWT
↓
Supabase API
↓
RLS
↓
PostgreSQL

Contoh: Mahasiswa A harus hanya dapat membaca data akademiknya sendiri. Mahasiswa tidak boleh dapat UPDATE nilai mahasiswa lain, DELETE KRS mahasiswa lain, membaca data admin, atau mengambil data dosen yang tidak diperlukan — walaupun request dimanipulasi dari client.

Authorization dilakukan di sisi backend/cloud/database policy (RLS), bukan hanya menyembunyikan tombol di UI:

if (role == 'mahasiswa') {
hideAdminButton();
}

Menyembunyikan tombol bukan security. Itu hanya menyembunyikan tombol.

---

12. Role-Based Access Control

Role awal: ADMIN, DOSEN, MAHASISWA.
Role opsional: KAPRODI.

Admin dapat mengelola: Mahasiswa, Dosen, Program studi, Mata kuliah, Kurikulum, Kelas, Jadwal, Academic period, User, Data akademik.

Dosen dapat: melihat kelas yang diampu, melihat mahasiswa dalam kelas, mengelola presensi, input/update nilai sesuai kewenangan, melihat jadwal mengajar.

Mahasiswa dapat: melihat profil, melihat KRS, mengambil KRS sesuai periode, melihat jadwal, melihat nilai, melihat presensi, melihat informasi akademik.

Kaprodi dapat diberikan permission administratif terbatas terhadap: Program studi, Kurikulum, Mata kuliah, Kelas, Dosen, Monitoring akademik.

---

13. Database Modeling Awal

Struktur utama: users, roles, students, lecturers, study_programs, academic_periods, courses, curriculums, curriculum_courses, classes, class_lecturers, class_schedules, rooms, enrollments/krs, grades, attendance, attendance_records, audit_logs.

Contoh relasi:

users
│
├──── students
│
└──── lecturers

study_programs
│
├──── students
└──── lecturers

courses
│
└──── curriculum_courses

curriculums
│
└──── curriculum_courses

classes
│
├──── course
├──── lecturer
├──── schedule
└──── KRS/enrollment

students
│
├──── KRS
├──── grades
└──── attendance

Database menggunakan: primary key, foreign key, unique constraint, check constraint jika relevan, index, migration.

---

14. Authentication

Menggunakan Email/Username + Password atau mekanisme login yang disediakan Supabase.

Session: Access Token + Refresh Token.

Flow:

Flutter
↓
Login
↓
Supabase Auth
↓
Session/JWT
↓
Flutter
↓
Request data (via Dart Isolate / Dart server untuk web)
↓
Authorization/RLS

Password tidak disimpan plaintext.

---

15. Audit Log

Tabel audit_logs untuk mencatat event penting:

ADMIN_CREATED_STUDENT
ADMIN_UPDATED_COURSE
DOSEN_SUBMITTED_GRADE
DOSEN_UPDATED_ATTENDANCE
STUDENT_SUBMITTED_KRS
ADMIN_CHANGED_USER_ROLE

Informasi minimal: id, user_id, action, entity, entity_id, metadata, created_at.

Audit log berguna untuk: debugging, keamanan, accountability, demonstrasi fitur enterprise.

---

16. Flutter Architecture

Project dibagi berdasarkan feature:

lib/
├── app/
│ ├── app.dart
│ ├── router.dart
│ └── theme.dart
│
├── core/
│ ├── network/
│ ├── storage/
│ ├── error/
│ └── utils/
│
├── shared/
│ ├── widgets/
│ └── components/
│
└── features/
├── auth/
├── dashboard/
├── mahasiswa/
├── dosen/
├── admin/
├── akademik/
├── krs/
├── jadwal/
├── nilai/
├── presensi/
└── profile/

Feature tidak langsung melakukan query database. Pola:

Page
↓
State / ViewModel
↓
Use Case / Service
↓
Repository
↓
Backend Isolate / Dart Server (Business Logic)
↓
Supabase

Contoh:

KRSPage
↓
KRSController
↓
KRSRepository
↓
Backend Isolate (validasi & business rule)
↓
Supabase
↓
PostgreSQL

---

17. Struktur Kode Backend (Shared antara Isolate dan Server Web)

Business logic ditulis sebagai package Dart murni yang dapat dipakai ulang, tanpa duplikasi, oleh:

- Dart Isolate (mobile & desktop)
- Dart Server / dart_frog (web, localhost)

packages/
└── sia_backend_core/
├── lib/
│ ├── services/
│ │ ├── auth_service.dart
│ │ ├── krs_service.dart
│ │ ├── nilai_service.dart
│ │ ├── jadwal_service.dart
│ │ └── presensi_service.dart
│ ├── repositories/
│ ├── models/
│ └── supabase_client.dart
└── pubspec.yaml

Isolate entry point dan Dart server (dart_frog route handler) sama-sama memanggil service dari package sia_backend_core ini — perbedaannya hanya di lapisan transport (message passing vs HTTP).

---

18. State Management

Riverpod menangani: authentication state, user session, loading state, error state, fetched data, reactive UI.

---

19. Routing

Menggunakan Router. Route dapat dipisahkan berdasarkan role:

/login

/admin
/admin/users
/admin/mahasiswa
/admin/dosen
/admin/mata-kuliah

/dosen
/dosen/kelas
/dosen/nilai
/dosen/presensi

/mahasiswa
/mahasiswa/krs
/mahasiswa/jadwal
/mahasiswa/nilai

Protection tidak berhenti pada routing Flutter. Database/security layer (RLS) tetap memastikan authorization.

---

20. Komunikasi Flutter ↔ Backend

Mobile/Desktop (Isolate):

Flutter (main isolate)
↓ SendPort/ReceivePort
Dart Isolate (business layer, package sia_backend_core)
↓ HTTPS
Supabase

Web (Dart server, localhost):

Flutter Web
↓ HTTPS (localhost saat dev/presentasi)
Dart Server / dart_frog (business layer, package sia_backend_core)
↓ HTTPS
Supabase

---

21. Development Environment

Development awal:

Flutter
↓
Local development
↓
Backend Isolate / Dart Server
↓
Supabase
↓
PostgreSQL

Database dikembangkan menggunakan: Supabase dashboard, migration files, SQL migration, local Supabase/PostgreSQL untuk testing bila diperlukan.

Tidak ada kewajiban menjalankan database production di laptop.

Menjalankan project untuk development:

Web:
flutter run -d chrome # buka otomatis di localhost, hot reload
flutter run -d web-server --web-port=8080

Backend Dart untuk web:
dart_frog dev # localhost:8080

Mobile/Desktop (embedded, tidak perlu perintah backend terpisah):
flutter run -d <device>

---

22. Production / Distribusi Mobile

Build:

flutter build apk --release

Output: app-release.apk

APK berisi:

Flutter application

- Dart Isolate (embedded business layer)

Device cukup:

Install APK
↓
Internet
↓
Supabase
↓
PostgreSQL

Tidak perlu: backend installation, Docker, PostgreSQL installation, localhost.

---

23. Production / Distribusi Windows

Build:

flutter build windows --release

Output berupa folder (exe + DLL Flutter engine). Untuk menjadi satu file installer:

- Inno Setup — membuat script .iss yang mem-package seluruh folder menjadi satu setup.exe
- Atau MSIX package:
  flutter pub add msix
  flutter pub run msix:create

Installer berisi:

Flutter application (Windows)

- Dart Isolate (embedded business layer)

Desktop layout menggunakan DesktopLayout, dapat menggunakan desain visual serupa dengan Web Desktop karena keduanya memiliki area layar besar.

---

24. Web

Web tetap menggunakan Flutter Web.

Development & presentasi: localhost (Flutter Web + Dart server dart_frog, dua proses/dua port berjalan bersamaan).

Production nantinya dapat menggunakan static hosting untuk Flutter Web, dan hosting terpisah (misal Fly.io/Railway/Render) untuk Dart server jika business layer web perlu diakses tanpa localhost.

Flutter Web
│
▼
Dart Server (dart_frog)
│
▼
Supabase
│
▼
PostgreSQL

---

25. Presentasi

Mobile dan Windows: karena database berada di cloud dan backend embedded dalam aplikasi, device tidak harus terhubung ke laptop presenter. HP/Windows bisa menggunakan Wi-Fi kampus, Wi-Fi rumah, hotspot, atau mobile data, selama koneksi internet tersedia.

Internet
│
┌───┼───┐
│ │ │
HP Windows
│ │ │
└───┼───┘
│
Supabase
│
PostgreSQL

Web: dijalankan dari laptop presenter melalui localhost (Flutter Web + dart_frog), sehingga presentasi web tetap membutuhkan laptop sebagai host, sedangkan mobile dan Windows tidak.

Masalah jaringan lokal seperti AP isolation tidak menjadi masalah untuk mobile/Windows karena aplikasi tidak mengakses backend yang berjalan di laptop.

---

26. Data Dummy

Data dummy dibuat cukup realistis tetapi tidak berlebihan.

Roles: Admin, Dosen, Mahasiswa.
Users: 2–3 Admin, 2–3 Dosen, 2–3 Mahasiswa.
Supporting Data: beberapa Program Studi, Mata Kuliah, Kurikulum, Kelas, Jadwal, KRS, Nilai, Presensi.

Tujuan dummy data: memperlihatkan relasi database, role, dashboard, workflow akademik, dan memungkinkan demo end-to-end. Tidak perlu seeding data sampai memenuhi ratusan MB.

---

27. Contoh End-to-End Workflow

Mahasiswa login:

Mahasiswa
↓
Flutter Login
↓
Authentication
↓
Session
↓
Dashboard

Mahasiswa melihat KRS:

KRS Page
↓
KRS Controller
↓
Repository
↓
Backend Isolate / Dart Server
↓
Supabase
↓
PostgreSQL
↓
KRS data
↓
Flutter

Dosen input nilai:

Dosen
↓
Kelas
↓
Daftar Mahasiswa
↓
Input Nilai
↓
Authorization check
↓
Database
↓
Audit Log

Mahasiswa melihat nilai:

Mahasiswa
↓
Nilai
↓
RLS / authorization
↓
PostgreSQL
↓
Nilai mahasiswa tersebut

---

28. Prinsip Arsitektur

1. Database terpusat — tidak ada database akademik terpisah per device.

All clients
↓
One PostgreSQL database

2. UI tidak mengandung business logic berat — Flutter hanya bertanggung jawab terhadap presentation, interaction, state, navigation.

3. Data access melalui abstraction — tidak menyebarkan query Supabase ke seluruh widget. Gunakan Repository, Service, Datasource.

4. Security tidak dipercaya kepada client — Flutter dan Dart Isolate/server bukan trusted boundary; authorization final tetap di RLS/Supabase.

5. Satu codebase Flutter untuk Android, Web, Windows.

6. Satu bahasa (Dart) untuk frontend dan backend/business layer, menghilangkan kebutuhan FFI/native binding lintas bahasa.

7. Mobile didistribusikan sebagai satu APK, Windows sebagai satu installer — user tidak perlu menginstall backend secara manual.

8. Business logic backend ditulis sekali (package bersama), dipakai ulang oleh Isolate (mobile/desktop) maupun Dart server (web) — tidak ada duplikasi implementasi.

---

29. Hal yang Tidak Digunakan

Arsitektur ini secara sengaja tidak menggunakan:

❌ PostgreSQL langsung dari Flutter menggunakan privileged credential
❌ Database lokal per device sebagai database utama
❌ Backend yang harus dijalankan manual oleh user (mobile/desktop)
❌ Docker di device pengguna
❌ VPS milik sendiri sebagai syarat penggunaan aplikasi
❌ Microservices
❌ Banyak aplikasi frontend berbeda
❌ Business logic yang seluruhnya berada di widget
❌ Bahasa backend native terpisah (Go/Rust) dengan FFI — dihindari karena kompleksitas dan risiko development tidak sepadan dengan beban kerja I/O-bound proyek ini
❌ Node.js embedded di mobile — overhead runtime terlalu besar untuk manfaat yang didapat

Microservices tidak diperlukan karena skala proyek ini lebih cocok dengan Modular Monolith.

---

30. Arsitektur Final

Mobile

┌──────────────────────────────┐
│ SIA APK │
│ │
│ Flutter (main isolate) │
│ │ │
│ ▼ │
│ Dart Isolate │
│ (Embedded Backend) │
│ │
└──────────────┬───────────────┘
│ HTTPS
▼
┌──────────────┐
│ Supabase │
│ Auth │
│ API │
│ RLS │
└──────┬───────┘
│
▼
PostgreSQL

Windows

┌──────────────────────────────┐
│ SIA Installer/App │
│ │
│ Flutter (main isolate) │
│ │ │
│ ▼ │
│ Dart Isolate │
│ (Embedded Backend) │
│ │
└──────────────┬───────────────┘
│ HTTPS
▼
Supabase
│
▼
PostgreSQL

Web

Flutter Web
│
▼
Dart Server (dart_frog, localhost)
│
▼
Supabase
│
▼
PostgreSQL

---

31. Struktur Repository Tingkat Atas

sia/
├── frontend/
│ └── Flutter project (Android, Web, Windows)
│
├── backend/
│ ├── sia_backend_core/ # package business logic bersama
│ ├── isolate_entry/ # entry point Dart Isolate (mobile/desktop)
│ └── web_server/ # dart_frog project (web, localhost)
│
├── database/
│ ├── migrations/
│ └── seed/
│
├── docs/
│ ├── architecture.md
│ ├── database.md
│ ├── security.md
│ ├── roles-permissions.md
│ └── api.md
│
└── README.md

---

32. Kesimpulan Keputusan Teknologi

Frontend → Flutter / Dart
State Management → Riverpod
Routing → GoRouter
Networking (web dev) → Dio / HTTP (Flutter Web ke Dart server lokal)
Backend / Business Layer → Dart Isolate (mobile & desktop), dart_frog (web)
Database → PostgreSQL
Database Hosting → Supabase
Authentication → Supabase Auth
Authorization → RLS + application-level authorization (di backend layer)
Architecture → Modular Monolith, satu bahasa penuh (Dart)
Deployment Mobile → Single APK
Deployment Web → Flutter Web + Dart server (localhost saat presentasi)
Deployment Windows → Single installer (MSIX/Inno Setup)
Primary Database → Cloud PostgreSQL
Local Database → Tidak digunakan sebagai database utama

Target pengalaman pengguna (mobile/Windows):

INSTALL
↓
OPEN
↓
LOGIN
↓
INTERNET
↓
ACCESS CENTRAL DATABASE

Tidak ada proses: Install Docker, Install bahasa/runtime backend terpisah, Start backend server manual, Start PostgreSQL, Configure localhost (untuk mobile/Windows).

---

33. Catatan Implementasi Penting

Dart Isolate merupakan bagian teknis penting dari rancangan, namun jauh lebih sederhana dibanding pendekatan native embedded (FFI ke Go/Rust) karena tidak melibatkan boundary bahasa, native library packaging per ABI, atau cross-compilation.

Yang perlu dipertimbangkan dalam implementasi:

- Desain kontrak pesan antara main isolate dan backend isolate (format request/response)
- Error propagation dari backend isolate ke UI
- Lifecycle isolate (kapan spawn, kapan dispose)
- Struktur package bersama (sia_backend_core) agar dapat dipakai baik oleh isolate maupun dart_frog tanpa duplikasi
- Autentikasi/session handling konsisten di kedua jalur (isolate dan web server)
- Penanganan kegagalan jaringan ke Supabase
- Build pipeline untuk APK dan installer Windows

Karena kompleksitas teknisnya jauh lebih rendah dibanding pendekatan Go/Rust, proof-of-concept awal cukup difokuskan pada: komunikasi dasar main isolate ↔ backend isolate, dan satu service (misal auth) yang berjalan di kedua jalur (isolate & dart_frog) menggunakan package bersama yang sama.

---

34. Definisi Sederhana Proyek

Dalam satu kalimat:

«SIA multiplatform berbasis Flutter dengan embedded Dart Isolate sebagai business layer untuk mobile dan desktop, serta Dart server (dart_frog) untuk web, menggunakan Supabase sebagai backend cloud/data platform dan PostgreSQL sebagai database terpusat, sehingga aplikasi Android dapat didistribusikan sebagai satu APK, Windows sebagai satu installer, dan seluruh client mengakses sumber data akademik yang sama melalui internet — dengan satu bahasa (Dart) digunakan penuh dari frontend hingga business layer.»
