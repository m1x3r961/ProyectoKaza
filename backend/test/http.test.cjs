require('reflect-metadata');
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {createServer}=require('node:http');
test('HTTP bootstrap enforces authentication, CORS and DTO validation',async(t)=>{
 const user='11111111-1111-4111-8111-111111111111';
 const upstream=createServer((req,res)=>{
  res.setHeader('Content-Type','application/json');
  if(req.url==='/auth/v1/user')res.end(JSON.stringify({id:user}));
  else if(req.url.startsWith('/rest/v1/profiles'))res.end(JSON.stringify({status:'ACTIVE'}));
  else if(req.url.startsWith('/rest/v1/rpc/kaza_my_listings'))res.end('[]');
  else {res.statusCode=500;res.end('{"message":"Unexpected test request"}');}
 });
 await new Promise(resolve=>upstream.listen(0,'127.0.0.1',resolve));
 t.after(()=>new Promise(resolve=>upstream.close(resolve)));
 Object.assign(process.env,{APP_ENV:'test',SUPABASE_URL:`http://127.0.0.1:${upstream.address().port}`,SUPABASE_SERVICE_ROLE_KEY:'test-only-key',CORS_ORIGINS:'https://client.test'});
 const {createApp}=require('../dist/bootstrap');
 const app=await createApp();await app.listen(0,'127.0.0.1');t.after(()=>app.close());
 const base=await app.getUrl();
 const health=await fetch(base);assert.equal(health.status,200);assert.ok(health.headers.get('x-request-id'));
 const denied=await fetch(base+'/api/listings/mine',{headers:{'x-user-id':user}});assert.equal(denied.status,401);
 const token='header.'+Buffer.from(JSON.stringify({sub:user,iss:process.env.SUPABASE_URL+'/auth/v1',aud:'authenticated',exp:Math.floor(Date.now()/1000)+60})).toString('base64url')+'.signature';
 const headers={Authorization:'Bearer '+token,'Content-Type':'application/json',Origin:'https://client.test'};
 const mine=await fetch(base+'/api/listings/mine',{headers});assert.equal(mine.status,200);assert.deepEqual(await mine.json(),[]);assert.equal(mine.headers.get('access-control-allow-origin'),'https://client.test');
 const invalid=await fetch(base+'/api/listings',{method:'POST',headers,body:JSON.stringify({title:'Casa',operatorUserId:'forged'})});assert.equal(invalid.status,400);
 const error=await invalid.json();assert.ok(error.requestId);
 const preflight=await fetch(base+'/api/listings',{method:'OPTIONS',headers:{Origin:'https://attacker.test','Access-Control-Request-Method':'POST'}});assert.notEqual(preflight.headers.get('access-control-allow-origin'),'https://attacker.test');
});
