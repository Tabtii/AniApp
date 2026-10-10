import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,readdirSync} from 'node:fs';
import {PGlite} from '@electric-sql/pglite';

test('dub reconciliation is atomic, idempotent, private and preserves conflicting/precise events',async()=>{
  const db=new PGlite();
  try{
    await db.exec(`create role anon; create role authenticated; create role service_role bypassrls;
      create schema vault; create table vault.decrypted_secrets(name text,decrypted_secret text);
      create schema auth; create table auth.users(id uuid primary key);
      create function auth.uid() returns uuid language sql stable as $$ select null::uuid $$;`);
    for(const file of readdirSync('../supabase/migrations').filter(f=>f.endsWith('.sql')).sort())await db.exec(readFileSync('../supabase/migrations/'+file,'utf8'));
    const one='https://www.anime2you.de/news/123/test/',two='https://www.anime2you.de/news/124/follow-up/';
    await db.query(`insert into public.dub_source_documents(source_url,source_key) values ($1,'anime2you'),($2,'anime2you')`,[one,two]);
    const event=(url,day='2026-10-18',status='confirmed',episode=null)=>({mal_id:123,title:'Test Season 2',episode,kind:'dub',starts_on:day,
      provider:'Netflix',region:'DE',audio_language:'de',status,source_url:url,release_note:'Test verified fact'});
    const apply=async(e,reason=null)=> (await db.query('select public.apply_dub_candidates($1,$2) as result',[e.source_url,JSON.stringify([{key:'test|'+(e.episode??'premiere'),event:e,reason,evidence:'Short source claim.'}])])).rows[0].result;
    // Public clients cannot read the queue, resolve mappings, or trigger publication.
    for(const role of ['anon','authenticated']){
      await db.exec(`set role ${role}`);
      for(const table of ['dub_source_documents','dub_candidates','dub_title_matches'])await assert.rejects(db.query('select * from public.'+table));
      await assert.rejects(apply(event(one)));
      await db.exec('reset role');
    }
    await db.exec('set role service_role');
    assert.equal((await apply(event(one,null,'announced'))).published,1);
    let row=(await db.query('select * from public.release_events')).rows[0];const id=row.id;
    assert.equal(row.starts_on,null);
    assert.equal((await apply(event(two))).published,1); // a follow-up can resolve TBA
    row=(await db.query('select id,starts_on::text from public.release_events')).rows[0];
    assert.equal(row.id,id);assert.equal(row.starts_on,'2026-10-18');
    await apply(event(two));assert.equal((await db.query('select count(*)::int as n from public.release_events')).rows[0].n,1);
    // A changed date at the same source updates in place.
    await apply(event(two,'2026-10-25','delayed'));
    row=(await db.query('select id,starts_on::text,status from public.release_events')).rows[0];
    assert.deepEqual(row,{id,starts_on:'2026-10-25',status:'delayed'});
    await apply(event(one,null,'announced')); // older TBA cannot erase the date
    assert.equal((await db.query('select starts_on::text as d from public.release_events')).rows[0].d,'2026-10-25');
    assert.equal((await apply(event(one,'2026-10-30'))).conflicts,1);
    assert.equal((await db.query('select starts_on::text as d from public.release_events')).rows[0].d,'2026-10-25');
    assert.equal((await apply(event(one,'2026-10-30'), 'title_unmapped')).review,1);
    // Incomplete or disappeared article text never deletes known events.
    await db.query('select public.apply_dub_candidates($1,$2)',[two,'[]']);
    assert.equal((await db.query('select count(*)::int as n from public.release_events where published')).rows[0].n,1);
    // Adopt manually reviewed same-title/provider/language/episode rows, retain ID.
    await db.query(`insert into public.release_events(mal_id,title,episode,kind,starts_on,provider,region,audio_language,status,source_url,published)
      values(123,'Test Season 2',22,'dub','2026-10-18','Netflix','DE','de','confirmed',$1,true)`,[two]);
    const before=(await db.query('select id from public.release_events where episode=22')).rows[0].id;
    await apply(event(two,'2026-10-25','delayed',22));
    assert.equal((await db.query('select id from public.release_events where episode=22')).rows[0].id,before);
    // Provider episode timestamp is more precise than a parsed article day.
    await db.exec(`update public.release_events set starts_on=null,starts_at='2026-10-25T19:00:00Z' where episode=22`);
    assert.equal((await apply(event(two,'2026-10-26','confirmed',22))).conflicts,1);
    assert.ok((await db.query('select starts_at from public.release_events where episode=22')).rows[0].starts_at);
    // A malformed batch rolls back the preceding valid event too.
    await assert.rejects(db.query('select public.apply_dub_candidates($1,$2)',[two,JSON.stringify([
      {key:'valid-new',event:event(two,'2026-10-26','confirmed',30),evidence:'Fact'},
      {key:'bad',event:{...event(two),kind:'japan'},evidence:'Bad fact'},
    ])]));
    assert.equal((await db.query('select count(*)::int as n from public.release_events where episode=30')).rows[0].n,0);
    await db.exec('reset role; set role anon');
    assert.equal((await db.query('select count(*)::int as n from public.release_events')).rows[0].n,2);
  }finally{await db.close();}
});
