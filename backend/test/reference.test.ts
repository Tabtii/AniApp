import {test} from 'node:test';
import assert from 'node:assert/strict';
import {Enrichment} from '../../supabase/functions/anime-enrichment/providers.ts';
import {annDetails,decodeXml,propertiesMatch,readEntity,wikidataItem,wikidataSearchUrl,wikipediaSummary} from '../../supabase/functions/anime-enrichment/reference.ts';

const labels={entities:{P4086:{labels:{en:{value:'MyAnimeList anime ID'}}},P1985:{labels:{en:{value:'Anime News Network anime ID'}}}}};
const entity=(over:Record<string,unknown>={})=>({entities:{Q1:{claims:{
  P4086:[{rank:'normal',mainsnak:{datavalue:{value:'52991'}}}],
  P1985:[{rank:'normal',mainsnak:{datavalue:{value:'25346'}}}]},
  sitelinks:{dewiki:{title:'Frieren – Nach dem Ende der Reise'}},...over}}});
const summary={type:'standard',title:'Frieren – Nach dem Ende der Reise',extract:'Frieren ist eine Manga-Serie.',
  content_urls:{desktop:{page:'https://de.wikipedia.org/wiki/Frieren_%E2%80%93_Nach_dem_Ende_der_Reise'}}};
const annXml='<ann><anime id="25346" gid="1" type="TV" name="Frieren: Beyond Journey&apos;s End">'+
  '<info gid="2" type="Main title" lang="JA">Sousou no Frieren</info>'+
  '<info gid="3" type="Plot Summary">Frieren &amp; Himmel <i>defeated</i> the Demon King.</info></anime></ann>';

