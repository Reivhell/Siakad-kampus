# 01 — Dashboard & Statistik Akademik (Role Admin)

> Modul dashboard utama bagi Administrator untuk memantau status operasional kampus, statistik civitas akademika, metrik perkuliahan, pusat antrean persetujuan (approval queue), dan sistem peringatan dini (early warning system) secara real-time.

---

## 1. Tujuan Fitur
Menyediakan pusat kendali visual (*executive & operational cockpit*) berkecepatan tinggi bagi Admin untuk memantau kesehatan seluruh proses akademik, mendeteksi hambatan operasional sedini mungkin, serta mengeksekusi tindakan administratif penting tanpa harus berpindah-pindah menu.

---

## 2. Navigasi & Kontrol Global Dashboard (Header Controls)

Pada bagian atas dashboard terdapat kontrol universal yang memfilter seluruh widget secara reaktif:

| Kontrol | Tipe UI | Fungsi & Logika Bisnis |
| :--- | :--- | :--- |
| **Filter Periode Akademik** | Dropdown Selector | Default mengarah ke `periode_akademik` aktif (`aktif = true`). Admin dapat memilih semester sebelumnya untuk perbandingan data historis (*time-travel analytics*). |
| **Filter Program Studi** | Multi/Single Select | Memfilter data statistik untuk seluruh institusi (Universitas/Fakultas) atau fokus ke satu Program Studi tertentu (misal: "Teknik Informatika"). |
| **Mode Tampilan (Presentation Mode)** | Toggle Switch | Menyembunyikan data sensitif personal (NPM, nomor HP, email pribadi) saat aplikasi dipresentasikan di proyektor/sidang tugas akhir. |
| **Ekspor Laporan Snapshot** | Tombol Aksi | Mengunduh ringkasan ringkas statistik dashboard dalam format PDF (Executive One-Page Summary) atau Excel. |
| **Penyegaran Data (Auto Refresh)** | Toggle + Interval | Pilihan pembaruan otomatis (tiap 1, 5, atau 15 menit) atau tombol refresh manual untuk menyinkronkan data dengan Supabase. |

---

