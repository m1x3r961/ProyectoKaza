BEGIN;
-- Prevent moving CRM references across tenants even when both IDs are valid foreign keys.
CREATE FUNCTION kaza_private.check_crm_links() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE c public.crm_contacts; o public.crm_opportunities; BEGIN
 IF TG_TABLE_NAME IN ('crm_opportunities','crm_tasks') THEN
 IF NEW.contact_id IS NOT NULL THEN
  SELECT * INTO c FROM public.crm_contacts WHERE id=NEW.contact_id;
  IF c.organization_id IS DISTINCT FROM NEW.organization_id OR (NEW.organization_id IS NULL AND c.agent_id<>NEW.agent_id) THEN RAISE EXCEPTION 'Cross tenant contact' USING ERRCODE='42501'; END IF;
 END IF;
 END IF;
 IF TG_TABLE_NAME='crm_tasks' THEN
  IF NEW.opportunity_id IS NOT NULL THEN
   SELECT * INTO o FROM public.crm_opportunities WHERE id=NEW.opportunity_id;
   IF o.organization_id IS DISTINCT FROM NEW.organization_id OR (NEW.organization_id IS NULL AND o.agent_id<>NEW.agent_id) THEN RAISE EXCEPTION 'Cross tenant opportunity' USING ERRCODE='42501'; END IF;
  END IF;
 END IF;
 IF TG_OP='UPDATE' AND (OLD.agent_id<>NEW.agent_id OR OLD.organization_id IS DISTINCT FROM NEW.organization_id) THEN RAISE EXCEPTION 'Ownership is immutable' USING ERRCODE='42501'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER kaza_crm_contact_scope BEFORE UPDATE ON public.crm_contacts FOR EACH ROW EXECUTE FUNCTION kaza_private.check_crm_links();
CREATE TRIGGER kaza_crm_opportunity_scope BEFORE INSERT OR UPDATE ON public.crm_opportunities FOR EACH ROW EXECUTE FUNCTION kaza_private.check_crm_links();
CREATE TRIGGER kaza_crm_task_scope BEFORE INSERT OR UPDATE ON public.crm_tasks FOR EACH ROW EXECUTE FUNCTION kaza_private.check_crm_links();
-- Reading participant lists or message history must not reveal messages after host membership is revoked.
ALTER TABLE public.messages REPLICA IDENTITY FULL;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM pg_publication WHERE pubname='supabase_realtime') AND NOT EXISTS(SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='messages') THEN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
 END IF;
END $$;
-- The definer projection already authorizes users. Returning titles here avoids granting raw listing access.
CREATE FUNCTION public.kaza_conversations(p_actor uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 SELECT coalesce(jsonb_agg(x),'[]') INTO result FROM (SELECT c.id,c.created_at,jsonb_build_object('title',l.title) AS listings FROM public.conversations c JOIN public.listings l ON l.id=c.listing_id WHERE kaza_private.conversation_access(p_actor,c.id) ORDER BY c.created_at DESC LIMIT 100) x;
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.kaza_conversations(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_conversations(uuid) TO service_role;
CREATE FUNCTION public.kaza_listing_limits(p_actor uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 RETURN jsonb_build_object('active',(SELECT count(*) FROM public.listings WHERE operator_user_id=p_actor AND status IN ('AVAILABLE','RESERVED')),
 'limit',CASE WHEN EXISTS(SELECT 1 FROM public.kaza_entitlements WHERE user_id=p_actor AND expires_at>now()) THEN NULL ELSE 2 END);
END $$;
REVOKE ALL ON FUNCTION public.kaza_listing_limits(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_listing_limits(uuid) TO service_role;
COMMIT;
