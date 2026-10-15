-- ============================================================================
-- 00032 · Registro con correo de un perfil huérfano
-- ============================================================================
-- Problema: public.profiles.email es UNIQUE pero profiles.id no referencia
-- auth.users. Si se borra una cuenta Auth, su perfil queda huérfano y un nuevo
-- registro con el mismo correo falla en handle_new_user con
-- "Database error saving new user".
--
-- Solución, solo para perfiles cuyo id ya no existe en auth.users:
--   * Perfil ACTIVO sin datos dependientes → se reasigna al nuevo usuario.
--   * Perfil dado de baja (DELETED) o con datos dependientes → se conserva,
--     se libera su correo y el nuevo usuario recibe un perfil limpio.
-- Un correo que pertenece a una cuenta Auth existente sigue fallando: nunca se
-- mezclan dos cuentas vivas.
--
-- Aplicar manualmente en Supabase SQL Editor. Idempotente.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_email text := COALESCE(NEW.email, '');
  v_orphan public.profiles%ROWTYPE;
BEGIN
  IF v_email <> '' THEN
    SELECT p.* INTO v_orphan
    FROM public.profiles p
    WHERE p.email = v_email
      AND p.id <> NEW.id
      AND NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = p.id)
    FOR UPDATE;

    IF FOUND THEN
      IF v_orphan.status IS DISTINCT FROM 'DELETED' THEN
        BEGIN
          UPDATE public.profiles SET id = NEW.id, updated_at = now() WHERE id = v_orphan.id;
          RETURN NEW;
        EXCEPTION WHEN foreign_key_violation THEN
          NULL; -- Dependent rows still point at the old id; fall through.
        END;
      END IF;
      UPDATE public.profiles
      SET email = 'orphan+' || v_orphan.id::text || '@kaza.invalid', updated_at = now()
      WHERE id = v_orphan.id;
    END IF;
  END IF;

  INSERT INTO public.profiles (
    id, email, full_name, is_agent, system_role, status, created_at, updated_at
  ) VALUES (
    NEW.id,
    v_email,
    COALESCE(
      NEW.raw_user_meta_data ->> 'full_name',
      NEW.raw_user_meta_data ->> 'name',
      NULLIF(split_part(v_email, '@', 1), ''),
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
