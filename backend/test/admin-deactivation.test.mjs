import {test} from 'node:test';
import assert from 'node:assert/strict';
import {database,asUser} from './database-helper.mjs';

const admin='11111111-1111-4111-8111-111111111111';
const user='22222222-2222-4222-8222-222222222222';

test('admin deletion is a protected, audited soft deactivation',async(t)=>{
 const db=await database();t.after(()=>db.close());
 await db.query('INSERT INTO auth.users(id,email) VALUES($1,$2),($3,$4)',[admin,'admin@test.local',user,'user@test.local']);
 for(const [id,email] of [[admin,'admin@test.local'],[user,'user@test.local']]) {
  await asUser(db,id,()=>db.query('SELECT public.fn_upsert_profile($1,$2,$3)',[id,email,'Test user']));
 }
 await db.query('INSERT INTO public.kaza_admins(user_id) VALUES($1)',[admin]);
 const payload={title:'Casa del usuario',description:'Test',propertyType:'Casa',countryCode:'BOL',cityId:'santa_cruz',operationType:'SALE',priceOriginal:100000,currencyOriginal:'USD',latitude:-17.783345,longitude:-63.182145,photos:[],contactPhone:'PRIVATE',address:'PRIVATE'};
 const listing=(await db.query('SELECT public.kaza_publish($1,$2,$3) AS result',[user,'delete-user-test-01',payload])).rows[0].result;

 const result=(await db.query("SELECT public.kaza_moderate($1,$2,'delete_user',$3) AS result",[admin,user,'Baja solicitada por administración'])).rows[0].result;
 assert.equal(result.success,true);
 assert.equal(result.affectedListings,1);
 assert.equal((await db.query('SELECT status FROM public.profiles WHERE id=$1',[user])).rows[0].status,'DELETED');
 assert.equal((await db.query('SELECT moderation_status FROM public.listings WHERE id=$1',[listing.id])).rows[0].moderation_status,'SUSPENDED');
 const dashboard=(await db.query('SELECT public.kaza_admin_dashboard($1) AS result',[admin])).rows[0].result;
 assert.equal(dashboard.users.some(row=>row.id===user),false);
 assert.equal((await db.query("SELECT count(*) AS n FROM public.kaza_audit WHERE action='delete_user' AND target=$1",[user])).rows[0].n,1);
 await assert.rejects(db.query("SELECT public.kaza_moderate($1,$2,'delete_user',$3)",[admin,admin,'Intento contra administrador']),e=>e.code==='42501');
 await assert.rejects(db.query('SELECT public.kaza_conversations($1)',[user]),e=>e.code==='42501');
});
