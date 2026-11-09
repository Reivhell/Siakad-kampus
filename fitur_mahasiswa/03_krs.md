# 03 — KRS 

> Status: KANONIS — `Rencana.md §12` (melihat + mengambil KRS sesuai periode), route `/mahasiswa/krs` (§19), service `krs_service` (§17), audit `STUDENT_SUBMITTED_KRS` (§15). Matriks plafon SKS-IPS, flow `MENUNGGU_APPROVAL`, `disetujui_oleh_pa`/`catatan_pa`, dan kode `MAHASISWA_BATALKAN_KRS` = EKSTENSI dari `fitur_admin/07`, bukan kontrak Rencana.

## 1. Flow

`DRAFT → MENUNGGU_APPROVAL → AKTIF` (disahkan PA/Admin) atau `BATAL`. Batal mandiri hanya sampai minggu ke-2 (KPRS).

## 2. Aturan Bisnis

Plafon SKS dari IPS lalu: >=3.00→24, >=2.50→21, >=2.00→18, >=1.50→15, <1.50→12, smt 1-2 paket 20.

Tolak jika: kelas penuh (`jumlah_terdaftar >= kapasitas`), bentrok `jadwal_kelas`, duplikat MK sama, over SKS, status bukan AKTIF, atau **prasyarat belum terpenuhi** (`15_prasyarat_mata_kuliah.md`).

Panel rekomendasi MK mengikuti `14_rekomendasi_kelas.md`; rekomendasi tidak mendaftarkan otomatis.

```dart
int maxSks({required int semester, required double? ipsLalu}) {
  if (semester <= 2 || ipsLalu == null) return 20;
  if (ipsLalu >= 3.0) return 24;
  if (ipsLalu >= 2.5) return 21;
  if (ipsLalu >= 2.0) return 18;
  if (ipsLalu >= 1.5) return 15;
  return 12;
}
```

## 3. Audit & Edge Cases

- Setiap ajukan/batal → `log_aktivitas` (`MAHASISWA_AJUKAN_KRS` / `MAHASISWA_BATALKAN_KRS`).
- Race slot terakhir → `SELECT ... FOR UPDATE` di `kelas` dalam transaksi.
- KRS ditolak PA → tampilkan `catatan_pa`, kembali ke DRAFT.
