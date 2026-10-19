import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {database} from './database-helper.mjs';

test('spatial_ref_sys stays readable but rejects API writes',async(t)=>{
 const db=await database();t.after(()=>db.close());
 await db.exec("GRANT ALL ON public.spatial_ref_sys TO anon,authenticated"); // Supabase default exposure
 const sql=await readFile(new URL('../../supabase/migrations/00033_lock_spatial_ref_sys.sql',import.meta.url),'utf8');
 await db.exec(sql);await db.exec(sql); // idempotent
 await db.exec('SET ROLE anon');
 try{
  assert.ok((await db.query('SELECT count(*)::int AS n FROM public.spatial_ref_sys')).rows[0].n>0);
  await assert.rejects(db.query("INSERT INTO public.spatial_ref_sys(srid,auth_name) VALUES(999999,'x')"),e=>e.code==='42501');
  await assert.rejects(db.query('DELETE FROM public.spatial_ref_sys WHERE srid=4326'),e=>e.code==='42501');
 }finally{await db.exec('RESET ROLE');}
 assert.equal((await db.query("SELECT relrowsecurity FROM pg_class WHERE oid='public.spatial_ref_sys'::regclass")).rows[0].relrowsecurity,true);
});
