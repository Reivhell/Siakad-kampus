-- Local-only Supabase-compatible auth stub.
-- Never apply to a real Supabase project.

CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text UNIQUE,
    encrypted_password text,
    email_confirmed_at timestamptz,
    raw_user_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid
LANGUAGE sql STABLE AS $$
    SELECT NULLIF(
        COALESCE(
            current_setting('request.jwt.claim.sub', true),
            (NULLIF(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
        ),
        ''
    )::uuid
$$;

CREATE OR REPLACE FUNCTION auth.role() RETURNS text
LANGUAGE sql STABLE AS $$
    SELECT COALESCE(
        NULLIF(current_setting('request.jwt.claim.role', true), ''),
        (NULLIF(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
    )
$$;

CREATE OR REPLACE FUNCTION auth.jwt() RETURNS jsonb
LANGUAGE sql STABLE AS $$
    SELECT COALESCE(NULLIF(current_setting('request.jwt.claims', true), '')::jsonb, '{}'::jsonb)
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN BYPASSRLS;
    END IF;
END $$;

GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;
GRANT SELECT ON auth.users TO service_role;

-- Mirror existing app users so the FK below is valid.
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at)
SELECT u.id, lower(u.email), crypt('SIAKAD#2026', gen_salt('bf')), now()
FROM public."user" u
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'user_id_auth_fkey'
    ) THEN
        ALTER TABLE public."user"
            ADD CONSTRAINT user_id_auth_fkey
            FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE NOT VALID;
    END IF;
END $$;

ALTER TABLE public."user" VALIDATE CONSTRAINT user_id_auth_fkey;

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
