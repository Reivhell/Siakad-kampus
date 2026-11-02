# 12 — Layanan Pengajuan Akademik (P2)

> Status: EKSTENSI P2 — di luar `Rencana.md` (§12 tidak mengatur pengajuan cuti, banding nilai, atau konversi untuk mahasiswa; tidak ada di §19/§17/§27). Modul ini menutup sisi mahasiswa dari tiga proses yang sisi adminnya sudah ada (`Admin.md` modul 08, 12, 14; `fitur_admin/07` untuk status KRS). Setiap sub-layanan membutuhkan migration baru — dilarang mengarang kolom pada tabel ERD v1 yang sudah baku.

## 12.1 Pengajuan Cuti & Aktif Kembali

- Latar: `mahasiswa.status` mengenal `CUTI` (ERD), tetapi tidak ada flow pengajuannya di Rencana maupun modul admin. Tanpa flow ini status CUTI hanya bisa diubah manual oleh Admin.
- Flow: mahasiswa ajukan (semester cuti, alasan, dokumen) → status `PENGAJUAN` → Admin setujui/tolak → `status` berubah + KRS periode berjalan ikut dibekukan (`MENGUNDURKAN_DIRI` bila sudah terisi).
- Kebutuhan data baru: tabel `pengajuan_cuti` (`npm`, `periode`, `alasan`, `status`, `diputus_oleh`, `diputus_pada`). Migration di luar ERD v1 — spek SQL menyusul saat backlog ini dieksekusi.
- Audit usulan: `MAHASISWA_AJUKAN_CUTI` (bukan kode kanonis §15).

## 12.2 Banding Nilai

- Latar: modul admin 08 memiliki mekanisme unlock nilai oleh Admin; Rencana tidak mengatur dari sisi mahasiswa bagaimana keberatan diajukan.
- Flow: dari KHS (`05`), tombol Ajukan Banding pada MK final (maks. N hari setelah `disubmit_pada`) → isi alasan → status `PENGAJUAN` → dosen pengampu tindak lanjuti (ubah nilai / tolak dengan alasan) → mahasiswa terima notifikasi hasil.
- Kebutuhan data baru: tabel `banding_nilai` (`id_krs`, `alasan`, `status`, `jawaban_dosen`). Tidak menyentuh tabel `nilai` sebelum dosen memutuskan.
- Audit usulan: `MAHASISWA_AJUKAN_BANDING`.

## 12.3 Pengajuan Konversi / Transfer / MBKM

- Latar: sisi mahasiswa dari modul admin 14 (`14_konversi_nilai_dan_transfer`). Mahasiswa pindahan, alih jenjang, atau peserta MBKM mengajukan penyetaraan kredit.
- Flow: pilih jenis (pindahan / alih jenjang / MBKM 20 SKS) → unggah transkrip asal + daftar MK yang dimohonkan → status `PENGAJUAN` → Kaprodi/Admin petakan (`equivalence mapping`) → hasil masuk sebagai pengakuan kredit.
- Kebutuhan data baru: tabel `pengajuan_konversi` + `konversi_mapping`. Lihat modul admin 14 untuk format SK penyetaraan.
- Audit usulan: `MAHASISWA_AJUKAN_KONVERSI`.

## Aturan lintas sub-layanan

1. Semua pengajuan read-own + RLS npm sendiri; daftar pengajuan = riwayat milik sendiri.
2. Tanpa migration yang disahkan, modul ini tidak diimplementasikan — status tetap backlog.
3. Tidak mengubah kontrak kanonis P0 (§3a `Mahasiswa.md`).
