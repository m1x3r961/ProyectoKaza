-- ============================================================================
-- 00034 · Eliminación de cuenta solicitada por el propio usuario (Google Play)
-- ============================================================================
-- El backend verifica la sesión, llama a kaza_delete_own_account y después
-- da de baja la cuenta Auth con la API de administración (borrado lógico de
-- Supabase Auth: sin sesiones, identidades ni correo). La fila de auth.users se
-- conserva porque conversaciones, publicaciones y auditoría la referencian.
--
-- Esta función:
--   * Rechaza cuentas administradoras (requieren revisión del operador).
--   * Retira y oculta las publicaciones del usuario.
--   * Anonimiza el perfil y libera su correo (orphan+<id>@kaza.invalid).
--   * Borra solo datos propios sin valor para terceros (borradores y
--     favoritos). Las conversaciones conservan los mensajes de la otra parte.
--   * Registra la baja en kaza_audit.
-- Es idempotente: repetirla sobre un perfil ya eliminado no cambia nada.
--
-- Aplicar manualmente en Supabase SQL Editor.
-- ============================================================================
BEGIN;
SET LOCAL lock_timeout = '10s';

CREATE OR REPLACE FUNCTION public.kaza_delete_own_account(p_actor uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE
 v_profile public.profiles%ROWTYPE;
 v_listings integer := 0;
BEGIN
 IF p_actor IS NULL OR NOT EXISTS(SELECT 1 FROM auth.users WHERE id=p_actor) THEN
  RAISE EXCEPTION 'Missing' USING ERRCODE='P0002';
 END IF;
 IF EXISTS(SELECT 1 FROM public.kaza_admins WHERE user_id=p_actor)
 OR EXISTS(SELECT 1 FROM public.kaza_admin_bootstrap WHERE user_id=p_actor) THEN
  RAISE EXCEPTION 'Admin accounts require operator review' USING ERRCODE='42501';
 END IF;

 SELECT * INTO v_profile FROM public.profiles WHERE id=p_actor FOR UPDATE;
 IF FOUND AND v_profile.status='DELETED' THEN
  RETURN jsonb_build_object('success',true,'alreadyDeleted',true,'affectedListings',0,'email',NULL);
 END IF;

 UPDATE public.listings l
 SET status=CASE WHEN l.status IN ('CLOSED','ARCHIVED') THEN l.status ELSE 'WITHDRAWN'::public.listing_status_enum END,
     moderation_status='SUSPENDED',version=version+1,updated_at=now()
 WHERE (l.operator_user_id=p_actor OR EXISTS(SELECT 1 FROM public.properties p WHERE p.id=l.property_id AND p.owner_id=p_actor))
   AND (l.moderation_status <> 'SUSPENDED' OR l.status NOT IN ('WITHDRAWN','CLOSED','ARCHIVED'));
 GET DIAGNOSTICS v_listings=ROW_COUNT;

 UPDATE public.listing_transfers SET status='CANCELLED'
 WHERE status='PENDING' AND (requested_by=p_actor OR target_operator=p_actor);
 DELETE FROM public.listing_drafts WHERE user_id=p_actor;
 DELETE FROM public.saved_properties WHERE user_id=p_actor;

 UPDATE public.profiles SET
   status='DELETED',
   email='orphan+' || p_actor::text || '@kaza.invalid',
   full_name='Usuario eliminado',
   phone=NULL, avatar_url=NULL, biography=NULL, location=NULL,
   license_number=NULL, organization=NULL, zone=NULL,
   pref_property_types='{}', pref_goals='{}', pref_areas='{}',
   updated_at=now()
  WHERE id=p_actor;

 INSERT INTO public.kaza_audit(actor,action,target,reason)
 VALUES(p_actor,'self_delete_account',p_actor,'Eliminación solicitada por el usuario desde la app');

 RETURN jsonb_build_object('success',true,'alreadyDeleted',false,'affectedListings',v_listings,'email',v_profile.email);
END $$;

REVOKE ALL ON FUNCTION public.kaza_delete_own_account(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_delete_own_account(uuid) TO service_role;
COMMIT;