test('Wikidata lookup uses the MAL ID statement and needs exactly one item',()=>{
  assert.match(wikidataSearchUrl(52991),/haswbstatement%3AP4086%3D52991/);
  assert.throws(()=>wikidataSearchUrl(-1));
  assert.equal(wikidataItem({query:{search:[{title:'Q1'}]}}),'Q1');
  assert.equal(wikidataItem({query:{search:[{title:'Q1'},{title:'Q2'}]}}),null);
  assert.equal(wikidataItem({query:{search:[]}}),null);
  assert.throws(()=>wikidataItem({}));
});
test('property IDs must carry the expected labels, otherwise lookups fail closed',()=>{
  assert.equal(propertiesMatch(labels),true);
  assert.equal(propertiesMatch({entities:{...labels.entities,P4086:{labels:{en:{value:'MyAnimeList manga ID'}}}}}),false);
});
test('the item must itself carry the MAL ID; ambiguous ANN IDs are dropped',()=>{
  assert.deepEqual(readEntity(entity(),'Q1',52991),{qid:'Q1',annId:25346,dewiki:'Frieren – Nach dem Ende der Reise'});
  assert.equal(readEntity(entity(),'Q1',1),null);
  const twoAnn=entity({claims:{P4086:[{mainsnak:{datavalue:{value:'52991'}}}],
    P1985:[{mainsnak:{datavalue:{value:'1'}}},{mainsnak:{datavalue:{value:'2'}}}]}});
  assert.equal(readEntity(twoAnn,'Q1',52991)?.annId,null);
  const deprecated=entity({claims:{P4086:[{rank:'deprecated',mainsnak:{datavalue:{value:'52991'}}}]}});
  assert.equal(readEntity(deprecated,'Q1',52991),null);
});
test('Wikipedia summaries keep title, link and licence; disambiguations and foreign links are rejected',()=>{
  const s=wikipediaSummary(summary)!;
  assert.equal(s.extract,'Frieren ist eine Manga-Serie.');
  assert.equal(s.license,'https://creativecommons.org/licenses/by-sa/4.0/deed.de');
  assert.match(s.history_url,/action=history/);
  assert.equal(wikipediaSummary({...summary,type:'disambiguation'}),null);
  assert.equal(wikipediaSummary({...summary,content_urls:{desktop:{page:'https://evil.example/wiki/x'}}}),null);
});
test('ANN entries match the requested ID and decode the plot summary as plain text',()=>{
  const d=annDetails(annXml,25346)!;
  assert.equal(d.title,"Frieren: Beyond Journey's End");
  assert.equal(d.synopsis,'Frieren & Himmel defeated the Demon King.');
  assert.equal(d.source,'https://www.animenewsnetwork.com/encyclopedia/anime.php?id=25346');
  assert.equal(annDetails(annXml,1),null);
  assert.equal(annDetails('<ann><warning>no result for anime=9</warning></ann>',9),null);
  assert.throws(()=>annDetails('<html>error</html>',1));
  assert.equal(decodeXml('a &#252; &#x263A; &unknown;'),'a ü ☺ &unknown;');
});
function fake(routes:Record<string,()=>Response>,seen:string[]=[]){
  return async(url:string|URL|Request,init?:RequestInit)=>{
    const u=String(url);seen.push(u);
    if(u.includes('wikimedia')||u.includes('wikipedia')||u.includes('wikidata'))assert.match(new Headers(init?.headers).get('User-Agent')??'',/^AniApp\//);
    for(const [k,r] of Object.entries(routes))if(u.includes(k))return r();
    throw new Error(`Unexpected request ${u}`);
  };
}
const full={'props=labels':()=>Response.json(labels),'list=search':()=>Response.json({query:{search:[{title:'Q1'}]}}),
  'action=wbgetentities&ids=Q1':()=>Response.json(entity()),'rest_v1/page/summary':()=>Response.json(summary),
  'encyclopedia/api.xml':()=>new Response(annXml)};
test('reference lookup returns Wikipedia and ANN with sources and caches per MAL ID',async()=>{
  const seen:string[]=[];
  const service=new Enrichment({},fake(full,seen));
  const r=await service.reference(52991);
  assert.equal(r.wikipedia.status,'ok');assert.equal(r.wikipedia.wikidata,'https://www.wikidata.org/wiki/Q1');
  assert.equal(r.ann.status,'ok');assert.equal(r.ann.synopsis,'Frieren & Himmel defeated the Demon King.');
  const count=seen.length;await service.reference(52991);assert.equal(seen.length,count);
});
test('register switches and wrong property labels make no reference requests',async()=>{
  const none=new Enrichment({},async()=>{throw new Error('Must not request');});
  assert.deepEqual(await none.reference(52991,new Set(['wikidata'])),{wikipedia:{status:'unavailable'},ann:{status:'unavailable'}});
  const seen:string[]=[];
  const wrong=new Enrichment({},fake({...full,'props=labels':()=>Response.json({entities:{P4086:{labels:{en:{value:'Other'}}},P1985:labels.entities.P1985}})},seen));
  assert.equal((await wrong.reference(52991)).wikipedia.status,'unavailable');
  assert.ok(seen.every(u=>u.includes('props=labels')));
  const partly=new Enrichment({},fake(full,[]));
  const r=await partly.reference(52991,new Set(['ann','wikipedia']));
  assert.equal(r.ann.status,'unavailable');assert.equal(r.wikipedia.status,'unavailable');
});
test('unmapped titles and failed upstreams are reported, failures are not cached',async()=>{
  const unmapped=new Enrichment({},fake({...full,'list=search':()=>Response.json({query:{search:[]}})}));
  assert.deepEqual(await unmapped.reference(1),{wikipedia:{status:'unmapped'},ann:{status:'unmapped'}});
  let calls=0;
  const flaky=new Enrichment({},fake({...full,'rest_v1/page/summary':()=>++calls===1?new Response('down',{status:503}):Response.json(summary)}));
  assert.equal((await flaky.reference(52991)).wikipedia.status,'unavailable');
  assert.equal((await flaky.reference(52991)).wikipedia.status,'ok');
});