## 3. Rincian Komponen & Widget Dashboard

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ [Filter Semester: Ganjil 2025/2026 ▼]  [Prodi: Semua Prodi ▼]  [Presentation Mode: OFF]│
├────────────────────────────────────────────────────────────────────────────────────────┤
│ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐ ┌────────────┐ │
│ │ PERIODE AKTIF │ │ MAHASISWA AKTIF│ │  DOSEN AKTIF  │ │ KELAS DIBUKA  │ │PARTISIPASI │ │
│ │ Ganjil 25/26  │ │ 1.420 Org     │ │ 78 Dosen      │ │ 112 Rombel    │ │KRS: 94.2%  │ │
│ └───────────────┘ └───────────────┘ └───────────────┘ └───────────────┘ └────────────┘ │
├───────────────────────────────────────────────────────┬────────────────────────────────┤
│ 📅 TIMELINE SEMESTER: MINGGU KE-8 DARI 16 [■■■■■■■■□□] │ ⚡ PINTASAN AKSI CEPAT         │
│   • Masa KRS: Selesai   • UTS: Sedang Berjalan        │   [+ Mahasiswa] [+ Buka Kelas] │
│   • UAS: 6 Minggu Lagi  • Input Nilai: Dibuka         │   [+ Tambah Dosen] [Broadcast] │
├───────────────────────────────────────────────────────┴────────────────────────────────┤
│ 🚨 PUSAT PERINGATAN DINI (EARLY WARNING & ANOMALY CENTER)                              │
│   [!] 3 Kelas Kuota Penuh (100%)       [!] 2 Kelas Kurang Peminat (< 5 mhs)            │
│   [!] 4 Dosen Belum Input Nilai UTS    [!] 12 Mahasiswa Kehadiran < 75% (Terancam UAS) │
├────────────────────────────────────────┬───────────────────────────────────────────────┤
│ 📥 ANTREAN PERSETUJUAN (TASK QUEUE)    │ 🏫 UTILISASI RUANGAN & PERKULIAHAN HARI INI   │
│   • 2 Pengajuan Buka Kunci Nilai (Dosen)│   • 18 Perkuliahan Sedang Berlangsung        │
│   • 5 Permohonan Force-Add KRS         │   • Tingkat Okupansi Ruang: 76%               │
│   • 1 Pengajuan Cuti Akademik          │   • Ruang Terpadat: Lab Komputer 1            │
├────────────────────────────────────────┼───────────────────────────────────────────────┤
│ 📊 GRAFIK STATISTIK & ANALITIK         │ 📜 JEJAK AKTIVITAS SISTEM TERKINI (LIVE LOG)  │
│   • Donut: Progres Nilai (Draft/Final) │   • [10:45] Dosen X memfinalisasi nilai TI101 │
│   • Bar: Distribusi Mhs per Prodi      │   • [10:30] Admin override KRS mhs 261001001  │
│   • Histogram: Beban SKS Mahasiswa     │   • [09:15] Mahasiswa Y ajukan cuti semester  │
└────────────────────────────────────────┴───────────────────────────────────────────────┘
```

---

### 3.1 Kartu Ringkasan Eksekutif (Primary KPI Metric Cards)
| Indikator | Sumber Data | Informasi Tambahan & Tooltip |
| :--- | :--- | :--- |
| **Periode Akademik Aktif** | `periode_akademik` WHERE `aktif = true` | Menampilkan nama semester (misal: "Ganjil 2025/2026"), tanggal awal-akhir, dan sisa hari operasional. |
| **Total Mahasiswa Aktif** | `mahasiswa` WHERE `status = 'AKTIF'` | Jumlah mahasiswa aktif, disertai lencana kecil rincian: Mahasiswa Baru, Cuti, dan Lulus semester ini. |
| **Total Dosen Aktif** | `dosen` WHERE `status = 'AKTIF'` | Total dosen pengajar aktif beserta rasio ideal Dosen : Mahasiswa (contoh: `1 : 28`). |
| **Total Kelas Dibuka** | `kelas` pada periode aktif | Total rombel yang dibuka, disertai indikator: berapa kelas yang sudah memiliki dosen vs kelas tanpa dosen. |
| **Tingkat Partisipasi KRS** | `krs` vs total `mahasiswa` aktif | Persentase mahasiswa yang telah mengunci formulir KRS (Target 100% sebelum masa perkuliahan dimulai). |
| **Rata-rata IPK Kampus** | `nilai` akumulatif per prodi | Rata-rata capaian akademik mahasiswa pada semester sebelumnya sebagai indikator mutu pembelajaran. |

---

### 3.2 Visualisasi Timeline & Kalender Semester (Semester Progress Tracker)
- **Indikator Kemajuan Semester**: Progress bar persentase perjalanan semester (contoh: *"Minggu ke-8 dari 16 Minggu Perkuliahan — 50% Berjalan"*).
- **Penanda Fase Akademik (Milestone Status)**:
  1. Masa Pengisian KRS (Selesai)
  2. Masa Perubahan KRS / KPRS (Selesai)
  3. Ujian Tengah Semester (UTS) — *Tahap Sedang Berjalan*
  4. Batas Input Nilai UTS (Deadline: 14 Oktober 2026)
  5. Ujian Akhir Semester (UAS) (Jadwal: 10 Desember 2026)
  6. Batas Finalisasi Nilai Akhir Dosen (Deadline: 28 Desember 2026)
  7. Rapat Yudisium & Penerbitan KHS Resmi

---

### 3.3 Pusat Peringatan Dini & Anomali (Early Warning & Anomaly Center)
Widget cerdas yang secara proaktif mendeteksi permasalahan operasional untuk segera ditindaklanjuti:
1. **Peringatan Kuota Kelas Kritis (Over-Capacity Alert)**:
   - Menampilkan daftar kelas yang telah mencapai 100% kapasitas (`jumlah_terdaftar >= kapasitas`).
   - Tindakan cepat: Tombol langsung *"Buka Kelas Paralel Baru"* atau *"Naikkan Kuota Kelas"*.
2. **Peringatan Kelas Kurang Peminat (Low Enrollment Alert)**:
   - Menampilkan kelas dengan pendaftar di bawah ambang batas efisiensi perkuliahan (misal: `< 5 mahasiswa`).
   - Tindakan cepat: Evaluasi penggabungan kelas (merger) atau pembatalan penawaran kelas.
3. **Peringatan Kepatuhan Nilai Dosen (Grade Submission Deadline)**:
   - Mendeteksi kelas yang belum difinalisasi nilainya oleh dosen pengampu ketika mendekati batas akhir (H-7 dan H-3 deadline).
   - Tindakan cepat: Tombol kirim notifikasi/reminder otomatis ke email atau nomor dosen.
4. **Deteksi Konflik & Anomali Penjadwalan**:
   - Menampilkan daftar kelas yang belum dialokasikan ruangan (`id_ruangan IS NULL`).
   - Mendeteksi kelas yang belum memiliki dosen pengampu (`kelas_dosen` kosong).
5. **Mahasiswa Berisiko Akademik Tinggi (At-Risk Students Alert)**:
   - **Skrining Presensi Rendah**: Mahasiswa dengan persentase kehadiran `< 75%` (terancam tidak dapat mengikuti UAS).
   - **Evaluasi Indeks Prestasi Rendah**: Mahasiswa dengan IPS `< 2.00` yang memerlukan bimbingan khusus dosen wali/PA.
   - **Batas Masa Studi**: Mahasiswa tingkat akhir yang mendekati batas maksimal masa studi (Semester 12–14 untuk jenjang S1).

---

### 3.4 Pusat Antrean Tugas & Persetujuan Pending (Action Items & Task Queue)
Daftar permohonan dari dosen dan mahasiswa yang memerlukan keputusan/tindakan langsung dari Admin:
1. **Permohonan Buka Kunci Nilai (*Unlock Grade Request*)**:
   - Dosen yang mengajukan perbaikan nilai setelah finalisasi terkunci (disertai alasan/berita acara).
   - Aksi: Setujui (Buka Kunci) atau Tolak Permohonan.
2. **Permohonan *Force-Add* KRS (Dispensasi Kuota Penuh)**:
   - Pengajuan mahasiswa yang membutuhkan mata kuliah wajib prasyarat kelulusan pada kelas yang kuotanya telah habis.
   - Aksi: *Approve Force-Add* atau alihkan ke kelas paralel lain.
3. **Pengajuan Cuti Akademik Mahasiswa**:
   - Pengajuan status cuti semester mahasiswa yang menunggu verifikasi berkas administrasi dan surat bebas tanggungan keuangan.
   - Aksi: Verifikasi status mahasiswa menjadi `CUTI`.
4. **Tiket Reset Password & Akun Terkunci**:
   - Permintaan bantuan akses akun dari civitas yang lupa sandi atau mengalami kendala login.

---

### 3.5 Monitoring Pelaksanaan Perkuliahan & Presensi Real-Time
1. **Kuliah Hari Ini (Today's Live Classes)**:
   - Widget ringkasan jadwal kuliah yang berlangsung pada hari ini (berdasarkan hari kalender 1–7).
   - Status pertemuan: Berapa kelas yang sedang berlangsung, kelas yang sudah selesai diabsen, dan kelas yang tertunda/belum dimulai.
2. **Tingkat Utilisasi Ruang Kuliah (Room Occupancy Rate)**:
   - Persentase jam penggunaan ruang kuliah dibandingkan total ketersediaan ruang kampus.
   - Indikator ruangan terpadat (paling sering dipesan) dan ruangan kosong yang dapat digunakan sebagai ruang kuliah pengganti.
3. **Ketercapaian Pertemuan Dosen (Teaching Progress Target)**:
   - Target standar 16 kali pertemuan per semester.
   - Distribusi progres pertemuan:
     - 🟢 On-Track (sesuai minggu akademik)
     - 🟡 Tertinggal 1–2 pertemuan
     - 🔴 Tertinggal > 2 pertemuan (perlu koordinasi jadwal kuliah pengganti / *make-up class*)

---

### 3.6 Analisis KRS & Penyerapan Kurikulum
1. **Top 5 Mata Kuliah Paling Diminati / Over-subscribed**:
   - Daftar mata kuliah pilihan atau wajib yang paling cepat habis kuotanya saat masa registrasi KRS dibuka.
2. **Distribusi Beban SKS Mahasiswa (SKS Load Distribution)**:
   - Histogram sebaran pengambilan beban SKS mahasiswa aktif pada semester berjalan:
     - Maksimal (24 SKS)
     - Reguler (20–23 SKS)
     - Sedang (15–19 SKS)
     - Minimal (< 15 SKS / Semester Akhir / Skripsi Saja)
3. **Rekapitulasi Total SKS Dibuka**:
   - Total kapasitas kursi yang disediakan kampus vs total kursi yang berhasil diserap oleh mahasiswa.

---

### 3.7 Grafik & Analisis Data Visual (Interactive Analytics)
1. **Grafik Distribusi Mahasiswa per Program Studi**:
   - Bar chart komparasi mahasiswa aktif, cuti, dan lulus antar prodi.
2. **Grafik Donat Status Penginputan Nilai Dosen**:
   - Segmentasi progres penilaian:
     - 🔴 Belum Diinput (0%)
     - 🟡 Draft / Sebagian (UTS/Tugas saja)
     - 🟢 Sudah Difinalisasi (Lengkap)
3. **Grafik Tren Mahasiswa Baru 5 Tahun Terakhir**:
   - Line chart laju pertumbuhan penerimaan mahasiswa baru per tahun masuk.
4. **Grafik Sebaran IPK Mahasiswa per Angkatan**:
   - Diagram sebaran mutu akademik (IPK 3.51–4.00 Dengan Pujian, 3.00–3.50 Sangat Memuaskan, 2.75–2.99 Memuaskan, < 2.75 Butuh Perhatian).

---

### 3.8 Streaming Jejak Aktivitas Sistem Terkini (Live Audit Stream)
- Menampilkan 10 transaksi atau perubahan data terbaru dari tabel `log_aktivitas` secara kronologis mundur:
  - Timestamp (misal: "3 menit lalu")
  - Aktor Pengguna (Nama & Role Admin/Dosen/Mahasiswa)
  - Aksi yang Dilakukan (contoh: `ADMIN_BUAT_KELAS`, `DOSEN_FINALISASI_NILAI`, `MAHASISWA_AJUKAN_KRS`)
  - Entitas & ID Objek
  - Tombol *"Lihat Selengkapnya"* yang mengarahkan langsung ke modul [10_audit_log_dan_keamanan.md](file:///home/sejel/Documents/SIAKAD_Kampus/fitur_admin/10_audit_log_dan_keamanan.md).
- **Indikator Anomali Keamanan**: Notifikasi khusus jika terdeteksi aktivitas mencurigakan (misal: lonjakan percobaan login gagal atau percobaan modifikasi data di luar jam kerja).

---

### 3.9 Pusat Pengumuman & Broadcast Kampus (Internal Announcement Center)
- **Status Banner Pengumuman Aktif**:
  - Menampilkan ringkasan pengumuman penting yang saat ini tampil di beranda mahasiswa dan dosen (misal: *"Jadwal KRS Diperpanjang s.d. 15 Oktober 2026"*).
- **Pintasan Broadcast Cepat**:
  - Modal cepat untuk menerbitkan pengumuman instan dengan opsi target penerima:
    - Seluruh Civitas Akademika
    - Khusus Dosen
    - Khusus Mahasiswa (dapat difilter per Program Studi atau Angkatan)

---

### 3.10 Dermaga Pintasan Cepat (Quick Action Dock / FAB)
Tombol akses instan melayang (*Floating Action Button / Quick Bar*) untuk fungsi-fungsi harian yang paling sering dipakai Admin:
- **[+ Registrasi Mahasiswa Baru]**: Membuka form cepat penambahan mahasiswa sekaligus generate NPM dan akun Supabase.
- **[+ Buka Kelas Baru]**: Membuka dialog penawaran kelas perkuliahan di semester aktif.
- **[+ Registrasi Dosen Baru]**: Input biodata dosen & pembuatan kredensial login NIDN.
- **[+ Buat Pengumuman Baru]**: Membuka formulir broadcast pengumuman kampus.
- **[Lihat Konflik Jadwal]**: Navigasi instan ke halaman kalender plotting bentrok.

---

### 3.11 Status Kesehatan Sistem & Integrasi Cloud (System Health Status Widget)
Widget pemantauan performa teknis di footer dashboard:
- **Konektivitas Supabase & Database**:
  - Indikator status koneksi (🟢 Terhubung / 🟡 Latensi Tinggi / 🔴 Terputus).
  - Ping waktu respons (misal: `Latency: 48 ms`).
- **Kapasitas Database Terkelola**:
  - Tinjauan perkiraan jumlah baris data dan batas penggunaan kuota Supabase (Free-tier safety monitor).
- **Status Sinkronisasi & Backup**:
  - Waktu pencadangan basis data otomatis terakhir (misal: *"Backup Otomatis Terakhir: Hari ini 03:00 WIB"*).

---

## 4. Hak Akses & Kinerja Sistem
1. **Hak Akses**:
   - Seluruh widget dashboard hanya dapat diakses oleh pengguna dengan role `ADMIN`.
2. **Kinerja & Caching Data**:
   - Untuk mencegah beban kueri agregasi berat ke Supabase PostgreSQL, metrik KPI dan grafik statistik dihitung menggunakan *Database Views* teroptimasi (`v_dashboard_kpi`, `v_rekap_krs`) atau mekanisme caching di sisi State Management Flutter (Riverpod `ref.watch` dengan invalidasi berkala).
3. **Responsivitas Tampilan**:
   - **Desktop / Web (≥ 1024 px)**: Layout multi-kolom (3–4 kolom grid) dengan visualisasi grafik lengkap.
   - **Tablet (600–1023 px)**: Layout 2 kolom adaptif.
   - **Mobile (< 600 px)**: Layout 1 kolom vertikal bersusun dengan kartu metrik yang dapat di-swipe secara horizontal (*carousel cards*).
