import {test} from 'node:test';import assert from 'node:assert/strict';
import {collectOfficialNews,officialUrl,parseOfficialFeed,parseOfficialPage} from '../../supabase/functions/content-sync/official-news.ts';
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
const annFeed=`<?xml version="1.0"?><rss version="2.0"><channel><title>ANN</title>
<item><title>Frieren Season 2 English Dub Premieres</title><link>https://www.animenewsnetwork.com/news/2026-10-14/frieren-season-2-english-dub/.231000?utm_source=rss</link>
<description>Crunchyroll announced the &lt;cite&gt;English dub&lt;/cite&gt; premiere.</description><pubDate>Tue, 14 Oct 2026 15:00:00 -0400</pubDate></item>
<item><title>Off-site link</title><link>https://evil.test/news/2026-10-14/x</link><pubDate>Tue, 14 Oct 2026 15:00:00 -0400</pubDate></item>
<item><title>Old story</title><link>https://www.animenewsnetwork.com/news/2026-08-01/old/.1</link><pubDate>Sat, 01 Aug 2026 10:00:00 +0000</pubDate></item>
</channel></rss>`;
test('ANN newsfeed keeps headline, date, feed preview and a clean article link only',()=>{
 const rows=parseOfficialFeed(annFeed,'ann',new Date('2026-10-15T12:00:00Z'));
 assert.equal(rows.length,1);
 assert.equal(rows[0].source_url,'https://www.animenewsnetwork.com/news/2026-10-14/frieren-season-2-english-dub/.231000');
 assert.equal(rows[0].source_name,'Anime News Network');assert.equal(rows[0].published_at,'2026-10-14T19:00:00.000Z');
 assert.equal(rows[0].summary,'Crunchyroll announced the English dub premiere.');assert.equal(rows[0].category,'dub');assert.equal(rows[0].language,'en');
 assert.throws(()=>parseOfficialFeed('<html>not a feed</html>','ann'),/Invalid newsfeed/);
 assert.throws(()=>parseOfficialFeed('<rss><channel></channel></rss>','ann'),/no recent articles/);
});
test('approved ANN makes exactly one feed request and no robots or article requests',async()=>{
 const calls:string[]=[];
 const result=await collectOfficialNews('ann',{status:'approved',ingestion_enabled:true},(async(url:any)=>{calls.push(String(url));return new Response(annFeed);}) as typeof fetch,[],new Date('2026-10-15T12:00:00Z'),async()=>{});
 assert.deepEqual(calls,['https://www.animenewsnetwork.com/news/rss.xml?ann-edition=w']);
 assert.equal(result.state,'ok');assert.equal(result.rows.length,1);
 const denied:string[]=[];
 await collectOfficialNews('ann',{status:'permission_requested',ingestion_enabled:false},(async(url:any)=>{denied.push(String(url));return new Response(annFeed);}) as typeof fetch);
 assert.equal(denied.length,0);
});
