-- KAZA security baseline. Apply after the legacy schema (see docs/IMPLEMENTACION_SEGURIDAD.md).
-- Additive data changes; access is deliberately deny-by-default.
BEGIN;
-- Refuse to change policies in a shared/drifted schema before an operator reconciles it.
DO $$ DECLARE unknown text; BEGIN
 SELECT string_agg(c.relname,', ') INTO unknown FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='public' AND c.relkind IN ('r','p','v','m','f') AND c.relname NOT IN ('achievement_collections','achievement_editions','achievement_series','achievement_templates','achievements_catalog','admin_cases','collaboration_members','collaboration_milestones','collaborations','conversation_participants','conversations','crm_contacts','crm_opportunities','crm_tasks','dev_documents','dev_financial_records','dev_project_stages','dev_projects','dev_units','kaza_admins','kaza_audit','kaza_entitlements','kaza_requests','listing_drafts','listing_media','listing_promotions','listing_transfers','listings','market_cycles','messages','mock_credit_applications','mock_user_kyc','mock_wallet_transactions','mock_wallets','organization_invitations','organization_memberships','organizations','professional_profiles','profiles','properties','saved_properties','user_achievements','visit_records','workspaces')
 AND NOT EXISTS(SELECT 1 FROM pg_depend d WHERE d.classid='pg_class'::regclass AND d.objid=c.oid AND d.deptype='e');
 IF unknown IS NOT NULL THEN RAISE EXCEPTION 'Unrecognized public relations: %. Reconcile before applying security policies.',unknown; END IF;
