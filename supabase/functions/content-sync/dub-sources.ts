import {robotPolicy} from './adn-news.ts';
import {newsPreview,sourceImage,type Row} from './content.ts';
import {text,type Document,type DubSource} from './dub-parser.ts';

export const feeds = [
  {source:'cr_de',url:'https://cr-news-api-service.prd.crunchyrollsvc.com/v1/de-DE/rss'},
  {source:'cr_en',url:'https://cr-news-api-service.prd.crunchyrollsvc.com/v1/en-US/rss'},
  {source:'anime2you',url:'https://www.anime2you.de/feed/'},
  {source:'aninews',url:'https://www.aninews.de/feed'},
] as const;
export function articleIdentity(value:string):{url:string;source:DubSource}|null {
  try{
    const u=new URL(text(value));
    if(u.protocol!=='https:'||u.username||u.password||u.port||u.search)return null;
    u.hash='';
    if(['crunchyroll.com','www.crunchyroll.com'].includes(u.hostname)&&/^\/(?:(?:de|en)\/)?news\/[a-z-]+\/20\d\d\/\d{1,2}\/\d{1,2}\/[a-z0-9-]+\/?$/.test(u.pathname)){
      u.hostname='www.crunchyroll.com';return {url:u.href,source:u.pathname.startsWith('/de/')?'cr_de':'cr_en'};
    }
    if(u.hostname==='news.animationdigitalnetwork.com'&&/^\/de\/20\d\d\/\d{2}\/\d{2}\/[a-z0-9-]+\/$/.test(u.pathname))return {url:u.href,source:'adn'};
    if(['www.anime2you.de','www.aninews.de'].includes(u.hostname)&&/^\/news\/\d+\/[a-z0-9-]+\/?$/.test(u.pathname))return {url:u.href,source:u.hostname==='www.anime2you.de'?'anime2you':'aninews'};
  }catch{/* A URL from an article is data, never an arbitrary fetch target. */}
  return null;
}
export function parseFeed(xml:string,source:DubSource,now=new Date()):Document[] {
  if(!/<rss\b/i.test(xml)||/<!DOCTYPE|<!ENTITY/i.test(xml))throw new Error('Invalid announcement feed');
  const rows:Document[]=[];
  for(const match of [...xml.matchAll(/<item\b[^>]*>([\s\S]*?)<\/item>/gi)].slice(0,60)){
    const item=match[1],field=(name:string)=>new RegExp(`<${name}\\b[^>]*>([\\s\\S]*?)<\\/${name}>`,'i').exec(item)?.[1]??'';
    const id=articleIdentity(field('link')),headline=text(field('title')),date=new Date(text(field('pubDate')));
    if(!id||id.source!==source||!headline||!Number.isFinite(date.getTime())||date>now||now.getTime()-date.getTime()>45*86400000)continue;
    const body=field('content:encoded').replace(/^\s*<!\[CDATA\[|\]\]>\s*$/g,'')||field('description').replace(/^\s*<!\[CDATA\[|\]\]>\s*$/g,'');
    const image=/<media:thumbnail\b[^>]*url=["']([^"']+)["']/i.exec(item)?.[1];
    rows.push({url:id.url,source,headline,published_at:date.toISOString(),body,
      image_url:sourceImage(image,'a.storyblok.com')});
  }
  return rows;
}
export function feedNews(doc:Document,now=new Date()):Row {
  return {headline:doc.headline.slice(0,250),summary:newsPreview(doc.body)||doc.headline.slice(0,200),source_name:'Crunchyroll News',
    source_url:doc.url,published_at:doc.published_at,checked_at:now.toISOString(),image_url:doc.image_url??null,
    language:doc.source==='cr_de'?'de':'en',category:/dub|synchro/i.test(doc.headline)?'dub':'announcement',published:true};
}
function attributes(tag:string):Record<string,string>{
  return Object.fromEntries([...tag.matchAll(/([\w:-]+)\s*=\s*(["'])([\s\S]*?)\2/g)].map(m=>[m[1].toLowerCase(),text(m[3])]));
}
function contentDiv(html:string):string|null {
  const start=/<div\b[^>]*class=["'][^"']*\b(?:entry-content|td-post-content)\b[^"']*["'][^>]*>/i.exec(html);
  if(!start)return null;
  const rest=html.slice(start.index+start[0].length);let depth=1;
  for(const t of rest.matchAll(/<\/?div\b[^>]*>/gi)){
    depth+=t[0].startsWith('</')?-1:1;
    if(depth===0)return rest.slice(0,t.index);
  }
  throw new Error('Incomplete article body');
}
// Page-declared URL for the error column: host and path only, restricted characters.
function declaredPath(value:string):string {
  try{const u=new URL(value);return (u.hostname+u.pathname+(u.search?'?…':'')).replace(/[^\w./:?…-]/g,'').slice(0,120);}
  catch{return 'unparseable';}
}
export class ArticleGone extends Error {}
export function parsePage(html:string,url:string):Document {
  const id=articleIdentity(url);if(!id)throw new Error('Unapproved announcement URL');
  const meta:Record<string,string>={};let canonical='';
  for(const m of html.matchAll(/<(meta|link)\b[^>]*>/gi)){
    const a=attributes(m[0]);if(m[1].toLowerCase()==='meta')meta[a.property??a.name]=a.content;
    else if(a.rel==='canonical')canonical=a.href;
  }
  // Distinct reasons, so the source status shows what changed on the page.
  const declared=canonical||meta['og:url'];
  if(!declared)throw new Error('Article identity missing (no canonical/og:url)');
  // Relative URLs and a differing trailing slash still name the same article.
  let resolved='';try{resolved=new URL(declared,url).href;}catch{/* reported below */}
  const bare=(v?:string)=>v?.replace(/\/$/,'');
  // Crunchyroll serves removed articles as its news index; that is not a source fault.
  if(id.source.startsWith('cr_')&&/^https:\/\/(?:www\.)?crunchyroll\.com\/(?:(?:de|en)\/)?news\/?$/.test(resolved))throw new ArticleGone('Article removed (canonical points to news index)');
  if(bare(articleIdentity(resolved)?.url)!==bare(id.url))throw new Error(`Article identity mismatched (${declaredPath(resolved)})`);
  if(meta['og:type']!=='article')throw new Error(`Article type unexpected (${String(meta['og:type']??'none').slice(0,40)})`);
  const date=new Date(meta['article:published_time']);
  if(!meta['og:title']||!Number.isFinite(date.getTime()))throw new Error('Article metadata missing');
  const stripped=html.replace(/<(script|style)\b[^>]*>[\s\S]*?<\/\1>/gi,'');
  let body=contentDiv(stripped);
  if(!body&&id.source.startsWith('cr_'))body=/<article\b[^>]*>([\s\S]*?)<\/article>/i.exec(stripped)?.[1]??null;
  if(!body||text(body).length<100)throw new Error('Readable article body unavailable');
  return {...id,headline:meta['og:title'],published_at:date.toISOString(),body};
}
export class SourceError extends Error {constructor(public status:number){super(`Announcement HTTP ${status}`);}}
export function announcementReader(fetcher:typeof fetch=fetch,deadline=Date.now()+40000,pause=(ms:number)=>new Promise(r=>setTimeout(r,ms)),anime2youRedirects=false){
  const robots=new Map<string,string>(),last=new Map<string,number>(),blocked=new Set<string>();
  async function request(url:string,headers:Record<string,string>={}){
    if(Date.now()+250>deadline)throw new Error('Announcement crawl budget exhausted');
    const response=await fetcher(url,{redirect:anime2youRedirects?'manual':'error',headers:{'User-Agent':'AniApp/0.3.6 (+https://github.com/Tabtii/AniApp)',Accept:'application/rss+xml, text/html, text/plain',...headers},signal:AbortSignal.timeout(Math.min(6000,deadline-Date.now()))});
    if(response.status===304||[301,302,303,307,308].includes(response.status))return {response,body:'',url};
    if(!response.ok)throw new SourceError(response.status);
    const reader=response.body?.getReader();if(!reader)throw new Error('Empty announcement response');
    const decoder=new TextDecoder();let size=0,body='';
    for(;;){const {value,done}=await reader.read();if(done)break;size+=value.length;if(size>1500000){await reader.cancel();throw new Error('Announcement response too large');}body+=decoder.decode(value,{stream:true});}
    return {response,body:body+decoder.decode(),url};
  }
  return async function read(url:string,headers:Record<string,string>={},redirects=0):Promise<{response:Response;body:string;url:string}>{
    const allowed=feeds.some(f=>f.url===url)||articleIdentity(url)?.url===url;
    if(!allowed)throw new Error('Unapproved announcement fetch');
    const u=new URL(url);if(blocked.has(u.origin))throw new Error('Source blocked for this run');
    try{
      // These two explicitly published RSS subscriptions are not website crawl
      // paths. Their API host has no public /robots.txt route (API Gateway returns
      // "Missing Authentication Token" there). Read ONLY the allowlisted feeds;
      // a 401/403/429 from the feed itself still stops this origin. Article pages
      // below retain their robots policy and never use an API/proxy workaround.
      if(feeds.some(f=>f.source.startsWith('cr_')&&f.url===url)){
        const wait=Math.max(0,1000-(Date.now()-(last.get(u.origin)??0)));
        if(wait)await pause(wait);last.set(u.origin,Date.now());
        return await request(url,headers);
      }
      if(!robots.has(u.origin)){
        try{robots.set(u.origin,(await request(u.origin+'/robots.txt')).body);}
        catch(e){if(e instanceof SourceError&&e.status===404)robots.set(u.origin,'');else throw e;}
        last.set(u.origin,Date.now());
      }
      const policy=robotPolicy(robots.get(u.origin)!,u.pathname);
      if(!policy.allowed)throw new Error('Source robots.txt disallows this path');
      const wait=Math.max(0,policy.delay*1000-(Date.now()-(last.get(u.origin)??0)));
      if(wait>8000||Date.now()+wait+250>deadline)throw new Error('Announcement crawl budget exhausted');
      if(wait)await pause(wait);last.set(u.origin,Date.now());
      const result=await request(url,headers);
      if([301,302,303,307,308].includes(result.response.status)){
        const target=new URL(result.response.headers.get('location')??'',url).href;
        const from=articleIdentity(url),to=articleIdentity(target);
        const articleId=(value:string)=>new URL(value).pathname.split('/')[2];
        if(!anime2youRedirects||redirects>=2||from?.source!=='anime2you'||to?.source!=='anime2you'||articleId(url)!==articleId(target)||target===url)throw new Error('Unapproved article redirect');
        // Re-enter normal origin, robots, rate and budget checks for every hop.
        return await read(to.url,headers,redirects+1);
      }
      return result;
    }catch(e){if(e instanceof SourceError&&[401,403,429].includes(e.status))blocked.add(u.origin);throw e;}
  };
}
