-- Ejecutar manualmente después de 00023–00026.
-- La API verifica la sesión Google antes de llamar a esta función.
BEGIN;
SET LOCAL lock_timeout = '10s';

CREATE TABLE IF NOT EXISTS public.kaza_admin_bootstrap (
 singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
 user_id uuid NOT NULL REFERENCES auth.users(id),
 claimed_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.kaza_admin_bootstrap ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kaza_admin_bootstrap FROM PUBLIC,anon,authenticated,service_role;

-- Conservar una asignación anterior; no sustituir al administrador existente.
INSERT INTO public.kaza_admin_bootstrap(singleton,user_id)
SELECT true,user_id FROM public.kaza_admins ORDER BY created_at,user_id LIMIT 1
ON CONFLICT(singleton) DO NOTHING;

CREATE OR REPLACE FUNCTION public.kaza_claim_initial_admin(p_actor uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 -- Todos los intentos comparten el mismo bloqueo, incluso con usuarios distintos.
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
 -- La marca persiste aunque se retire el permiso: nunca reabrir el primer acceso.
 RETURN EXISTS(SELECT 1 FROM public.kaza_admins WHERE user_id=p_actor);
END $$;
REVOKE ALL ON FUNCTION public.kaza_claim_initial_admin(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_claim_initial_admin(uuid) TO service_role;
COMMIT;