END $$;
CREATE SCHEMA IF NOT EXISTS kaza_private;
REVOKE ALL ON SCHEMA kaza_private FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA kaza_private TO authenticated, service_role;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'ACTIVE';
CREATE TABLE public.kaza_entitlements (user_id uuid PRIMARY KEY REFERENCES auth.users(id), tier text NOT NULL CHECK(tier IN ('PLUS','PRO','BUSINESS','PROPERTIES')), expires_at timestamptz NOT NULL, verified_reference text NOT NULL);
CREATE TABLE public.kaza_admins (user_id uuid PRIMARY KEY REFERENCES auth.users(id), created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE public.kaza_audit (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, actor uuid NOT NULL, action text NOT NULL, target uuid, reason text, created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE public.listing_drafts (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES auth.users(id), payload jsonb NOT NULL DEFAULT '{}', updated_at timestamptz NOT NULL DEFAULT now(), CHECK (octet_length(payload::text) < 100000));
ALTER TABLE public.listings ADD COLUMN IF NOT EXISTS version integer NOT NULL DEFAULT 0;
ALTER TABLE public.listings ADD COLUMN IF NOT EXISTS moderation_status text NOT NULL DEFAULT 'APPROVED' CHECK(moderation_status IN ('APPROVED','SUSPENDED'));
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS show_contact boolean NOT NULL DEFAULT false;
CREATE TABLE public.kaza_requests (actor uuid NOT NULL, operation text NOT NULL, key text NOT NULL, payload jsonb NOT NULL, result jsonb NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(actor,operation,key));
CREATE TABLE public.listing_transfers (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), listing_id uuid NOT NULL REFERENCES public.listings(id), requested_by uuid NOT NULL, target_workspace uuid NOT NULL REFERENCES public.workspaces(id), target_operator uuid NOT NULL REFERENCES auth.users(id), listing_version integer NOT NULL, expires_at timestamptz NOT NULL DEFAULT now()+interval '7 days', status text NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','ACCEPTED','CANCELLED')));
CREATE TABLE public.conversation_participants (conversation_id uuid NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE, user_id uuid NOT NULL REFERENCES auth.users(id), PRIMARY KEY(conversation_id,user_id));
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS client_id uuid;
CREATE UNIQUE INDEX messages_client_unique ON public.messages(sender_user_id,client_id) WHERE client_id IS NOT NULL;
CREATE TABLE public.organization_invitations (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES public.organizations(id), invited_email text NOT NULL, invited_by uuid NOT NULL REFERENCES auth.users(id), role_name text NOT NULL DEFAULT 'OPERATOR' CHECK(role_name IN ('OPERATOR','VIEWER')), code text NOT NULL UNIQUE DEFAULT upper(replace(gen_random_uuid()::text,'-','')), status text NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','ACCEPTED','REJECTED')), expires_at timestamptz NOT NULL DEFAULT now()+interval '7 days', created_at timestamptz NOT NULL DEFAULT now());

-- Existing privileged profile values were client-editable: DO NOT derive admin access from them.
-- kaza_admins starts empty; bootstrap administrators out of band after identity review.
DO $$ DECLARE t record; p record; f record; BEGIN
 FOR t IN SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename <> 'spatial_ref_sys' LOOP
  EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t.tablename);
  EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC, anon, authenticated',t.tablename);
  EXECUTE format('GRANT ALL ON public.%I TO service_role',t.tablename);
 END LOOP;
 FOR p IN SELECT tablename,policyname FROM pg_policies WHERE schemaname='public' LOOP
  EXECUTE format('DROP POLICY %I ON public.%I',p.policyname,p.tablename);
 END LOOP;
 FOR f IN SELECT oid::regprocedure AS signature FROM pg_proc WHERE pronamespace='public'::regnamespace AND (proname LIKE 'fn_%' OR proname='increment_property_view') LOOP
  EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated',f.signature);
 END LOOP;
END $$;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA kaza_private REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon, authenticated;

CREATE FUNCTION kaza_private.active(p_user uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT p_user IS NOT NULL AND EXISTS(SELECT 1 FROM auth.users WHERE id=p_user) AND NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=p_user AND status <> 'ACTIVE');
$$;
CREATE FUNCTION kaza_private.workspace_access(p_user uuid,p_workspace uuid,p_write boolean DEFAULT false) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT kaza_private.active(p_user) AND (EXISTS(SELECT 1 FROM public.workspaces WHERE id=p_workspace AND owner_user_id=p_user) OR EXISTS(SELECT 1 FROM public.organizations o JOIN public.organization_memberships m ON m.organization_id=o.id WHERE o.workspace_id=p_workspace AND m.user_id=p_user AND (NOT p_write OR upper(m.role_name) IN ('OWNER','ADMIN','OPERATOR','AGENT'))));
$$;
CREATE FUNCTION kaza_private.org_access(p_user uuid,p_org uuid,p_write boolean DEFAULT false) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM public.organizations o WHERE o.id=p_org AND kaza_private.workspace_access(p_user,o.workspace_id,p_write));
$$;
CREATE FUNCTION kaza_private.conversation_access(p_user uuid,p_conversation uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT kaza_private.active(p_user) AND EXISTS(SELECT 1 FROM public.conversation_participants cp JOIN public.conversations c ON c.id=cp.conversation_id JOIN public.listings l ON l.id=c.listing_id WHERE cp.user_id=p_user AND cp.conversation_id=p_conversation AND (NOT EXISTS(SELECT 1 FROM public.organization_memberships m JOIN public.organizations o ON o.id=m.organization_id WHERE m.user_id=p_user AND o.workspace_id=c.workspace_id) OR kaza_private.workspace_access(p_user,c.workspace_id))) ;
$$;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA kaza_private FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION kaza_private.active(uuid),kaza_private.workspace_access(uuid,uuid,boolean),kaza_private.org_access(uuid,uuid,boolean),kaza_private.conversation_access(uuid,uuid) TO authenticated,service_role;

GRANT SELECT ON public.profiles TO authenticated;
GRANT UPDATE(full_name,phone,avatar_url,biography,location,pref_property_types,pref_goals,pref_areas,pref_notifications,onboarding_status) ON public.profiles TO authenticated;
CREATE POLICY profile_self ON public.profiles FOR SELECT TO authenticated USING(id=auth.uid() AND kaza_private.active(auth.uid()));
CREATE POLICY profile_edit ON public.profiles FOR UPDATE TO authenticated USING(id=auth.uid() AND kaza_private.active(auth.uid())) WITH CHECK(id=auth.uid());
GRANT SELECT,INSERT,DELETE ON public.saved_properties TO authenticated;
CREATE POLICY saved_self ON public.saved_properties FOR ALL TO authenticated USING(user_id=auth.uid() AND kaza_private.active(auth.uid())) WITH CHECK(user_id=auth.uid() AND kaza_private.active(auth.uid()));
GRANT SELECT,INSERT,UPDATE,DELETE ON public.listing_drafts TO authenticated;
CREATE POLICY draft_self ON public.listing_drafts FOR ALL TO authenticated USING(user_id=auth.uid() AND kaza_private.active(auth.uid())) WITH CHECK(user_id=auth.uid() AND kaza_private.active(auth.uid()));
GRANT SELECT ON public.properties,public.listings,public.market_cycles,public.workspaces,public.organizations,public.organization_memberships TO authenticated;
CREATE POLICY property_private ON public.properties FOR SELECT TO authenticated USING(kaza_private.active(auth.uid()) AND (owner_id=auth.uid() OR EXISTS(SELECT 1 FROM public.listings l WHERE l.property_id=properties.id AND kaza_private.workspace_access(auth.uid(),l.workspace_id))));
CREATE POLICY listing_private ON public.listings FOR SELECT TO authenticated USING(kaza_private.workspace_access(auth.uid(),workspace_id));
CREATE POLICY cycle_private ON public.market_cycles FOR SELECT TO authenticated USING(EXISTS(SELECT 1 FROM public.listings l WHERE l.market_cycle_id=market_cycles.id AND kaza_private.workspace_access(auth.uid(),l.workspace_id)));
CREATE POLICY workspace_private ON public.workspaces FOR SELECT TO authenticated USING(kaza_private.workspace_access(auth.uid(),id));
CREATE POLICY organization_private ON public.organizations FOR SELECT TO authenticated USING(kaza_private.workspace_access(auth.uid(),workspace_id));
CREATE POLICY membership_private ON public.organization_memberships FOR SELECT TO authenticated USING(kaza_private.org_access(auth.uid(),organization_id));
GRANT SELECT ON public.organization_invitations TO authenticated;
CREATE POLICY invitation_self ON public.organization_invitations FOR SELECT TO authenticated USING(kaza_private.active(auth.uid()) AND lower(invited_email)=lower(auth.jwt()->>'email'));
GRANT SELECT ON public.conversations,public.conversation_participants,public.messages,public.visit_records TO authenticated;
CREATE POLICY conversation_self ON public.conversations FOR SELECT TO authenticated USING(kaza_private.conversation_access(auth.uid(),id));
CREATE POLICY participant_self ON public.conversation_participants FOR SELECT TO authenticated USING(kaza_private.conversation_access(auth.uid(),conversation_id));
CREATE POLICY messages_self ON public.messages FOR SELECT TO authenticated USING(kaza_private.conversation_access(auth.uid(),conversation_id));
CREATE POLICY visits_self ON public.visit_records FOR SELECT TO authenticated USING(kaza_private.active(auth.uid()) AND auth.uid() IN(visitor_user_id,host_user_id));
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['crm_contacts','crm_opportunities','crm_tasks'] LOOP
  EXECUTE format('GRANT SELECT,INSERT,UPDATE,DELETE ON public.%I TO authenticated',t);
  EXECUTE format('CREATE POLICY crm_scope ON public.%I FOR ALL TO authenticated USING (kaza_private.active(auth.uid()) AND ((organization_id IS NULL AND agent_id=auth.uid()) OR kaza_private.org_access(auth.uid(),organization_id,true))) WITH CHECK (kaza_private.active(auth.uid()) AND agent_id=auth.uid() AND (organization_id IS NULL OR kaza_private.org_access(auth.uid(),organization_id,true)))',t);
 END LOOP;
 FOREACH t IN ARRAY ARRAY['achievements_catalog','achievement_series','achievement_collections','achievement_templates','achievement_editions'] LOOP
  EXECUTE format('GRANT SELECT ON public.%I TO anon,authenticated',t);
  EXECUTE format('CREATE POLICY catalog_read ON public.%I FOR SELECT USING(true)',t);
 END LOOP;
END $$;
GRANT SELECT ON public.user_achievements TO authenticated;
CREATE POLICY achievements_self ON public.user_achievements FOR SELECT TO authenticated USING(user_id=auth.uid() AND kaza_private.active(auth.uid()));
GRANT SELECT ON public.professional_profiles TO authenticated;
CREATE POLICY professional_self ON public.professional_profiles FOR SELECT TO authenticated USING(id=auth.uid() AND kaza_private.active(auth.uid()));
GRANT SELECT,INSERT,UPDATE,DELETE ON public.dev_projects,public.dev_project_stages,public.dev_units,public.dev_documents,public.dev_financial_records TO authenticated;
CREATE POLICY project_self ON public.dev_projects FOR ALL TO authenticated USING(owner_id=auth.uid() AND kaza_private.active(auth.uid())) WITH CHECK(owner_id=auth.uid() AND kaza_private.active(auth.uid()) AND (org_id IS NULL OR kaza_private.org_access(auth.uid(),org_id,true)));
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['dev_project_stages','dev_units','dev_documents','dev_financial_records'] LOOP
 EXECUTE format('CREATE POLICY project_child ON public.%I FOR ALL TO authenticated USING(EXISTS(SELECT 1 FROM public.dev_projects p WHERE p.id=project_id AND p.owner_id=auth.uid())) WITH CHECK(EXISTS(SELECT 1 FROM public.dev_projects p WHERE p.id=project_id AND p.owner_id=auth.uid()))',t);
 END LOOP;
END $$;

-- Safe replacement signatures keep current profile screens compatible.
CREATE OR REPLACE FUNCTION public.fn_upsert_profile(p_id uuid,p_email text,p_full_name text,p_system_role text DEFAULT 'USER',p_is_agent boolean DEFAULT false,p_phone text DEFAULT NULL,p_license_number text DEFAULT NULL,p_organization text DEFAULT NULL,p_zone text DEFAULT NULL) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT kaza_private.active(auth.uid()) OR p_id IS DISTINCT FROM auth.uid() OR p_system_role <> 'USER' THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 INSERT INTO public.profiles(id,email,full_name,is_agent,phone,license_number,organization,zone) VALUES(auth.uid(),auth.jwt()->>'email',left(p_full_name,255),p_is_agent,p_phone,p_license_number,p_organization,p_zone)
 ON CONFLICT(id) DO UPDATE SET full_name=EXCLUDED.full_name,is_agent=EXCLUDED.is_agent,phone=coalesce(EXCLUDED.phone,profiles.phone),updated_at=now();
END $$;
CREATE OR REPLACE FUNCTION public.fn_update_profile_settings(p_email text,p_avatar_url text DEFAULT NULL,p_biography text DEFAULT NULL,p_location text DEFAULT NULL) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT kaza_private.active(auth.uid()) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 UPDATE public.profiles SET avatar_url=coalesce(p_avatar_url,avatar_url),biography=coalesce(p_biography,biography),location=coalesce(p_location,location),updated_at=now() WHERE id=auth.uid();
END $$;
CREATE OR REPLACE FUNCTION public.fn_complete_onboarding(p_email text,p_status text,p_property_types text[] DEFAULT '{}',p_goals text[] DEFAULT '{}',p_areas text[] DEFAULT '{}',p_notifications jsonb DEFAULT '{}') RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT kaza_private.active(auth.uid()) OR p_status NOT IN ('IN_PROGRESS','COMPLETED','SKIPPED') THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 UPDATE public.profiles SET onboarding_status=p_status,pref_property_types=p_property_types,pref_goals=p_goals,pref_areas=p_areas,pref_notifications=p_notifications,updated_at=now() WHERE id=auth.uid();
END $$;
CREATE OR REPLACE FUNCTION public.fn_upsert_professional_profile(p_role text DEFAULT 'AGENT',p_bio text DEFAULT NULL,p_phone text DEFAULT NULL,p_company_name text DEFAULT NULL,p_specialty text DEFAULT NULL,p_years_experience int DEFAULT 0) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT kaza_private.active(auth.uid()) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 INSERT INTO public.professional_profiles(id,role,bio,phone,company_name,specialty,years_experience) VALUES(auth.uid(),p_role,p_bio,p_phone,p_company_name,p_specialty,p_years_experience)
 ON CONFLICT(id) DO UPDATE SET role=EXCLUDED.role,bio=EXCLUDED.bio,phone=EXCLUDED.phone,company_name=EXCLUDED.company_name,specialty=EXCLUDED.specialty,years_experience=EXCLUDED.years_experience,updated_at=now();
END $$;
GRANT EXECUTE ON FUNCTION public.fn_upsert_profile(uuid,text,text,text,boolean,text,text,text,text),public.fn_update_profile_settings(text,text,text,text),public.fn_complete_onboarding(text,text,text[],text[],text[],jsonb),public.fn_upsert_professional_profile(text,text,text,text,text,integer) TO authenticated;

-- Public photos remain public; private drafts/documents require a separate bucket.
DROP POLICY IF EXISTS "Authenticated Users Upload Property Photos" ON storage.objects;
CREATE POLICY kaza_photos_insert ON storage.objects FOR INSERT TO authenticated WITH CHECK(bucket_id='property-photos' AND (storage.foldername(name))[1]=auth.uid()::text AND kaza_private.active(auth.uid()));
CREATE POLICY kaza_photos_delete ON storage.objects FOR DELETE TO authenticated USING(bucket_id='property-photos' AND (storage.foldername(name))[1]=auth.uid()::text AND kaza_private.active(auth.uid()));
UPDATE storage.buckets SET file_size_limit=10485760,allowed_mime_types=ARRAY['image/jpeg','image/png','image/webp'] WHERE id='property-photos';
CREATE INDEX kaza_listings_status_created ON public.listings(status,created_at DESC,id);
CREATE INDEX kaza_listings_workspace ON public.listings(workspace_id);
CREATE INDEX kaza_messages_conversation_created ON public.messages(conversation_id,created_at);
CREATE INDEX kaza_membership_user_org ON public.organization_memberships(user_id,organization_id);
COMMIT;
