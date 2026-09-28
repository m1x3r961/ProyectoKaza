import {test} from 'node:test';
import assert from 'node:assert/strict';
import {database,asUser} from './database-helper.mjs';

test('first administrator persists; later accounts and removal cannot reopen enrollment',async(t)=>{
 const db=await database();t.after(()=>db.close());
 const a='11111111-1111-4111-8111-111111111111',b='22222222-2222-4222-8222-222222222222';
 await db.query('INSERT INTO auth.users(id,email) VALUES($1,$2),($3,$4)',[a,'a@test.local',b,'b@test.local']);
 const claim=async(id)=>(await db.query('SELECT public.kaza_claim_initial_admin($1) AS granted',[id])).rows[0].granted;
 assert.equal(await claim(a),true);
 assert.equal(await claim(a),true);
 assert.equal(await claim(b),false);
 assert.deepEqual((await db.query('SELECT user_id FROM public.kaza_admins')).rows,[{user_id:a}]);
 assert.equal((await db.query("SELECT count(*) AS n FROM public.kaza_audit WHERE action='claim_initial_admin'")).rows[0].n,1);
 await asUser(db,b,async()=>{
  await assert.rejects(claim(b),e=>e.code==='42501');
  await assert.rejects(db.query('DELETE FROM public.kaza_admin_bootstrap'),e=>e.code==='42501');
 });
 await db.query('DELETE FROM public.kaza_admins WHERE user_id=$1',[a]);
 assert.equal(await claim(b),false);
 assert.equal(await claim(a),false);
 assert.deepEqual((await db.query('SELECT user_id FROM public.kaza_admin_bootstrap')).rows,[{user_id:a}]);
});

test('existing administrator is preserved on first Google access',async(t)=>{
 const db=await database();t.after(()=>db.close());
 const a='11111111-1111-4111-8111-111111111111',b='22222222-2222-4222-8222-222222222222';
 await db.query('INSERT INTO auth.users(id,email) VALUES($1,$2),($3,$4)',[a,'a@test.local',b,'b@test.local']);
 await db.query('INSERT INTO public.kaza_admins(user_id) VALUES($1)',[a]);
 assert.equal((await db.query('SELECT public.kaza_claim_initial_admin($1) AS granted',[b])).rows[0].granted,false);
 assert.deepEqual((await db.query('SELECT user_id FROM public.kaza_admin_bootstrap')).rows,[{user_id:a}]);
});
