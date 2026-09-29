-- Baja lógica de usuarios desde el panel administrativo.
-- Conserva los datos para auditoría, bloquea el acceso y retira sus publicaciones.
BEGIN;
SET LOCAL lock_timeout = '10s';

CREATE OR REPLACE FUNCTION public.kaza_admin_dashboard(p_actor uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT kaza_private.active(p_actor) OR NOT EXISTS(SELECT 1 FROM public.kaza_admins WHERE user_id=p_actor) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 RETURN jsonb_build_object(
  'users',(SELECT coalesce(jsonb_agg(x),'[]') FROM (SELECT id,email,full_name,system_role,status,created_at FROM public.profiles WHERE status <> 'DELETED' ORDER BY created_at DESC LIMIT 100) x),
  'properties',(SELECT coalesce(jsonb_agg(x),'[]') FROM (SELECT l.id,l.title,l.price_original AS price_usd,l.status,l.moderation_status,p.property_type,p.city_id,l.created_at FROM public.listings l JOIN public.properties p ON p.id=l.property_id ORDER BY l.created_at DESC LIMIT 100) x),
  'cases',(SELECT coalesce(jsonb_agg(x),'[]') FROM (SELECT * FROM public.admin_cases ORDER BY created_at DESC LIMIT 100) x)
 );
END $$;

CREATE OR REPLACE FUNCTION public.kaza_moderate(p_actor uuid,p_id uuid,p_action text,p_reason text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE changed integer; affected_listings integer := 0; BEGIN
 IF NOT kaza_private.active(p_actor) OR NOT EXISTS(SELECT 1 FROM public.kaza_admins WHERE user_id=p_actor) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 IF length(trim(p_reason)) NOT BETWEEN 8 AND 500 THEN RAISE EXCEPTION 'Reason required' USING ERRCODE='22023'; END IF;
 IF p_action IN ('suspend_user','restore_user','delete_user') THEN
  IF p_id=p_actor OR EXISTS(SELECT 1 FROM public.kaza_admins WHERE user_id=p_id) THEN RAISE EXCEPTION 'Admin accounts require operator review' USING ERRCODE='42501'; END IF;
  UPDATE public.profiles SET status=CASE p_action WHEN 'suspend_user' THEN 'SUSPENDED' WHEN 'delete_user' THEN 'DELETED' ELSE 'ACTIVE' END WHERE id=p_id AND (p_action <> 'delete_user' OR status <> 'DELETED');
  GET DIAGNOSTICS changed=ROW_COUNT;
  IF changed=0 THEN RAISE EXCEPTION 'Missing' USING ERRCODE='P0002'; END IF;
  IF p_action='delete_user' THEN
   UPDATE public.listings l SET moderation_status='SUSPENDED',version=version+1,updated_at=now()
   FROM public.properties p WHERE p.id=l.property_id AND p.owner_id=p_id AND l.moderation_status <> 'SUSPENDED';
   GET DIAGNOSTICS affected_listings=ROW_COUNT;
  END IF;
 ELSIF p_action IN ('suspend_listing','restore_listing') THEN
  UPDATE public.listings SET moderation_status=CASE p_action WHEN 'suspend_listing' THEN 'SUSPENDED' ELSE 'APPROVED' END,version=version+1,updated_at=now() WHERE id=p_id;
  GET DIAGNOSTICS changed=ROW_COUNT;
 ELSIF p_action='resolve_case' THEN
  UPDATE public.admin_cases SET status='RESOLVED',updated_at=now() WHERE id=p_id;
  GET DIAGNOSTICS changed=ROW_COUNT;
 ELSE RAISE EXCEPTION 'Invalid action' USING ERRCODE='22023'; END IF;
 IF changed=0 THEN RAISE EXCEPTION 'Missing' USING ERRCODE='P0002'; END IF;
 INSERT INTO public.kaza_audit(actor,action,target,reason) VALUES(p_actor,p_action,p_id,p_reason);
 RETURN jsonb_build_object('success',true,'affectedListings',affected_listings);
END $$;

REVOKE ALL ON FUNCTION public.kaza_admin_dashboard(uuid),public.kaza_moderate(uuid,uuid,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_admin_dashboard(uuid),public.kaza_moderate(uuid,uuid,text,text) TO service_role;
COMMIT;
