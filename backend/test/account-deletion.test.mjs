import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {database,asUser} from './database-helper.mjs';

const admin='33333333-3333-4333-8333-333333333333';
const owner='44444444-4444-4444-8444-444444444444';
const buyer='55555555-5555-4555-8555-555555555555';
const one=async(db,sql,args)=>(await db.query(sql,args)).rows[0];

test('users delete their own account: anonymized, listings hidden, audited, admins refused',async(t)=>{
 const db=await database();t.after(()=>db.close());
 await db.exec(await readFile(new URL('../../supabase/migrations/00034_account_deletion.sql',import.meta.url),'utf8'));
 await db.query('INSERT INTO auth.users(id,email) VALUES($1,$2),($3,$4),($5,$6)',[admin,'admin@test.local',owner,'owner@test.local',buyer,'buyer@test.local']);
 for(const [id,email] of [[admin,'admin@test.local'],[owner,'owner@test.local'],[buyer,'buyer@test.local']]) {
  await asUser(db,id,()=>db.query('SELECT public.fn_upsert_profile($1,$2,$3)',[id,email,'Test user']));
 }
 await db.query('INSERT INTO public.kaza_admins(user_id) VALUES($1)',[admin]);
 await db.query("UPDATE public.profiles SET phone='+59170000000',biography='Bio',avatar_url='https://x/a.jpg',location='Santa Cruz' WHERE id=$1",[owner]);
 const payload={title:'Casa a eliminar',description:'Test',propertyType:'Casa',countryCode:'BOL',cityId:'santa_cruz',operationType:'SALE',priceOriginal:100000,currencyOriginal:'USD',latitude:-17.783345,longitude:-63.182145,photos:[],contactPhone:'PRIVATE',address:'PRIVATE'};
 const listing=(await one(db,'SELECT public.kaza_publish($1,$2,$3) AS result',[owner,'self-delete-test-01',payload])).result;
 const property=(await one(db,'SELECT property_id FROM public.listings WHERE id=$1',[listing.id])).property_id;
 const conversation=(await one(db,'SELECT public.kaza_start_conversation($1,$2) AS id',[buyer,property])).id;
 await db.query("SELECT public.kaza_send_message($1,$2,'Hola, me interesa',gen_random_uuid())",[buyer,conversation]);
 await db.query("SELECT public.kaza_send_message($1,$2,'Claro, coordinemos',gen_random_uuid())",[owner,conversation]);

 // Not callable by app sessions directly.
 await assert.rejects(asUser(db,owner,()=>db.query('SELECT public.kaza_delete_own_account($1)',[owner])),/permission denied/i);
 // Admin accounts are refused and stay untouched.
 await assert.rejects(db.query('SELECT public.kaza_delete_own_account($1)',[admin]),e=>e.code==='42501');
 assert.equal((await one(db,'SELECT status FROM public.profiles WHERE id=$1',[admin])).status,'ACTIVE');

 const result=(await one(db,'SELECT public.kaza_delete_own_account($1) AS result',[owner])).result;
 assert.equal(result.success,true);
 assert.equal(result.affectedListings,1);
 assert.equal(result.email,`${owner}@test.local`); // fn_upsert_profile takes the JWT email

 const p=await one(db,'SELECT * FROM public.profiles WHERE id=$1',[owner]);
 assert.equal(p.status,'DELETED');
 assert.equal(p.email,`orphan+${owner}@kaza.invalid`);
 assert.equal(p.full_name,'Usuario eliminado');
 for(const field of ['phone','biography','avatar_url','location']) assert.equal(p[field],null,field);

 const l=await one(db,'SELECT status,moderation_status FROM public.listings WHERE id=$1',[listing.id]);
 assert.equal(l.status,'WITHDRAWN');
 assert.equal(l.moderation_status,'SUSPENDED');

 assert.equal((await one(db,"SELECT count(*)::int AS n FROM public.kaza_audit WHERE action='self_delete_account' AND actor=$1 AND target=$1",[owner])).n,1);
 // The other party keeps the conversation and their own messages.
 assert.equal((await one(db,'SELECT count(*)::int AS n FROM public.messages WHERE conversation_id=$1 AND sender_user_id=$2',[conversation,buyer])).n,1);
 assert.equal((await one(db,'SELECT status FROM public.profiles WHERE id=$1',[buyer])).status,'ACTIVE');
 // The deleted account loses access to protected operations.
 await assert.rejects(db.query('SELECT public.kaza_conversations($1)',[owner]),e=>e.code==='42501');

 // Retrying (e.g. after an Auth API failure) is a no-op.
 const again=(await one(db,'SELECT public.kaza_delete_own_account($1) AS result',[owner])).result;
 assert.equal(again.alreadyDeleted,true);
 assert.equal((await one(db,"SELECT count(*)::int AS n FROM public.kaza_audit WHERE action='self_delete_account' AND target=$1",[owner])).n,1);

 // The freed email no longer blocks a new profile with that address.
 const fresh='66666666-6666-4666-8666-666666666666';
 await db.query("INSERT INTO public.profiles(id,email,full_name) VALUES($1,$2,'Nueva')",[fresh,`${owner}@test.local`]);
 assert.equal((await one(db,'SELECT count(*)::int AS n FROM public.profiles WHERE email=$1',[`${owner}@test.local`])).n,1);
});
