import {test} from 'node:test';
import assert from 'node:assert/strict';
import {anime2youMetadata,collectAnime2You,ANIME2YOU_LINK_TEXT} from '../../supabase/functions/content-sync/anime2you.ts';

const now=new Date('2026-10-14T14:00:00Z');
const url='https://www.anime2you.de/news/123/test/';
const permission={status:'approved',ingestion_enabled:true,images_allowed:true};
const html=(description='Original &amp; unverändert.',canonical=url)=>`<html><head>
 <link rel="canonical" href="${canonical}"><meta property="og:type" content="article">
 <meta property="og:title" content="Korrigierter Titel"><meta property="article:published_time" content="2026-10-14T10:00:00Z">
 <meta name="description" content="${description}"><meta property="og:description" content="Andere Vorschau">
 <meta property="og:image" content="https://www.anime2you.de/media/image.jpg"></head>
 <body>Dieser Artikeltext darf nicht zur Vorschau werden.</body></html>`;
const feed=`<rss><item><title>Feedtitel</title><link>${url}</link><pubDate>Wed, 14 Oct 2026 10:00:00 GMT</pubDate>
 <description>Dieser Feedtext darf nicht zur Vorschau werden.</description></item></rss>`;
const fake=(article:(u:string,init:RequestInit)=>Response)=>(async(u:any,init:any)=>{
 if(String(u).endsWith('/robots.txt'))return new Response('User-agent: *\nAllow: /');
 if(String(u).endsWith('/feed/'))return new Response(feed);
 return article(String(u),init);
}) as typeof fetch;

test('publisher meta-description is preserved, with safe identity/image handling and no article summary',()=>{
 const row=anime2youMetadata(html(),url,now);
 assert.equal(row.summary,'Original & unverändert.');assert.equal(row.preview_kind,'publisher_meta');
 assert.equal(row.headline,'Korrigierter Titel');
 assert.equal(row.image_url,'https://www.anime2you.de/media/image.jpg');
 assert.throws(()=>anime2youMetadata(html('Text','https://evil.test/news/123/test/'),url,now),/identity/);
 assert.equal(anime2youMetadata(html().replace('https://www.anime2you.de/media/image.jpg','https://evil.test/image.jpg'),url,now).image_url,null);
 assert.throws(()=>anime2youMetadata(html().replace('2026-10-14T10:00:00Z','2026-08-01T10:00:00Z'),url,now),/stale/);
 const absent=html().replace(/<meta (?:name="description"|property="og:description")[^>]*>/g,'');
 assert.equal(anime2youMetadata(absent,url,now).summary,ANIME2YOU_LINK_TEXT);
 assert.equal(anime2youMetadata(html('x'.repeat(1501)),url,now).preview_kind,'link_only');
});

test('permission is checked before the first request; image permission is applied independently',async()=>{
 let calls=0;
 const denied=await collectAnime2You({...permission,status:'permission_requested'},[],(async()=>{calls++;throw Error('Must not fetch');}) as typeof fetch,now,async()=>{});
 assert.equal(calls,0);assert.equal(denied.state,'permission_pending');
 const result=await collectAnime2You({...permission,images_allowed:false},[],fake(()=>new Response(html())),now,async()=>{});
 assert.equal(result.rows[0].summary,'Original & unverändert.');assert.equal(result.rows[0].image_url,null);
});

test('corrections replace metadata; 304 retains publisher text; missing pages are removed, outages never invent summaries',async()=>{
 const first=await collectAnime2You(permission,[],fake(()=>new Response(html(),{headers:{etag:'"one"'}})),now,async()=>{});
 const old=first.rows[0];assert.equal(first.checked,1);
 let conditional:string|undefined;
 const same=await collectAnime2You(permission,[old],fake((_u,init)=>{conditional=(init.headers as Record<string,string>)['If-None-Match'];return new Response(null,{status:304});}),now,async()=>{});
 assert.equal(conditional,'"one"');assert.equal(same.rows[0].summary,old.summary);
 const changed=await collectAnime2You(permission,[old],fake(()=>new Response(html('Korrigierte Originalvorschau.'),{headers:{etag:'"two"'}})),now,async()=>{});
 assert.equal(changed.rows[0].summary,'Korrigierte Originalvorschau.');assert.equal(changed.rows[0].source_url,url);
 const gone=await collectAnime2You(permission,[old],fake(()=>new Response(null,{status:410})),now,async()=>{});
 assert.deepEqual(gone.removed,[url]);assert.equal(gone.rows.length,0);
 const unavailable=await collectAnime2You(permission,[],fake(()=>new Response(null,{status:503})),now,async()=>{});
 assert.equal(unavailable.rows[0].summary,ANIME2YOU_LINK_TEXT);assert.equal(unavailable.state,'degraded');
});

test('rotation refreshes retained articles outside the feed and stops after access/rate denial',async()=>{
 const oldUrl='https://www.anime2you.de/news/122/older/';
 const prior={headline:'Alt',summary:ANIME2YOU_LINK_TEXT,category:'announcement',source_name:'Anime2You',source_url:oldUrl,
  published_at:'2026-10-13T10:00:00Z',checked_at:now.toISOString(),published:true,language:'de',preview_kind:'link_only'};
 const calls:string[]=[];
 const result=await collectAnime2You(permission,[prior],fake(u=>{calls.push(u);return new Response(html('Aktualisiert.',u));}),now,async()=>{});
 assert.ok(calls.includes(oldUrl));assert.equal(result.rows.find(r=>r.source_url===oldUrl)?.summary,'Aktualisiert.');
 let requests=0;
 const limited=await collectAnime2You(permission,[prior],fake(()=>{requests++;return new Response(null,{status:429});}),now,async()=>{});
 assert.equal(requests,1);assert.equal(limited.state,'degraded');
});

test('publisher slug redirects keep the same article identity and reject cross-origin or cross-article redirects',async()=>{
 const target='https://www.anime2you.de/news/123/corrected-slug/';
 const result=await collectAnime2You(permission,[],fake(u=>u===url?
  new Response(null,{status:301,headers:{location:target}}):new Response(html('Korrektur.',target))),now,async()=>{});
 assert.equal(result.rows[0].summary,'Korrektur.');assert.equal(result.rows[0].source_url,url);
 for(const bad of ['https://evil.test/news/123/test/','https://www.anime2you.de/news/999/another/']){
  let requests=0;
  const denied=await collectAnime2You(permission,[],fake(()=>{requests++;return new Response(null,{status:301,headers:{location:bad}});}),now,async()=>{});
  assert.equal(requests,1);assert.equal(denied.rows[0].preview_kind,'link_only');
  assert.match(denied.failed[0].error,/redirect/);
 }
});

test('a changed feed slug updates the retained article rather than creating a duplicate',async()=>{
 const previousUrl='https://www.anime2you.de/news/123/previous-slug/';
 const known=[{headline:'Previous',summary:'Publisher text',category:'announcement',source_name:'Anime2You',source_url:previousUrl,
  published_at:'2026-10-14T10:00:00Z',checked_at:now.toISOString(),preview_kind:'publisher_meta'}];
 const result=await collectAnime2You(permission,known,fake(u=>new Response(html('Aktuell.',u))),now,async()=>{});
 assert.equal(result.rows.length,1);assert.equal(result.rows[0].source_url,previousUrl);assert.equal(result.rows[0].summary,'Aktuell.');
});
