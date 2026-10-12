import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,readdirSync} from 'node:fs';
import {PGlite} from '@electric-sql/pglite';

test('private follows, inbox revisions, review guards and source rights fail closed',async()=>{
 const db=new PGlite();
 const owner='11111111-1111-4111-8111-111111111111',other='22222222-2222-4222-8222-222222222222';
 try{
  await db.exec(`create role anon;create role authenticated;create role service_role bypassrls;create schema vault;create table vault.decrypted_secrets(name text,decrypted_secret text);create schema auth;create table auth.users(id uuid primary key);create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('app.user_id',true),'')::uuid $$;grant usage on schema auth to authenticated;`);
  for(const file of readdirSync('../supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(readFileSync('../supabase/migrations/'+file,'utf8'));
  await db.query('insert into auth.users values ($1),($2)',[owner,other]);
  await db.query('insert into public.companion_reviewers(user_id) values ($1)',[owner]);
  await db.exec(`set role authenticated;set app.user_id='${owner}'`);
  await db.query(`insert into public.dub_follows(user_id,mal_id,region,audio_language) values ($1,123,'DE','de')`,[owner]);
  await assert.rejects(db.query(`insert into public.dub_follows(user_id,mal_id,region,audio_language) values ($1,123,'DE','de')`,[other]));
  await assert.rejects(db.query('select * from public.companion_reviewers'));
  await assert.rejects(db.query(`update public.source_rights set status='approved'`));
  await db.exec('reset role;set role service_role');
  const url='https://www.anime2you.de/news/123/test/';
  await db.query(`insert into public.dub_source_documents(source_url,source_key,content_hash) values ($1,'anime2you','v1')`,[url]);
  const event={mal_id:123,title:'Exact Season 2',episode:1,kind:'dub',provider:'Netflix',region:'DE',audio_language:'de',starts_on:'2026-11-01',status:'confirmed',source_url:url};
  const proposal={key:'s2e1',event,reason:'title_unmapped',evidence:'Exact title, region, audio, episode and date.'};
  const apply=async(p)=>db.query('select public.apply_dub_candidates($1,$2)',[url,JSON.stringify([p])]);
  await apply(proposal);
  const candidate=(await db.query('select * from public.dub_candidates')).rows[0];
  const review=(actor,stamp,ev=event)=>db.query('select public.review_dub_candidate($1,$2,$3,$4,true,$5,$6)',[actor,url,'s2e1',stamp,JSON.stringify(ev),'Verified original announcement']);
  await assert.rejects(review(other,candidate.checked_at));
  await assert.rejects(review(owner,'2020-01-01'));
  await review(owner,candidate.checked_at);
  assert.equal((await db.query('select count(*)::int n from public.release_inbox')).rows[0].n,1);
  // Unchanged scraping cannot undo approval or spam readers.
  await apply(proposal);
  assert.equal((await db.query('select decision from public.dub_candidates')).rows[0].decision,'published');
  await db.exec('update public.release_events set checked_at=now()');
  assert.equal((await db.query('select count(*)::int n from public.release_inbox')).rows[0].n,1);
  await db.exec(`update public.release_events set starts_on='2026-11-08',status='delayed'`);
  const alerts=(await db.query('select revision,kind,superseded from public.release_inbox order by revision')).rows;
  assert.equal(alerts.length,2);assert.equal(alerts[0].superseded,true);assert.equal(alerts[1].kind,'changed');
  await db.query(`update public.dub_source_documents set content_hash='v2' where source_url=$1`,[url]);
  await apply(proposal);
  assert.equal((await db.query('select decision from public.dub_candidates')).rows[0].decision,'review');
  // Due reminders are idempotent, and never call an estimated time a release.
  await db.exec(`update public.release_events set starts_on=current_date,status='confirmed'`);
  await db.query('select public.deliver_due_dub_alerts()');await db.query('select public.deliver_due_dub_alerts()');
  assert.equal((await db.query(`select count(*)::int n from public.release_inbox where kind='scheduled_today'`)).rows[0].n,1);
  await db.exec(`reset role;set role authenticated;set app.user_id='${other}'`);
  assert.equal((await db.query('select * from public.release_inbox')).rows.length,0);
  assert.equal((await db.query('select * from public.dub_follows')).rows.length,0);
  await db.exec(`set app.user_id='${owner}'`);
  assert.ok((await db.query('select * from public.release_inbox')).rows.length>0);
  await assert.rejects(db.exec(`update public.release_inbox set kind='announcement'`));
  await db.exec('update public.release_inbox set read_at=now()');
  assert.equal((await db.query(`select count(*)::int n from public.source_rights where source_key<>'mydublist' and (commercial_allowed or ingestion_enabled)`)).rows[0].n,0);
 }finally{await db.close();}
});
