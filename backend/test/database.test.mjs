import { test } from 'node:test';
import assert from 'node:assert/strict';
import { database,asUser } from './database-helper.mjs';
const a='11111111-1111-4111-8111-111111111111', b='22222222-2222-4222-8222-222222222222';
const payload={title:'Prueba',description:'Test',propertyType:'Casa',countryCode:'BOL',cityId:'santa_cruz',operationType:'SALE',priceOriginal:100000,currencyOriginal:'USD',latitude:-17.783345,longitude:-63.182145,photos:[],contactPhone:'PRIVATE',address:'PRIVATE EXACT'};
test('migrations, RLS, transactions and authorized workflows',async(t)=>{
 const db=await database(); t.after(()=>db.close());
 await db.query('INSERT INTO auth.users(id,email) VALUES($1,$2),($3,$4)',[a,`${a}@test.local`,b,`${b}@test.local`]);
 for(const id of [a,b]) await asUser(db,id,()=>db.query('SELECT public.fn_upsert_profile($1,$2,$3)',[id,`${id}@test.local`,'Test']));
 const rpc=async(name,args)=> (await db.query(`SELECT public.${name}(${args.map((_,i)=>'$'+(i+1)).join(',')}) AS result`,args)).rows[0].result;
 let listing;
 await t.test('publication is idempotent and public data is minimized',async()=>{
  listing=await rpc('kaza_publish',[a,'request-0000000001',payload]);
  assert.deepEqual(await rpc('kaza_publish',[a,'request-0000000001',payload]),listing);
  await assert.rejects(rpc('kaza_publish',[a,'request-0000000001',{...payload,title:'Changed'}]),e=>e.code==='23505');
  const catalog=await rpc('kaza_catalog',[{detail:true}]); assert.equal(catalog.length,1);
  assert.equal(catalog[0].latitude,-17.783); assert.equal(catalog[0].address_canonical,undefined);assert.equal(catalog[0].contact_phone,null);assert.equal(catalog[0].owner_id,undefined);
 });
 await t.test('anonymous cannot read profiles or execute privileged commands',async()=>{
  await db.exec('SET ROLE anon');
  try{await assert.rejects(db.query('SELECT * FROM public.profiles'),e=>e.code==='42501');await assert.rejects(rpc('kaza_publish',[a,'request-0000000009',payload]),e=>e.code==='42501');}finally{await db.exec('RESET ROLE');}
 });
 await t.test('another user cannot read private assets, profiles or favorites',async()=>{
  await asUser(db,a,()=>db.query('INSERT INTO public.saved_properties(user_id,property_id) VALUES($1,$2)',[a,listing.propertyId]));
  await asUser(db,b,async()=>{
   assert.equal((await db.query('SELECT * FROM public.properties')).rows.length,0);
   assert.equal((await db.query('SELECT * FROM public.saved_properties')).rows.length,0);
   assert.deepEqual((await db.query('SELECT id FROM public.profiles')).rows.map(r=>r.id),[b]);
   await assert.rejects(db.query('INSERT INTO public.saved_properties(user_id,property_id) VALUES($1,$2)',[a,listing.propertyId]),e=>e.code==='42501');
  });
 });
 await t.test('roles and subscriptions cannot be self assigned',async()=>{
  await asUser(db,b,async()=>{
   await assert.rejects(db.query("UPDATE public.profiles SET system_role='ADMIN' WHERE id=$1",[b]),e=>e.code==='42501');
   await assert.rejects(db.query("SELECT public.fn_upgrade_subscription('BUSINESS')"),e=>e.code==='42501');
   await assert.rejects(db.query("SELECT public.fn_upsert_profile($1,$2,'Test','ADMIN')",[b,`${b}@test.local`]),e=>e.code==='42501');
   await assert.rejects(db.query("INSERT INTO public.kaza_admins(user_id) VALUES($1)",[b]),e=>e.code==='42501');
  });
 });
 await t.test('invalid publication rolls back property and cycle',async()=>{
  const before=(await db.query('SELECT count(*) AS n FROM public.properties')).rows[0].n;
  await assert.rejects(rpc('kaza_publish',[a,'request-0000000002',{...payload,currencyOriginal:'TOO_LONG'}]));
  assert.equal((await db.query('SELECT count(*) AS n FROM public.properties')).rows[0].n,before);
 });
 await t.test('wrong owner and stale versions cannot change state',async()=>{
  await assert.rejects(rpc('kaza_listing_command',[b,listing.id,'status',{status:'PAUSED',version:0}]),e=>e.code==='42501');
  await rpc('kaza_listing_command',[a,listing.id,'status',{status:'PAUSED',version:0}]);
  await assert.rejects(rpc('kaza_listing_command',[a,listing.id,'status',{status:'AVAILABLE',version:0}]),e=>e.code==='40001');
  await rpc('kaza_listing_command',[a,listing.id,'status',{status:'AVAILABLE',version:1}]);
 });
 await t.test('chat is private and message retries are idempotent',async()=>{
  const c=await rpc('kaza_start_conversation',[b,listing.propertyId]);
  const id='33333333-3333-4333-8333-333333333333';
  const message=await rpc('kaza_send_message',[b,c,'Hola',id]);
  assert.equal((await rpc('kaza_send_message',[b,c,'Hola',id])).id,message.id);
  await assert.rejects(rpc('kaza_send_message',[b,c,'Other text',id]),e=>e.code==='23505');
  await asUser(db,a,async()=>assert.equal((await db.query('SELECT * FROM public.messages')).rows.length,1));
 });
 await t.test('organization creation is atomic and membership cannot be forged',async()=>{
  const org=await rpc('kaza_create_organization',[a,{legal_name:'Test Org',org_type:'AGENCY'}]);
  await asUser(db,b,()=>assert.rejects(db.query("INSERT INTO public.organization_memberships(organization_id,user_id,role_name) VALUES($1,$2,'ADMIN')",[org,b]),e=>e.code==='42501'));
  const invitation=await rpc('kaza_invite',[a,org,`${b}@test.local`,'OPERATOR']);
  await assert.rejects(rpc('kaza_respond_invitation',[a,invitation.code,null,true]),e=>e.code==='22023');
  await rpc('kaza_respond_invitation',[b,invitation.code,null,true]);
  await assert.rejects(rpc('kaza_respond_invitation',[b,invitation.code,null,true]),e=>e.code==='22023');
 });
 await t.test('admin requires independent trusted membership and audited reason',async()=>{
  await assert.rejects(rpc('kaza_admin_dashboard',[b]),e=>e.code==='42501');
  await db.query('INSERT INTO public.kaza_admins(user_id) VALUES($1)',[a]);
  await rpc('kaza_moderate',[a,listing.id,'suspend_listing','Review required']);
  assert.equal((await rpc('kaza_catalog',[{}])).length,0);
  assert.equal((await db.query("SELECT count(*) AS n FROM public.kaza_audit WHERE action='suspend_listing'")).rows[0].n,1);
 });
 await t.test('CRM allows own edits and rejects foreign contact and opportunity references',async()=>{
  const contact=await asUser(db,a,async()=>{
   const row=(await db.query("INSERT INTO public.crm_contacts(agent_id,first_name) VALUES($1,'Own') RETURNING id",[a])).rows[0];
   await db.query("UPDATE public.crm_contacts SET first_name='Edited' WHERE id=$1",[row.id]);
   return row.id;
  });
  const opportunity=await asUser(db,a,async()=>(await db.query("INSERT INTO public.crm_opportunities(agent_id,contact_id,title) VALUES($1,$2,'Own deal') RETURNING id",[a,contact])).rows[0].id);
  await asUser(db,b,async()=>{
   assert.equal((await db.query('SELECT * FROM public.crm_contacts')).rows.length,0);
   await assert.rejects(db.query("INSERT INTO public.crm_opportunities(agent_id,contact_id,title) VALUES($1,$2,'Foreign')",[b,contact]),e=>e.code==='42501');
   await assert.rejects(db.query("INSERT INTO public.crm_tasks(agent_id,opportunity_id,title) VALUES($1,$2,'Foreign')",[b,opportunity]),e=>e.code==='42501');
  });
 });
 await t.test('storage upload and delete are limited to the authenticated user folder',async()=>{
  await asUser(db,a,()=>db.query("INSERT INTO storage.objects(bucket_id,name) VALUES('property-photos',$1)",[a+'/draft/photo.png']));
  await asUser(db,b,async()=>{
   await assert.rejects(db.query("INSERT INTO storage.objects(bucket_id,name) VALUES('property-photos',$1)",[a+'/draft/forged.png']),e=>e.code==='42501');
   assert.equal((await db.query('DELETE FROM storage.objects WHERE name=$1 RETURNING id',[a+'/draft/photo.png'])).rows.length,0);
  });
 });
 await t.test('unrelated participants and removed hosts cannot read or send messages',async()=>{
  const c='44444444-4444-4444-8444-444444444444';
  await db.query('INSERT INTO auth.users(id,email) VALUES($1,$2)',[c,`${c}@test.local`]);
  const conversation=(await db.query('SELECT id FROM public.conversations LIMIT 1')).rows[0].id;
  await asUser(db,c,async()=>assert.equal((await db.query('SELECT * FROM public.messages')).rows.length,0));
  await assert.rejects(rpc('kaza_send_message',[c,conversation,'Unauthorized','55555555-5555-4555-8555-555555555555']),e=>e.code==='42501');
  const workspace=(await db.query('SELECT workspace_id FROM public.conversations WHERE id=$1',[conversation])).rows[0].workspace_id;
  await db.query('UPDATE public.workspaces SET owner_user_id=$1 WHERE id=$2',[c,workspace]);
  await asUser(db,a,async()=>assert.equal((await db.query('SELECT * FROM public.messages')).rows.length,0));
  await assert.rejects(rpc('kaza_send_message',[a,conversation,'Revoked','66666666-6666-4666-8666-666666666666']),e=>e.code==='42501');
  await db.query('UPDATE public.workspaces SET owner_user_id=$1 WHERE id=$2',[a,workspace]);
 });
 await t.test('legacy paid profile does not grant trusted publication entitlement',async()=>{
  await db.query("UPDATE public.profiles SET subscription_tier='BUSINESS' WHERE id=$1",[b]);
  await rpc('kaza_publish',[b,'quota-00000000001',payload]);
  await rpc('kaza_publish',[b,'quota-00000000002',payload]);
  await assert.rejects(rpc('kaza_publish',[b,'quota-00000000003',payload]),e=>e.code==='23514');
  await asUser(db,b,()=>assert.rejects(db.query("INSERT INTO public.kaza_entitlements VALUES($1,'PRO',now()+interval '1 year','forged')",[b]),e=>e.code==='42501'));
 });
 await t.test('demo transfers preserve total balance and are idempotent',async()=>{
  await db.query("INSERT INTO public.mock_user_kyc(user_id,status,id_number) VALUES($1,'VERIFIED','DEMO')",[a]);
  await db.query('INSERT INTO public.mock_wallets(user_id,balance) VALUES($1,5000),($2,5000)',[a,b]);
  const result=await rpc('kaza_mock_transfer',[a,b,100,'transfer-00000001','Demo',null]);
  assert.deepEqual(await rpc('kaza_mock_transfer',[a,b,100,'transfer-00000001','Demo',null]),result);
  assert.equal(Number((await db.query('SELECT sum(balance) AS total FROM public.mock_wallets')).rows[0].total),10000);
  assert.equal(Number((await db.query('SELECT balance FROM public.mock_wallets WHERE user_id=$1',[a])).rows[0].balance),4900);
  await assert.rejects(rpc('kaza_mock_transfer',[a,b,9000,'transfer-00000002','Demo',null]));
  assert.equal(Number((await db.query('SELECT balance FROM public.mock_wallets WHERE user_id=$1',[a])).rows[0].balance),4900);
 });
 await t.test('suspension immediately blocks own private reads and commands',async()=>{
  await db.query("UPDATE public.profiles SET status='SUSPENDED' WHERE id=$1",[b]);
  await asUser(db,b,async()=>{
   assert.equal((await db.query('SELECT * FROM public.profiles')).rows.length,0);
   assert.equal((await db.query('SELECT * FROM public.listings')).rows.length,0);
  });
  await assert.rejects(rpc('kaza_conversations',[b]),e=>e.code==='42501');
 });
});
