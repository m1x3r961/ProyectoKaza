require('reflect-metadata');
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {Reflector}=require('@nestjs/core');
const {AuthGuard}=require('../dist/security/auth.guard');
const {configuration}=require('../dist/config');
const {ListingsService}=require('../dist/domain/listings/listings.service');
const id='11111111-1111-4111-8111-111111111111';
const config={url:'https://unit.supabase.co',demo:false};
function token(extra={}){return 'header.'+Buffer.from(JSON.stringify({sub:id,iss:config.url+'/auth/v1',aud:'authenticated',exp:Math.floor(Date.now()/1000)+1000,aal:'aal1',amr:[{method:'oauth'}],...extra})).toString('base64url')+'.signature';}
function fixture({admin=false,bootstrap=false,claimAllowed=false,google=true,publicRoute=false,demo=false,verified=true,status='ACTIVE',privileged=false}={}){
 const request={headers:{authorization:'Bearer '+token(),'x-user-id':'attacker'}};
 const handler=()=>{}; const klass=()=>{};
 if(admin)Reflect.defineMetadata('admin',true,handler);
 if(bootstrap)Reflect.defineMetadata('adminBootstrap',true,handler);
 if(publicRoute)Reflect.defineMetadata('public',true,handler);
 if(demo)Reflect.defineMetadata('demo',true,handler);
 const calls=[];
 const db={config,rpc:async(name,args)=>{calls.push({name,args});if(claimAllowed)privileged=true;return claimAllowed;},client:{auth:{getUser:async()=>({data:{user:verified?{id,app_metadata:{provider:google?'google':'email'},identities:[{provider:google?'google':'email'}]}:null},error:verified?null:{message:'invalid'}})},from:(table)=>({select:()=>({eq:()=>({maybeSingle:async()=>({data:table==='profiles'?{status}:privileged?{user_id:id}:null,error:null})})})})}};
 const guard=new AuthGuard(new Reflector(),db);
 const context={getHandler:()=>handler,getClass:()=>klass,switchToHttp:()=>({getRequest:()=>request})};
 return {request,guard,context,calls};
}
test('configuration fails closed and rejects demo on production project',()=>{
 assert.throws(()=>configuration({}),/Missing/);
 const env={APP_ENV:'production',SUPABASE_URL:config.url,SUPABASE_SERVICE_ROLE_KEY:'server-key'};
 assert.throws(()=>configuration(env),/CORS/);
 assert.throws(()=>configuration({...env,CORS_ORIGINS:'*'}),/CORS/);
 assert.throws(()=>configuration({...env,APP_ENV:'demo',PRODUCTION_SUPABASE_URL:config.url}),/different/);
});
test('verified identity ignores client user header',async()=>{const f=fixture();assert.equal(await f.guard.canActivate(f.context),true);assert.equal(f.request.actor.id,id);});
test('missing, expired, wrong audience/issuer and unverified JWT are rejected',async()=>{
 for(const extra of [{exp:1},{aud:'service_role'},{iss:'https://attacker/auth/v1'},{sub:'attacker'}]){const f=fixture();f.request.headers.authorization='Bearer '+token(extra);await assert.rejects(f.guard.canActivate(f.context),e=>e.getStatus()===401);}
 const f=fixture();delete f.request.headers.authorization;await assert.rejects(f.guard.canActivate(f.context),e=>e.getStatus()===401);
 const bad=fixture({verified:false});await assert.rejects(bad.guard.canActivate(bad.context),e=>e.getStatus()===401);
});
test('admin requires Google OAuth and persisted membership, without mandatory TOTP',async()=>{
 const email=fixture({admin:true,privileged:true,google:false});await assert.rejects(email.guard.canActivate(email.context),e=>e.getStatus()===403);
 const password=fixture({admin:true,privileged:true});password.request.headers.authorization='Bearer '+token({amr:[{method:'password'}]});await assert.rejects(password.guard.canActivate(password.context),e=>e.getStatus()===403);
 const noRole=fixture({admin:true});await assert.rejects(noRole.guard.canActivate(noRole.context),e=>e.getStatus()===403);assert.equal(noRole.calls.length,0);
 const good=fixture({admin:true,privileged:true});assert.equal(await good.guard.canActivate(good.context),true);
});
test('only the explicit access endpoint claims the verified Google actor',async()=>{
 const first=fixture({admin:true,bootstrap:true,claimAllowed:true});assert.equal(await first.guard.canActivate(first.context),true);
 assert.deepEqual(first.calls,[{name:'kaza_claim_initial_admin',args:{p_actor:id}}]);
 const later=fixture({admin:true,bootstrap:true});await assert.rejects(later.guard.canActivate(later.context),e=>e.getStatus()===403);
 const email=fixture({admin:true,bootstrap:true,google:false,claimAllowed:true});await assert.rejects(email.guard.canActivate(email.context),e=>e.getStatus()===403);assert.equal(email.calls.length,0);
});
test('suspended account and demo route are blocked',async()=>{for(const options of [{status:'SUSPENDED'},{demo:true}]){const f=fixture(options);await assert.rejects(f.guard.canActivate(f.context),e=>[403,404].includes(e.getStatus()));}});
test('publish requires stable key and rejects photos owned by another user',async()=>{
 let called=false;const s=new ListingsService({config,rpc:async()=>{called=true;return{id:'persisted'};}});
 assert.throws(()=>s.createListing(id,{title:'House',priceOriginal:10},''));
 assert.throws(()=>s.createListing(id,{title:'House',priceOriginal:10,photos:[config.url+'/storage/v1/object/public/property-photos/other/file.png']},'request-000000001'));
 assert.equal(called,false);
 assert.deepEqual(await s.createListing(id,{title:'House',priceOriginal:10},'request-000000001'),{id:'persisted'});
});
