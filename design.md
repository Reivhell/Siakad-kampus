# Design System & UI/UX Guidelines — SIAKAD KAMPUS

> Dokumen ini mendefinisikan spesifikasi sistem desain visual, palet warna, tipografi, komponen UI, tata letak responsif, dan panduan aksesibilitas untuk aplikasi **Sistem Informasi Akademik (SIA / SIAKAD)** multiplatform berbasis Flutter (Android, Web, dan Windows).

---

## Daftar Isi

1. [Filosofi & Identitas Desain](#1-filosofi--identitas-desain)
2. [Sistem Warna (Color System)](#2-sistem-warna-color-system)
   - [Brand & Identity Palette](#21-brand--identity-palette)
   - [Status & Semantic Palette](#22-status--semantic-palette)
   - [Light Mode Specification](#23-light-mode-specification)
   - [Dark Mode Specification](#24-dark-mode-specification)
   - [Tabel Token Warna & Flutter Mapping](#25-tabel-token-warna--flutter-mapping)
3. [Tipografi (Typography)](#3-tipografi-typography)
   - [Prinsip Pemilihan Font](#31-prinsip-pemilihan-font-modern-seimbang-nyaman-dibaca)
   - [Font Terpilih](#32-font-terpilih-calm-modern-rekomendasi-final)
   - [Skala Tipografi](#33-skala-tipografi-plus-jakarta-sans--jetbrains-mono)
   - [Penerapan di Flutter](#34-penerapan-di-flutter-google_fonts)
4. [Sistem Spacing, Radius, & Elevasi](#4-sistem-spacing-radius--elevasi)
   - [Skala Spacing (4-Point Grid)](#41-skala-spacing-4-point-grid)
   - [Border Radius](#42-border-radius)
   - [Elevasi & Shadow](#43-elevasi--shadow)
5. [Tata Letak & Responsivitas Multiplatform](#5-tata-letak--responsivitas-multiplatform)
   - [Breakpoints Layar](#51-breakpoints-layar)
   - [Pola Navigasi per Perangkat](#52-pola-navigasi-per-perangkat)
6. [Spesifikasi Komponen Inti UI Akademik](#6-spesifikasi-komponen-inti-ui-akademik)
   - [Metric & Summary Card](#61-metric--summary-card)
   - [Jadwal & Mata Kuliah Card](#62-jadwal--mata-kuliah-card)
   - [Data Table & Grid (KRS, KHS, Nilai)](#63-data-table--grid-krs-khs-nilai)
   - [Form & Input Controls](#64-form--input-controls)
   - [Status Badges & Chips](#65-status-badges--chips)
   - [Buttons & Actions](#66-buttons--actions)
7. [Micro-Interactions & State Feedback](#7-micro-interactions--state-feedback)
   - [State Interaksi](#71-state-interaksi)
   - [Loading & Skeleton States](#72-loading--skeleton-states)
   - [Empty States](#73-empty-states)
   - [SnackBars & Alerts](#74-snackbars--alerts)
8. [Panduan Aksesibilitas (WCAG 2.1 AA)](#8-panduan-aksesibilitas-wcag-21-aa)
9. [Referensi Implementasi Flutter (`theme.dart`)](#9-referensi-implementasi-flutter-themedart)

---

## 1. Filosofi & Identitas Desain

Sistem Informasi Akademik adalah instrumen harian bagi tiga role utama: **Mahasiswa**, **Dosen**, dan **Admin**. Desain harus menyeimbangkan kejelasan data numerik/tabel dengan kenyamanan navigasi jangka panjang.

### Prinsip Utama:
1. **Clarity over Clutter (Kejelasan di Atas Segalanya)**:
   - Data akademik (IPK, SKS, Jadwal, Nilai) harus dapat dipindai (*scannable*) dalam hitungan detik tanpa distraksi visual berlebih.
2. **Professional & Trustworthy (Akademik & Berwibawa)**:
   - Menggunakan warna dasar *Indigo Blue* sebagai lambang stabilitas institusi akademik, dipadukan dengan aksen *Gold* yang mencerminkan prestasi dan keunggulan.
3. **Adaptive Ergonomics (Kenyamanan Multiplatform)**:
   - Satu codebase Flutter harus terasa native di layar sentuh Android (touch-friendly, min 48dp hit target), browser Web (widescreen data-density), dan desktop Windows (dense data table, keyboard shortcuts, fast navigation).
4. **Accessible by Default (Inklusif & Aksesibel)**:
   - Kontras warna teks memenuhi standar WCAG 2.1 AA (minimal 4.5:1), transisi halus, serta dukungan Dark Mode penuh untuk kenyamanan mata saat lembur tugas atau rekap nilai di malam hari.

---

## 2. Sistem Warna (Color System)

### 2.1 Brand & Identity Palette

Warna identitas utama mengacu pada fondasi brand SIAKAD:

| Token Name | Hex Code | Flutter Hex (0xAARRGGBB) | Deskripsi & Peran Visual |
| :--- | :--- | :--- | :--- |
| **Indigo Blue** *(Primary)* | `#1E3A8A` | `0xFF1E3A8A` | Warna dominan utama: AppBar, Sidebar aktif, Primary Button, Header brand. |
| **Indigo Light** | `#3B82F6` | `0xFF3B82F6` | Varian cerah untuk hover state, active pill, link, dan dark mode primary. |
| **Elegant Navy** | `#172554` | `0xFF172554` | Warna navy pekat dan elegan untuk kontras tinggi, surface dark, border solid, atau top header mobile. |
| **Snow White** *(Light Canvas)*| `#F8FAFC` | `0xFFF8FAFC` | Latar belakang kanvas aplikasi pada Light Mode. Dingin, bersih, tidak menyilaukan. |
| **Gold Accent** *(Accent)* | `#FFEE2E` | `0xFFFFEE2E` | Aksen warna emas untuk highlight prestasi (IPK cumlaude, bintang favorit, pin jadwal, badge unggulan). |


---

### 2.2 Status & Semantic Palette

Digunakan untuk memberikan indikator visual status akademik yang konsisten di seluruh modul:

| Status Token | Hex Code | Flutter Hex | Arti & Penggunaan Akademik |
| :--- | :--- | :--- | :--- |
| **Pass / Success** | `#3FD478` | `0xFF3FD478` | Status KRS Disetujui, Mahasiswa Aktif, Presensi Hadir, Nilai Lulus, Sukses Simpan Data. |
| **Success Surface** | `#DCFCE7` | `0xFFDCFCE7` | Background badge status sukses (Light Mode). |
| **Alert / Warning** | `#E1E11E` *(alt: `#F59E0B`)*| `0xFFE1E11E` / `0xFFF59E0B` | Status KRS Menunggu Persetujuan, Batas Akhir Pembayaran, Presensi Izin/Sakit, Masa Revisi. |
| **Warning Surface** | `#FEF3C7` | `0xFFFEF3C7` | Background badge status pending/peringatan (Light Mode). |
| **Warning / Danger** | `#EC1431` | `0xFFEC1431` | Status KRS Ditolak, Mahasiswa Non-Aktif/Drop Out, Presensi Alpa, Nilai E/Gagal, Hapus Data, Form Error. |
| **Danger Surface** | `#FEE2E2` | `0xFFFEE2E2` | Background badge status ditolak/bahaya (Light Mode). |
| **Info / Notice** | `#0369A1` | `0xFF0369A1` | Pengumuman umum kampus, status KRS Sedang Disusun, info pengunduhan dokumen. Ink teks pada Info Surface `#E0F2FE` (5.17:1). |
| **Info Surface** | `#E0F2FE` | `0xFFE0F2FE` | Background badge status informasi. |

> [!IMPORTANT]
> **Aturan Warna sebagai Teks (Light Mode):** token di tabel atas adalah nilai *fill* (badge, icon, indikator strip). Nilainya **tidak boleh** dipakai langsung sebagai warna teks di atas permukaan terang. Untuk teks badge pada surface masing-masing, pakai *ink* partner yang sudah diuji kontrasnya:
>
> | Status | Fill | Ink Teks (AA) | Rasio |
> | :--- | :--- | :--- | ---: |
> | Pass | `#3FD478` | `#15803D` di atas `#DCFCE7` | 4.57:1 |
> | Alert | `#E1E11E` | `#845A09` di atas `#FEF3C7` | 5.47:1 |
> | Warning / Danger | `#EC1431` | `#B91C1C` di atas `#FEE2E2` | 5.30:1 |
> | Info | `#0369A1` | `#0369A1` di atas `#E0F2FE` | 5.17:1 |
> | Draft / Netral | `#F1F5F9` | `#475569` di atas `#F1F5F9` | 6.92:1 |
>
> `#3FD478` sebagai teks di atas putih hanya **1.93:1** — gagal total. Pemakaiannya hanya sebagai isian, garis strip, dan ikon.
>
> `Gold Accent #FFEE2E` juga **tidak boleh** jadi teks di atas kanvas terang (1.15:1). Di Light Mode jsonya deksoratif: isian badge, sorotan border, dan elemen non-teks. Teks di atas tombol gold harus `Ink #0F172A` (14.9:1). Di Dark Mode, padanannya `Champagne Gold #F5CD68` **boleh** jadi teks (11.75:1 di atas `#0E172B`).

---

### 2.3 Light Mode Specification

Mode standar untuk aktivitas akademik siang hari dengan kesan bersih, lega, dan modern.

```
┌─────────────────────────────────────────────────────────────┐
│  LIGHT MODE TOKENS                                          │
│                                                             │
│  Canvas Background      : #F8FAFC (Snow White)             │
│  Surface / Card Base    : #FFFFFF (Pure White)             │
│  Surface Elevated       : #F1F5F9 (Slate 100)              │
│  Borders & Dividers     : #E2E8F0 (Slate 200)              │
│  Text Primary           : #0F172A (Slate 900 - Kontras 16:1)│
│  Text Secondary / Muted : #64748B (Slate 500)              │
│  Text Disabled          : #94A3B8 (Slate 400)              │
│  Brand Primary Accent   : #1E3A8A (Indigo Blue)            │
│  Highlight Accent       : #FFEE2E (Gold Accent)            │
└─────────────────────────────────────────────────────────────┘
```

---

### 2.4 Dark Mode Specification — "Nocturne Academic" (Bespoke Midnight Sapphire)

Menghindari pendekatan konvensional abu-abu generik (*slate/gray slop*) yang kusam dan terasa seperti template dashboard biasa, Dark Mode SIAKAD mengusung konsep **Nocturne Academic**: perpaduan *Chromatic Abyss Navy* dengan aksen *Luminous Royal Indigo* dan *Celestial Champagne Gold*. 

Palet ini mempertahankan saturasi biru malam (8–12%) agar visual tetap memiliki kedalaman akademis yang berwibawa, menghindarkan kelelahan mata (*anti-eye-strain*) saat beraktivitas larut malam, serta menghilangkan silau berlebih (*glare / halation effect*).

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  NOCTURNE ACADEMIC — BESPOKE DARK MODE ARCHITECTURE                         │
├─────────────────────────────────────────────────────────────────────────────┤
│  CHROMATIC ELEVATION LAYERS                                                 │
│  Layer 0 (Canvas Void)     : #060A17 (Midnight Abyss Navy — rich blue base)  │
│  Layer 1 (Card / Surface)  : #0E172B (Deep Indigo Surface — chromatic ~10%) │
│  Layer 2 (Elevated / Modal): #16233B (Midnight Sapphire Floating)            │
│  Layer 3 (Active / Pill)   : #1E2F50 (Interactive Indigo Glow Fill)         │
│  Hairline Borders          : #1E2E4A (Subtle Bioluminescent Border 1px)     │
├─────────────────────────────────────────────────────────────────────────────┤
│  TYPOGRAPHY & ACCENTS                                                       │
│  Text Primary (Titles/Data): #EDF2F7 (Starlight Ivory — lembut & tajam)     │
│  Text Secondary (Labels)   : #8FA1BC (Atmospheric Slate-Blue)               │
│  Text Tertiary (Footnotes) : #7A8CAD (Dusk Slate — 5.26:1, lolos AA)   │
│  Brand Primary Accent      : #4F75FF (Luminous Royal Indigo — high contrast)│
│  Prestige Gold Accent      : #F5CD68 (Celestial Champagne Gold — anti-glare)│
├─────────────────────────────────────────────────────────────────────────────┤
│  BESPOKE SEMANTIC JEWELS (Dark Calibrated)                                  │
│  Pass / Lulus / Hadir      : #32D583 (Luminescent Mint Emerald)            │
│  Alert / Pending / Revisi  : #F7B944 (Warm Amber Ochre)                     │
│  Danger / Ditolak / Alpa   : #F43F5E (Ruby Rose Crimson)                    │
│  Info / Pengumuman         : #38BDF8 (Ethereal Sky Azure)                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Karakteristik & Rasional Desain:
1. **Chromatic Layering vs Gray Slop**: Latar belakang tidak menggunakan warna abu-abu netral mati (`#121212`) atau slate generic (`#1E293B`), melainkan *Abyss Navy* (`#060A17`) dan *Deep Indigo Surface* (`#0E172B`) yang memiliki harmoni rona langsung dengan warna brand utama `Indigo Blue (#1E3A8A)` dan `Elegant Navy (#172554)`.
2. **Anti-Glare Champagne Gold**: Menghindari kuning neon mentah (`#FFEE2E`) yang menyilaukan mata pada latar gelap. Sebagai gantinya, digunakan **Celestial Champagne Gold** (`#F5CD68`) yang hangat, prestisius, dan nyaman dipandang untuk penanda predikat kelulusan (Cumlaude), bintang mata kuliah, atau milestone SKS.
3. **Starlight Ivory Typography**: Menghindari `#FFFFFF` murni (100% white) pada bidang teks luas untuk mencegah efek pendaran kabur (*halo effect*) pada layar OLED/IPS, digantikan dengan **Starlight Ivory** (`#EDF2F7`) yang tetap menghasilkan rasio kontras tinggi (>13:1) namun ramah retina.
4. **Jewel Semantic Tone**: Warna status (merah, hijau, kuning) dikalibrasi ulang dari warna mentah menjadi warna permata bercahaya (*luminescent jewels*) agar tidak terasa seperti lampu hazard lalu lintas.

---

### 2.5 Tabel Token Warna & Flutter Mapping

```dart
// lib/app/theme/app_colors.dart
import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand
  static const Color indigoBlue = Color(0xFF1E3A8A);
  static const Color indigoLight = Color(0xFF3B82F6);
  static const Color elegantNavy = Color(0xFF172554);
  static const Color snowWhite = Color(0xFFF8FAFC);
  static const Color goldAccent = Color(0xFFFFEE2E);

  // Semantics
  static const Color pass = Color(0xFF3FD478);
  static const Color passSurface = Color(0xFFDCFCE7);
  static const Color alert = Color(0xFFE1E11E);
  static const Color alertSurface = Color(0xFFFEF3C7);
  static const Color warning = Color(0xFFEC1431);
  static const Color warningSurface = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0369A1);
  static const Color infoSurface = Color(0xFFE0F2FE);

  // Semantic *ink* — varian teks yang sudah diuji kontrasnya di atas
  // surface masing-masing. Fill di atas TIDAK boleh dipakai sebagai teks.
  static const Color passInk = Color(0xFF15803D);
  static const Color alertInk = Color(0xFF845A09);
  static const Color dangerInk = Color(0xFFB91C1C);
  static const Color infoInk = Color(0xFF0369A1);
  static const Color neutralInk = Color(0xFF475569);

  // Light Neutral
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark Neutral (Nocturne Academic)
  static const Color darkBg = Color(0xFF060A17);
  static const Color darkSurface = Color(0xFF0E172B);
  static const Color darkSurfaceElevated = Color(0xFF16233B);
  static const Color darkSurfaceInteractive = Color(0xFF1E2F50);
  static const Color darkBorder = Color(0xFF1E2E4A);
  static const Color darkTextPrimary = Color(0xFFEDF2F7);
  static const Color darkTextSecondary = Color(0xFF8FA1BC);
  static const Color darkTextMuted = Color(0xFF7A8CAD);
  static const Color darkPrimary = Color(0xFF4F75FF);
  static const Color darkGold = Color(0xFFF5CD68);

  // Dark Semantics
  static const Color darkPass = Color(0xFF32D583);
  static const Color darkAlert = Color(0xFFF7B944);
  static const Color darkDanger = Color(0xFFF43F5E);
  static const Color darkInfo = Color(0xFF38BDF8);
}
```

---

## 3. Tipografi (Typography)

### 3.1 Prinsip Pemilihan Font (Modern, Seimbang, Nyaman Dibaca)

Font bawaan generik membuat aplikasi terasa seperti template massal. SIAKAD dibaca berjam-jam (KRS, KHS, tabel nilai), jadi font harus memenuhi 3 syarat:
1. **Modern tapi tidak kaku**: tidak terlalu tegas/geometris dan dingin, tidak terlalu bulat/santai dan kekanak-kanakan.
2. **Nyaman untuk teks panjang**: *x-height* besar, *open aperture*, jarak huruf lega, angka tabular jelas agar IPK/SKS tidak melelahkan mata.
3. **Satu keluarga untuk semua**: cukup 1 font UI + 1 mono identifier agar konsisten Android/Web/Windows dan ringan dimuat.

---

### 3.2 Font Terpilih: "Calm Modern" (Rekomendasi Final)

#### UI, Body, Headings & Display: **Plus Jakarta Sans** *(Google Fonts)*
- *Karakter*: Humanist sans modern karya desainer Indonesia. Lengkung lembut, proporsi hangat, tegasnya pas untuk institusi tapi tetap ramah. Titik tengah antara kaku dan santai.
- *Kelebihan untuk SIAKAD*: x-height besar → nyaman dibaca di layar HP kecil maupun tabel desktop padat. Weight 400–700 stabil, tidak tipis menyilaukan di Dark Mode.
- *Aturan pakai*: semua teks UI memakai ini. Display angka hero (IPK) cukup pakai weight 700/800 ukuran besar, tidak perlu serif terpisah.

#### Academic Identifiers (NIM, Kode MK, Token, Jam): **JetBrains Mono** *(Google Fonts)*
- *Karakter*: Monospace modern yang lembut dan terbuka, nyaman untuk kode pendek.
- *Aturan pakai*: hanya untuk identifier pendek (`21102044`, `IF-3204`, `LAB-A302`). Jangan pakai untuk paragraf.

---

### 3.3 Skala Tipografi (Plus Jakarta Sans + JetBrains Mono)

| Text Style | Font Family | Size (sp) | Weight | Line Height | Penggunaan Spesifik di SIAKAD |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Display Large** | *Plus Jakarta Sans* | 38 sp | Bold (700) | 46 sp | Angka IPK Hero (e.g. `3.92`), Total SKS Kelulusan (`144 SKS`). |
| **Display Small** | *Plus Jakarta Sans* | 28 sp | SemiBold (600) | 36 sp | Ringkasan statistik dashboard admin/dosen (Total Mahasiswa, Kelas Aktif). |
| **Headline Large** | *Plus Jakarta Sans* | 24 sp | SemiBold (600) | 32 sp | Judul utama halaman (e.g. *Kartu Rencana Studi*, *Transkrip Akademik*). |
| **Headline Medium**| *Plus Jakarta Sans* | 20 sp | SemiBold (600) | 28 sp | Judul Card utama, Section header perkuliahan. |
| **Title Medium**   | *Plus Jakarta Sans* | 16 sp | SemiBold (600) | 24 sp | Nama Mata Kuliah di Card/Tabel, Nama Dosen Pengampu. |
| **Body Large**     | *Plus Jakarta Sans* | 16 sp | Regular (400) | 24 sp | Teks deskripsi silabus, pengumuman rektorat. |
| **Body Medium**    | *Plus Jakarta Sans* | 14 sp | Regular (400) | 20 sp | Teks isi tabel KHS/KRS, input form field. |
| **Code / Identifier**| *JetBrains Mono* | 13 sp | Medium (500) | 18 sp | NIM (`21102044`), Kode MK (`IF-3204`), Ruang (`LAB-A302`). |
| **Label Large**    | *Plus Jakarta Sans* | 14 sp | SemiBold (600) | 20 sp | Tombol utama (Simpan KRS, Ajukan Bimbingan, Login). |
| **Label Medium**   | *Plus Jakarta Sans* | 12 sp | SemiBold (600) | 16 sp | Badge status (Disetujui, Pending, Alpa), Header kolom tabel. |
| **Label Small**    | *Plus Jakarta Sans* | 10 sp | Medium (500) | 14 sp | Timestamp audit trail, caption footnote SKS semester. |

---

### 3.4 Penerapan di Flutter (`google_fonts`)

```yaml
# pubspec.yaml
dependencies:
  google_fonts: ^6.2.1
```

```dart
// lib/app/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Primary Font: Plus Jakarta Sans (UI, Body, Headings, Display)
  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  // Display angka hero (IPK): sama, cukup Bold besar
  static TextStyle get displayIpk => GoogleFonts.plusJakartaSans(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  // Monospace Font: JetBrains Mono (NIM, Kode MK, Nilai Huruf)
  static TextStyle get identifierCode => GoogleFonts.jetbrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );
}
```

---

## 4. Sistem Spacing, Radius, & Elevasi

### 4.1 Skala Spacing (4-Point Grid)

Konsistensi tata letak dijaga dengan kelipatan 4dp:

| Token | Ukuran | Contoh Penggunaan |
| :--- | :--- | :--- |
| `space-xxs` | 4 dp | Jarak antara icon dengan teks label kecil, margin badge. |
| `space-xs`  | 8 dp | Jarak internal form field, padding badge status. |
| `space-sm`  | 12 dp | Jarak antar item list padat (jadwal harian, opsi dropdown). |
| `space-md`  | 16 dp | Padding default Card, padding body halaman mobile. |
| `space-lg`  | 24 dp | Jarak antar Card section, padding modal dialog. |
| `space-xl`  | 32 dp | Jarak vertikal antar blok modul dashboard. |
| `space-2xl` | 48 dp | Margin container desktop, spacing halaman login. |

### 4.2 Border Radius

Menghadirkan kesan antarmuka yang ramah dan modern:

- **Radius XS (4 dp)**: Checkbox, tooltip, badge tag mini.
- **Radius SM (8 dp)**: Input text field, dropdown button, chip filter.
- **Radius MD (12 dp)**: Standard Card (Jadwal, Mata Kuliah, Pengumuman), Modal dialog.
- **Radius LG (16 dp)**: Floating action sheet, summary hero card.
- **Radius Full (999 dp)**: Pill badge status (e.g. `Hadir`, `Disetujui`), avatar profil, circular button.

### 4.3 Elevasi & Shadow

| Tingkat | Blur & Offset | Penggunaan |
| :--- | :--- | :--- |
| **Level 0 (Flat)** | `none` + 1px border (`#E2E8F0`) | Card dalam tabel, list item terstruktur. |
| **Level 1 (Subtle)** | `0px 2px 4px rgba(0, 0, 0, 0.04)` | Standard Content Card (Mata Kuliah, Jadwal Kuliah). |
| **Level 2 (Hover/Active)**| `0px 4px 12px rgba(30, 58, 138, 0.08)` | Card saat di-hover di Web/Windows, Dropdown menu. |
| **Level 3 (Floating)**| `0px 10px 24px rgba(15, 23, 42, 0.12)` | Bottom Sheet mobile, Floating Action Button. |
| **Level 4 (Modal)** | `0px 20px 32px rgba(15, 23, 42, 0.20)` | Dialog konfirmasi hapus/batal KRS, Preview PDF KHS. |

---

## 5. Tata Letak & Responsivitas Multiplatform

SIAKAD KAMPUS berjalan di **Android** (Handphone/Tablet), **Web Browser**, dan **Windows Desktop**. Desain harus beradaptasi secara mulus.

### 5.1 Breakpoints Layar

| Device Target | Lebar Layar (Width) | Tipe Layout | Grid Kolom |
| :--- | :--- | :--- | :--- |
| **Compact (Mobile)** | `< 600 dp` | Single Column vertikal, scroll-first | 4 Kolom |
| **Medium (Tablet / Foldable)** | `600 dp – 1023 dp` | Dual Column (Master-Detail) | 8 Kolom |
| **Expanded (Web / Windows)** | `≥ 1024 dp` | Multi-Column Dashboard (Sidebar + Canvas + Info Panel) | 12 Kolom |

---

### 5.2 Pola Navigasi per Perangkat

```
[ ANDROID / COMPACT ]
┌──────────────────────────┐
│ [≡] SIAKAD       [🔔][👤]│  ← Top App Bar
├──────────────────────────┤
│                          │
│                          │
│     Content Area         │  ← Single column list
│     (Vertical Scroll)    │
│                          │
├──────────────────────────┤
│ [🏠] [📅] [📚] [📊] [⚙️] │  ← Bottom Navigation Bar (5 tabs)
└──────────────────────────┘

[ WEB & WINDOWS / EXPANDED ]
┌──────────────┬───────────────────────────────────────────┐
│ SIAKAD LOGO  │ [🔍 Cari MK/NIM...]       [🔔] [Mode] [👤]│ ← Header
├──────────────┼───────────────────────────────────────────┤
│ [🏠] Beranda  │ Breadcrumb: Home > Akademik > KRS         │
│ [📚] KRS     │ ┌───────────────────────────────────────┐ │
│ [📊] KHS     │ │ Metric Cards (IPK, SKS, Semester)     │ │
│ [📅] Jadwal  │ └───────────────────────────────────────┘ │
│ [👥] Dosen   │ ┌───────────────────────────────────────┐ │
│ [⚙️] Admin   │ │ Data Table with Filter & Export       │ │
│              │ │                                       │ │
│ [🚪] Logout  │ └───────────────────────────────────────┘ │
└──────────────┴───────────────────────────────────────────┘
   Sidebar                      Main Work Area
```

---

## 6. Spesifikasi Komponen Inti UI Akademik

### 6.1 Metric & Summary Card

Digunakan pada Dashboard Mahasiswa, Dosen, dan Admin untuk menampilkan statistik utama:

- **Komposisi**: Icon container berlatar lembut + Label judul kecil + Nilai statistik ukuran besar + Sub-keterangan tren atau status.
- **Aksen Khusus**: IPK Cumlaude (≥ 3.50) mendapatkan badge bintang emas (`#FFEE2E`).

```
┌──────────────────────────────────────┐
│  (★) Indeks Prestasi Kumulatif (IPK)  │
│  3.84                                │
│  ● Semester 5 • 96 / 144 SKS Tempuh  │
└──────────────────────────────────────┘
```

### 6.2 Jadwal & Mata Kuliah Card

Menampilkan informasi jadwal perkuliahan harian:
- **Warna Aksen Kiri (Indicator Strip)**: 4dp garis vertikal penanda status kelas (Hijau: Sedang Berlangsung, Biru: Akan Datang, Abu: Selesai).
- **Elemen Teks**: Jam (e.g. `08:00 - 10:30 WIB`), Ruang (e.g. `Lab Komputer 302`), Kode & Nama MK, Dosen Pengampu, Jumlah SKS (Pill Badge).

### 6.3 Data Table & Grid (KRS, KHS, Nilai)

Khusus tampilan Web & Windows:
- **Header**: Background `#F1F5F9` (Dark: `#16233B`), teks SemiBold, ikon sortir.
- **Row Styling**: Alternating strip (zebra table) untuk memudahkan pembacaan baris yang panjang.
- **Action Column**: Icon button ringkas (Edit, Hapus, Detail, Cetak KHS) dengan tooltip deskriptif.
- **Sticky Column & Header**: Kolom Mata Kuliah dan Header tetap terlihat saat di-scroll horizontal atau vertikal.

### 6.4 Form & Input Controls

- **Standard State**: Border `1.5px` warna `#E2E8F0`, latar `#FFFFFF`.
- **Focus State**: Border `2px` warna `#1E3A8A`, subtle outer glow `0 0 0 3px rgba(30, 58, 138, 0.15)`.
- **Error State**: Border `1.5px` warna `#EC1431`, pesan helper error teks merah di bawah field.
- **Disabled State**: Latar `#F1F5F9`, border `#CBD5E1`, text `#94A3B8`.

### 6.5 Status Badges & Chips

Format badge pill (`border-radius: 999px`, padding horizontal `10dp`, vertical `4dp`):

- **KRS Disetujui / Lulus**: Latar `#DCFCE7`, Teks `#15803D`, Icon Checkmark `●`.
- **KRS Menunggu Approval**: Latar `#FEF3C7`, Teks `#B45309`, Icon Jam Pasir `●`.
- **KRS Ditolak / Tidak Lulus**: Latar `#FEE2E2`, Teks `#B91C1C`, Icon Silang `●`.
- **Draft / Belum Diajukan**: Latar `#F1F5F9`, Teks `#475569`, Icon Pensil `●`.

### 6.6 Buttons & Actions

1. **Primary Button**: Background `#1E3A8A`, Teks Putih `#FFFFFF`, Hover `#172554`. Digunakan untuk aksi utama seperti *"Simpan KRS"*, *"Ajukan Validasi"*, *"Login"*.
2. **Secondary / Outlined Button**: Border `#1E3A8A`, Teks `#1E3A8A`, Background transparan. Digunakan untuk *"Download PDF"*, *"Batal"*, *"Kembali"*.
3. **Destructive Button**: Background `#C81E30`, Teks Putih (5.7:1). Digunakan untuk *"Drop Mata Kuliah"*, *"Hapus Akun"*. Token `#EC1431` hanya fill dekoratif — sebagai teks/button di atas putih hanya 4.46:1, di bawah ambang AA.
4. **Gold Highlight Button**: Background `#FFEE2E`, Teks `#0F172A`, Weight Bold. Digunakan untuk promosi/aksi unggulan khusus wisuda atau beasiswa.

---

## 7. Micro-Interactions & State Feedback

### 7.1 State Interaksi

- **Hover (Web/Windows)**: Transisi halus `150ms ease-in-out` pada card elevasi, button color change, dan cursor otomatis berubah menjadi `SystemMouseCursors.click`.
- **Press Effect (Mobile)**: Efek Material Ripple lembut (*ink splash*) dengan opacity `0.12`.

### 7.2 Loading & Skeleton States

- Dilarang membiarkan layar kosong saat data jadwal/transkrip sedang dimuat dari Supabase.
- Gunakan **Skeleton Shimmer Loader** dengan bentuk yang menyerupai tabel atau card yang sedang diambil datanya.
- Warna shimmer: `#E2E8F0` ke `#F8FAFC` (Light Mode), `#1E2E4A` ke `#16233B` (Dark Mode).

### 7.3 Empty States

Setiap list tanpa data (e.g. *Belum ada jadwal hari ini*, *Transkrip semester belum terbit*) harus memiliki:
- Ilustrasi visual / Icon tematik berukuran `80dp` ber-opacity `0.6`.
- Headline jelas (e.g. *"Tidak Ada Jadwal Kuliah Hari Ini"*).
- Pesan pendukung (e.g. *"Anda bebas hari ini, silakan periksa tugas atau agenda mandiri."*).
- Tombol aksi cepat jika relevan (e.g. *"Lihat Kalender Akademik"*).

### 7.4 SnackBars & Alerts

- Tampil melayang (*floating*) dengan margin `16dp` dan radius `12dp`.
- Menyertakan icon status di sisi kiri:
  - Sukses: Icon centang bulat hijau.
  - Peringatan: Icon segitiga seru amber.
  - Error: Icon tanda silang merah dengan action button *"Coba Lagi"*.

---

## 8. Panduan Aksesibilitas (WCAG 2.1 AA)

1. **Contrast Ratio**:
   - Teks normal (< 18pt) memiliki rasio kontras terhadap background minimal **4.5:1**.
   - Teks besar (≥ 18pt atau bold ≥ 14pt) minimal **3.0:1**.
   - Seluruh kombinasi warna Indigo Blue (`#1E3A8A`) di atas Snow White (`#F8FAFC`) memiliki rasio **9.9:1** (lolos AAA). Angka ini hasil hitung WCAG 2.1, diverifikasi ulang oleh `test/color_contrast_test.dart` — jangan dikoreksi manual tanpa menjalankan test.
2. **Touch Target Size**:
   - Seluruh elemen interaktif pada Android memiliki ukuran target sentuh minimal **48 x 48 dp**.
3. **Keyboard Navigation (Web & Windows)**:
   - Pengguna dapat bernavigasi menggunakan tombol `Tab`, `Shift+Tab`, `Enter`, dan `Space`.
   - Focus indicator outline jelas (`2dp outline` warna Indigo Light `#3B82F6`).
   - Dukungan shortcut keyboard umum: `Ctrl + S` (Simpan form), `Esc` (Tutup modal), `Ctrl + F` (Fokus pencarian data).
4. **Screen Reader Semantics**:
   - Widget kustom wajib dibungkus dengan `Semantics(label: "...", role: "...")` agar ramah bagi tunanetra.

---

## 9. Referensi Implementasi Flutter (`theme.dart`)

Berikut struktur implementasi `ThemeData` Flutter terpusat. Berkas implementasi yang sebenarnya ada di `lib/app/theme/app_colors.dart`, `lib/app/theme/app_typography.dart`, dan `lib/app/theme/siakad_theme.dart` — bukan `frontend/lib/app/theme.dart` (repo ini tidak punya folder `frontend/`).

```dart
// lib/app/theme/siakad_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SiakadTheme {
  // Brand Colors
  static const Color primaryIndigo = Color(0xFF1E3A8A);
  static const Color secondaryGold = Color(0xFFFFEE2E);
  static const Color canvasSnowWhite = Color(0xFFF8FAFC);
  static const Color canvasDarkAbyss = Color(0xFF060A17);
  static const Color cardDarkSurface = Color(0xFF0E172B);
  static const Color cardDarkElevated = Color(0xFF16233B);
  static const Color borderDark = Color(0xFF1E2E4A);
  static const Color primaryDarkIndigo = Color(0xFF4F75FF);
  static const Color accentDarkGold = Color(0xFFF5CD68);

  // Semantics — nilai *fill* (badge/ikon/indikator), BUKAN warna teks.
  // Untuk teks di atas surface terang, pakai *-ink dari AppColors.
  static const Color colorPass = Color(0xFF3FD478);
  static const Color colorAlert = Color(0xFFE1E11E);
  static const Color colorWarning = Color(0xFFEC1431);

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryIndigo,
      scaffoldBackgroundColor: canvasSnowWhite,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      colorScheme: const ColorScheme.light(
        primary: primaryIndigo,
        secondary: secondaryGold,
        surface: Colors.white,
        error: colorWarning,
        onPrimary: Colors.white,
        onSecondary: Color(0xFF0F172A),
        onSurface: Color(0xFF0F172A),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: colorWarning),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryDarkIndigo,
      scaffoldBackgroundColor: canvasDarkAbyss,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      colorScheme: const ColorScheme.dark(
        primary: primaryDarkIndigo,
        secondary: accentDarkGold,
        surface: cardDarkSurface,
        error: Color(0xFFF43F5E),
        onPrimary: Color(0xFF060A17),
        onSecondary: Color(0xFF060A17),
        onSurface: Color(0xFFEDF2F7),
      ),
      cardTheme: CardTheme(
        color: cardDarkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderDark),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardDarkSurface,
        foregroundColor: Color(0xFFEDF2F7),
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDarkElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryDarkIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF43F5E)),
        ),
      ),
    );
  }
}
```
