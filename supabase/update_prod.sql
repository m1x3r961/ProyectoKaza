BEGIN;
CREATE OR REPLACE FUNCTION kaza_private.assert_actor(p_actor uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN IF NOT kaza_private.active(p_actor) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF; END $$;
CREATE OR REPLACE FUNCTION kaza_private.personal_workspace(p_actor uuid) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE w uuid; BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 PERFORM pg_advisory_xact_lock(hashtextextended(p_actor::text,0));
 SELECT id INTO w FROM public.workspaces WHERE owner_user_id=p_actor AND workspace_type='PERSONAL' ORDER BY created_at LIMIT 1;
 IF w IS NULL THEN INSERT INTO public.workspaces(name,workspace_type,owner_user_id) VALUES('Personal','PERSONAL',p_actor) RETURNING id INTO w; END IF;
 RETURN w;
END $$;

CREATE OR REPLACE FUNCTION public.kaza_publish(p_actor uuid,p_key text,p_data jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE w uuid; prop uuid; cycle uuid; listing uuid; old public.kaza_requests; result jsonb; tier text; lon numeric; lat numeric; photo text;
BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 IF length(p_key) NOT BETWEEN 16 AND 100 OR length(trim(p_data->>'title')) NOT BETWEEN 1 AND 180 OR (p_data->>'operationType') NOT IN ('SALE','RENT','ANTICRETICO') THEN RAISE EXCEPTION 'Invalid input' USING ERRCODE='22023'; END IF;
 -- Serialize publishes per actor: idempotency and the FREE cap are checked under this lock.
 PERFORM pg_advisory_xact_lock(hashtextextended(p_actor::text,0));
 SELECT * INTO old FROM public.kaza_requests WHERE actor=p_actor AND operation='publish' AND key=p_key;
 IF FOUND THEN
  IF old.payload <> p_data THEN RAISE EXCEPTION 'Key reused' USING ERRCODE='23505'; END IF;
  RETURN old.result;
 END IF;
 w:=nullif(p_data->>'workspaceId','')::uuid;
 IF w IS NULL THEN w:=kaza_private.personal_workspace(p_actor); END IF;
 IF NOT kaza_private.workspace_access(p_actor,w,true) THEN RAISE EXCEPTION 'Forbidden workspace' USING ERRCODE='42501'; END IF;
 SELECT e.tier INTO tier FROM public.kaza_entitlements e WHERE e.user_id=p_actor AND e.expires_at>now();
 IF coalesce(tier,'FREE')='FREE' AND (SELECT count(*) FROM public.listings WHERE operator_user_id=p_actor AND status IN ('AVAILABLE','RESERVED'))>=2 THEN RAISE EXCEPTION 'Free listing limit' USING ERRCODE='23514'; END IF;
 lon:=(p_data->>'longitude')::numeric; lat:=(p_data->>'latitude')::numeric;
 IF lon NOT BETWEEN -180 AND 180 OR lat NOT BETWEEN -90 AND 90 OR lon IS NULL OR lat IS NULL THEN RAISE EXCEPTION 'Invalid location' USING ERRCODE='22023'; END IF;
 IF jsonb_array_length(coalesce(p_data->'photos','[]'))>20 THEN RAISE EXCEPTION 'Too many photos' USING ERRCODE='22023'; END IF;
 INSERT INTO public.properties(owner_id,title,description,property_type,country_code,city_id,address_canonical,canonical_location,public_location_geometry,latitude,longitude,total_surface_m2,covered_surface_m2,rooms,bathrooms,parking_spaces,age_years,floors_total,photos,amenities,contact_name,contact_phone,show_contact,status)
 VALUES(p_actor,p_data->>'title',p_data->>'description',p_data->>'propertyType',p_data->>'countryCode',p_data->>'cityId',p_data->>'address',public.ST_SetSRID(public.ST_MakePoint(lon::float,lat::float),4326)::public.geography,public.ST_SetSRID(public.ST_MakePoint(round(lon,3)::float,round(lat,3)::float),4326)::public.geography,lat,lon,coalesce((p_data->>'totalSurfaceM2')::numeric,0),coalesce((p_data->>'coveredSurfaceM2')::numeric,0),coalesce((p_data->>'rooms')::int,0),coalesce((p_data->>'bathrooms')::int,0),coalesce((p_data->>'parkingSpaces')::int,0),coalesce((p_data->>'ageYears')::int,0),coalesce((p_data->>'floorsTotal')::int,1),coalesce(p_data->'photos','[]'),coalesce(p_data->'amenities','[]'),p_data->>'contactName',p_data->>'contactPhone',coalesce((p_data->>'showContact')::boolean,false),'PUBLISHED') RETURNING id INTO prop;
 INSERT INTO public.market_cycles(property_id,operation_type) VALUES(prop,p_data->>'operationType') RETURNING id INTO cycle;
 INSERT INTO public.listings(property_id,market_cycle_id,workspace_id,operator_user_id,title,description,price_original,currency_original,pricing_mode,status)
 VALUES(prop,cycle,w,p_actor,p_data->>'title',p_data->>'description',(p_data->>'priceOriginal')::numeric,coalesce(p_data->>'currencyOriginal','USD'),CASE WHEN coalesce((p_data->>'contactForPrice')::boolean,false) THEN 'CONTACT_FOR_PRICE' ELSE 'PUBLIC_NUMERIC' END::public.pricing_mode_enum,'AVAILABLE') RETURNING id INTO listing;
 result:=jsonb_build_object('id',listing,'propertyId',prop,'version',0,'status','AVAILABLE');
 INSERT INTO public.kaza_requests(actor,operation,key,payload,result) VALUES(p_actor,'publish',p_key,p_data,result);
 INSERT INTO public.kaza_audit(actor,action,target) VALUES(p_actor,'publish',listing);
 RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.kaza_listing_command(p_actor uuid,p_id uuid,p_action text,p_data jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE l public.listings; target text; transfer uuid; operator_id uuid;
BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 SELECT operator_user_id INTO operator_id FROM public.listings WHERE id=p_id;
 PERFORM pg_advisory_xact_lock(hashtextextended(operator_id::text,0));
 SELECT * INTO l FROM public.listings WHERE id=p_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Missing' USING ERRCODE='P0002'; END IF;
 IF l.operator_user_id IS DISTINCT FROM operator_id THEN RAISE EXCEPTION 'Operator changed' USING ERRCODE='40001'; END IF;
 IF NOT kaza_private.workspace_access(p_actor,l.workspace_id,true) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 IF p_action='refresh' THEN
  UPDATE public.listings SET freshness_confirmed_at=now(),updated_at=now() WHERE id=p_id;
  RETURN jsonb_build_object('id',p_id,'version',l.version,'status',l.status);
 END IF;
 IF (p_data->>'version')::int IS DISTINCT FROM l.version THEN RAISE EXCEPTION 'Version conflict' USING ERRCODE='40001'; END IF;
 IF p_action='transfer' THEN
  IF l.status IN ('CLOSED','ARCHIVED') OR NOT kaza_private.workspace_access((p_data->>'newOperatorUserId')::uuid,(p_data->>'targetWorkspaceId')::uuid,true) THEN RAISE EXCEPTION 'Invalid recipient' USING ERRCODE='22023'; END IF;
  UPDATE public.listing_transfers SET status='CANCELLED' WHERE listing_id=p_id AND status='PENDING';
  INSERT INTO public.listing_transfers(listing_id,requested_by,target_workspace,target_operator,listing_version) VALUES(p_id,p_actor,(p_data->>'targetWorkspaceId')::uuid,(p_data->>'newOperatorUserId')::uuid,l.version) RETURNING id INTO transfer;
  RETURN jsonb_build_object('transferId',transfer,'status','PENDING');
 ELSIF p_action='status' THEN
  target:=p_data->>'status';
  IF l.moderation_status <> 'APPROVED' OR NOT (
   (l.status IN ('DRAFT','PAUSED') AND target IN ('AVAILABLE','WITHDRAWN')) OR
   (l.status='AVAILABLE' AND target IN ('RESERVED','PAUSED','WITHDRAWN')) OR
   (l.status='RESERVED' AND target IN ('AVAILABLE','CLOSED','WITHDRAWN'))
  ) THEN RAISE EXCEPTION 'Invalid transition' USING ERRCODE='23514'; END IF;
  IF target='AVAILABLE' AND l.status IN ('DRAFT','PAUSED') AND NOT EXISTS(SELECT 1 FROM public.kaza_entitlements WHERE user_id=l.operator_user_id AND expires_at>now()) AND (SELECT count(*) FROM public.listings WHERE operator_user_id=l.operator_user_id AND status IN ('AVAILABLE','RESERVED'))>=2 THEN RAISE EXCEPTION 'Free listing limit' USING ERRCODE='23514'; END IF;
  UPDATE public.listings SET status=target::public.listing_status_enum,version=version+1,updated_at=now() WHERE id=p_id;
  IF target='CLOSED' THEN
   UPDATE public.market_cycles SET status='CLOSED',closed_at=now() WHERE id=l.market_cycle_id;
   UPDATE public.listings SET status='CLOSED',version=version+1,updated_at=now() WHERE market_cycle_id=l.market_cycle_id AND id<>p_id AND status NOT IN ('CLOSED','ARCHIVED');
  END IF;
 ELSE RAISE EXCEPTION 'Invalid action' USING ERRCODE='22023'; END IF;
 INSERT INTO public.kaza_audit(actor,action,target,reason) VALUES(p_actor,'listing_status',p_id,target);
 RETURN jsonb_build_object('id',p_id,'version',l.version+1,'status',target);
END $$;
CREATE OR REPLACE FUNCTION public.kaza_accept_transfer(p_actor uuid,p_id uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE t public.listing_transfers; l public.listings;
BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 -- Lock listing before transfer, matching request lock order.
 PERFORM pg_advisory_xact_lock(hashtextextended(p_actor::text,0));
 SELECT x.* INTO l FROM public.listings x JOIN public.listing_transfers y ON y.listing_id=x.id WHERE y.id=p_id FOR UPDATE OF x;
 SELECT * INTO t FROM public.listing_transfers WHERE id=p_id FOR UPDATE;
 IF t.id IS NULL OR t.target_operator<>p_actor OR NOT kaza_private.workspace_access(p_actor,t.target_workspace,true) OR NOT kaza_private.workspace_access(t.requested_by,l.workspace_id,true) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 IF t.status<>'PENDING' OR t.expires_at<now() OR t.listing_version<>l.version THEN RAISE EXCEPTION 'Conflict' USING ERRCODE='40001'; END IF;
 IF l.operator_user_id<>p_actor AND l.status IN ('AVAILABLE','RESERVED') AND NOT EXISTS(SELECT 1 FROM public.kaza_entitlements WHERE user_id=p_actor AND expires_at>now()) AND (SELECT count(*) FROM public.listings WHERE operator_user_id=p_actor AND status IN ('AVAILABLE','RESERVED'))>=2 THEN RAISE EXCEPTION 'Free listing limit' USING ERRCODE='23514'; END IF;
 UPDATE public.listings SET workspace_id=t.target_workspace,operator_user_id=p_actor,version=version+1,updated_at=now() WHERE id=t.listing_id;
 UPDATE public.listing_transfers SET status='ACCEPTED' WHERE id=p_id;
 INSERT INTO public.kaza_audit(actor,action,target) VALUES(p_actor,'accept_transfer',t.listing_id);
 RETURN jsonb_build_object('id',t.listing_id,'status','ACCEPTED');
END $$;

-- Public projection: exact location, owner ID and private contact never leave through the catalog.
CREATE OR REPLACE FUNCTION kaza_private.public_listing(l public.listings,p public.properties,p_detail boolean DEFAULT false) RETURNS jsonb LANGUAGE sql STABLE SET search_path='' AS $$
 SELECT jsonb_build_object('id',p.id,'listing_id',l.id,'title',l.title,'price_usd',CASE WHEN l.pricing_mode='PUBLIC_NUMERIC' THEN l.price_original ELSE NULL END,'currency_code',l.currency_original,'operation',CASE c.operation_type WHEN 'SALE' THEN 'VENTA' WHEN 'RENT' THEN 'ALQUILER' ELSE c.operation_type END,'property_type',p.property_type,'latitude',round(p.latitude::numeric,3),'longitude',round(p.longitude::numeric,3),'public_location_mode','APPROXIMATE','rooms',p.rooms,'bathrooms',p.bathrooms,'total_surface_m2',p.total_surface_m2,'photos',CASE WHEN p_detail THEN coalesce(p.photos,'[]') ELSE CASE WHEN jsonb_array_length(coalesce(p.photos,'[]'))>0 THEN jsonb_build_array(p.photos->0) ELSE '[]'::jsonb END END,'status','PUBLISHED','city_id',p.city_id,'updated_at',l.freshness_confirmed_at,'has_active_promotion',false)
 || CASE WHEN p_detail THEN jsonb_build_object('description',l.description,'amenities',p.amenities,'covered_surface_m2',p.covered_surface_m2,'parking_spaces',p.parking_spaces,'age_years',p.age_years,'floors_total',p.floors_total,'contact_name',CASE WHEN p.show_contact THEN p.contact_name ELSE NULL END,'contact_phone',CASE WHEN p.show_contact THEN p.contact_phone ELSE NULL END) ELSE '{}'::jsonb END
 FROM public.market_cycles c WHERE c.id=l.market_cycle_id;
$$;
CREATE OR REPLACE FUNCTION public.kaza_catalog(p_query jsonb DEFAULT '{}') RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT coalesce(jsonb_agg(row ORDER BY created_at DESC,id),'[]') FROM (
 SELECT kaza_private.public_listing(l,p,coalesce((p_query->>'detail')::boolean,false)) AS row,l.created_at,l.id
 FROM public.listings l JOIN public.properties p ON p.id=l.property_id
 WHERE l.status='AVAILABLE' AND l.moderation_status='APPROVED' AND kaza_private.active(l.operator_user_id)
 AND (p_query->>'id' IS NULL OR p.id=(p_query->>'id')::uuid)
 AND round(p.latitude::numeric,3) BETWEEN coalesce((p_query->>'south')::numeric,-90) AND coalesce((p_query->>'north')::numeric,90)
 AND round(p.longitude::numeric,3) BETWEEN coalesce((p_query->>'west')::numeric,-180) AND coalesce((p_query->>'east')::numeric,180)
 AND (p_query->>'type' IS NULL OR p.property_type=p_query->>'type')
 AND (p_query->>'operation' IS NULL OR EXISTS(SELECT 1 FROM public.market_cycles c WHERE c.id=l.market_cycle_id AND c.operation_type=p_query->>'operation'))
 ORDER BY l.created_at DESC,l.id LIMIT least(greatest(coalesce((p_query->>'limit')::int,100),1),100) OFFSET least(greatest(coalesce((p_query->>'offset')::int,0),0),10000)
 ) q;
$$;
CREATE INDEX kaza_public_lat_lng ON public.properties((round(latitude::numeric,3)),(round(longitude::numeric,3)));
CREATE OR REPLACE FUNCTION public.kaza_my_listings(p_actor uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 SELECT coalesce(jsonb_agg(x),'[]') INTO result FROM (SELECT l.id,l.property_id,l.title,l.description,l.price_original,l.currency_original,l.status,l.version,l.moderation_status,l.freshness_confirmed_at,l.updated_at,p.views_count FROM public.listings l JOIN public.properties p ON p.id=l.property_id WHERE kaza_private.workspace_access(p_actor,l.workspace_id) ORDER BY l.created_at DESC LIMIT 200) x;
 RETURN result;
END $$;
CREATE OR REPLACE FUNCTION public.kaza_saved(p_actor uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',s.id,'property_id',s.property_id,'properties',kaza_private.public_listing(l,p,true))),'[]') INTO result
 FROM public.saved_properties s JOIN public.properties p ON p.id=s.property_id JOIN LATERAL(SELECT * FROM public.listings x WHERE x.property_id=p.id AND x.status='AVAILABLE' AND x.moderation_status='APPROVED' ORDER BY x.created_at DESC LIMIT 1) l ON true WHERE s.user_id=p_actor;
 RETURN result;
END $$;
CREATE OR REPLACE FUNCTION public.kaza_admin_dashboard(p_actor uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT kaza_private.active(p_actor) OR NOT EXISTS(SELECT 1 FROM public.kaza_admins WHERE user_id=p_actor) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 RETURN jsonb_build_object('users',(SELECT coalesce(jsonb_agg(x),'[]') FROM (SELECT id,email,full_name,system_role,status,created_at FROM public.profiles ORDER BY created_at DESC LIMIT 100) x),'properties',(SELECT coalesce(jsonb_agg(x),'[]') FROM (SELECT l.id,l.title,l.price_original AS price_usd,l.status,l.moderation_status,p.property_type,p.city_id,l.created_at FROM public.listings l JOIN public.properties p ON p.id=l.property_id ORDER BY l.created_at DESC LIMIT 100) x),'cases',(SELECT coalesce(jsonb_agg(x),'[]') FROM (SELECT * FROM public.admin_cases ORDER BY created_at DESC LIMIT 100) x));
END $$;
CREATE OR REPLACE FUNCTION public.kaza_moderate(p_actor uuid,p_id uuid,p_action text,p_reason text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE changed integer; BEGIN
 IF NOT kaza_private.active(p_actor) OR NOT EXISTS(SELECT 1 FROM public.kaza_admins WHERE user_id=p_actor) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 IF length(trim(p_reason)) NOT BETWEEN 8 AND 500 THEN RAISE EXCEPTION 'Reason required' USING ERRCODE='22023'; END IF;
 IF p_action IN ('suspend_user','restore_user') THEN
  IF p_id=p_actor OR EXISTS(SELECT 1 FROM public.kaza_admins WHERE user_id=p_id) THEN RAISE EXCEPTION 'Admin accounts require operator review' USING ERRCODE='42501'; END IF;
  UPDATE public.profiles SET status=CASE p_action WHEN 'suspend_user' THEN 'SUSPENDED' ELSE 'ACTIVE' END WHERE id=p_id;
 ELSIF p_action IN ('suspend_listing','restore_listing') THEN
  UPDATE public.listings SET moderation_status=CASE p_action WHEN 'suspend_listing' THEN 'SUSPENDED' ELSE 'APPROVED' END,version=version+1,updated_at=now() WHERE id=p_id;
 ELSIF p_action='resolve_case' THEN UPDATE public.admin_cases SET status='RESOLVED',updated_at=now() WHERE id=p_id;
 ELSE RAISE EXCEPTION 'Invalid action' USING ERRCODE='22023'; END IF;
 GET DIAGNOSTICS changed=ROW_COUNT;
 IF changed=0 THEN RAISE EXCEPTION 'Missing' USING ERRCODE='P0002'; END IF;
 INSERT INTO public.kaza_audit(actor,action,target,reason) VALUES(p_actor,p_action,p_id,p_reason);
 RETURN jsonb_build_object('success',true);
END $$;
-- All command entry points are callable only by the verified backend.
DO $$ DECLARE f record; BEGIN
 FOR f IN SELECT oid::regprocedure signature FROM pg_proc WHERE pronamespace='public'::regnamespace AND proname LIKE 'kaza_%' LOOP
 EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC,anon,authenticated',f.signature);
 EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role',f.signature);
 END LOOP;
END $$;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA kaza_private FROM PUBLIC,anon;
COMMIT;
BEGIN;
ALTER TABLE public.conversation_participants ADD COLUMN is_host boolean NOT NULL DEFAULT false;
CREATE OR REPLACE FUNCTION kaza_private.conversation_access(p_user uuid,p_conversation uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT kaza_private.active(p_user) AND EXISTS(SELECT 1 FROM public.conversation_participants cp JOIN public.conversations c ON c.id=cp.conversation_id WHERE cp.user_id=p_user AND cp.conversation_id=p_conversation AND (NOT cp.is_host OR kaza_private.workspace_access(p_user,c.workspace_id,true)));
$$;
CREATE OR REPLACE FUNCTION public.kaza_start_conversation(p_actor uuid,p_property uuid) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE l public.listings; c uuid;
BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 SELECT * INTO l FROM public.listings WHERE property_id=p_property AND status='AVAILABLE' AND moderation_status='APPROVED' ORDER BY created_at DESC LIMIT 1;
 IF NOT FOUND OR NOT kaza_private.active(l.operator_user_id) THEN RAISE EXCEPTION 'Unavailable' USING ERRCODE='P0002'; END IF;
 IF l.operator_user_id=p_actor THEN RAISE EXCEPTION 'Own listing' USING ERRCODE='22023'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(p_actor::text||l.id::text,1));
 SELECT x.id INTO c FROM public.conversations x JOIN public.conversation_participants cp ON cp.conversation_id=x.id WHERE x.listing_id=l.id AND cp.user_id=p_actor AND NOT cp.is_host LIMIT 1;
 IF c IS NULL THEN
  INSERT INTO public.conversations(listing_id,workspace_id) VALUES(l.id,l.workspace_id) RETURNING id INTO c;
  INSERT INTO public.conversation_participants(conversation_id,user_id,is_host) VALUES(c,p_actor,false),(c,l.operator_user_id,true);
 END IF;
 RETURN c;
END $$;
CREATE OR REPLACE FUNCTION public.kaza_send_message(p_actor uuid,p_conversation uuid,p_content text,p_client uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE m public.messages;
BEGIN
 IF NOT kaza_private.conversation_access(p_actor,p_conversation) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 IF length(trim(p_content)) NOT BETWEEN 1 AND 4000 THEN RAISE EXCEPTION 'Invalid content' USING ERRCODE='22023'; END IF;
 INSERT INTO public.messages(conversation_id,sender_user_id,content,client_id) VALUES(p_conversation,p_actor,p_content,p_client) ON CONFLICT(sender_user_id,client_id) WHERE client_id IS NOT NULL DO NOTHING RETURNING * INTO m;
 IF m.id IS NULL THEN SELECT * INTO m FROM public.messages WHERE sender_user_id=p_actor AND client_id=p_client; END IF;
 IF m.content<>p_content OR m.conversation_id<>p_conversation THEN RAISE EXCEPTION 'Conflict' USING ERRCODE='23505'; END IF;
 RETURN to_jsonb(m);
END $$;
CREATE OR REPLACE FUNCTION public.kaza_create_organization(p_actor uuid,p_data jsonb) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE w uuid; o uuid; BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 IF length(trim(p_data->>'legal_name')) NOT BETWEEN 1 AND 180 THEN RAISE EXCEPTION 'Invalid name' USING ERRCODE='22023'; END IF;
 INSERT INTO public.workspaces(name,workspace_type,owner_user_id) VALUES(p_data->>'legal_name','ORGANIZATION',p_actor) RETURNING id INTO w;
 INSERT INTO public.organizations(workspace_id,legal_name,description,website,logo_url,contact_email,contact_phone,city,address,org_type) VALUES(w,p_data->>'legal_name',p_data->>'description',p_data->>'website',p_data->>'logo_url',p_data->>'contact_email',p_data->>'contact_phone',p_data->>'city',p_data->>'address',coalesce(p_data->>'org_type','AGENCY')) RETURNING id INTO o;
 INSERT INTO public.organization_memberships(organization_id,user_id,role_name) VALUES(o,p_actor,'ADMIN');
 RETURN o;
END $$;
CREATE OR REPLACE FUNCTION public.kaza_invite(p_actor uuid,p_org uuid,p_email text,p_role text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result public.organization_invitations; BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 IF NOT EXISTS(SELECT 1 FROM public.organizations o JOIN public.workspaces w ON w.id=o.workspace_id WHERE o.id=p_org AND w.owner_user_id=p_actor) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 IF p_role NOT IN ('OPERATOR','VIEWER') OR length(p_email) NOT BETWEEN 3 AND 254 THEN RAISE EXCEPTION 'Invalid invitation' USING ERRCODE='22023'; END IF;
 INSERT INTO public.organization_invitations(organization_id,invited_email,invited_by,role_name) VALUES(p_org,lower(p_email),p_actor,p_role) RETURNING * INTO result;
 RETURN to_jsonb(result);
END $$;
CREATE OR REPLACE FUNCTION public.kaza_respond_invitation(p_actor uuid,p_code text,p_id uuid,p_accept boolean) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE i public.organization_invitations; email text; BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 SELECT u.email INTO email FROM auth.users u WHERE u.id=p_actor;
 SELECT * INTO i FROM public.organization_invitations WHERE (id=p_id OR code=upper(p_code)) AND lower(invited_email)=lower(email) FOR UPDATE;
 IF i.id IS NULL OR i.expires_at<now() OR i.status<>'PENDING' THEN RAISE EXCEPTION 'Invalid invitation' USING ERRCODE='22023'; END IF;
 IF NOT kaza_private.active(i.invited_by) OR NOT EXISTS(SELECT 1 FROM public.organizations o JOIN public.workspaces w ON w.id=o.workspace_id WHERE o.id=i.organization_id AND w.owner_user_id=i.invited_by) THEN RAISE EXCEPTION 'Invitation no longer authorized' USING ERRCODE='42501'; END IF;
 IF p_accept THEN INSERT INTO public.organization_memberships(organization_id,user_id,role_name) VALUES(i.organization_id,p_actor,i.role_name) ON CONFLICT(organization_id,user_id) DO NOTHING; END IF;
 UPDATE public.organization_invitations SET status=CASE WHEN p_accept THEN 'ACCEPTED' ELSE 'REJECTED' END WHERE id=i.id;
 RETURN jsonb_build_object('success',true);
END $$;
-- Safe, explicit migration of legacy inventory. Run separately after reviewing the report.
CREATE OR REPLACE FUNCTION public.kaza_backfill_legacy() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.properties; w uuid; c uuid; n integer:=0; st public.listing_status_enum;
BEGIN
 FOR p IN SELECT * FROM public.properties x WHERE NOT EXISTS(SELECT 1 FROM public.listings l WHERE l.property_id=x.id) AND kaza_private.active(x.owner_id) FOR UPDATE LOOP
  w:=kaza_private.personal_workspace(p.owner_id);
  st:=CASE p.status WHEN 'PUBLISHED' THEN 'AVAILABLE' WHEN 'AVAILABLE' THEN 'AVAILABLE' WHEN 'RESERVED' THEN 'RESERVED' WHEN 'CLOSED' THEN 'CLOSED' ELSE 'PAUSED' END;
  INSERT INTO public.market_cycles(property_id,operation_type,status,start_date,closed_at) VALUES(p.id,CASE p.operation WHEN 'ALQUILER' THEN 'RENT' WHEN 'TEMPORAL' THEN 'RENT' WHEN 'ANTICRETICO' THEN 'ANTICRETICO' ELSE 'SALE' END,CASE WHEN st='CLOSED' THEN 'CLOSED' ELSE 'OPEN' END::public.market_cycle_status_enum,p.created_at,CASE WHEN st='CLOSED' THEN p.updated_at ELSE NULL END) RETURNING id INTO c;
  INSERT INTO public.listings(property_id,market_cycle_id,workspace_id,operator_user_id,title,description,price_original,currency_original,status,moderation_status,created_at) VALUES(p.id,c,w,p.owner_id,coalesce(p.title,p.property_type,'Inmueble'),p.description,p.price_usd,coalesce(p.currency_code,'USD'),st,CASE WHEN p.status IN ('BANNED','SUSPENDED','BLOCKED') THEN 'SUSPENDED' ELSE 'APPROVED' END,p.created_at);
  n:=n+1;
 END LOOP;
 RETURN jsonb_build_object('migrated',n,'unmapped',(SELECT count(*) FROM public.properties x WHERE NOT EXISTS(SELECT 1 FROM public.listings l WHERE l.property_id=x.id)));
END $$;
-- Atomic mock transfer, reachable only in the isolated demo backend.
CREATE OR REPLACE FUNCTION public.kaza_mock_transfer(p_actor uuid,p_receiver uuid,p_amount numeric,p_key text,p_concept text,p_listing uuid DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE sender public.mock_wallets; receiver public.mock_wallets; old public.kaza_requests; result jsonb; payload jsonb; tx uuid;
BEGIN
 PERFORM kaza_private.assert_actor(p_actor); PERFORM kaza_private.assert_actor(p_receiver);
 IF p_actor=p_receiver OR p_amount<=0 OR p_amount<>round(p_amount,2) OR p_amount IS NULL OR length(p_key) NOT BETWEEN 16 AND 100 THEN RAISE EXCEPTION 'Invalid transfer' USING ERRCODE='22023'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.mock_user_kyc WHERE user_id=p_actor AND status='VERIFIED') THEN RAISE EXCEPTION 'KYC required' USING ERRCODE='42501'; END IF;
 payload:=jsonb_build_object('receiver',p_receiver,'amount',p_amount,'concept',p_concept,'listing',p_listing);
 PERFORM pg_advisory_xact_lock(hashtextextended(p_actor::text||p_key,2));
 SELECT * INTO old FROM public.kaza_requests WHERE actor=p_actor AND operation='mock_transfer' AND key=p_key;
 IF FOUND THEN IF old.payload<>payload THEN RAISE EXCEPTION 'Conflict' USING ERRCODE='23505'; END IF; RETURN old.result; END IF;
 INSERT INTO public.mock_wallets(user_id) VALUES(p_actor),(p_receiver) ON CONFLICT(user_id) DO NOTHING;
 PERFORM 1 FROM public.mock_wallets WHERE user_id IN (p_actor,p_receiver) ORDER BY user_id FOR UPDATE;
 SELECT * INTO sender FROM public.mock_wallets WHERE user_id=p_actor;
 SELECT * INTO receiver FROM public.mock_wallets WHERE user_id=p_receiver;
 IF NOT sender.is_active OR NOT receiver.is_active OR sender.balance<p_amount THEN RAISE EXCEPTION 'Insufficient balance' USING ERRCODE='23514'; END IF;
 UPDATE public.mock_wallets SET balance=balance-p_amount,updated_at=now() WHERE id=sender.id;
 UPDATE public.mock_wallets SET balance=balance+p_amount,updated_at=now() WHERE id=receiver.id;
 INSERT INTO public.mock_wallet_transactions(sender_wallet_id,receiver_wallet_id,amount,concept,reference_listing_id) VALUES(sender.id,receiver.id,p_amount,p_concept,p_listing) RETURNING id INTO tx;
 result:=jsonb_build_object('success',true,'demo',true,'senderBalance',sender.balance-p_amount,'transaction',jsonb_build_object('id',tx,'amount',p_amount,'currency','BOB','status','COMPLETED'));
 INSERT INTO public.kaza_requests(actor,operation,key,payload,result) VALUES(p_actor,'mock_transfer',p_key,payload,result);
 RETURN result;
END $$;
DO $$ DECLARE f record; BEGIN
 FOR f IN SELECT oid::regprocedure signature FROM pg_proc WHERE pronamespace='public'::regnamespace AND proname LIKE 'kaza_%' LOOP
 EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC,anon,authenticated',f.signature);
 EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role',f.signature);
 END LOOP;
END $$;
REVOKE ALL ON FUNCTION public.kaza_backfill_legacy() FROM service_role;
COMMIT;
BEGIN;
-- Prevent moving CRM references across tenants even when both IDs are valid foreign keys.
CREATE OR REPLACE FUNCTION kaza_private.check_crm_links() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
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
CREATE OR REPLACE FUNCTION public.kaza_conversations(p_actor uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 SELECT coalesce(jsonb_agg(x),'[]') INTO result FROM (SELECT c.id,c.created_at,jsonb_build_object('title',l.title) AS listings FROM public.conversations c JOIN public.listings l ON l.id=c.listing_id WHERE kaza_private.conversation_access(p_actor,c.id) ORDER BY c.created_at DESC LIMIT 100) x;
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.kaza_conversations(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_conversations(uuid) TO service_role;
CREATE OR REPLACE FUNCTION public.kaza_listing_limits(p_actor uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 RETURN jsonb_build_object('active',(SELECT count(*) FROM public.listings WHERE operator_user_id=p_actor AND status IN ('AVAILABLE','RESERVED')),
 'limit',CASE WHEN EXISTS(SELECT 1 FROM public.kaza_entitlements WHERE user_id=p_actor AND expires_at>now()) THEN NULL ELSE 2 END);
END $$;
REVOKE ALL ON FUNCTION public.kaza_listing_limits(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_listing_limits(uuid) TO service_role;
COMMIT;
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
-- =============================================================================
-- KAZA: Fix critical permission errors (42501 Forbidden & Storage 403)
-- Migration: 00031_fix_permissions.sql
--
-- PROBLEMA 1: fn_upsert_profile y fn_update_profile_settings lanzaban Forbidden (42501) al crear cuenta.
--   - 00023 llamaba kaza_private.active() que podia fallar si el perfil era nuevo.
--   - 00030 introdujo un EXCEPTION handler que hacia UPDATE SET id=auth.uid()
--     sobre la PK, causando errores de integridad referencial.
--   - Solucion: funciones robustas que usan auth.uid() directamente y realizan UPSERT.
--
-- PROBLEMA 2: StorageException: new row violates row-level security policy (403 Unauthorized)
--   - El bucket 'avatars' no existia o no tenia politicas RLS creadas.
--   - Al subir la foto de perfil en "Completa tu perfil", Supabase Storage rechazaba la subida.
--   - Solucion: Crear buckets 'avatars' y 'property-photos' en storage.buckets
--     y definir politicas RLS de SELECT, INSERT, UPDATE, DELETE para 'authenticated'.
--
-- PROBLEMA 3: "permission denied for table properties" al publicar.
--   - Las funciones kaza_publish, kaza_my_listings, etc. estaban revocadas para
--     authenticated (00024 hizo REVOKE ALL en todas las kaza_* functions).
--   - Solucion: dar GRANT EXECUTE de las RPCs publicas a authenticated.
-- =============================================================================

BEGIN;

-- ============================================================
-- FIX 1: fn_upsert_profile y fn_update_profile_settings robustas
-- ============================================================
CREATE OR REPLACE FUNCTION public.fn_upsert_profile(
  p_id             uuid,
  p_email          text,
  p_full_name      text,
  p_system_role    text    DEFAULT 'USER',
  p_is_agent       boolean DEFAULT false,
  p_phone          text    DEFAULT NULL,
  p_license_number text    DEFAULT NULL,
  p_organization   text    DEFAULT NULL,
  p_zone           text    DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Solo el propio usuario puede actualizar su perfil.
  IF p_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = '42501';
  END IF;

  -- No se aceptan roles privilegiados desde el cliente.
  IF p_system_role NOT IN ('USER') THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = '42501';
  END IF;

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
    COALESCE(auth.jwt() ->> 'email', p_email, ''),
    left(trim(p_full_name), 255),
    p_is_agent,
    'USER',
    NULLIF(trim(p_phone), ''),
    NULLIF(trim(p_license_number), ''),
    NULLIF(trim(p_organization), ''),
    NULLIF(trim(p_zone), ''),
    'ACTIVE',
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name      = EXCLUDED.full_name,
    is_agent       = EXCLUDED.is_agent,
    phone          = COALESCE(EXCLUDED.phone,          public.profiles.phone),
    license_number = COALESCE(EXCLUDED.license_number, public.profiles.license_number),
    organization   = COALESCE(EXCLUDED.organization,   public.profiles.organization),
    zone           = COALESCE(EXCLUDED.zone,           public.profiles.zone),
    updated_at     = now();
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_upsert_profile(
  uuid, text, text, text, boolean, text, text, text, text
) TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_update_profile_settings(
  p_email      text,
  p_avatar_url text DEFAULT NULL,
  p_biography  text DEFAULT NULL,
  p_location   text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = '42501';
  END IF;

  INSERT INTO public.profiles (
    id, email, full_name, is_agent, system_role, status, avatar_url, biography, location, created_at, updated_at
  ) VALUES (
    auth.uid(),
    COALESCE(auth.jwt() ->> 'email', p_email, ''),
    split_part(COALESCE(auth.jwt() ->> 'email', p_email, ''), '@', 1),
    false,
    'USER',
    'ACTIVE',
    p_avatar_url,
    p_biography,
    p_location,
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    avatar_url = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url),
    biography  = COALESCE(EXCLUDED.biography,  public.profiles.biography),
    location   = COALESCE(EXCLUDED.location,   public.profiles.location),
    updated_at = now();
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_update_profile_settings(text, text, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_complete_onboarding(
  p_email          text,
  p_status         text,
  p_property_types text[] DEFAULT '{}',
  p_goals          text[] DEFAULT '{}',
  p_areas          text[] DEFAULT '{}',
  p_notifications  jsonb  DEFAULT '{}'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL OR p_status NOT IN ('IN_PROGRESS', 'COMPLETED', 'SKIPPED') THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = '42501';
  END IF;

  UPDATE public.profiles
  SET onboarding_status   = p_status,
      pref_property_types = p_property_types,
      pref_goals          = p_goals,
      pref_areas          = p_areas,
      pref_notifications  = p_notifications,
      updated_at          = now()
  WHERE id = auth.uid();
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_complete_onboarding(text, text, text[], text[], text[], jsonb) TO authenticated;

-- ============================================================
-- FIX 2: handle_new_user trigger (crear perfil al registrarse)
-- ============================================================
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
      NEW.raw_user_meta_data ->> 'full_name',
      NEW.raw_user_meta_data ->> 'name',
      split_part(COALESCE(NEW.email, ''), '@', 1),
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

-- ============================================================
-- FIX 3: Storage Buckets & Politicas RLS (Avatares y Fotos)
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET public = true;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'property-photos',
  'property-photos',
  true,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Politicas RLS para bucket 'avatars'
DROP POLICY IF EXISTS "avatars_select" ON storage.objects;
CREATE POLICY "avatars_select" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_insert" ON storage.objects;
CREATE POLICY "avatars_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_update" ON storage.objects;
CREATE POLICY "avatars_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars')
  WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_delete" ON storage.objects;
CREATE POLICY "avatars_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'avatars');

-- Politicas RLS para bucket 'property-photos'
DROP POLICY IF EXISTS "property_photos_select" ON storage.objects;
CREATE POLICY "property_photos_select" ON storage.objects
  FOR SELECT USING (bucket_id = 'property-photos');

DROP POLICY IF EXISTS "property_photos_insert" ON storage.objects;
CREATE POLICY "property_photos_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'property-photos');

DROP POLICY IF EXISTS "property_photos_delete" ON storage.objects;
CREATE POLICY "property_photos_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'property-photos');

-- ============================================================
-- FIX 4: Exponer RPCs publicas a authenticated
-- ============================================================
GRANT EXECUTE ON FUNCTION public.kaza_publish(uuid, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_my_listings(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_catalog(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_saved(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_listing_command(uuid, uuid, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_start_conversation(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.kaza_send_message(uuid, uuid, text, uuid) TO authenticated;

-- ============================================================
-- FIX 5: Recuperar perfiles faltantes de usuarios existentes
-- ============================================================
INSERT INTO public.profiles (id, email, full_name, is_agent, system_role, status, created_at, updated_at)
SELECT
  u.id,
  COALESCE(u.email, ''),
  COALESCE(
    u.raw_user_meta_data ->> 'full_name',
    u.raw_user_meta_data ->> 'name',
    split_part(COALESCE(u.email, ''), '@', 1),
    'Usuario'
  ),
  FALSE, 'USER', 'ACTIVE', now(), now()
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
ON CONFLICT (id) DO NOTHING;

COMMIT;
