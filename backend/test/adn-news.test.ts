import {test} from 'node:test';
import assert from 'node:assert/strict';
import {articleUrl,discoverArticles,robotPolicy,parseArticle,crawlAdnNews} from '../../supabase/functions/content-sync/adn-news.ts';
const origin='https://news.animationdigitalnetwork.com';
const url=origin+'/de/2026/10/04/announcement/';
const now=new Date('2026-10-08T17:00:00Z');
const html=(u=url)=>`<html><link rel="canonical" href="${u}"><meta property="og:type" content="article"><meta property="og:locale" content="de_DE"><meta property="og:url" content="${u}"><meta property="og:title" content="Neue Staffel &amp; Synchro"><meta property="og:description" content="${'Vorschau '.repeat(30)}"><meta property="article:published_time" content="2026-10-04T05:00:00Z"><meta property="og:image" content="${origin}/wp-content/uploads/image.jpg"></html>`;
const feed=(urls=[url])=>`<rss><channel>${urls.map(u=>`<item><link>${u}</link></item>`).join('')}</channel></rss>`;
test('ADN crawler limits discovery to German dated articles on the fixed origin',()=>{
 for(const bad of ['https://evil.test/de/2026/10/04/news/',origin+'/de/wp-admin/',url+'?secret=x','http://news.animationdigitalnetwork.com/de/2026/10/04/news/','https://u:p@news.animationdigitalnetwork.com/de/2026/10/04/news/'])assert.equal(articleUrl(bad),null);
 assert.deepEqual(discoverArticles(feed([url,url,'https://evil.test/news'])),[url]);
 assert.deepEqual(discoverArticles(`<a href="${url}">News</a><a href="/de/">Home</a>`,true),[url]);
});
test('robots rules honor named agents, longest allow rule, wildcards and crawl delay',()=>{
 const robots='User-agent: *\nDisallow: /de/\nAllow: /de/feed/\nCrawl-delay: 3';
 assert.deepEqual(robotPolicy(robots,'/de/feed/'),{allowed:true,delay:3});
 assert.equal(robotPolicy(robots,'/de/2026/10/04/news/').allowed,false);
 assert.equal(robotPolicy('User-agent: *\nDisallow: /*.json$','/data.json').allowed,false);
 assert.equal(robotPolicy('User-agent: *\nDisallow: /\nUser-agent: AniApp\nAllow: /de/','/de/').allowed,true);
});
test('HTML metadata becomes a short sourced news preview, not an episode release',()=>{
 const row=parseArticle(html(),url,now);
 assert.equal(row.headline,'Neue Staffel & Synchro');assert.equal(row.category,'dub');
 assert.equal(row.source_name,'ADN News');assert.ok(row.summary.split(' ').length<=21);
 assert.equal(row.published_at,'2026-10-04T05:00:00.000Z');assert.equal(row.starts_at,undefined);assert.equal(row.mal_id,undefined);
 assert.equal(parseArticle(html().replace(origin+'/wp-content/uploads/image.jpg','https://evil.test/image.jpg'),url,now).image_url,null);
 for(const bad of [html(url.replace('announcement','other')),html().replace('de_DE','fr_FR'),html().replace('2026-10-04T05:00:00Z','2026-11-01T00:00:00Z'),html().replace('2026-10-04T05:00:00Z','2025-01-01T00:00:00Z'),'<html>Login</html>'])assert.throws(()=>parseArticle(bad,url,now));
});
test('crawler observes robots, avoids redirects, caches articles and keeps partial failures separate',async()=>{
 const urls:string[]=[],delays:number[]=[];
 const fetcher:typeof fetch=async(input,init)=>{
   const u=String(input);urls.push(u);assert.equal(init?.redirect,'error');
   assert.match(new Headers(init?.headers).get('User-Agent')!,/AniApp/);
   return new Response(u.endsWith('robots.txt')?'User-agent: *\nDisallow: /wp-admin/':u.endsWith('feed/')?feed():html());
 };
 const a=await crawlAdnNews(fetcher,[],now,async(ms)=>{delays.push(ms);});
 assert.equal(a.rows.length,1);assert.equal(urls.length,3);assert.ok(delays.every(ms=>ms>0));
 urls.length=0;
 const cached=await crawlAdnNews(fetcher,[{source_url:url,checked_at:now.toISOString()}],now,async()=>{});
 assert.equal(cached.cached,1);assert.equal(cached.rows.length,0);assert.equal(urls.length,2);
 const blocked:typeof fetch=async(input)=>new Response(String(input).endsWith('robots.txt')?'User-agent: *\nDisallow: /de/':feed());
 await assert.rejects(crawlAdnNews(blocked,[],now,async()=>{}),/robots/);
});
test('access denials stop crawling and missing feed alone permits the public-index fallback',async()=>{
 let calls=0;
 await assert.rejects(crawlAdnNews(async()=>{calls++;return new Response('',{status:403});},[],now,async()=>{}));
 assert.equal(calls,1);
 const urls:string[]=[];
 const result=await crawlAdnNews(async(input)=>{
   const u=String(input);urls.push(u);
   if(u.endsWith('robots.txt'))return new Response('User-agent: *\nAllow: /');
   if(u.endsWith('feed/'))return new Response('',{status:404});
   if(u===origin+'/de/')return new Response(`<a href="${url}">News</a>`);
   return new Response(html());
 },[],now,async()=>{});
 assert.equal(result.rows.length,1);assert.equal(urls.length,4);
 let articleCalls=0;
 const partial=await crawlAdnNews(async(input)=>{
   const u=String(input);
   if(u.endsWith('robots.txt'))return new Response('User-agent: *\nAllow: /');
   if(u.endsWith('feed/'))return new Response(feed([url,url.replace('announcement','another')]));
   articleCalls++;return new Response('',{status:429});
 },[],now,async()=>{});
 assert.equal(articleCalls,1);assert.equal(partial.rows.length,0);assert.equal(partial.failed.length,1);
});
