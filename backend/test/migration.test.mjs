import {test} from 'node:test';
import assert from 'node:assert/strict';
import {database,asUser} from './database-helper.mjs';
import {migrationBundle} from '../scripts/migrations.mjs';
import {readFile} from 'node:fs/promises';

test('fresh bundle is atomic and supplies the complete secured schema',async(t)=>{
 const db=await database({mode:'empty'});t.after(()=>db.close());
 await db.exec(await migrationBundle('fresh'));
 await db.exec(await readFile(new URL('../../supabase/preflight.sql',import.meta.url),'utf8'));
 assert.equal((await db.query("SELECT count(*) AS n FROM pg_policies WHERE schemaname='public' AND tablename='profiles'")).rows[0].n,2);
 await assert.rejects(db.exec(await migrationBundle('fresh')),/empty KAZA schema/);
 await db.exec('ROLLBACK');
});
test('manual SQL bundle matches its versioned migration sources',async()=>{
 assert.equal(await readFile(new URL('../../supabase/manual/kaza-upgrade.sql',import.meta.url),'utf8'),await migrationBundle('upgrade'));
});

test('upgrade repairs missing organization columns without exposing personal CRM rows',async(t)=>{
 const db=await database({mode:'legacy'});t.after(()=>db.close());
 const tables=['properties','crm_contacts','crm_opportunities','crm_tasks'];
 for(const table of tables)await db.exec(`ALTER TABLE public.${table} DROP COLUMN organization_id`);
 const a='11111111-1111-4111-8111-111111111111',b='22222222-2222-4222-8222-222222222222';
 for(const id of [a,b]){
  await db.query('INSERT INTO auth.users(id,email) VALUES($1,$2)',[id,`${id}@test.local`]);
  await db.query('INSERT INTO public.profiles(id,email,full_name) VALUES($1,$2,$3)',[id,`${id}@test.local`,'Existing user']);
 }
 await db.query("INSERT INTO public.crm_contacts(agent_id,first_name) VALUES($1,'Existing contact')",[a]);
 await db.exec(await migrationBundle('upgrade'));
 for(const table of tables){
  const column=(await db.query("SELECT data_type,is_nullable FROM information_schema.columns WHERE table_schema='public' AND table_name=$1 AND column_name='organization_id'",[table])).rows[0];
  assert.deepEqual(column,{data_type:'uuid',is_nullable:'YES'});
 }
 await asUser(db,a,async()=>{
  const rows=(await db.query('SELECT first_name,organization_id FROM public.crm_contacts')).rows;
  assert.deepEqual(rows,[{first_name:'Existing contact',organization_id:null}]);
  await assert.rejects(db.query("INSERT INTO public.crm_contacts(agent_id,first_name,organization_id) VALUES($1,'Invalid org',$2)",[a,b]),e=>e.code==='42501');
 });
 await asUser(db,b,async()=>assert.equal((await db.query('SELECT * FROM public.crm_contacts')).rows.length,0));
 await assert.rejects(db.query("INSERT INTO public.crm_contacts(agent_id,first_name,organization_id) VALUES($1,'Invalid org',$2)",[a,b]),e=>e.code==='23503');
});
test('incremental upgrade preserves legacy inventory and supports explicit backfill',async(t)=>{
 const db=await database({mode:'legacy'});t.after(()=>db.close());
 const user='99999999-9999-4999-8999-999999999999';
 await db.query('INSERT INTO auth.users(id,email) VALUES($1,$2)',[user,'legacy@test.local']);
 await db.query("INSERT INTO public.properties(owner_id,title,property_type,country_code,city_id,status,latitude,longitude,price_usd,currency_code) VALUES($1,'Existing house','Casa','BOL','santa_cruz','PUBLISHED',-17.78,-63.18,125000,'USD')",[user]);
 await db.exec(await migrationBundle('upgrade'));
 const result=(await db.query('SELECT public.kaza_backfill_legacy() AS report')).rows[0].report;
 assert.equal(result.migrated,1);
 assert.equal((await db.query('SELECT count(*) AS n FROM public.properties')).rows[0].n,1);
 assert.equal((await db.query('SELECT price_original FROM public.listings')).rows[0].price_original,'125000.00');
 assert.equal((await db.query('SELECT public.kaza_backfill_legacy() AS report')).rows[0].report.migrated,0);
});
