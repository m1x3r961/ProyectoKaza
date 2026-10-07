-- =============================================================================
-- KAZA FIX: Reemplazar fn_upsert_profile con versión funcional
-- Ejecutar en Supabase SQL Editor
-- =============================================================================
-- El problema: 00023_security_baseline redefinió fn_upsert_profile con una
-- validación que llama a kaza_private.active() la cual puede fallar para
-- usuarios nuevos que aún no tienen fila en profiles. Además revocó todos
-- los permisos de INSERT en profiles para el rol authenticated.
--
-- La solución: Reemplazar la función con una que sea genuinamente SECURITY
-- DEFINER (corre como postgres/superuser, sin restricciones de RLS) y que
-- no dependa de kaza_private.active() para su propio INSERT.
-- =============================================================================

BEGIN;

-- Remplazar fn_upsert_profile con versión robusta
CREATE OR REPLACE FUNCTION public.fn_upsert_profile(
  p_id uuid,
  p_email text,
  p_full_name text,
  p_system_role text DEFAULT 'USER',
  p_is_agent boolean DEFAULT false,
  p_phone text DEFAULT NULL,
  p_license_number text DEFAULT NULL,
  p_organization text DEFAULT NULL,
  p_zone text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Validación mínima de seguridad: solo el propio usuario puede actualizar su perfil
  IF p_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = '42501';
  END IF;

  -- Solo aceptar roles válidos (no ADMIN desde el cliente)
  IF p_system_role NOT IN ('USER') THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = '42501';
  END IF;

  -- Upsert por ID (auth.uid() = profiles.id)
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
    COALESCE(auth.jwt()->>'email', p_email, ''),
    left(p_full_name, 255),
    p_is_agent,
    'USER',
    p_phone,
    p_license_number,
    p_organization,
    p_zone,
    'ACTIVE',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name     = EXCLUDED.full_name,
    is_agent      = EXCLUDED.is_agent,
    phone         = COALESCE(EXCLUDED.phone, public.profiles.phone),
    license_number= COALESCE(EXCLUDED.license_number, public.profiles.license_number),
    organization  = COALESCE(EXCLUDED.organization, public.profiles.organization),
    zone          = COALESCE(EXCLUDED.zone, public.profiles.zone),
    updated_at    = NOW();

EXCEPTION WHEN unique_violation THEN
  -- Conflict por email (usuario con ID distinto) → actualizar por email
  UPDATE public.profiles SET
    id             = auth.uid(),
    full_name      = left(p_full_name, 255),
    is_agent       = p_is_agent,
    phone          = COALESCE(p_phone, public.profiles.phone),
    updated_at     = NOW()
  WHERE email = COALESCE(auth.jwt()->>'email', p_email);
END;
$$;

-- Asegurar que usuarios autenticados pueden ejecutar la función
GRANT EXECUTE ON FUNCTION public.fn_upsert_profile(uuid, text, text, text, boolean, text, text, text, text) TO authenticated;

-- Trigger para nuevos usuarios (por si no estaba aplicado)
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
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(COALESCE(NEW.email, ''), '@', 1),
      'Usuario'
    ),
    FALSE, 'USER', 'ACTIVE', NOW(), NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Recuperar usuarios existentes en auth.users que no tienen fila en profiles
INSERT INTO public.profiles (id, email, full_name, is_agent, system_role, status, created_at, updated_at)
SELECT
  u.id,
  COALESCE(u.email, ''),
  COALESCE(
    u.raw_user_meta_data->>'full_name',
    u.raw_user_meta_data->>'name',
    split_part(COALESCE(u.email, ''), '@', 1),
    'Usuario'
  ),
  FALSE,
  'USER',
  'ACTIVE',
  NOW(),
  NOW()
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
ON CONFLICT (id) DO NOTHING;

COMMIT;
