-- Ejecutar completo en Supabase SQL Editor como postgres, después de 00023–00026.
-- Incluye la configuración de 00027 si falta; no repitas kaza-upgrade.sql si ya lo aplicaste.
-- Autoriza una cuenta existente. No crea usuarios ni elimina otros administradores.
BEGIN;
SET LOCAL lock_timeout = '10s';

DO $$
BEGIN
 IF to_regclass('public.kaza_admins') IS NULL
    OR to_regclass('public.kaza_audit') IS NULL
    OR to_regprocedure('kaza_private.active(uuid)') IS NULL
    OR to_regprocedure('kaza_private.assert_actor(uuid)') IS NULL THEN
  RAISE EXCEPTION 'Falta la base de seguridad de KAZA (00023–00026). No se realizó ningún cambio. Revisa las migraciones instaladas antes de continuar.';
 END IF;
END $$;

-- Serializar toda la reparación con los intentos de primer acceso.
SELECT pg_advisory_xact_lock(71629349);
CREATE TABLE IF NOT EXISTS public.kaza_admin_bootstrap (
 singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
 user_id uuid NOT NULL REFERENCES auth.users(id),
 claimed_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.kaza_admin_bootstrap ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kaza_admin_bootstrap FROM PUBLIC,anon,authenticated,service_role;
INSERT INTO public.kaza_admin_bootstrap(singleton,user_id)
SELECT true,user_id FROM public.kaza_admins ORDER BY created_at,user_id LIMIT 1
ON CONFLICT(singleton) DO NOTHING;

CREATE OR REPLACE FUNCTION public.kaza_claim_initial_admin(p_actor uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 PERFORM pg_advisory_xact_lock(71629349);
 IF NOT EXISTS(SELECT 1 FROM public.kaza_admin_bootstrap) THEN
  IF EXISTS(SELECT 1 FROM public.kaza_admins) THEN
   INSERT INTO public.kaza_admin_bootstrap(singleton,user_id)
   SELECT true,user_id FROM public.kaza_admins ORDER BY created_at,user_id LIMIT 1;
  ELSE
   INSERT INTO public.kaza_admin_bootstrap(singleton,user_id) VALUES(true,p_actor);
   INSERT INTO public.kaza_admins(user_id) VALUES(p_actor);
   INSERT INTO public.kaza_audit(actor,action,target) VALUES(p_actor,'claim_initial_admin',p_actor);
  END IF;
 END IF;
 RETURN EXISTS(SELECT 1 FROM public.kaza_admins WHERE user_id=p_actor);
END $$;
REVOKE ALL ON FUNCTION public.kaza_claim_initial_admin(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_claim_initial_admin(uuid) TO service_role;

DO $$
DECLARE
 target_id uuid;
 matches integer;
 inserted_count integer;
BEGIN
 SELECT count(*) INTO matches FROM auth.users WHERE lower(email) = 'sczkaza@gmail.com';
 IF matches <> 1 THEN
  RAISE EXCEPTION 'Se esperaba una sola cuenta sczkaza@gmail.com en Authentication > Users; encontradas: %. Inicia sesión con Google primero si no existe.', matches;
 END IF;
 SELECT id INTO target_id FROM auth.users WHERE lower(email) = 'sczkaza@gmail.com';
 IF NOT kaza_private.active(target_id) THEN
  RAISE EXCEPTION 'La cuenta está inactiva. Revisa su estado antes de autorizarla.';
 END IF;

 -- Mismo bloqueo que el alta inicial para evitar carreras con un login simultáneo.
 PERFORM pg_advisory_xact_lock(71629349);
 INSERT INTO public.kaza_admins(user_id) VALUES(target_id) ON CONFLICT(user_id) DO NOTHING;
 GET DIAGNOSTICS inserted_count = ROW_COUNT;
 INSERT INTO public.kaza_admin_bootstrap(singleton,user_id)
 SELECT true,user_id FROM public.kaza_admins ORDER BY created_at,user_id LIMIT 1
 ON CONFLICT(singleton) DO NOTHING;
 IF inserted_count = 1 THEN
  INSERT INTO public.kaza_audit(actor,action,target,reason)
  VALUES(target_id,'manual_admin_grant',target_id,
   'Asignación manual por operador SQL (' || session_user || '); actor identifica la cuenta destinataria, no una sesión de esa cuenta.');
 END IF;
END $$;
COMMIT;

SELECT u.email, a.user_id, a.created_at
FROM public.kaza_admins a JOIN auth.users u ON u.id = a.user_id
WHERE lower(u.email) = 'sczkaza@gmail.com';
