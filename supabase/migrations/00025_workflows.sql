BEGIN;
ALTER TABLE public.conversation_participants ADD COLUMN is_host boolean NOT NULL DEFAULT false;
CREATE OR REPLACE FUNCTION kaza_private.conversation_access(p_user uuid,p_conversation uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT kaza_private.active(p_user) AND EXISTS(SELECT 1 FROM public.conversation_participants cp JOIN public.conversations c ON c.id=cp.conversation_id WHERE cp.user_id=p_user AND cp.conversation_id=p_conversation AND (NOT cp.is_host OR kaza_private.workspace_access(p_user,c.workspace_id,true)));
$$;
CREATE FUNCTION public.kaza_start_conversation(p_actor uuid,p_property uuid) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
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
CREATE FUNCTION public.kaza_send_message(p_actor uuid,p_conversation uuid,p_content text,p_client uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE m public.messages;
BEGIN
 IF NOT kaza_private.conversation_access(p_actor,p_conversation) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 IF length(trim(p_content)) NOT BETWEEN 1 AND 4000 THEN RAISE EXCEPTION 'Invalid content' USING ERRCODE='22023'; END IF;
 INSERT INTO public.messages(conversation_id,sender_user_id,content,client_id) VALUES(p_conversation,p_actor,p_content,p_client) ON CONFLICT(sender_user_id,client_id) WHERE client_id IS NOT NULL DO NOTHING RETURNING * INTO m;
 IF m.id IS NULL THEN SELECT * INTO m FROM public.messages WHERE sender_user_id=p_actor AND client_id=p_client; END IF;
 IF m.content<>p_content OR m.conversation_id<>p_conversation THEN RAISE EXCEPTION 'Conflict' USING ERRCODE='23505'; END IF;
 RETURN to_jsonb(m);
END $$;
CREATE FUNCTION public.kaza_create_organization(p_actor uuid,p_data jsonb) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE w uuid; o uuid; BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 IF length(trim(p_data->>'legal_name')) NOT BETWEEN 1 AND 180 THEN RAISE EXCEPTION 'Invalid name' USING ERRCODE='22023'; END IF;
 INSERT INTO public.workspaces(name,workspace_type,owner_user_id) VALUES(p_data->>'legal_name','ORGANIZATION',p_actor) RETURNING id INTO w;
 INSERT INTO public.organizations(workspace_id,legal_name,description,website,logo_url,contact_email,contact_phone,city,address,org_type) VALUES(w,p_data->>'legal_name',p_data->>'description',p_data->>'website',p_data->>'logo_url',p_data->>'contact_email',p_data->>'contact_phone',p_data->>'city',p_data->>'address',coalesce(p_data->>'org_type','AGENCY')) RETURNING id INTO o;
 INSERT INTO public.organization_memberships(organization_id,user_id,role_name) VALUES(o,p_actor,'ADMIN');
 RETURN o;
END $$;
CREATE FUNCTION public.kaza_invite(p_actor uuid,p_org uuid,p_email text,p_role text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result public.organization_invitations; BEGIN
 PERFORM kaza_private.assert_actor(p_actor);
 IF NOT EXISTS(SELECT 1 FROM public.organizations o JOIN public.workspaces w ON w.id=o.workspace_id WHERE o.id=p_org AND w.owner_user_id=p_actor) THEN RAISE EXCEPTION 'Forbidden' USING ERRCODE='42501'; END IF;
 IF p_role NOT IN ('OPERATOR','VIEWER') OR length(p_email) NOT BETWEEN 3 AND 254 THEN RAISE EXCEPTION 'Invalid invitation' USING ERRCODE='22023'; END IF;
 INSERT INTO public.organization_invitations(organization_id,invited_email,invited_by,role_name) VALUES(p_org,lower(p_email),p_actor,p_role) RETURNING * INTO result;
 RETURN to_jsonb(result);
END $$;
CREATE FUNCTION public.kaza_respond_invitation(p_actor uuid,p_code text,p_id uuid,p_accept boolean) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
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
CREATE FUNCTION public.kaza_backfill_legacy() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
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
CREATE FUNCTION public.kaza_mock_transfer(p_actor uuid,p_receiver uuid,p_amount numeric,p_key text,p_concept text,p_listing uuid DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
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
