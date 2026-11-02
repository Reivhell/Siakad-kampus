# 04 — Jadwal Kuliah

> Status: KANONIS — `Rencana.md §12` (melihat jadwal), route `/mahasiswa/jadwal` (§19), service `jadwal_service` (§17). Kode: fitur `jadwal/` + `mahasiswa/` (§16).

## Aturan

- Grid Senin-Minggu dari `jadwal_kelas` join `krs AKTIF` sendiri. Read-only.
- Badge pengampu utama vs co-dosen. `id_ruangan` NULL → `Ruang menyusul`.

```sql
SELECT jk.hari, jk.jam_mulai, jk.jam_selesai, mk.nama, k.kode,
       r.kode AS ruangan, d.nama_lengkap AS dosen
FROM krs
JOIN kelas k ON krs.id_kelas = k.id
JOIN mata_kuliah mk ON k.id_mata_kuliah = mk.id
JOIN jadwal_kelas jk ON jk.id_kelas = k.id
LEFT JOIN ruangan r ON jk.id_ruangan = r.id
LEFT JOIN kelas_dosen kd ON kd.id_kelas = k.id AND kd.pengampu_utama = true
LEFT JOIN dosen d ON kd.id_dosen = d.nidn
WHERE krs.id_mahasiswa = $1 AND krs.status = 'AKTIF'
  AND k.id_periode_akademik = $2
ORDER BY jk.hari, jk.jam_mulai;
```
