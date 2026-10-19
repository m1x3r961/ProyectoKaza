require('reflect-metadata');
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {AccountService}=require('../dist/domain/account/account.service');
const id='11111111-1111-4111-8111-111111111111';
function service({rpcResult={success:true,affectedListings:2,email:'user@test.local'},authError=null,files=[{name:'a.jpg'}]}={}){
 const calls=[];
 const bucket={list:async(folder)=>{calls.push(['list',folder]);return {data:files};},remove:async(paths)=>{calls.push(['remove',paths]);return {};}};
 const db={rpc:async(name,args)=>{calls.push(['rpc',name,args]);return rpcResult;},client:{auth:{admin:{deleteUser:async(user,soft)=>{calls.push(['deleteUser',user,soft]);return {error:authError};}}},storage:{from:(b)=>{calls.push(['bucket',b]);return bucket;}}}};
 return {s:new AccountService(db),calls};
}
test('account deletion anonymizes first, then removes avatars and soft-deletes the Auth user',async()=>{
 const {s,calls}=service();
 assert.deepEqual(await s.deleteOwn(id),{success:true,affectedListings:2});
 assert.deepEqual(calls,[['rpc','kaza_delete_own_account',{p_actor:id}],['bucket','avatars'],['list','user@test.local'],['remove',['user@test.local/a.jpg']],['deleteUser',id,true]]);
});
test('retry after a deleted profile skips storage and still closes Auth; Auth failure surfaces as 503',async()=>{
 const retry=service({rpcResult:{success:true,alreadyDeleted:true,affectedListings:0,email:null}});
 await retry.s.deleteOwn(id);assert.deepEqual(retry.calls.map(c=>c[0]),['rpc','deleteUser']);
 const failing=service({authError:{message:'down'}});
 await assert.rejects(failing.s.deleteOwn(id),e=>e.getStatus()===503);
});
