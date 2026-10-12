import {test} from 'node:test';
import assert from 'node:assert/strict';
import {dates,extractDubs,exactAnime,titleKey,type Document} from '../../supabase/functions/content-sync/dub-parser.ts';
import {articleIdentity,parseFeed,parsePage,announcementReader,feeds} from '../../supabase/functions/content-sync/dub-sources.ts';
import {proposal,syncDubAnnouncements} from '../../supabase/functions/content-sync/dub-sync.ts';

const doc=(body:string,overrides:Partial<Document>={}):Document=>({source:'anime2you',url:'https://www.anime2you.de/news/123/test/',
  headline:'»Test Anime Season 2«: Deutsche Synchro startet',published_at:'2026-10-10T10:00:00Z',body,...overrides});
test('DE premiere uses the dub claim date, not article/Japanese dates or an invented time',()=>{
  const rows=extractDubs(doc('<p>»Test Anime Season 2« startet am 18. Oktober 2026 mit deutscher Synchro auf Netflix.</p><p>Die japanische Premiere war am 4. Oktober.</p>'));
  assert.equal(rows.length,1);assert.equal(rows[0].starts_on,'2026-10-18');assert.equal(rows[0].reason,null);
  assert.equal(rows[0].episode,null);assert.equal(rows[0].region,'DE');
  assert.equal(proposal(rows[0],{mal_id:9,title:'Test Anime Season 2'},'https://example.com').event.starts_at,undefined);
});
test('English audio requires explicit region evidence and does not infer DE or US from locale',()=>{
  const d=doc('The English dub premieres on October 18, 2026 in the United States and United Kingdom.',{source:'cr_en',headline:'Test Anime Season 2 English Dub Reveals Release Date'});
  const rows=extractDubs(d);assert.deepEqual(rows.map(r=>r.region),['US','GB']);assert.ok(rows.every(r=>r.language==='en'&&r.starts_on==='2026-10-18'&&!r.reason));
  const missing=extractDubs({...d,body:'The English dub premieres on October 18, 2026.'});
  assert.equal(missing[0].reason,'region_unconfirmed');assert.equal(missing[0].region,null);
});
test('dates retain year boundaries and reject day/year confusion and invalid calendar dates',()=>{
  assert.deepEqual(dates('5. November 2026','2026-10-10'),['2026-11-05']);
  assert.deepEqual(dates('January 2','2026-12-20'),['2027-01-02']);
  assert.deepEqual(dates('31. Februar 2026','2026-01-01'),[]);
  assert.deepEqual(dates('October 4, 2026','2026-10-10'),['2026-10-04']);
});
test('announced dub without a date remains TBA even when a simulcast date is nearby',()=>{
  const rows=extractDubs(doc('<p>Die japanische Fassung beginnt am 12. Oktober 2026.</p><p>Die deutsche Synchro startet zu einem späteren Zeitpunkt auf Crunchyroll.</p>'));
  assert.equal(rows[0].status,'announced');assert.equal(rows[0].starts_on,null);assert.equal(rows[0].reason,null);
});
test('explicit older-season episode and batches are imported without projecting future weeks',()=>{
  const episode=extractDubs(doc('»Test Anime Season 2«: Folge 22 der deutschen Synchro wurde bei Crunchyroll auf den 17. Oktober 2026 verschoben.'));
  assert.equal(episode[0].episode,22);assert.equal(episode[0].status,'delayed');assert.equal(episode[0].starts_on,'2026-10-17');
  const batch=extractDubs(doc('»Test Anime Season 2«: Episoden 13–15 starten am 18. Oktober 2026 mit deutscher Synchro auf Netflix.'));
  assert.deepEqual(batch.map(r=>r.episode),[13,14,15]);
  assert.deepEqual(extractDubs(doc('»Test Anime Season 2« startet ab dem 18. Oktober 2026 jede Woche mit deutscher Synchro auf Netflix.')).map(r=>r.episode),[null]);
});
test('subtitles, existing-season availability and ambiguous/multiple claims cannot become confirmed dubs',()=>{
  assert.deepEqual(extractDubs(doc('»Test Anime Season 2« startet am 18. Oktober mit deutschen Untertiteln auf Netflix.')),[]);
  assert.deepEqual(extractDubs(doc('Staffel 1 steht mit deutscher Synchro auf Crunchyroll bereit.',{headline:'Test Anime Season 2 reveals trailer'})),[]);
  assert.equal(extractDubs(doc('»Test Anime Season 2« startet mit deutscher Synchro am 18. Oktober 2026 auf Netflix und am 20. Oktober auf Crunchyroll.'))[0].reason,'provider_ambiguous');
  assert.equal(extractDubs(doc('»Test Anime Season 2«: Keine deutsche Synchro angekündigt, Termin offen bei Netflix.'))[0].reason,'negated_or_uncertain');
  assert.equal(extractDubs(doc('»Test Anime Season 2«: Staffel 1 startet am 18. Oktober mit deutscher Synchro auf Netflix.'))[0].reason,'season_scope_unconfirmed');
});
test('ADN card requires same-title German audio evidence and ignores synopsis dates/comments',()=>{
  const body='<p>Unsere deutsche Synchro zu Test Anime.</p><div class="adn-lineup-card"><h3>SYNOPSIS</h3><p>Im Jahr 2024, am 3. Oktober ...</p><h6>Test Anime</h6><p>22. Oktober (SYNC)</p></div>';
  const rows=extractDubs(doc(body,{source:'adn',headline:'Herbstprogramm'}));
  assert.equal(rows.length,1);assert.equal(rows[0].starts_on,'2026-10-22');assert.equal(rows[0].title,'Test Anime');assert.equal(rows[0].reason,null);
  assert.deepEqual(extractDubs(doc(body.replace('deutsche','französische'),{source:'adn'})),[]);
});
test('exact season-specific identity rejects fuzzy, ambiguous and wrong-season catalog matches',()=>{
  assert.equal(titleKey('Test Staffel 2'),titleKey('Test 2nd Season'));
  assert.equal(exactAnime('Test Season 2',[{mal_id:1,title:'Test',title_english:'Test'}]),null);
  assert.equal(exactAnime('Test',[{mal_id:1,title:'Test'},{mal_id:2,title:'Test'}]),null);
  assert.equal(exactAnime('Test Season 2',[{mal_id:2,title:'Test 2nd Season'}])?.mal_id,2);
});
test('feeds accept official English URLs without a locale prefix and reject arbitrary fetch targets',()=>{
  assert.equal(articleIdentity('https://crunchyroll.com/news/announcements/2026/10/10/test')?.source,'cr_en');
  for(const bad of ['http://www.anime2you.de/news/1/test/','https://www.anime2you.de.evil.com/news/1/test/','https://user@www.anime2you.de/news/1/test/','https://www.anime2you.de/news/1/test/?url=secret'])assert.equal(articleIdentity(bad),null);
  const xml='<rss><channel><item><title>Test English Dub</title><link>https://crunchyroll.com/news/announcements/2026/10/10/test</link><pubDate>Sat, 10 Oct 2026 08:00:00 GMT</pubDate><content:encoded>The English dub premieres on October 18 in the United States.</content:encoded></item></channel></rss>';
  assert.equal(parseFeed(xml,'cr_en',new Date('2026-10-10T10:00:00Z')).length,1);
  assert.throws(()=>parseFeed('<!DOCTYPE rss>'+xml,'cr_en'));
});
test('article parser bounds the editorial body and does not read comments or scripts',()=>{
  const url='https://www.anime2you.de/news/123/test/';
  const html=`<meta property="og:type" content="article"><meta property="og:title" content="Test"><meta property="article:published_time" content="2026-10-10T08:00:00Z"><link rel="canonical" href="${url}"><div class="td-post-content"><div><p>${'Editorial text. '.repeat(10)}</p></div></div><div id="comments"><p>Fake dub date</p></div>`;
  assert.ok(!parsePage(html,url).body.includes('Fake'));
  assert.throws(()=>parsePage('<html>Javascript shell only</html>',url));
});
test('crawler respects robots and stops an origin after rate limiting without fetching unapproved hosts',async()=>{
  const calls:string[]=[];
  const read=announcementReader((async(url:any)=>{calls.push(String(url));return String(url).endsWith('robots.txt')?new Response('User-agent: *\nDisallow: /news/999/'):new Response('rate limit',{status:429});}) as typeof fetch,Date.now()+5000,async()=>{});
  await assert.rejects(read('https://www.anime2you.de/news/999/test/'),/robots/);
  await assert.rejects(read('https://www.anime2you.de/news/123/test/'),/429/);
  await assert.rejects(read('https://www.anime2you.de/news/124/test/'),/blocked/);
  await assert.rejects(read('https://evil.test/'),/Unapproved/);
  assert.equal(calls.length,2);
});

