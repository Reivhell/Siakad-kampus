-- Supabase-only: rapikan auth.users hasil salinan dari PostgreSQL lokal.
-- Salinan pg_dump hanya membawa kolom stub lokal; Supabase butuh aud/role
-- dan auth.identities agar login email/password bekerja.
-- Aman dijalankan berulang.

UPDATE auth.users
SET aud = 'authenticated'
WHERE aud IS NULL OR aud = '';

UPDATE auth.users
SET role = 'authenticated'
WHERE role IS NULL OR role = '';

UPDATE auth.users
SET instance_id = '00000000-0000-0000-0000-000000000000'
WHERE instance_id IS NULL;

-- Samakan bentuk dengan user yang dibuat GoTrue.
UPDATE auth.users
SET raw_app_meta_data = jsonb_build_object(
        'provider', 'email',
        'providers', jsonb_build_array('email')
    )
WHERE raw_app_meta_data IS NULL OR raw_app_meta_data = '{}'::jsonb;

INSERT INTO auth.identities
    (provider_id, user_id, identity_data, provider, last_sign_in_at,
     created_at, updated_at)
SELECT
    u.id::text,
    u.id,
    jsonb_build_object(
        'sub', u.id::text,
        'email', u.email,
        'email_verified', u.email_confirmed_at IS NOT NULL,
        'phone_verified', false
    ),
    'email',
    NULL,
    COALESCE(u.created_at, now()),
    now()
FROM auth.users u
WHERE u.email IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM auth.identities i
      WHERE i.user_id = u.id AND i.provider = 'email'
  );

-- public."user".id harus sama dengan auth.users.id agar policy auth.uid() valid.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'user_id_auth_fkey'
          AND conrelid = 'public."user"'::regclass
    ) THEN
        ALTER TABLE public."user"
            ADD CONSTRAINT user_id_auth_fkey
            FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE NOT VALID;
    END IF;
END $$;

ALTER TABLE public."user" VALIDATE CONSTRAINT user_id_auth_fkey;
