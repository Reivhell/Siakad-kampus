# 05 — Nilai & KHS

> Status: KANONIS — `Rencana.md §12` (melihat nilai) + workflow "Mahasiswa melihat nilai" (§27), route `/mahasiswa/nilai` (§19), service `nilai_service` (§17).

## Aturan

- `sudah_final = false` → watermark DRAFT. Final → tampilkan `disubmit_pada`, kunci.
- IPS = Σ(bobot×SKS)/ΣSKS (hanya yang ada huruf). RLS own-data via `krs`.

```sql
SELECT mk.kode, mk.nama, mk.sks, n.nilai_uts, n.nilai_uas,
       n.nilai_tugas, n.nilai_akhir, n.huruf_nilai, n.sudah_final
FROM krs
JOIN kelas k ON krs.id_kelas = k.id
JOIN mata_kuliah mk ON k.id_mata_kuliah = mk.id
LEFT JOIN nilai n ON n.id_krs = krs.id
WHERE krs.id_mahasiswa = $1 AND krs.id_periode_akademik = $2
ORDER BY mk.kode;
```

## Edge Cases

- Nilai belum diinput → strip `-`, jangan hitung IPS. Mengulang → tampilkan riwayat, tandai lulus.
- Panel simulasi target IPK: lihat `13_kalkulator_ipk.md` (baca-saja, tanpa tabel baru).
