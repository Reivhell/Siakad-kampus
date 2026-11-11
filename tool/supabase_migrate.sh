#!/usr/bin/env bash
# Migrasi SIAKAD: PostgreSQL lokal -> Supabase (schema + reference + auth + data).
#
# Wajib:
#   SUPABASE_DB_URL   connection string Postgres Supabase, mis.
#                     postgresql://postgres.<ref>:<password>@aws-0-<region>.pooler.supabase.com:5432/postgres?sslmode=require
# Opsional:
#   LOCAL_DATABASE_URL  default postgresql://postgres@127.0.0.1:5432/siakad
#   SCHEMA_ONLY=1       hanya schema + reference, tanpa auth.users/data
#
# Jalankan dari root repo: ./tool/supabase_migrate.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -f backend/web_server/.env ]]; then
  set -a
  # shellcheck disable=SC1091
  source backend/web_server/.env
  set +a
fi

: "${SUPABASE_DB_URL:?Set SUPABASE_DB_URL ke connection string Supabase (sslmode=require)}"
LOCAL_DATABASE_URL="${LOCAL_DATABASE_URL:-postgresql://postgres@127.0.0.1:5432/siakad}"
DUMP_FILE="$(mktemp)"
trap 'rm -f "$DUMP_FILE"' EXIT

# pg_dump 18 menulis SET transaction_timeout yang tidak ada di PG < 17.
strip_pg18_settings() { sed '/^SET transaction_timeout = 0;$/d'; }

echo "==> 1/5 cek koneksi"
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -tAc 'select 1' >/dev/null
[[ "${SCHEMA_ONLY:-0}" == "1" ]] || psql "$LOCAL_DATABASE_URL" -v ON_ERROR_STOP=1 -tAc 'select 1' >/dev/null

echo "==> 2/5 schema migrations"
dart run tool/db.dart migrate --env supabase --url "$SUPABASE_DB_URL"

if [[ "${SCHEMA_ONLY:-0}" == "1" ]]; then
  echo "==> 3/5 auth.users + data dilewati"
else
  echo "==> 3/5 auth.users (UUID + bcrypt hash dipertahankan)"
  pg_dump "$LOCAL_DATABASE_URL" \
    --data-only --table=auth.users \
    --column-inserts --on-conflict-do-nothing \
    --no-owner --no-privileges \
    | strip_pg18_settings \
    | psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -q
  psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -q -f database/supabase/001_auth_fix.sql

  echo "==> 4/5 data public"
  pg_dump "$LOCAL_DATABASE_URL" \
    --data-only --exclude-schema=auth \
    --exclude-table=public.schema_migrations \
    --column-inserts --on-conflict-do-nothing \
    --no-owner --no-privileges \
    | strip_pg18_settings > "$DUMP_FILE"
  # Trigger audit menimpa hash yang sudah tersimpan saat insert. Matikan
  # selama restore; transaksi membuat trigger aktif lagi bila gagal.
  {
    echo 'BEGIN;'
    echo 'ALTER TABLE public.log_aktivitas DISABLE TRIGGER trg_audit_chain;'
    cat "$DUMP_FILE"
    echo 'ALTER TABLE public.log_aktivitas ENABLE TRIGGER trg_audit_chain;'
    echo 'COMMIT;'
  } | psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -q
fi

# Data lokal sudah membawa reference rows (dengan UUID asli). Seed hanya
# melengkapi baris yang belum ada; ON CONFLICT membuatnya tidak menimpa.
echo "==> 5/5 reference seed"
dart run tool/db.dart seed --env supabase --url "$SUPABASE_DB_URL"

echo "==> verify"
dart run tool/db.dart verify --url "$SUPABASE_DB_URL"
