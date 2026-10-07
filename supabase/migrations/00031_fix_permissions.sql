-- =============================================================================
-- KAZA: Fix critical permission errors (42501 Forbidden & Storage 403)
-- Migration: 00031_fix_permissions.sql
--
-- PROBLEMA 1: fn_upsert_profile y fn_update_profile_settings lanzaban Forbidden (42501) al crear cuenta.
--   - 00023 llamaba kaza_private.active() que podia fallar si el perfil era nuevo.
--   - 00030 introdujo un EXCEPTION handler que hacia UPDATE SET id=auth.uid()
--     sobre la PK, causando errores de integridad referencial.
--   - Solucion: funciones robustas que usan auth.uid() directamente y realizan UPSERT.
--
-- PROBLEMA 2: StorageException: new row violates row-level security policy (403 Unauthorized)
--   - El bucket 'avatars' no existia o no tenia politicas RLS creadas.
--   - Al subir la foto de perfil en "Completa tu perfil", Supabase Storage rechazaba la subida.
--   - Solucion: Crear buckets 'avatars' y 'property-photos' en storage.buckets
--     y definir politicas RLS de SELECT, INSERT, UPDATE, DELETE para 'authenticated'.
--
-- PROBLEMA 3: "permission denied for table properties" al publicar.
--   - Las funciones kaza_publish, kaza_my_listings, etc. estaban revocadas para
--     authenticated (00024 hizo REVOKE ALL en todas las kaza_* functions).
--   - Solucion: dar GRANT EXECUTE de las RPCs publicas a authenticated.
-- =============================================================================

BEGIN;

-- ============================================================
-- FIX 1: fn_upsert_profile y fn_update_profile_settings robustas
-- ============================================================
CREATE OR REPLACE FUNCTION public.fn_upsert_profile(
  p_id             uuid,
  p_email          text,
  p_full_name      text,
  p_system_role    text    DEFAULT 'USER',
  p_is_agent       boolean DEFAULT false,
  p_phone          text    DEFAULT NULL,
  p_license_number text    DEFAULT NULL,
  p_organization   text    DEFAULT NULL,
  p_zone           text    DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Solo el propio usuario puede actualizar su perfil.
  IF p_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = '42501';
  END IF;

  -- No se aceptan roles privilegiados desde el cliente.
  IF p_system_role NOT IN ('USER') THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = '42501';
  END IF;

  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    is_agent,
    system_role,
    phone,
    license_number,
    organization,
    zone,
    status,
    created_at,
    updated_at
  ) VALUES (
    auth.uid(),
    COALESCE(auth.jwt() ->> 'email', p_email, ''),
    left(trim(p_full_name), 255),
    p_is_agent,
    'USER',
    NULLIF(trim(p_phone), ''),
    NULLIF(trim(p_license_number), ''),
    NULLIF(trim(p_organization), ''),
    NULLIF(trim(p_zone), ''),
    'ACTIVE',
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name      = EXCLUDED.full_name,
    is_agent       = EXCLUDED.is_agent,
    phone          = COALESCE(EXCLUDED.phone,          public.profiles.phone),
    license_number = COALESCE(EXCLUDED.license_number, public.profiles.license_number),
    organization   = COALESCE(EXCLUDED.organization,   public.profiles.organization),
    zone           = COALESCE(EXCLUDED.zone,           public.profiles.zone),
    updated_at     = now();
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_upsert_profile(
  uuid, text, text, text, boolean, text, text, text, text
) TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_update_profile_settings(
  p_email      text,
  p_avatar_url text DEFAULT NULL,
  p_biography  text DEFAULT NULL,
  p_location   text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = '42501';
  END IF;

  INSERT INTO public.profiles (
    id, email, full_name, is_agent, system_role, status, avatar_url, biography, location, created_at, updated_at
  ) VALUES (
    auth.uid(),
    COALESCE(auth.jwt() ->> 'email', p_email, ''),
    split_part(COALESCE(auth.jwt() ->> 'email', p_email, ''), '@', 1),
    false,
    'USER',
    'ACTIVE',
    p_avatar_url,
    p_biography,
    p_location,
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    avatar_url = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url),
    biography  = COALESCE(EXCLUDED.biography,  public.profiles.biography),
    location   = COALESCE(EXCLUDED.location,   public.profiles.location),
    updated_at = now();
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_update_profile_settings(text, text, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_complete_onboarding(
  p_email          text,
  p_status         text,
  p_property_types text[] DEFAULT '{}',
  p_goals          text[] DEFAULT '{}',
  p_areas          text[] DEFAULT '{}',
  p_notifications  jsonb  DEFAULT '{}'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL OR p_status NOT IN ('IN_PROGRESS', 'COMPLETED', 'SKIPPED') THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = '42501';
  END IF;

  UPDATE public.profiles
  SET onboarding_status   = p_status,
      pref_property_types = p_property_types,
      pref_goals          = p_goals,
      pref_areas          = p_areas,
      pref_notifications  = p_notifications,
      updated_at          = now()
  WHERE id = auth.uid();
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_complete_onboarding(text, text, text[], text[], text[], jsonb) TO authenticated;

-- ============================================================
-- FIX 2: handle_new_user trigger (crear perfil al registrarse)
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (
    id, email, full_name, is_agent, system_role, status, created_at, updated_at
  ) VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(
      NEW.raw_user_meta_data ->> 'full_name',
      NEW.raw_user_meta_data ->> 'name',
      split_part(COALESCE(NEW.email, ''), '@', 1),
      'Usuario'
    ),
    FALSE, 'USER', 'ACTIVE', now(), now()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- FIX 3: Storage Buckets & Politicas RLS (Avatares y Fotos)
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET public = true;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'property-photos',
  'property-photos',
  true,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Politicas RLS para bucket 'avatars'
DROP POLICY IF EXISTS "avatars_select" ON storage.objects;
CREATE POLICY "avatars_select" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_insert" ON storage.objects;
CREATE POLICY "avatars_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_update" ON storage.objects;
CREATE POLICY "avatars_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars')
  WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_delete" ON storage.objects;
CREATE POLICY "avatars_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'avatars');

-- Politicas RLS para bucket 'property-photos'
DROP POLICY IF EXISTS "property_photos_select" ON storage.objects;
CREATE POLICY "property_photos_select" ON storage.objects
  FOR SELECT USING (bucket_id = 'property-photos');

DROP POLICY IF EXISTS "property_photos_insert" ON storage.objects;
CREATE POLICY "property_photos_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'property-photos');

DROP POLICY IF EXISTS "property_photos_delete" ON storage.objects;
CREATE POLICY "property_photos_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'property-photos');

-- ============================================================
-- FIX 4: Exponer RPCs publicas a authenticated
-- ============================================================
GRANT EXECUTE ON FUNCTION public.kaza_publish(uuid, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_my_listings(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_catalog(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_saved(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_listing_command(uuid, uuid, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_start_conversation(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_send_message(uuid, uuid, text, uuid) TO authenticated;

-- ============================================================
-- FIX 5: Recuperar perfiles faltantes de usuarios existentes
-- ============================================================
INSERT INTO public.profiles (id, email, full_name, is_agent, system_role, status, created_at, updated_at)
SELECT
  u.id,
  COALESCE(u.email, ''),
  COALESCE(
    u.raw_user_meta_data ->> 'full_name',
    u.raw_user_meta_data ->> 'name',
    split_part(COALESCE(u.email, ''), '@', 1),
    'Usuario'
  ),
  FALSE, 'USER', 'ACTIVE', now(), now()
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
ON CONFLICT (id) DO NOTHING;

COMMIT;
