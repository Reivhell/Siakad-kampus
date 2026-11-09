-- 022_buat_mata_kuliah_prasyarat.sql
-- Relasi prasyarat mata kuliah untuk validasi pengambilan KRS.
-- Referensi: fitur_mahasiswa/15_prasyarat_mata_kuliah.md
-- Catatan: ERD.md v1 belum memuat tabel ini; migration ini menambahkannya.

CREATE TABLE IF NOT EXISTS mata_kuliah_prasyarat (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_mata_kuliah uuid NOT NULL REFERENCES mata_kuliah(id) ON DELETE CASCADE,
    id_prasyarat   uuid NOT NULL REFERENCES mata_kuliah(id) ON DELETE RESTRICT,
    nilai_minimal  text NOT NULL DEFAULT 'C'
        CHECK (nilai_minimal IN ('A', 'AB', 'B', 'BC', 'C', 'D')),
    dibuat_pada    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_mk_prasyarat UNIQUE (id_mata_kuliah, id_prasyarat),
    CONSTRAINT chk_prasyarat_bukan_diri_sendiri
        CHECK (id_mata_kuliah <> id_prasyarat)
);

CREATE INDEX IF NOT EXISTS idx_mk_prasyarat_mk
    ON mata_kuliah_prasyarat (id_mata_kuliah);

CREATE INDEX IF NOT EXISTS idx_mk_prasyarat_prasyarat
    ON mata_kuliah_prasyarat (id_prasyarat);

-- Tolak relasi melingkar (A butuh B, B butuh A, dst.).
CREATE OR REPLACE FUNCTION cek_siklus_prasyarat()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        WITH RECURSIVE rantai(id) AS (
            SELECT NEW.id_prasyarat
            UNION
            SELECT mp.id_prasyarat
            FROM mata_kuliah_prasyarat mp
            JOIN rantai r ON mp.id_mata_kuliah = r.id
        )
        SELECT 1 FROM rantai WHERE id = NEW.id_mata_kuliah
    ) THEN
        RAISE EXCEPTION
            'Siklus prasyarat terdeteksi: mata kuliah % tidak boleh menjadi prasyarat dirinya sendiri secara tidak langsung',
            NEW.id_mata_kuliah;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_cek_siklus_prasyarat ON mata_kuliah_prasyarat;
CREATE TRIGGER trg_cek_siklus_prasyarat
    BEFORE INSERT OR UPDATE ON mata_kuliah_prasyarat
    FOR EACH ROW
    EXECUTE FUNCTION cek_siklus_prasyarat();

COMMENT ON TABLE mata_kuliah_prasyarat IS
    'Prasyarat MK; dicek di krs_service saat submit KRS. Lihat fitur_mahasiswa/15.';
