-- =============================================================================
-- KAZA: AUTH TRIGGER - Auto-crear perfil al registrar usuario nuevo
-- Migration: 00029_auth_user_trigger.sql
--
-- PROBLEMA: fn_upsert_profile lanza 42501 Forbidden para usuarios nuevos
-- porque el rol 'authenticated' NO tiene permiso INSERT en public.profiles
-- (solo SELECT y UPDATE de columnas específicas, según 00023_security_baseline).
--
-- SOLUCIÓN: Trigger SECURITY DEFINER que corre como service_role al momento
-- del signup, creando la fila inicial en profiles. Así cuando el cliente
-- llama a fn_upsert_profile, la fila ya existe y el ON CONFLICT(id) ejecuta
-- UPDATE (permitido) en lugar de INSERT (denegado).
-- =============================================================================

BEGIN;

-- 1. Función disparada al crear un nuevo usuario en auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    is_agent,
    system_role,
    status,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(COALESCE(NEW.email, ''), '@', 1),
      'Usuario'
    ),
    FALSE,
    'USER',
    'ACTIVE',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING; -- Si ya existe (ej: re-signup), no sobreescribir
  RETURN NEW;
END;
$$;

-- 2. Revocar acceso publico a la funcion para que solo corra como trigger
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;

-- 3. Crear el trigger en auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

COMMIT;
