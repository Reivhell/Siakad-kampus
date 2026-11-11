# 02 — Profil & Status Mahasiswa

> Status: KANONIS — `Rencana.md §12` (melihat profil). Route `/mahasiswa/profil` dari ARCHITECTURE (pelengkap §12; §19 hanya mencantumkan krs/jadwal/nilai). Kode: fitur `profile/` + `mahasiswa/` (§16).

## 1. Ruang Lingkup

Tampilkan `npm (10 digit)`, `nama_lengkap`, `program_studi`, `tahun_masuk`, `status`, dosen wali. Edit terbatas: `telepon`, `url_avatar` di `user`. Kode: `lib/mahasiswa/profil/`.

## 2. Aturan Bisnis

- Validasi NPM `^[0-9]{10}$` (Angkatan2+Fak3+Prodi2+Urut3).
- Jika `status != 'AKTIF'`, kunci menu KRS dengan banner alasan.
- Perubahan profil tulis `log_aktivitas` (`MAHASISWA_UBAH_PROFIL`).

```sql
SELECT m.npm, m.nama_lengkap, m.status, ps.nama AS prodi, u.email, u.telepon
FROM mahasiswa m
JOIN program_studi ps ON m.id_program_studi = ps.id
JOIN "user" u ON m.id_user = u.id
WHERE m.npm = $1;
```

## 3. Edge Cases

- `id_user` NULL (belum link Auth) → tombol hubungi Admin.
- Avatar gagal load → fallback inisial.
