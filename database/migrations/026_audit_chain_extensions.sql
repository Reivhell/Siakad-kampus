-- pgcrypto di Supabase terpasang di schema extensions, bukan public.
-- fn_audit_chain memanggil digest(), jadi schema itu harus ada di search_path.
ALTER FUNCTION public.fn_audit_chain()
    SET search_path = public, extensions, pg_temp;
