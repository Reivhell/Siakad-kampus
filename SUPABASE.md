# Migrasi PostgreSQL lokal → Supabase

Skrip: `tool/supabase_migrate.sh`. Menerapkan schema, memindahkan `auth.users`
(UUID + bcrypt hash dipertahankan), lalu menyalin seluruh data `public`.

## Yang harus disiapkan

Isi `backend/web_server/.env` (jangan commit):

```dotenv
# Runtime backend
SUPABASE_URL=https://<ref>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
JWT_SECRET=<acak-min-32-karakter>
APP_ENV=production

# Migrasi (Session Pooler, port 5432)
SUPABASE_DB_URL=postgresql://postgres.<ref>:<password>@aws-0-<region>.pooler.supabase.com:5432/postgres?sslmode=require
```

`SUPABASE_DB_URL` memakai **Session Pooler :5432**. Port 6543 (transaction mode)
tidak cocok untuk migrasi. URL-encode karakter khusus di password.

Prasyarat: project Supabase baru/kosong, PostgreSQL 15+, `psql` + `pg_dump` 16+
terpasang, dan database lokal berisi data yang mau dipindah.

## Jalankan

```bash
# 1. Backup dulu (wajib)
pg_dump "$DATABASE_URL" -Fc -f /tmp/siakad-local.dump
pg_dump "$SUPABASE_DB_URL" -Fc -f /tmp/siakad-supabase-before.dump

# 2. Migrasi penuh
./tool/supabase_migrate.sh

# Opsi
SCHEMA_ONLY=1 ./tool/supabase_migrate.sh   # schema + reference saja
```

Urutan skrip:

1. cek koneksi,
2. `tool/db.dart migrate --env supabase` (semua migrasi, stub lokal dilewati),
3. salin `auth.users` via `pg_dump`,
4. `database/supabase/001_auth_fix.sql` — isi `aud`/`role`/`instance_id`,
   buat `auth.identities`, pasang FK `public."user".id → auth.users.id`,
5. salin data `public` (kecuali `schema_migrations`),
6. seed reference idempoten, lalu verifikasi.

`ON CONFLICT DO NOTHING` membuat skrip aman diulang. Reference seed dijalankan
setelah data agar UUID asli dari database lokal tidak tertimpa UUID konstan seed.

## Setelah migrasi

```bash
cd backend/web_server
dart_frog dev          # atau jalankan build production
```

Uji login memakai akun hasil migrasi (password lama tetap berlaku):

| Akun | Password |
|---|---|
| `admin@kampus.ac.id` | `Admin#12345` |
| `dosen@kampus.ac.id` | `Dosen#12345` |
| `mahasiswa@kampus.ac.id` | `Mhs#12345` |

Cek cepat di SQL Editor Supabase:

```sql
select count(*) from public."user";
select count(*) from auth.users;
select count(*) from public.user_role;
select count(*) from auth.identities where provider = 'email';
```

## Project yang sudah berisi data

Jangan langsung restore. Bandingkan dulu jumlah baris/hash per tabel. Kalau data
sudah identik, cukup perbaiki schema dan auth:

```bash
dart run tool/db.dart migrate --env supabase
psql "$SUPABASE_DB_URL" -f database/supabase/001_auth_fix.sql
```

`tool/db.dart` sekarang menolak `--env local` untuk host non-lokal, karena
`local_000_supabase_stub` pernah ikut diterapkan ke project Supabase. Efeknya:
`auth.users` tanpa `aud`/`role`/`identity` → login GoTrue gagal. `001_auth_fix.sql`
memperbaikinya tanpa mengubah password.

## Catatan

- Stub `database/local/000_supabase_stub.sql` **tidak** dijalankan; Supabase sudah
  punya `auth` schema dan role `anon`/`authenticated`/`service_role`.
- `fn_audit_chain` memakai `digest()` dari schema `extensions`; migration `026`
  menambahkan schema itu ke `search_path`. Tanpa ini insert `log_aktivitas` gagal
  di Supabase.
- Password tidak di-reset: hash bcrypt disalin apa adanya, sehingga pengguna
  tidak perlu mengganti sandi.
- File Storage (avatar/dokumen) tidak ikut. Pindahkan bucket terpisah bila ada.
- Jangan pernah memakai service-role key di aplikasi Flutter.
- Rollback: restore dump `siakad-supabase-before.dump`. Project Supabase gratis
  tidak punya PITR; buat backup manual sebelum menjalankan skrip.
