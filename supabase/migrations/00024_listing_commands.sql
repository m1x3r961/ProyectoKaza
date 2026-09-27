BEGIN;
CREATE FUNCTION kaza_private.assert_actor(p_actor uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN IF NOT kaza_private.active(p_actor) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF; END $$;
CREATE FUNCTION kaza_private.personal_workspace(p_actor uuid) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE w uuid; BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 PERFORM pg_advisory_xact_lock(hashtextextended(p_actor::text,0));
 SELECT id INTO w FROM public.workspaces WHERE owner_user_id=p_actor AND workspace_type='PERSONAL' ORDER BY created_at LIMIT 1;
 IF w IS NULL THEN INSERT INTO public.workspaces(name,workspace_type,owner_user_id) VALUES('Personal','PERSONAL',p_actor) RETURNING id INTO w; END IF;
 RETURN w;
END $$;

CREATE FUNCTION public.kaza_publish(p_actor uuid,p_key text,p_data jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
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

CREATE FUNCTION public.kaza_listing_command(p_actor uuid,p_id uuid,p_action text,p_data jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
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
CREATE FUNCTION public.kaza_accept_transfer(p_actor uuid,p_id uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
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
CREATE FUNCTION kaza_private.public_listing(l public.listings,p public.properties,p_detail boolean DEFAULT false) RETURNS jsonb LANGUAGE sql STABLE SET search_path='' AS $$
 SELECT jsonb_build_object('id',p.id,'listing_id',l.id,'title',l.title,'price_usd',CASE WHEN l.pricing_mode='PUBLIC_NUMERIC' THEN l.price_original ELSE NULL END,'currency_code',l.currency_original,'operation',CASE c.operation_type WHEN 'SALE' THEN 'VENTA' WHEN 'RENT' THEN 'ALQUILER' ELSE c.operation_type END,'property_type',p.property_type,'latitude',round(p.latitude::numeric,3),'longitude',round(p.longitude::numeric,3),'public_location_mode','APPROXIMATE','rooms',p.rooms,'bathrooms',p.bathrooms,'total_surface_m2',p.total_surface_m2,'photos',CASE WHEN p_detail THEN coalesce(p.photos,'[]') ELSE CASE WHEN jsonb_array_length(coalesce(p.photos,'[]'))>0 THEN jsonb_build_array(p.photos->0) ELSE '[]'::jsonb END END,'status','PUBLISHED','city_id',p.city_id,'updated_at',l.freshness_confirmed_at,'has_active_promotion',false)
 || CASE WHEN p_detail THEN jsonb_build_object('description',l.description,'amenities',p.amenities,'covered_surface_m2',p.covered_surface_m2,'parking_spaces',p.parking_spaces,'age_years',p.age_years,'floors_total',p.floors_total,'contact_name',CASE WHEN p.show_contact THEN p.contact_name ELSE NULL END,'contact_phone',CASE WHEN p.show_contact THEN p.contact_phone ELSE NULL END) ELSE '{}'::jsonb END
 FROM public.market_cycles c WHERE c.id=l.market_cycle_id;
$$;
CREATE FUNCTION public.kaza_catalog(p_query jsonb DEFAULT '{}') RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
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
CREATE FUNCTION public.kaza_my_listings(p_actor uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 SELECT coalesce(jsonb_agg(x),'[]') INTO result FROM (SELECT l.id,l.property_id,l.title,l.description,l.price_original,l.currency_original,l.status,l.version,l.moderation_status,l.freshness_confirmed_at,l.updated_at,p.views_count FROM public.listings l JOIN public.properties p ON p.id=l.property_id WHERE kaza_private.workspace_access(p_actor,l.workspace_id) ORDER BY l.created_at DESC LIMIT 200) x;
 RETURN result;
END $$;
CREATE FUNCTION public.kaza_saved(p_actor uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',s.id,'property_id',s.property_id,'properties',kaza_private.public_listing(l,p,true))),'[]') INTO result
 FROM public.saved_properties s JOIN public.properties p ON p.id=s.property_id JOIN LATERAL(SELECT * FROM public.listings x WHERE x.property_id=p.id AND x.status='AVAILABLE' AND x.moderation_status='APPROVED' ORDER BY x.created_at DESC LIMIT 1) l ON true WHERE s.user_id=p_actor;
 RETURN result;
END $$;
CREATE FUNCTION public.kaza_admin_dashboard(p_actor uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT kaza_private.active(p_actor) OR NOT EXISTS(SELECT 1 FROM public.kaza_admins WHERE user_id=p_actor) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 RETURN jsonb_build_object('users',(SELECT coalesce(jsonb_agg(x),'[]') FROM (SELECT id,email,full_name,system_role,status,created_at FROM public.profiles ORDER BY created_at DESC LIMIT 100) x),'properties',(SELECT coalesce(jsonb_agg(x),'[]') FROM (SELECT l.id,l.title,l.price_original AS price_usd,l.status,l.moderation_status,p.property_type,p.city_id,l.created_at FROM public.listings l JOIN public.properties p ON p.id=l.property_id ORDER BY l.created_at DESC LIMIT 100) x),'cases',(SELECT coalesce(jsonb_agg(x),'[]') FROM (SELECT * FROM public.admin_cases ORDER BY created_at DESC LIMIT 100) x));
END $$;
CREATE FUNCTION public.kaza_moderate(p_actor uuid,p_id uuid,p_action text,p_reason text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
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
