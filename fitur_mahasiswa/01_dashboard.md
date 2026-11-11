# 01 — Dashboard / Info Akademik Mahasiswa

> Status: KANONIS — `Rencana.md §12` (melihat informasi akademik) + `§16` (fitur `dashboard/` lintas-role, BUKAN route `/mahasiswa/dashboard`) + `§27` (Login→Dashboard). Layar ini agregat read-only dari 5 service kanonis; tidak ada service backend sendiri (§17).

## 1. Tujuan & Ruang Lingkup

Satu layar status studi, read-only agregat. Filter `periode_akademik.aktif = true` dan `krs.id_mahasiswa = npm sendiri`. Kode Flutter: `lib/mahasiswa/dashboard/` + `lib/features/mahasiswa/`.

KPI: IPK/IPS, SKS tempuh/lulus, jadwal hari ini, status KRS, alert presensi merah.

## 2. Wireframe

```
┌─────────────────────────────────────────────────┐
│ Halo, Reza (2410010015)      S1 TI ● AKTIF      │
│ IPK 3.42 | SKS 68/144 | Semester 5             │
├─────────────────────────────────────────────────┤
│ 📅 Hari ini: 2 kelas                            │
│ 08:00 TI301-A Basis Data @Lab-1                 │
│ 13:00 TI302-B Jaringan @R-201                   │
├─────────────────────────────────────────────────┤
│ 🟡 KRS: MENUNGGU_APPROVAL (21 SKS)              │
│ 🔴 Presensi kritis: TI302-B 68%                 │
└─────────────────────────────────────────────────┘
```

## 3. Aturan Bisnis

- SKS tempuh = sum SKS `krs AKTIF` periode aktif. SKS lulus = SKS dengan huruf final bukan E.
- Bobot: A=4, AB=3.5, B=3, BC=2.5, C=2, D=1, E=0. IPS = Σ(bobot×SKS)/ΣSKS.
- Alert merah jika ada MK kehadiran <75%.

## 4. Query

```sql
SELECT mk.nama, k.kode, jk.jam_mulai, r.kode AS ruangan
FROM krs
JOIN kelas k ON krs.id_kelas = k.id
JOIN mata_kuliah mk ON k.id_mata_kuliah = mk.id
JOIN jadwal_kelas jk ON jk.id_kelas = k.id
LEFT JOIN ruangan r ON jk.id_ruangan = r.id
WHERE krs.id_mahasiswa = $1 AND krs.status = 'AKTIF'
  AND jk.hari = EXTRACT(ISODOW FROM NOW())
ORDER BY jk.jam_mulai;
```

## 5. RLS & Edge Cases

- Policy: hanya baris `npm` sendiri (via `mahasiswa.id_user = auth.uid()`).
- Periode belum aktif → banner, sembunyikan KRS. Status CUTI/DO → kunci aksi.
