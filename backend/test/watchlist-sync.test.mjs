import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,readdirSync} from 'node:fs';
import {PGlite} from '@electric-sql/pglite';
const owner='11111111-1111-4111-8111-111111111111',other='22222222-2222-4222-8222-222222222222';
async function database() {
 const db=new PGlite();
 await db.exec(`create role anon;create role authenticated;create role service_role bypassrls;create schema vault;create table vault.decrypted_secrets(name text,decrypted_secret text);create schema auth;create table auth.users(id uuid primary key);create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('app.user_id',true),'')::uuid $$;grant usage on schema auth to authenticated;`);
 for(const file of readdirSync('../supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(readFileSync('../supabase/migrations/'+file,'utf8'));
 await db.query('insert into auth.users values ($1),($2)',[owner,other]);
 return db;
}
const entry=n=>({anime:{id:123,title:'Test',episodes:12},status:'watching',watched:n});
async function sync(db,revision,value) {return (await db.query('select public.sync_watchlist(123,$1,$2) result',[revision,value===null?null:JSON.stringify(value)])).rows[0].result;}
test('two devices, safe retries, explicit resets and delete/recreate conflicts',async()=>{
 const db=await database();
 try {
  await db.exec(`set role authenticated;set app.user_id='${owner}'`);
  const first=await sync(db,null,entry(3));assert.equal(first.applied,true);
  const second=await sync(db,first.revision,entry(8));assert.equal(second.applied,true);
  const stale=await sync(db,first.revision,entry(4));assert.equal(stale.applied,false);assert.equal(stale.entry.watched,8);
  const retry=await sync(db,first.revision,entry(8));assert.equal(retry.applied,true);assert.equal(retry.revision,second.revision);
  const reset=await sync(db,second.revision,entry(2));assert.equal(reset.applied,true);assert.equal(reset.entry.watched,2);
  assert.equal((await sync(db,second.revision,null)).applied,false);
  const removed=await sync(db,reset.revision,null);assert.equal(removed.applied,true);assert.equal(removed.entry,null);
  assert.equal((await sync(db,reset.revision,null)).applied,true);
  assert.equal((await sync(db,reset.revision,entry(4))).applied,false);
  const recreated=await sync(db,null,entry(2));assert.notEqual(recreated.revision,reset.revision);
  assert.equal((await sync(db,reset.revision,entry(5))).applied,false);
  await db.exec(`update public.watchlist set watched_episodes=6 where mal_id=123`);
  assert.equal((await sync(db,recreated.revision,entry(3))).applied,false);
  await assert.rejects(sync(db,null,{...entry(4),anime:{id:999}}));
  const current=await sync(db,null,entry(0));
  await assert.rejects(sync(db,current.revision,{...entry(4),watched:-1}));
 }finally{await db.close();}
});
test('watchlist RPC isolates users and denies guests',async()=>{
 const db=await database();
 try {
  await db.exec(`set role authenticated;set app.user_id='${owner}'`);
  const original=await sync(db,null,entry(4));
  await db.exec(`set app.user_id='${other}'`);
  const foreign=await sync(db,original.revision,entry(7));assert.equal(foreign.applied,false);assert.equal(foreign.entry,null);
  assert.equal((await sync(db,null,entry(1))).applied,true);
  await db.exec(`set app.user_id='${owner}'`);assert.equal((await sync(db,null,entry(0))).entry.watched,4);
  await db.exec('reset role;set role anon');await assert.rejects(sync(db,null,entry(1)));
  await db.exec("reset role;set role authenticated;set app.user_id=''");await assert.rejects(sync(db,null,entry(1)));
 }finally{await db.close();}
});
test('news applies personal, region and source filters before limit',async()=>{
 const db=await database();
 try {
  await db.exec(`insert into public.news(mal_id,headline,summary,category,source_name,source_url,published_at,published,language,regions,providers)
   select 999,'Unrelated '||i,'Summary','announcement','Other','https://example.com/'||i,now(),true,'de',array['DE'],array['Netflix'] from generate_series(1,130) i;
   insert into public.news(mal_id,headline,summary,category,source_name,source_url,published_at,published,language,regions,providers) values
   (123,'Relevant','Summary','announcement','Official','https://example.com/relevant',now()-interval '1 day',true,'de',array['DE'],array['ADN']),
   (123,'Wrong region','Summary','announcement','Official','https://example.com/us',now(),true,'de',array['US'],array['ADN']),
   (123,'Muted','Summary','announcement','Muted','https://example.com/muted',now(),true,'de',array['DE'],array['ADN']),
   (123,'Private','Summary','announcement','Official','https://example.com/private',now(),false,'de',array['DE'],array['ADN']);set role anon;`);
  assert.deepEqual((await db.query(`select headline from public.companion_news(array['de'],'DE',array['ADN'],array['Muted'],array[123]::bigint[])`)).rows,[{headline:'Relevant'}]);
  assert.equal((await db.query(`select * from public.companion_news(array['de'],'DE','{}','{}','{}')`)).rows.length,0);
  assert.equal((await db.query(`select * from public.companion_news(array['en'],'DE','{}','{}',null)`)).rows.length,0);
 }finally{await db.close();}
});
