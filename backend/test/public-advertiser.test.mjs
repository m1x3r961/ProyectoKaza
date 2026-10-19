import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {database,asUser} from './database-helper.mjs';

const user='33333333-3333-4333-8333-333333333333';

test('catalog detail exposes only public advertiser data',async(t)=>{
 const db=await database();t.after(()=>db.close());
 await db.exec(await readFile(new URL('../../supabase/migrations/00035_public_advertiser.sql',import.meta.url),'utf8'));
 await db.query('INSERT INTO auth.users(id,email) VALUES($1,$2)',[user,'owner@test.local']);
 await asUser(db,user,()=>db.query('SELECT public.fn_upsert_profile($1,$2,$3)',[user,'owner@test.local','Owner Private']));
 const payload={title:'Depto',description:'Test',propertyType:'Departamento',countryCode:'BOL',cityId:'santa_cruz',operationType:'SALE',priceOriginal:90000,currencyOriginal:'USD',latitude:-17.78,longitude:-63.18,photos:[],contactPhone:'70000000',address:'PRIVATE'};
 await db.query('SELECT public.kaza_publish($1,$2,$3)',[user,'advertiser-test-01',payload]);
 const detail=async()=>(await db.query("SELECT public.kaza_catalog('{\"detail\":true}') AS r")).rows[0].r[0];
 const list=async()=>(await db.query("SELECT public.kaza_catalog('{}') AS r")).rows[0].r[0];

 // Personal listing, contact hidden: no name, no private data.
 let a=(await detail()).advertiser;
 assert.equal(a.kind,'PERSONAL');assert.equal(a.name,null);assert.equal(a.active_listings,1);assert.equal(a.is_verified,false);
 assert.match(a.member_since,/^\d{4}$/);
 assert.ok(!JSON.stringify(a).includes('owner@test.local'));assert.ok(!JSON.stringify(a).includes('Owner Private'));
 assert.equal((await list()).advertiser,undefined); // list payload stays small

 // Contact name shown only when the publisher opted in.
 await db.query("UPDATE public.properties SET show_contact=true, contact_name='Ana Pérez'");
 assert.equal((await detail()).advertiser.name,'Ana Pérez');

 // Organization workspace: company data wins.
 const ws=(await db.query('SELECT workspace_id FROM public.listings LIMIT 1')).rows[0].workspace_id;
 await db.query("UPDATE public.workspaces SET workspace_type='ORGANIZATION' WHERE id=$1",[ws]);
 await db.query("INSERT INTO public.organizations(workspace_id,legal_name,is_verified) VALUES($1,'Inmobiliaria Sur',true)",[ws]);
 a=(await detail()).advertiser;
 assert.equal(a.kind,'ORGANIZATION');assert.equal(a.name,'Inmobiliaria Sur');assert.equal(a.is_verified,true);
});
