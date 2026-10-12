import {test} from 'node:test';
import assert from 'node:assert/strict';
import {kitsuDetails,kitsuLookupUrl} from '../../supabase/functions/anime-enrichment/kitsu.ts';
import {Enrichment} from '../../supabase/functions/anime-enrichment/providers.ts';

const fixture=()=>({data:[{type:'mappings',attributes:{externalSite:'myanimelist/anime',externalId:'52991'},relationships:{item:{data:{type:'anime',id:'46474'}}}}],included:[{type:'anime',id:'46474',attributes:{canonicalTitle:'Sousou no Frieren',titles:{en:'Frieren'},nsfw:false,ageRating:'PG',episodeCount:28,episodeLength:24,startDate:'2023-09-29',endDate:'2024-03-22',status:'finished',synopsis:'A journey.',posterImage:{large:'https://media.kitsu.app/anime/46474/poster_image/large.jpg'},coverImage:{large:'https://media.kitsu.app/anime/46474/cover_image/large.jpg'},youtubeVideoId:'qgQunxD0qCk'}}]});

test('Kitsu requires an exact unambiguous MAL mapping even when upstream ignores filters',()=>{
 const input=fixture();
 assert.equal(kitsuDetails(input,52991)?.episodes,28);
 assert.equal(kitsuDetails(input,21),null);
 assert.equal(kitsuDetails({...input,links:{next:'another-page'}},52991),null);
 const conflicting=fixture();conflicting.data.push({...conflicting.data[0],relationships:{item:{data:{type:'anime',id:'2'}}}});
 assert.equal(kitsuDetails(conflicting,52991),null);
 input.included[0].attributes.nsfw=true;assert.equal(kitsuDetails(input,52991),null);
 assert.throws(()=>kitsuLookupUrl(-1));
 const u=new URL(kitsuLookupUrl(52991));assert.equal(u.origin,'https://kitsu.app');assert.equal(u.searchParams.get('filter[externalId]'),'52991');
});
test('Kitsu exposes only validated source media and original dates, never dub or provider dates',()=>{
 const input=fixture();input.included[0].attributes.posterImage.large='https://evil.test/a.jpg';
 input.included[0].attributes.youtubeVideoId='javascript:bad';
 const result=kitsuDetails(input,52991)!;
 assert.equal(result.poster,null);assert.equal(result.trailer_url,null);
 assert.equal(result.start_date,'2023-09-29');assert.equal(result.starts_at,undefined);assert.equal(result.audio_language,undefined);
});
test('Kitsu is keyless, coalesced, and independent of other enrichment failures',async()=>{
 let calls=0;
 const service=new Enrichment({},async(url,init)=>{
   if(String(url).startsWith('https://kitsu.app/')){calls++;assert.equal(new Headers(init?.headers).has('Authorization'),false);return Response.json(fixture());}
   throw new Error('Other source offline');
 });
 const [detail,kitsu]=await Promise.all([service.detail(52991,'de','DE'),service.kitsu(52991)]);
 assert.equal(calls,1);assert.equal(kitsu.status,'ok');assert.equal(detail.kitsu.status,'ok');assert.equal(detail.dub.status,'unavailable');
 assert.equal(detail.streaming.status,'unconfigured');assert.equal(detail.anilist.status,'approval_required');
 const offline=new Enrichment({},async()=>new Response('',{status:503}));
 assert.equal((await offline.kitsu(21)).status,'unavailable');
});
