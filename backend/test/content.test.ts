import {test} from 'node:test';
import assert from 'node:assert/strict';
import {broadcastEvents,rssNews,malNews} from '../../supabase/functions/content-sync/content.ts';
const now=new Date('2026-10-08T10:00:00Z');
const anime={mal_id:1,title:'Series',airing:true,broadcast:{day:'Fridays',time:'00:30',timezone:'Asia/Tokyo'}};
test('broadcast dates account for JST day boundaries and never invent episode numbers',()=>{
 const row=broadcastEvents([anime],now)[0];
 assert.equal(row.starts_at,'2026-10-08T15:30:00.000Z');
 assert.equal(row.episode,null);assert.equal(row.status,'estimated');assert.equal(row.region,'JP');
 assert.equal(broadcastEvents([anime],new Date('2026-10-08T16:00:00Z'))[0].starts_at,'2026-10-15T15:30:00.000Z');
 assert.deepEqual(broadcastEvents([{...anime,airing:false}],now),[]);
 assert.deepEqual(broadcastEvents([{...anime,broadcast:{...anime.broadcast,timezone:null}}],now),[]);
 assert.deepEqual(broadcastEvents([{...anime,aired:{to:'2026-09-01'}}],now),[]);
});
test('news import rejects untrusted links, stale/future articles and invalid XML',()=>{
 const item=(url:string,date='Wed, 07 Oct 2026 18:00:00 GMT')=>`<item><title><![CDATA[Neue Staffel &amp; Synchro]]></title><link>${url}</link><pubDate>${date}</pubDate></item>`;
 const good=item('https://www.anime2you.de/news/123/title/');
 const rows=rssNews(`<rss><channel>${good}${item('https://evil.example/news/1')}${item('https://www.anime2you.de/news/2','Fri, 09 Oct 2026 18:00:00 GMT')}</channel></rss>`,now);
 assert.equal(rows.length,1);assert.equal(rows[0].headline,'Neue Staffel & Synchro');assert.equal(rows[0].language,'de');assert.equal(rows[0].published,true);
 assert.throws(()=>rssNews('<html>Not a feed</html>',now));
 assert.throws(()=>rssNews('<rss></rss>',now));
 assert.deepEqual(malNews([{mal_id:123,title:'News',url:'https://evil.example/news/1',date:now.toISOString()}],now),[]);
 const n=malNews([{mal_id:123,title:'News',url:'https://myanimelist.net/news/1',date:now.toISOString()}],now)[0];
 assert.equal(n.mal_id,undefined); // News ID must never be treated as an anime ID.
 assert.equal(n.language,'en');
});
