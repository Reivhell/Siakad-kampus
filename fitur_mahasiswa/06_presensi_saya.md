# 06 — Presensi Saya

> Status: KANONIS — `Rencana.md §12` (melihat presensi). Route `/mahasiswa/presensi` dari ARCHITECTURE (pelengkap; §19 tidak mencantumkannya). Service `presensi_service` (§17). Ambang 75%/85% = EKSTENSI dari modul admin, bukan kontrak Rencana.

## Aturan

- Status `HADIR/IZIN/SAKIT/ALPHA`. % = HADIR / total tercatat.
- Hijau >=85%, kuning 75-84%, merah <75% + banner syarat UAS.

```sql
SELECT p.pertemuan_ke, p.tanggal_pertemuan, p.topik, rp.status
FROM krs
JOIN rekap_presensi rp ON rp.id_krs = krs.id
JOIN presensi p ON rp.id_presensi = p.id
WHERE krs.id_mahasiswa = $1 AND krs.id_kelas = $2
ORDER BY p.pertemuan_ke;
```

## Edge Cases

- Belum dicatat dosen → `Belum dicatat`, jangan hitung alpha. KRS dibatalkan → riwayat dikunci.
