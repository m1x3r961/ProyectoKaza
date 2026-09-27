import { PGlite } from '@electric-sql/pglite';
import { postgis } from '@electric-sql/pglite-postgis';
import { uuid_ossp } from '@electric-sql/pglite/contrib/uuid_ossp';
import { readFile } from 'node:fs/promises';
export async function database({mode='all'}={}) {
 const db=new PGlite({extensions:{postgis,uuid_ossp}});
 await db.exec(`
 CREATE ROLE anon NOLOGIN; CREATE ROLE authenticated NOLOGIN; CREATE ROLE service_role NOLOGIN BYPASSRLS;
 CREATE SCHEMA auth; CREATE SCHEMA storage;
 CREATE TABLE auth.users(id uuid PRIMARY KEY,email text);
 CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$ SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
 CREATE FUNCTION auth.jwt() RETURNS jsonb LANGUAGE sql STABLE AS $$ SELECT coalesce(nullif(current_setting('request.jwt.claims',true),''),'{}')::jsonb $$;
 CREATE FUNCTION auth.role() RETURNS text LANGUAGE sql STABLE AS $$ SELECT current_user::text $$;
 GRANT USAGE ON SCHEMA auth,storage,public TO anon,authenticated,service_role;
 CREATE TABLE storage.buckets(id text PRIMARY KEY,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
 CREATE TABLE storage.objects(id uuid DEFAULT gen_random_uuid(),bucket_id text,name text);
 ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
 GRANT ALL ON storage.objects TO anon,authenticated,service_role;
 CREATE FUNCTION storage.foldername(text) RETURNS text[] LANGUAGE sql IMMUTABLE AS $$ SELECT string_to_array($1,'/') $$;
 `);
 const order=JSON.parse(await readFile(new URL('../../supabase/migration-order.json',import.meta.url),'utf8'));
 const files=mode==='empty'?[]:mode==='legacy'?order.slice(0,order.findIndex(f=>f.startsWith('00023_'))):order;
 for(const file of files){try{await db.exec(await readFile(new URL('../../supabase/migrations/'+file,import.meta.url),'utf8'));}catch(e){await db.close();throw new Error(`Migration ${file}: ${e.message}`,{cause:e});}}
 return db;
}
export async function asUser(db,id,work){
 await db.exec('SET ROLE authenticated');
 await db.query("SELECT set_config('request.jwt.claim.sub',$1,false),set_config('request.jwt.claims',$2,false)",[id,JSON.stringify({sub:id,email:`${id}@test.local`})]);
 try{return await work();}finally{await db.exec('RESET ROLE');}
}
