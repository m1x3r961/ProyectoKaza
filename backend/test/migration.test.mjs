import {test} from 'node:test';
import assert from 'node:assert/strict';
import {database} from './database-helper.mjs';
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
