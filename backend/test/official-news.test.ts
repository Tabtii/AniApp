import {test} from 'node:test';import assert from 'node:assert/strict';
import {collectOfficialNews,officialUrl,parseOfficialPage} from '../../supabase/functions/content-sync/official-news.ts';
test('additional publishers make zero requests before a recorded permission',async()=>{
 let calls=0;const fetcher=async()=>{calls++;throw new Error('Must not fetch');};
 for(const permission of [undefined,{status:'permission_requested',ingestion_enabled:true},{status:'approved',ingestion_enabled:false}]){
  const result=await collectOfficialNews('hidive',permission,fetcher as typeof fetch);assert.equal(result.state,'pending');
 }assert.equal(calls,0);
});
test('official news rejects arbitrary origins and does not turn a news date into dub evidence',()=>{
 const url='https://news.hidive.com/2026/10/10/exact-dub-announcement';
 assert.equal(officialUrl('https://evil.test/2026/10/10/a','hidive'),null);
 const row=parseOfficialPage(`<link rel="canonical" href="${url}"><meta property="og:type" content="article"><meta property="og:title" content="New English dub"><meta property="article:published_time" content="2026-10-10T10:00:00Z">`,url,'hidive',new Date('2026-10-12'));
 assert.equal(row.category,'dub');assert.equal(row.image_url,null);assert.equal(row.mal_id,undefined);assert.equal(row.starts_on,undefined);assert.equal(row.audio_language,undefined);
});
test('approved crawler respects robots before reading an index',async()=>{
 let calls=0;await assert.rejects(collectOfficialNews('hidive',{status:'approved',ingestion_enabled:true},async()=>{calls++;return new Response('User-agent: *\nDisallow: /dubs');},[],new Date(),async()=>{}));assert.equal(calls,1);
});