test('hourly worker revisits articles that left the feed; 304 and outages preserve releases',async()=>{
  const old='https://www.anime2you.de/news/101/old-dub/',failed='https://www.anime2you.de/news/102/unavailable/';
  const watched=[{source_url:old,source_key:'anime2you',etag:'"v1"',parser_version:1,needs_review:false},
    {source_url:failed,source_key:'anime2you',parser_version:1}];
  const writes:{path:string;body:any;method:string}[]=[],requests:{url:string;headers:any}[]=[];
  const db=async(path:string,body:any,method='POST')=>{
    if(method==='GET'){
      if(path.startsWith('dub_source_documents?select=source_url'))return watched;
      if(path.startsWith('dub_source_documents?'))return watched;
      return [];
    }
    writes.push({path,body,method});return null;
  };
  const fetcher=(async(url:any,init:any)=>{
    requests.push({url:String(url),headers:init.headers});
    if(String(url).endsWith('/robots.txt'))return new Response('User-agent: *\nAllow: /');
    if(url===old)return new Response(null,{status:304});
    if(url===failed)return new Response('Unavailable',{status:503});
    return new Response('<rss><channel></channel></rss>');
  }) as typeof fetch;
  const report=await syncDubAnnouncements(db,fetcher,new Date('2026-10-10T10:00:00Z'),async()=>{});
  assert.equal(requests.find(r=>r.url===old)?.headers['If-None-Match'],'"v1"');
  assert.equal(report.unchanged,1);assert.equal(report.published,0);
  assert.ok(report.failed.some(r=>r.source===failed));
  assert.ok(writes.every(w=>w.path.startsWith('dub_source_documents?')));
  assert.ok(writes.some(w=>w.body.error==='Announcement HTTP 503'&&!w.body.checked_at));
  assert.ok(writes.some(w=>w.body.error===null&&w.body.checked_at));
});

test('official RSS subscription uses only its published path and still honors feed access denials',async()=>{
  const calls:string[]=[];
  const read=announcementReader((async(url:any)=>{calls.push(String(url));return new Response('Denied',{status:403});}) as typeof fetch,Date.now()+5000,async()=>{});
  await assert.rejects(read(feeds[0].url),/403/);
  await assert.rejects(read(feeds[1].url),/blocked/);
  assert.deepEqual(calls,[feeds[0].url]);
});
