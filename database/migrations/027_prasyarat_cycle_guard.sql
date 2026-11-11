CREATE OR REPLACE FUNCTION public.fn_check_prasyarat_cycle()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.id_mata_kuliah_syarat IS NULL THEN
        RETURN NEW;
    END IF;

    IF NEW.id_mata_kuliah = NEW.id_mata_kuliah_syarat THEN
        RAISE EXCEPTION
            'Mata kuliah % tidak boleh menjadi prasyarat dirinya sendiri',
            NEW.id_mata_kuliah;
    END IF;

    IF EXISTS (
        WITH RECURSIVE prerequisite_chain(id) AS (
            SELECT NEW.id_mata_kuliah_syarat
            UNION
            SELECT p.id_mata_kuliah_syarat
            FROM public.prasyarat_mata_kuliah p
            JOIN prerequisite_chain chain
              ON p.id_mata_kuliah = chain.id
            WHERE p.id_kurikulum = NEW.id_kurikulum
              AND p.id_mata_kuliah_syarat IS NOT NULL
              AND p.id <> NEW.id
        )
        SELECT 1
        FROM prerequisite_chain
        WHERE id = NEW.id_mata_kuliah
    ) THEN
        RAISE EXCEPTION
            'Siklus prasyarat terdeteksi pada mata kuliah % dalam kurikulum %',
            NEW.id_mata_kuliah,
            NEW.id_kurikulum;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prasyarat_no_cycle
    ON public.prasyarat_mata_kuliah;

CREATE TRIGGER trg_prasyarat_no_cycle
    BEFORE INSERT OR UPDATE OF
        id_kurikulum,
        id_mata_kuliah,
        id_mata_kuliah_syarat
    ON public.prasyarat_mata_kuliah
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_check_prasyarat_cycle();
