import {test} from 'node:test';
import assert from 'node:assert/strict';
import {rssNews} from '../../supabase/functions/content-sync/content.ts';
import {loadAniNews} from '../../supabase/functions/content-sync/aninews.ts';
const now=new Date('2026-10-09T08:00:00Z'),url='https://www.aninews.de/news/123/new-season';
const item=(category='Anime',link=url)=>`<item><title>Neue Staffel angekündigt</title><link>${link}</link><pubDate>Thu, 08 Oct 2026 12:00:00 GMT</pubDate><category><![CDATA[${category}]]></category><description>Eine neue Anime-Staffel wurde angekündigt.</description></item>`;
const feed=`<rss>${item()}${item('Games','https://www.aninews.de/news/124/game')}</rss>`;
const article=`<meta property="og:type" content="article"><meta property="og:locale" content="de_DE"><meta property="og:url" content="${url}"><meta property="og:image" content="https://www.aninews.de/wp-content/uploads/image.jpg">`;
test('AniNews imports only anime stories from its own source and never confuses news and MAL IDs',()=>{
 const rows=rssNews(feed,now,'AniNews');assert.equal(rows.length,1);assert.equal(rows[0].source_name,'AniNews');assert.equal(rows[0].mal_id,undefined);
 assert.throws(()=>rssNews(`<rss>${item('Anime','https://evil.test/news/1/x')}</rss>`,now,'AniNews'));
 assert.throws(()=>rssNews(feed,now));
});
test('AniNews verifies article identity/images, daily caching and robots before crawling',async()=>{
 const calls:string[]=[];
 const fetcher:typeof fetch=async(input,init)=>{const u=String(input);calls.push(u);assert.equal(init?.redirect,'error');return new Response(u.endsWith('robots.txt')?'User-agent: *\nAllow: /':u.endsWith('/feed')?feed:article);};
 const result=await loadAniNews(fetcher,[],now,async()=>{});assert.equal(result.rows.length,1);assert.ok(result.rows[0].image_url);assert.equal(calls.length,3);
 calls.length=0;const cached=await loadAniNews(fetcher,result.rows,now,async()=>{});assert.equal(cached.cached,1);assert.equal(calls.length,2);
 await assert.rejects(loadAniNews(async()=>new Response('User-agent: *\nDisallow: /'),[],now,async()=>{}),/robots/);
 await assert.rejects(loadAniNews(async(input)=>new Response(String(input).endsWith('robots.txt')?'User-agent: *\nAllow: /':String(input).endsWith('/feed')?feed:article.replace('content="article"','content="website"')),[],now,async()=>{}),/verified/);
});
test('AniNews stops on denied access and does not erase existing data',async()=>{
 let calls=0;await assert.rejects(loadAniNews(async()=>{calls++;return new Response('',{status:403});},[],now,async()=>{}));assert.equal(calls,1);
});
