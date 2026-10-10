import {test} from 'node:test';
import assert from 'node:assert/strict';
import {adnEvents,adnDays,loadAdn,berlinDay} from '../../supabase/functions/content-sync/adn.ts';
const now=new Date('2026-10-08T12:00:00Z');
const video={id:1,type:'EPS',season:'1',shortNumber:'27',url:'https://animationdigitalnetwork.com/de/video/1381-rilakkuma/1-folge-27',releaseDate:'2026-10-10T01:00:00Z',languages:['vostde'],show:{id:1381,title:'Rilakkuma',distributions:'de'}};
test('ADN keeps continuing seasons, exact episode numbers and distinct release languages',()=>{
 const rows=adnEvents({videos:[video]},'2026-10-10',now).rows;
 assert.equal(rows[0].mal_id,60153);assert.equal(rows[0].episode,27);assert.equal(rows[0].kind,'streaming');assert.equal(rows[0].audio_language,'ja');assert.equal(rows[0].starts_at,video.releaseDate.replace('Z','.000Z'));
 const unknown=adnEvents({videos:[{...video,languages:[]}]},'2026-10-10',now).rows;
 assert.equal(unknown[0].audio_language,null);assert.equal(unknown[0].kind,'streaming');
 const dub=adnEvents({videos:[{...video,languages:['vde']}]},'2026-10-10',now).rows;
 assert.equal(dub[0].kind,'dub');assert.equal(dub[0].audio_language,'de');
 assert.equal(adnEvents({videos:[{...video,season:'2'}]},'2026-10-10',now).rows.length,0);
});
test('ADN rejects wrong locales, untrusted links and wrong days without inventing mappings',()=>{
 assert.throws(()=>adnEvents({videos:[{...video,show:{...video.show,distributions:'fr'}}]},'2026-10-10',now));
 assert.throws(()=>adnEvents({videos:[{...video,url:'https://evil.example/de/video/1381-rilakkuma'}]},'2026-10-10',now));
 assert.throws(()=>adnEvents({videos:[video]},'2026-10-11',now));
 const other={...video,show:{id:9999,distributions:'de'},url:'https://animationdigitalnetwork.com/de/video/9999-other/1'};
 assert.deepEqual(adnEvents({videos:[other]},'2026-10-10',now).unmapped,['9999:1']);
 assert.equal(berlinDay(new Date('2026-10-09T23:30:00Z')),'2026-10-10');
 assert.equal(berlinDay(new Date('2026-10-25T23:30:00Z')),'2026-10-26');
 assert.deepEqual(adnDays({dateRules:['2026-09-01','2026-10-10','2026-10-10','2026-11-01']},now),['2026-10-10']);
});
test('back-catalog additions remain provider releases, not new original broadcasts',()=>{
 const row=adnEvents({videos:[{...video,show:{id:213,distributions:'de'},shortNumber:'39',url:'https://animationdigitalnetwork.com/de/video/213-revolutionary-girl-utena/39'}]},'2026-10-10',now).rows[0];
 assert.equal(row.mal_id,440);assert.equal(row.episode,39);assert.equal(row.kind,'streaming');assert.match(row.release_note,/ADN-Katalog/);assert.match(row.release_note,/deutschen Untertiteln/);
});
test('a failed ADN day is excluded from replacement; valid empty days can clear cancellations',async()=>{
 const result=await loadAdn(async url=>{
  if(url.endsWith('/rule'))return JSON.stringify({dateRules:['2026-10-10','2026-10-11','2026-10-12']});
  if(url.endsWith('10'))return JSON.stringify({videos:[video]});
  if(url.endsWith('11'))throw new Error('Unavailable');
  return JSON.stringify({videos:[]});
 },now);
 assert.deepEqual(result.days,['2026-10-10','2026-10-12']);assert.equal(result.rows.length,1);assert.equal(result.failed.length,1);
});

test('ADN cleanup follows successful upserts and is scoped to verified days across DST',async()=>{
 const {saveAdn}=await import('../../supabase/functions/content-sync/adn.ts');
 const data={rows:adnEvents({videos:[video]},'2026-10-10',now).rows,days:['2026-10-10','2026-10-25'],failed:[],unmapped:[]};
 const calls:Array<{path:string,body:any,method?:string}>=[];
 await saveAdn(data,async(path,body,method)=>{calls.push({path,body,method});});
 assert.equal(calls.length,2);assert.ok(calls[0].path.includes('on_conflict'));
 const url=new URL(calls[1].path,'https://db.invalid/');
 assert.equal(calls[1].method,'PATCH');assert.deepEqual(calls[1].body,{published:false});
 assert.equal(url.searchParams.get('provider'),'eq.ADN');
 assert.equal(url.searchParams.get('source_url'),'like.https://animationdigitalnetwork.com/de/video/*');
 assert.equal(url.searchParams.get('checked_at'),'lt.'+calls[0].body[0].checked_at);
 assert.ok(url.searchParams.get('or')!.includes('starts_at.gte.2026-10-24T22:00:00.000Z,starts_at.lt.2026-10-25T23:00:00.000Z'));
 let count=0;await assert.rejects(saveAdn(data,async()=>{count++;throw new Error('Write failed');}));assert.equal(count,1);
});
