-- ============================================================================
-- 00033 · Cerrar public.spatial_ref_sys (alerta "rls_disabled_in_public")
-- ============================================================================
-- PostGIS crea spatial_ref_sys en public y 00023 la excluyó al activar RLS.
-- Con la clave pública cualquiera podía leerla y la API aceptaba escrituras.
-- Son datos de referencia (códigos EPSG): se mantiene la lectura, que PostGIS
-- necesita para ST_Transform, y se bloquea cualquier escritura desde la API.
--
-- En algunos proyectos la tabla pertenece a supabase_admin; si el rol que
-- ejecuta no es dueño, se aplica solo la revocación de escrituras y se avisa.
-- Aplicar manualmente en Supabase SQL Editor. Idempotente.
-- ============================================================================

DO $$
BEGIN
  IF to_regclass('public.spatial_ref_sys') IS NULL THEN
    RETURN;
  END IF;

  BEGIN
    REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
      ON public.spatial_ref_sys FROM PUBLIC, anon, authenticated;
    GRANT SELECT ON public.spatial_ref_sys TO anon, authenticated;
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE WARNING 'spatial_ref_sys: sin permiso para revocar escrituras (%).', SQLERRM;
  END;

  BEGIN
    ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS spatial_ref_sys_read ON public.spatial_ref_sys;
    CREATE POLICY spatial_ref_sys_read ON public.spatial_ref_sys FOR SELECT USING (true);
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE WARNING 'spatial_ref_sys: el rol actual no es dueño; RLS no se pudo activar (%). Las escrituras quedan bloqueadas por permisos.', SQLERRM;
  END;
END $$;
