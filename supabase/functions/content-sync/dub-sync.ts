import {sourceImage,type Row} from './content.ts';
import {extractDubs,exactAnime,titleKey,PARSER_VERSION,type Document,type Candidate} from './dub-parser.ts';
import {feeds,parseFeed,parsePage,feedNews,articleIdentity,announcementReader} from './dub-sources.ts';
import {reviewedDubIdentities} from './dub-identities.ts';
type Database=(path:string,body:unknown,method?:string)=>Promise<any>;

export function proposal(candidate:Candidate,match:Row|null,url:string):Row {
  const c=candidate;
  const event=match&&c.provider&&c.region?{mal_id:match.mal_id,title:match.title,episode:c.episode,kind:'dub',starts_on:c.starts_on,
    provider:c.provider,region:c.region,audio_language:c.language,status:c.status,source_url:url,image_url:match.image_url??null,
    release_note:`${c.language==='de'?'Deutsche Synchronfassung':'English dub'} · ${c.episode===null?'Start / premiere':`Folge / episode ${c.episode}`} · ${c.starts_on?'Tag bestätigt; Uhrzeit offen / Date confirmed; time TBA.':'Termin offen / Date TBA.'}`} : null;
  return {key:[titleKey(c.title),c.provider,c.region,c.language,c.episode??'premiere'].join('|'),
    evidence:c.evidence,reason:c.reason??(!match?'title_unmapped':null),event};
}
export async function syncDubAnnouncements(db:Database,fetcher:typeof fetch=fetch,now=new Date(),pause=(ms:number)=>new Promise(r=>setTimeout(r,ms))) {
  const deadline=Date.now()+45000,read=announcementReader(fetcher,deadline,pause);
  const report={published:0,review:0,conflicts:0,checked:0,unchanged:0,discovered:0,failed:[] as Row[]};
  const incoming=new Map<string,Document>();
  for(const f of feeds){
    try{
      const documents=parseFeed((await read(f.url)).body,f.source,now);
      if(!documents.length)throw new Error('Empty recent announcement feed');
      if(f.source.startsWith('cr_'))await db('news?on_conflict=source_url',documents.map(d=>feedNews(d,now)));
      for(const doc of documents){
        // Source body language is never used as the audio language.
        if(/(?:English|German)[- ](?:language )?dub|deutsch\w*\s+(?:Synchro\w*|Sprachfassung)|englisch\w*\s+(?:Synchro\w*|Sprachfassung)|\bSYNC\b/i.test(doc.body+' '+doc.headline))incoming.set(doc.url,doc);
      }
    }catch(e){report.failed.push({source:f.source,error:e instanceof Error?e.message:'Unavailable'});}
  }
  // Discover new official ADN articles even when their headline does not say dub,
  // and keep prior announcement URLs under observation after they leave the feed.
  const knownNews:Row[]=await db('news?source_name=eq.ADN%20News&select=source_url,headline,published_at&order=published_at.desc&limit=30',undefined,'GET');
  const existingEvents:Row[]=await db('release_events?kind=eq.dub&published=eq.true&select=source_url,title&limit=300',undefined,'GET');
  const known:Row[]=await db('dub_source_documents?select=source_url&limit=5000',undefined,'GET');
  const existingUrls=new Set(known.map(r=>r.source_url));
  const discovered=new Map<string,Row>();
  const discoveries:Row[]=[...[...incoming.values()].map(d=>({source_url:d.url,headline:d.headline,published_at:d.published_at})),...knownNews,...existingEvents];
  for(const r of discoveries){
    const id=articleIdentity(r.source_url);if(!id||existingUrls.has(id.url))continue;
    const doc=incoming.get(id.url);
    const priority=doc&&extractDubs(doc).some(c=>!c.reason)?3:r.title?2:doc?1:0;
    discovered.set(id.url,{source_url:id.url,source_key:id.source,headline:(r.headline??r.title??'').slice(0,500),published_at:r.published_at??null,
      next_check_at:new Date(now.getTime()-priority*3600000).toISOString()});
  }
  if(discovered.size)await db('dub_source_documents?on_conflict=source_url',[...discovered.values()]);
  report.discovered=discovered.size;
  const query=new URLSearchParams({select:'*',next_check_at:`lte.${now.toISOString()}`,watch_until:`gte.${now.toISOString()}`,order:'next_check_at.asc,source_url.asc',limit:'8'});
  const due:Row[]=await db(`dub_source_documents?${query}`,undefined,'GET');
  const matches:Row[]=await db('dub_title_matches?select=*&limit=5000',undefined,'GET');
  const identities=new Map(matches.map(m=>[m.title_key,m]));
  for(const m of reviewedDubIdentities)for(const alias of m.aliases)identities.set(titleKey(alias),m);
  let searches=0;
  async function resolve(title:string):Promise<Row|null>{
    const key=titleKey(title),cached=identities.get(key);
    if(cached?.mal_id)return cached;
    if(cached&&now.getTime()-Date.parse(cached.checked_at)<86400000)return null;
    if(searches>=3||Date.now()+5000>deadline)return null;
    searches++;
    if(searches>1)await pause(1100);
    const url=`https://api.tenrai.org/v1/anime?q=${encodeURIComponent(title)}&limit=25&sfw=true`;
    const response=await fetcher(url,{redirect:'error',headers:{'User-Agent':'AniApp/0.3.6 (+https://github.com/Tabtii/AniApp)'},signal:AbortSignal.timeout(4500)});
    if(!response.ok)throw new Error(`Title catalog HTTP ${response.status}`);
    const data=await response.json();if(!Array.isArray(data.data))throw new Error('Invalid title catalog');
    // Ambiguous/truncated result sets are not proof of a unique identity.
    const found=data.pagination?.has_next_page?null:exactAnime(title,data.data);
    const match={title_key:key,mal_id:found?.mal_id??null,title:found?.title_english??found?.title??title,
      image_url:sourceImage(found?.images?.jpg?.large_image_url,'cdn.myanimelist.net'),checked_at:now.toISOString()};
    identities.set(key,match);await db('dub_title_matches?on_conflict=title_key',match);
    return match.mal_id?match:null;
  }
  for(const watched of due){
    if(Date.now()+1500>deadline)break;
    const url=watched.source_url;
    try{
      let doc=incoming.get(url),response:Response|undefined;
      if(!doc||!doc.source.startsWith('cr_')){
        const headers:Record<string,string>={};
        if(watched.parser_version===PARSER_VERSION&&!watched.needs_review){
          if(watched.etag)headers['If-None-Match']=watched.etag;
          if(watched.last_modified)headers['If-Modified-Since']=watched.last_modified;
        }
        const readPage=await read(url,headers);response=readPage.response;
        if(response.status===304){
          await db(`dub_source_documents?source_url=eq.${encodeURIComponent(url)}`,
            {checked_at:now.toISOString(),last_attempt_at:now.toISOString(),next_check_at:new Date(now.getTime()+6*3600000).toISOString(),error:null},'PATCH');
          report.unchanged++;continue;
        }
        doc=parsePage(readPage.body,url);
      }
      if(Date.parse(doc.published_at)>now.getTime())throw new Error('Future article metadata');
      const hash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(doc.headline+'\n'+doc.body)))).map(n=>n.toString(16).padStart(2,'0')).join('');
      if(hash===watched.content_hash&&watched.parser_version===PARSER_VERSION&&!watched.needs_review)report.unchanged++;
      else{
        const extracted=extractDubs(doc),candidates:Row[]=[];
        for(const c of extracted){
          // Failed identity lookup only holds this candidate, not other sources.
          let match:Row|null=null;
          try{if(!c.reason)match=await resolve(c.title);}catch(e){report.failed.push({source:url,error:e instanceof Error?e.message:'Title unavailable'});}
          candidates.push(proposal(c,match,url));
        }
        if(!candidates.length&&/dub|synchro|\bSYNC\b/i.test(doc.headline+' '+doc.body))candidates.push({key:'article-format',evidence:doc.headline.slice(0,1200),reason:'unsupported_or_ambiguous_format',event:null});
        const grouped=new Map<string,Row>();
        for(const c of candidates){
          const old=grouped.get(c.key);
          if(old&&JSON.stringify(old.event)!==JSON.stringify(c.event))c.reason='conflicting_article_claims';
          if(old?.reason==='conflicting_article_claims')c.reason=old.reason;
          grouped.set(c.key,c);
        }
        if(grouped.size>100)throw new Error('Announcement candidate limit exceeded');
        const applied=await db('rpc/apply_dub_candidates',{p_source_url:url,p_candidates:[...grouped.values()]});
        report.published+=applied.published;report.review+=applied.review;report.conflicts+=applied.conflicts;
      }
      await db(`dub_source_documents?source_url=eq.${encodeURIComponent(url)}`,{
        headline:doc.headline.slice(0,500),published_at:doc.published_at,checked_at:now.toISOString(),last_attempt_at:now.toISOString(),
        next_check_at:new Date(now.getTime()+(doc.source.startsWith('cr_')?1:6)*3600000).toISOString(),
        content_hash:hash,parser_version:PARSER_VERSION,etag:response?.headers.get('etag')??null,last_modified:response?.headers.get('last-modified')??null,error:null},'PATCH');
      report.checked++;
    }catch(e){
      const error=e instanceof Error?e.message:'Unavailable';report.failed.push({source:url,error});
      await db(`dub_source_documents?source_url=eq.${encodeURIComponent(url)}`,{last_attempt_at:now.toISOString(),next_check_at:new Date(now.getTime()+6*3600000).toISOString(),error:error.slice(0,500)},'PATCH');
    }
  }
  return report;
}
