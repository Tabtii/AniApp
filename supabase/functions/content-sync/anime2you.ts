import {cleanText,rssNews,sourceImage,type Row} from './content.ts';
import {announcementReader,articleIdentity,SourceError} from './dub-sources.ts';

export const ANIME2YOU_RETENTION_DAYS=30;
export const ANIME2YOU_LINK_TEXT='Originalmeldung auf Anime2You lesen.';
const origin='https://www.anime2you.de';
const articleKey=(url:string)=>new URL(url).pathname.split('/')[2];
const retained=(row:Row,now:Date)=>Number.isFinite(Date.parse(row.published_at))&&
  Date.parse(row.published_at)<=now.getTime()&&Date.parse(row.published_at)>=now.getTime()-ANIME2YOU_RETENTION_DAYS*86400000;

// Use only publisher-authored metadata, never an article-body excerpt or an AI summary.
export function anime2youMetadata(html:string,url:string,now=new Date()):Row {
  const id=articleIdentity(url);
  if(id?.source!=='anime2you')throw new Error('Invalid Anime2You article URL');
  const head=/<head\b[^>]*>([\s\S]*?)<\/head>/i.exec(html)?.[1]??html;
  const meta:Record<string,string>={};let canonical='';
  for(const tag of head.matchAll(/<(meta|link)\b[^>]*>/gi)){
    const a=Object.fromEntries([...tag[0].matchAll(/([\w:-]+)\s*=\s*(["'])([\s\S]*?)\2/g)].map(m=>[m[1].toLowerCase(),cleanText(m[3])]));
    if(tag[1].toLowerCase()==='meta')meta[(a.name??a.property??'').toLowerCase()]=a.content;
    else if(a.rel==='canonical')canonical=a.href;
  }
  if(articleIdentity(canonical||meta['og:url'])?.url!==id.url||meta['og:type']!=='article')throw new Error('Article identity missing/mismatched');
  const row={published_at:meta['article:published_time']};
  if(!meta['og:title']||!retained(row,now))throw new Error('Article metadata missing/stale');
  const description=meta.description||meta['og:description'];
  const valid=!!description&&description.length<=1500;
  return {headline:meta['og:title'].slice(0,250),published_at:new Date(row.published_at).toISOString(),
    summary:valid?description:ANIME2YOU_LINK_TEXT,preview_kind:valid?'publisher_meta':'link_only',
    image_url:sourceImage(meta['og:image'],new URL(origin).hostname)};
}

export async function collectAnime2You(permission:Row|undefined,known:Row[]=[],fetcher:typeof fetch=fetch,now=new Date(),pause=(ms:number)=>new Promise(r=>setTimeout(r,ms))){
  if(permission?.status!=='approved'||permission.ingestion_enabled!==true)return {state:'permission_pending',rows:[] as Row[],removed:[] as string[],checked:0,failed:[] as Row[]};
  const deadline=Date.now()+45000,read=announcementReader(fetcher,deadline,pause,true);
  const feed=rssNews((await read(origin+'/feed/')).body,now);
  const byArticle=new Map<string,Row>(),duplicates:string[]=[];
  for(const row of known){
    if(row.source_name!=='Anime2You'||articleIdentity(row.source_url)?.source!=='anime2you'||!retained(row,now))continue;
    const key=articleKey(row.source_url);
    if(byArticle.has(key)){duplicates.push(row.source_url);continue;}
    byArticle.set(key,row);
  }
  const previous=new Map([...byArticle.values()].map(r=>[r.source_url,r]));
  const rows=new Map<string,Row>();
  for(const row of feed){
    const old=byArticle.get(articleKey(row.source_url));
    const source_url=old?.source_url??row.source_url;
    rows.set(source_url,{...row,source_url,summary:old?.preview_kind==='publisher_meta'?old.summary:ANIME2YOU_LINK_TEXT,
      preview_kind:old?.preview_kind==='publisher_meta'?'publisher_meta':'link_only',
      metadata_checked_at:old?.metadata_checked_at??null,metadata_attempt_at:old?.metadata_attempt_at??null,
      metadata_etag:old?.metadata_etag??null,metadata_last_modified:old?.metadata_last_modified??null});
  }
  // Rotate through retained articles as well as the current feed, so corrections
  // are still picked up after a headline leaves the feed. No full article is saved.
  const candidates=new Map([...previous,...rows]);
  const due=[...candidates.values()].sort((a,b)=>(Date.parse(a.metadata_attempt_at)||0)-(Date.parse(b.metadata_attempt_at)||0)||Date.parse(b.published_at)-Date.parse(a.published_at)).slice(0,25);
  const removed:string[]=[...duplicates],failed:Row[]=[];let checked=0;
  for(const row of due){
    if(Date.now()+1500>deadline)break;
    const headers:Record<string,string>={};
    if(row.metadata_checked_at){
      if(row.metadata_etag)headers['If-None-Match']=row.metadata_etag;
      if(row.metadata_last_modified)headers['If-Modified-Since']=row.metadata_last_modified;
    }
    try{
      const result=await read(row.source_url,headers);
      const metadata=result.response.status===304?{}:anime2youMetadata(result.body,result.url,now);
      if(result.response.status===304&&!row.metadata_checked_at)throw new Error('Unexpected not-modified response');
      // Keep the original source identity for existing calendar references. Its
      // publisher redirect resolves to the same article ID, never another story.
      rows.set(row.source_url,{...row,...metadata,checked_at:now.toISOString(),metadata_checked_at:now.toISOString(),metadata_attempt_at:now.toISOString(),
        metadata_etag:result.response.headers.get('etag')??row.metadata_etag??null,
        metadata_last_modified:result.response.headers.get('last-modified')??row.metadata_last_modified??null});
      checked++;
    }catch(e){
      if(e instanceof SourceError&&[404,410].includes(e.status)){rows.delete(row.source_url);removed.push(row.source_url);continue;}
      failed.push({source:row.source_url,error:e instanceof Error?e.message:'Metadata unavailable'});
      rows.set(row.source_url,{...row,metadata_attempt_at:now.toISOString()});
      if(e instanceof SourceError&&[401,403,429].includes(e.status))break;
    }
  }
  return {state:failed.length?'degraded':'ok',rows:[...rows.values()].map(r=>({
    headline:r.headline,summary:r.summary,category:r.category,source_name:'Anime2You',source_url:r.source_url,
    published_at:r.published_at,checked_at:r.checked_at,published:true,language:'de',
    image_url:permission.images_allowed?r.image_url:null,preview_kind:r.preview_kind,
    metadata_checked_at:r.metadata_checked_at??null,metadata_attempt_at:r.metadata_attempt_at??null,
    metadata_etag:r.metadata_etag??null,metadata_last_modified:r.metadata_last_modified??null,
  })),removed,checked,failed};
}
