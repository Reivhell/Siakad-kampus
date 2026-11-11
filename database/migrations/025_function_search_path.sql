-- Fungsi trigger tidak boleh bergantung pada search_path sesi.
-- pg_dump mereset search_path ke '' saat restore, sehingga nama tabel tanpa
-- schema (mis. `UPDATE kelas ...` di perbarui_jumlah_terdaftar) gagal.
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN
        SELECT p.oid::regprocedure AS sig
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
          AND p.prokind = 'f'
          AND NOT EXISTS (
              SELECT 1 FROM unnest(COALESCE(p.proconfig, '{}')) c
              WHERE c LIKE 'search_path=%'
          )
          AND NOT EXISTS (
              SELECT 1 FROM pg_depend d
              WHERE d.classid = 'pg_proc'::regclass
                AND d.objid = p.oid
                AND d.deptype = 'e'
          )
    LOOP
        EXECUTE format('ALTER FUNCTION %s SET search_path = public, pg_temp', r.sig);
    END LOOP;
END $$;
