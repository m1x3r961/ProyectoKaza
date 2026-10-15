import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {database} from './database-helper.mjs';

const ids={a:'aaaaaaaa-0000-4000-8000-000000000001',b:'aaaaaaaa-0000-4000-8000-000000000002',c:'aaaaaaaa-0000-4000-8000-000000000003',d:'aaaaaaaa-0000-4000-8000-000000000004',e:'aaaaaaaa-0000-4000-8000-000000000005'};
const signup=(db,id,email)=>db.query("INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES($1,$2,'{\"full_name\":\"Nueva\"}')",[id,email]);
const profile=async(db,email)=>(await db.query('SELECT id,email,status,full_name FROM public.profiles WHERE email=$1',[email])).rows;

test('signup reuses or frees orphan profiles and never merges live accounts',async(t)=>{
 const db=await database();t.after(()=>db.close());
 await db.exec('ALTER TABLE auth.users ADD COLUMN raw_user_meta_data jsonb');
 await db.exec(await readFile(new URL('../../supabase/migrations/00032_signup_orphan_profiles.sql',import.meta.url),'utf8'));

 // Fresh email: plain profile.
 await signup(db,ids.a,'fresh@test.local');
 assert.deepEqual((await profile(db,'fresh@test.local')).map(r=>r.id),[ids.a]);

 // Active orphan (Auth user removed): profile moves to the new account.
 await db.query("INSERT INTO public.profiles(id,email,full_name,status) VALUES($1,'orphan@test.local','Antigua','ACTIVE')",[ids.b]);
 await signup(db,ids.c,'orphan@test.local');
 const moved=await profile(db,'orphan@test.local');
 assert.equal(moved.length,1);assert.equal(moved[0].id,ids.c);assert.equal(moved[0].full_name,'Antigua');

 // Deleted orphan: kept with a freed email, new account gets a clean profile.
 await db.query("INSERT INTO public.profiles(id,email,full_name,status) VALUES($1,'gone@test.local','Baja','DELETED')",[ids.d]);
 await signup(db,ids.e,'gone@test.local');
 const fresh=await profile(db,'gone@test.local');
 assert.equal(fresh.length,1);assert.equal(fresh[0].id,ids.e);assert.equal(fresh[0].status,'ACTIVE');
 assert.equal((await db.query('SELECT email FROM public.profiles WHERE id=$1',[ids.d])).rows[0].email,`orphan+${ids.d}@kaza.invalid`);

 // Active orphan with dependent rows: kept intact, email freed for the new account.
 const kept='aaaaaaaa-0000-4000-8000-000000000007',next='aaaaaaaa-0000-4000-8000-000000000008';
 await db.exec('CREATE TABLE public.dep_test(profile_id uuid REFERENCES public.profiles(id))');
 await db.query("INSERT INTO public.profiles(id,email,full_name,status) VALUES($1,'linked@test.local','Con datos','ACTIVE')",[kept]);
 await db.query('INSERT INTO public.dep_test VALUES($1)',[kept]);
 await signup(db,next,'linked@test.local');
 assert.deepEqual((await profile(db,'linked@test.local')).map(r=>r.id),[next]);
 assert.equal((await db.query('SELECT email FROM public.profiles WHERE id=$1',[kept])).rows[0].email,`orphan+${kept}@kaza.invalid`);

 // Email owned by a live Auth account still blocks the signup.
 await assert.rejects(signup(db,'aaaaaaaa-0000-4000-8000-000000000006','fresh@test.local'),/unique|duplicate/i);
});
