import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,readdirSync} from 'node:fs';
import {PGlite} from '@electric-sql/pglite';

test('Anime2You retention expires copied content, preserves calendar facts and enforces server-only controls',async()=>{
 const db=new PGlite();
 try{
  await db.exec(`create role anon;create role authenticated;create role service_role bypassrls;
   create schema vault;create table vault.decrypted_secrets(name text,decrypted_secret text);
   create schema auth;create table auth.users(id uuid primary key);
   create function auth.uid() returns uuid language sql stable as $$select null::uuid$$;`);
  for(const file of readdirSync('../supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(readFileSync('../supabase/migrations/'+file,'utf8'));
  const url='https://www.anime2you.de/news/123/old/';
  await db.query(`insert into public.news(headline,summary,category,source_name,source_url,published_at,published)
   values ('Old','Publisher preview','announcement','Anime2You',$1,now()-interval '31 days',true),
   ('Recent','Recent preview','announcement','Anime2You',$1||'recent/',now()-interval '1 day',true),
   ('Other','Other preview','announcement','Other publisher','https://example.org/news/1',now()-interval '31 days',true)`,[url]);
  await db.query(`insert into public.dub_source_documents(source_url,source_key,headline,published_at)
   values ($1,'anime2you','Copied title',now()-interval '31 days')`,[url]);
  const event={mal_id:123,title:'Series',episode:1,kind:'dub',provider:'Netflix',region:'DE',audio_language:'de',starts_on:'2026-12-01',status:'confirmed',source_url:url};
  const proposal={key:'test',event,reason:null,evidence:'Publisher sentence'};
  await db.query('select public.apply_dub_candidates($1,$2)',[url,JSON.stringify([proposal])]);
  await db.query(`insert into public.dub_review_audit(source_url,candidate_key,original_proposal,decision,note)
   values ($1,'test',$2,'approved','Reviewed date')`,[url,JSON.stringify(proposal)]);
  for(const role of ['anon','authenticated']){
   await db.exec(`set role ${role}`);
   await assert.rejects(db.query('select public.prune_anime2you_content()'));
   await assert.rejects(db.query("select public.begin_content_sync('secret')"));
   await assert.rejects(db.query("update public.source_rights set images_allowed=false where source_key='anime2you'"));
   await db.exec('reset role');
  }
  await db.exec('set role service_role');
  const result=(await db.query('select public.prune_anime2you_content() as result')).rows[0].result;
  assert.equal(result.news_removed,1);assert.equal(result.evidence_cleared,1);
  assert.equal((await db.query('select count(*)::int n from public.news')).rows[0].n,2);
  assert.equal((await db.query('select evidence from public.dub_candidates')).rows[0].evidence,'');
  assert.equal((await db.query('select headline from public.dub_source_documents')).rows[0].headline,'');
  assert.equal((await db.query('select original_proposal from public.dub_review_audit')).rows[0].original_proposal.evidence,undefined);
  assert.equal((await db.query('select count(*)::int n from public.release_events where published')).rows[0].n,1);
  await db.query(`select public.finish_content_sync('{"schedule":{"count":97}}')`);
  await db.query(`select public.finish_content_sync('{"anime2you":{"count":25}}')`);
  assert.deepEqual((await db.query('select report from public.content_sync_state')).rows[0].report,{schedule:{count:97},anime2you:{count:25}});
  await db.exec('reset role');
  await db.exec("insert into vault.decrypted_secrets values ('aniapp_content_sync','test-token'); update public.content_sync_state set last_attempt_at=now()-interval '15 minutes'");
  await db.exec('set role service_role');
  assert.equal((await db.query("select public.begin_content_sync('wrong') as result")).rows[0].result,'denied');
  assert.equal((await db.query("select public.begin_content_sync('test-token') as result")).rows[0].result,'ready');
  assert.equal((await db.query("select public.begin_content_sync('test-token') as result")).rows[0].result,'recent');
 }finally{await db.close();}
});
