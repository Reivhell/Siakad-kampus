# 14 — Rekomendasi Kelas

> Status: TURUNAN KANONIS — memperkaya `Rencana.md §12` ("mengambil KRS sesuai periode") dan route `/mahasiswa/krs` (§19). **Tanpa tabel baru**; memakai `kurikulum_mata_kuliah`, `nilai`, `kelas`, `jadwal_kelas`, dan prasyarat dari `15`.

## 1. Fungsi

Menjawab "MK apa yang sebaiknya saya ambil semester ini?" dengan urutan yang bisa dipertanggungjawabkan, bukan sekadar daftar semua kelas. Rekomendasi tampil di dalam layar KRS (`03`) sebagai panel samping, bukan route transaksi baru.

## 2. Status per MK

| Status | Syarat |
|:---|:---|
| `LULUS` | Punya nilai final dengan huruf lulus (default `A`–`C`) |
| `SEDANG_DIAMBIL` | Ada KRS periode aktif untuk MK tersebut |
| `BISA_DIAMBIL` | Belum lulus, prasyarat terpenuhi (`15`), kelas dibuka di periode aktif |
| `TERKUNCI_PRASYARAT` | Belum lulus dan minimal satu prasyarat belum terpenuhi |
| `BELUM_PERIODE` | `semester_rekomendasi` lebih tinggi dari semester berjalan |

## 3. Skor Prioritas

Urutkan `BISA_DIAMBIL` dengan skor menurun:

1. `semester_rekomendasi` paling kecil (kejar angkatan).
2. `jenis = 'WAJIB'` sebelum `PILIHAN`.
3. MK yang jadi prasyarat MK lain di kurikulum (unlock effect).
4. Sisa kuota kelas lebih besar.

Kemudian pilih greedy sampai plafon SKS (`03`) habis, dengan syarat tidak bentrok jadwal satu sama lain **dan** dengan KRS yang sudah ada. Tampilkan alasan singkat per baris: "wajib semester 5", "membuka TI401", "kuota 32/40".

## 4. Query Dasar

```sql
-- MK kurikulum aktif prodi yang belum lulus
SELECT mk.id, mk.kode, mk.nama, mk.sks, mk.jenis, kmk.semester_rekomendasi
FROM kurikulum k
JOIN kurikulum_mata_kuliah kmk ON kmk.id_kurikulum = k.id
JOIN mata_kuliah mk ON mk.id = kmk.id_mata_kuliah
WHERE k.aktif = true
  AND k.id_program_studi = (
    SELECT id_program_studi FROM mahasiswa WHERE npm = $1
  )
  AND NOT EXISTS (
    SELECT 1
    FROM krs
    JOIN kelas kl ON kl.id_kelas = krs.id_kelas
    JOIN nilai n ON n.id_krs = krs.id
    WHERE krs.id_mahasiswa = $1
      AND kl.id_mata_kuliah = mk.id
      AND n.sudah_final = true
      AND n.huruf_nilai IN ('A', 'AB', 'B', 'BC', 'C')
  );
```

Kelas yang ditawarkan:

```sql
SELECT k.id, k.kode, k.kapasitas, k.jumlah_terdaftar
FROM kelas k
WHERE k.id_mata_kuliah = $1
  AND k.id_periode_akademik = $2
  AND k.jumlah_terdaftar < k.kapasitas;
```

## 5. Aturan Bisnis

- Kurikulum acuan = kurikulum `aktif = true` milik prodi mahasiswa. Bila tidak ada, fallback ke kurikulum dengan `tahun` terdekat di bawah `tahun_masuk` dan tampilkan peringatan.
- Status kelulusan MK memakai ambang yang sama dengan prasyarat (default `C`); jangan hard-code berbeda di dua modul.
- Rekomendasi **tidak mendaftarkan** apa pun. Tombol "Tambahkan" tetap memanggil alur `03` dan validasi yang sama.
- Bila periode aktif belum ada, tampilkan mode pratinjau tanpa tombol tambah.
- Batasi 20 baris rekomendasi; sisanya di balik "lihat semua".

## 6. Wireframe

```
┌────────────────────────────────────────────────────┐
│ Rekomendasi Semester Ini         Plafon 21 SKS     │
├────────────────────────────────────────────────────┤
│ ☑ TI301 Basis Data   3 SKS  Wajib smt 5  [Bisa]   │
│ ☑ TI302 Jaringan     3 SKS  Wajib smt 5  [Bisa]   │
│ ☐ TI401 AI           3 SKS  Butuh TI301  [Kunci]  │
│ ☐ TI310 Pilihan      2 SKS  Pilihan      [Bisa]   │
├────────────────────────────────────────────────────┤
│ Terpilih 6 SKS · sisa plafon 15 SKS                │
└────────────────────────────────────────────────────┘
```

## 7. Edge Cases

- Prasyarat belum selesai tapi nilai sedang menunggu finalisasi → status `SEDANG_DIAMBIL`, jangan blokir (kebijakan: tunggu final).
- Kelas penuh semua → tampilkan "kuota habis" + arahkan lapor Admin (force-add di `fitur_admin/07`).
- MK sudah lulus tapi muncul lagi karena kurikulum berbeda versi → prioritaskan riwayat lulus, tandai sebagai "sudah ditempuh pada kurikulum lama".
