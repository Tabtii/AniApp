import {test} from 'node:test';
import assert from 'node:assert/strict';
import {Enrichment,validateInput,dubStatus,tmdbMapping,watchProviders,airingEvent} from '../../supabase/functions/anime-enrichment/providers.ts';

test('input limits IDs, regions, languages and modes; caller cannot set upstream URLs',()=>{
  for(const input of [{mal_id:-1},{mal_id:'21'},{mal_id:21,region:'DE&x=1'},{mode:'https://example.com'},{mal_id:21,language:'../../secret'}])assert.throws(()=>validateInput(input));
  assert.equal(validateInput({mal_id:21}).language,'de');
  assert.equal(validateInput({mode:'calendar'}).mode,'calendar');
});
test('dub existence never invents absence, provider availability, or release dates',()=>{
  assert.equal(dubStatus({dubbed:[1],partial:[2]},1),'available');
  assert.equal(dubStatus({dubbed:[1,2],partial:[2]},2),'partial');
  assert.equal(dubStatus({dubbed:[1],partial:[]},99),'unknown');
  assert.throws(()=>dubStatus({dubbed:['1'],partial:[]},1));
});
test('TMDb matches exact MAL IDs and seasons, rejects conflicting and multi-film mappings',()=>{
  const row={mal_id:53913,type:'TV',themoviedb_id:{tv:134667},season:{tmdb:2}};
  assert.deepEqual(tmdbMapping([row],53913),{type:'tv',id:134667,season:2});
  assert.equal(tmdbMapping([row],52991),null);
  assert.equal(tmdbMapping([row,{...row,season:{tmdb:1}}],53913),null);
  assert.equal(tmdbMapping([{mal_id:1,type:'MOVIE',themoviedb_id:{movie:[1,2]}}],1),null);
  assert.deepEqual(tmdbMapping([{mal_id:1,type:'MOVIE',themoviedb_id:{movie:[128]}}],1),{type:'movie',id:128,season:null});
});
test('watch providers preserve country, season and offer types without guessing audio',()=>{
  const p={provider_id:8,provider_name:'Netflix'};
  const value={results:{DE:{link:'https://www.themoviedb.org/tv/123/watch?locale=DE',flatrate:[p],buy:[p]},US:{link:'https://www.themoviedb.org/tv/123/watch',free:[{provider_id:9,provider_name:'Other'}]}}};
  const rows=watchProviders(value,'DE',{type:'tv',id:123,season:2},'2026-10-08T12:00:00Z');
  assert.equal(rows.length,1);assert.equal(rows[0].season_number,2);assert.deepEqual(rows[0].offers,['flatrate','buy']);
  assert.equal(rows[0].audio_languages,null);assert.equal(rows[0].subtitle_languages,null);
  assert.deepEqual(watchProviders(value,'AT',{type:'tv',id:123,season:2},'now'),[]);
  assert.throws(()=>watchProviders({results:{DE:{link:'https://evil.example'}}},'DE',{type:'tv',id:1,season:1},'now'));
});
test('missing credentials and AniList approval make no external requests',async()=>{
  const service=new Enrichment({},async()=>{throw new Error('Must not request');});
  assert.equal((await service.tmdb(21,'DE')).status,'unconfigured');
  assert.equal((await service.anilist(21)).status,'approval_required');
  assert.equal((await service.calendar()).status,'approval_required');
});
test('MyDubList loads the selected language, coalesces requests, and retains attribution',async()=>{
  let calls=0;
  const service=new Enrichment({},async(url)=>{calls++;assert.match(String(url),/normal\/dubbed_german.json$/);return Response.json({language:'German',dubbed:[21],partial:[]});});
  const [a,b]=await Promise.all([service.dub(21,'de'),service.dub(1,'de')]);
  assert.equal(calls,1);assert.equal(a.status,'available');assert.equal(b.status,'unknown');assert.equal(a.source,'https://mydublist.com');
  assert.equal(a.license,'https://creativecommons.org/licenses/by/4.0/');assert.ok(a.checked_at);assert.equal(a.starts_at,undefined);
});
test('failed dub response is unavailable and can recover; not cached as absent',async()=>{
  let calls=0;
  const service=new Enrichment({},async()=>++calls===1?new Response('bad',{status:503}):Response.json({language:'French',dubbed:[21],partial:[]}));
  assert.equal((await service.dub(21,'fr')).status,'unavailable');
  assert.equal((await service.dub(21,'fr')).status,'available');
});
test('TMDb uses server credential and season endpoint with distinct region results',async()=>{
  const urls:string[]=[];
  const service=new Enrichment({tmdbToken:'server-only'},async(url,init)=>{
    urls.push(String(url));
    if(String(url).includes('raw.githubusercontent.com'))return Response.json([{mal_id:53913,type:'TV',themoviedb_id:{tv:134667},season:{tmdb:2}}]);
    assert.equal(new Headers(init?.headers).get('Authorization'),'Bearer server-only');
    assert.match(String(url),/\/tv\/134667\/season\/2/);
    if(String(url).includes('/watch/providers'))return Response.json({results:{DE:{link:'https://www.themoviedb.org/tv/134667/watch?locale=DE',flatrate:[{provider_id:1,provider_name:'Provider'}]}}});
    return Response.json({overview:'Deutsche Beschreibung'});
  });
  const de=await service.tmdb(53913,'DE'),at=await service.tmdb(53913,'AT');
  assert.equal(de.status,'ok');assert.equal(de.providers.length,1);assert.equal(at.providers.length,0);assert.equal(urls.length,3);
  assert.equal(de.overview,'Deutsche Beschreibung');assert.ok(!JSON.stringify(de).includes('server-only'));
});
test('missing season providers never fall back to the series or another season',async()=>{
  const urls:string[]=[];
  const service=new Enrichment({tmdbKey:'test'},async(url)=>{
    urls.push(String(url));return String(url).includes('raw.githubusercontent.com')?Response.json([{mal_id:10,type:'TV',themoviedb_id:{tv:123},season:{tmdb:2}}]):new Response('{}',{status:404});
  });
  assert.equal((await service.tmdb(10,'DE')).status,'unavailable');assert.equal(urls.length,2);
});
test('AniList events require exact MAL identity, non-adult media and future time',()=>{
  const now=new Date('2026-10-08T12:00:00Z'),media={id:100,idMal:21,isAdult:false,title:{romaji:'One Piece'}};
  const air={episode:1200,airingAt:Math.floor(now.getTime()/1000)+3600,mediaId:100};
  const e=airingEvent(media,air,now)!;assert.equal(e.kind,'japan');assert.equal(e.status,'estimated');assert.equal(e.episode,1200);
  for(const m of [{...media,idMal:null},{...media,isAdult:true},{...media,id:101}])assert.equal(airingEvent(m,air,now),null);
  assert.equal(airingEvent(media,{...air,airingAt:1},now),null);
});
test('approved AniList detail sends idMal and returns future episode without dub claims',async()=>{
  const service=new Enrichment({anilistApproved:true},async(url,init)=>{
    assert.equal(String(url),'https://graphql.anilist.co');const q=JSON.parse(String(init?.body));
    assert.equal(q.variables.id,21);assert.match(q.query,/isAdult:false/);
    return Response.json({data:{Media:{id:100,idMal:21,isAdult:false,title:{romaji:'One Piece'},nextAiringEpisode:{episode:1200,airingAt:Math.floor(Date.now()/1000)+3600,mediaId:100}}}});
  });
  const result=await service.anilist(21);assert.equal(result.status,'ok');assert.equal(result.next_release.region,'JP');
});
test('calendar includes ongoing older seasons and discards past/adult/unmapped entries',async()=>{
  const future=Math.floor(Date.now()/1000)+3600;
  const service=new Enrichment({anilistApproved:true},async(url,init)=>{
    const q=JSON.parse(String(init?.body));assert.ok(!q.query.includes('season:'));assert.equal(q.variables.to-q.variables.from,7*86400);
    const media={id:100,idMal:21,isAdult:false,title:{romaji:'One Piece'}};
    return Response.json({data:{Page:{pageInfo:{hasNextPage:false},airingSchedules:[{media,episode:1200,airingAt:future,mediaId:100},{media:{...media,isAdult:true},episode:1201,airingAt:future,mediaId:100}]}}});
  });
  const result=await service.calendar();assert.equal(result.status,'ok');assert.equal(result.events.length,1);assert.equal(result.events[0].mal_id,21);
});
test('AniList rate limit honors cooldown instead of hammering the API',async()=>{
  let calls=0;const service=new Enrichment({anilistApproved:true},async()=>{calls++;return new Response('{}',{status:429,headers:{'Retry-After':'60'}});});
  assert.equal((await service.anilist(21)).status,'unavailable');assert.equal((await service.anilist(1)).status,'unavailable');assert.equal(calls,1);
});

// Keep the two-language mobile launch scope accepted by the deployed gateway.
test('launch preferences accept German and English independently of all selectable countries',()=>{
  for(const region of ['DE','AT','CH','US','GB'])for(const language of ['de','en']){
    const input=validateInput({mal_id:21,region,language});
    assert.equal(input.region,region);assert.equal(input.language,language);
  }
});
