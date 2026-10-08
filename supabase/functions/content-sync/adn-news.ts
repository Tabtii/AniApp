import {cleanText,newsPreview,sourceImage,type Row} from './content.ts';
const origin='https://news.animationdigitalnetwork.com';
const agent='AniApp';
export function articleUrl(value:string):string|null {
  try{const u=new URL(cleanText(value),origin);
    if(u.origin!==origin||u.username||u.password||u.search||!/^\/de\/\d{4}\/\d{2}\/\d{2}\/[a-z0-9-]+\/$/.test(u.pathname))return null;
    u.hash='';return u.href;
  }catch{return null;}
}
export function discoverArticles(document:string,html=false):string[] {
  const values=html?[...document.matchAll(/\bhref\s*=\s*["']([^"']+)["']/gi)].map(m=>m[1]):
    [...document.matchAll(/<item\b[^>]*>([\s\S]*?)<\/item>/gi)].map(m=>/<link\b[^>]*>([\s\S]*?)<\/link>/i.exec(m[1])?.[1]??'');
  return [...new Set(values.map(articleUrl).filter((v):v is string=>v!==null))]
    .sort((a,b)=>b.localeCompare(a)).slice(0,8);
}
type Rule={allow:boolean;path:string};
export function robotPolicy(document:string,path:string):{allowed:boolean;delay:number} {
  const groups:{agents:string[];rules:Rule[];delay:number}[]=[];
  let group:{agents:string[];rules:Rule[];delay:number}|null=null,hasRules=false;
  for(const raw of document.split(/\r?\n/)){
    const line=raw.split('#')[0].trim(),colon=line.indexOf(':');if(colon<0)continue;
    const key=line.slice(0,colon).trim().toLowerCase(),value=line.slice(colon+1).trim();
    if(key==='user-agent'){
      if(!group||hasRules){group={agents:[],rules:[],delay:0};groups.push(group);hasRules=false;}
      group.agents.push(value.toLowerCase());
    }else if(group && ['allow','disallow','crawl-delay'].includes(key)){
      hasRules=true;
      if(key==='crawl-delay'){const n=Number(value);if(Number.isFinite(n)&&n>=0)group.delay=n;}
      else if(value)group.rules.push({allow:key==='allow',path:value});
    }
  }
  const named=groups.filter(g=>g.agents.some(a=>a!=='*'&&agent.toLowerCase().startsWith(a)));
  const chosen=named.length?named:groups.filter(g=>g.agents.includes('*'));
  const matching=chosen.flatMap(g=>g.rules).filter(r=>{
    const end=r.path.endsWith('$'),p=end?r.path.slice(0,-1):r.path;
    const pattern=p.split('*').map(s=>s.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')).join('.*');
    return new RegExp('^'+pattern+(end?'$':'')).test(path);
  }).sort((a,b)=>b.path.replace(/[*$]/g,'').length-a.path.replace(/[*$]/g,'').length||Number(b.allow)-Number(a.allow));
  return {allowed:matching[0]?.allow??true,delay:Math.max(1,...chosen.map(g=>g.delay))};
}
function attrs(tag:string):Record<string,string>{
  const a:Record<string,string>={};
  for(const m of tag.matchAll(/([\w:-]+)\s*=\s*(["'])([\s\S]*?)\2/g))a[m[1].toLowerCase()]=cleanText(m[3]);
  return a;
}
export function parseArticle(html:string,url:string,now=new Date()):Row {
  const canonical=articleUrl(url);if(!canonical)throw new Error('Unapproved article URL');
  const meta:Record<string,string>={};let declared:string|null=null;
  for(const match of html.matchAll(/<(meta|link)\b[^>]*>/gi)){
    const a=attrs(match[0]);
    if(match[1].toLowerCase()==='meta')meta[a.property??a.name]=a.content;
    else if(a.rel==='canonical')declared=a.href;
  }
  if(meta['og:type']!=='article'||!meta['og:locale']?.startsWith('de')||
      articleUrl(meta['og:url']??'')!==canonical || (declared && articleUrl(declared)!==canonical))throw new Error('Article identity/locale mismatch');
  const title=meta['og:title']?.trim(),date=new Date(meta['article:published_time']);
  if(!title||!Number.isFinite(date.getTime())||date>now||now.getTime()-date.getTime()>30*86400000)throw new Error('Missing/stale article metadata');
  const category=/synchro|\bdub\b|auf Deutsch/i.test(title)?'dub':/staffel|season|line-up/i.test(title)?'season':/stream|simulcast/i.test(title)?'streaming':'announcement';
  return {headline:title.slice(0,250),summary:newsPreview(meta['og:description']??'')||'Neue Ankündigung von ADN.',
    source_name:'ADN News',source_url:canonical,published_at:date.toISOString(),checked_at:now.toISOString(),
    image_url:sourceImage(meta['og:image'],'news.animationdigitalnetwork.com'),language:'de',category,published:true};
}
class SourceError extends Error {constructor(public status:number){super(`ADN news HTTP ${status}`);}}
export async function crawlAdnNews(fetcher:typeof fetch=fetch,known:Row[]=[],now=new Date(),pause=(ms:number)=>new Promise(r=>setTimeout(r,ms))):Promise<{rows:Row[];failed:string[];cached:number}> {
  const deadline=Date.now()+45000;
  let lastRequest=0,robots='';
  const read=async(url:string,isRobots=false):Promise<string>=>{
    const u=new URL(url);
    if(u.origin!==origin || (!isRobots && !['/de/','/de/feed/'].includes(u.pathname)&&!articleUrl(url)))throw new Error('Unapproved crawl URL');
    const policy=robotPolicy(robots,u.pathname);
    if(!isRobots && !policy.allowed)throw new Error('Disallowed by robots.txt');
    const delay=Math.max(0,policy.delay*1000-(Date.now()-lastRequest));
    if(delay>8000||Date.now()+delay+1000>deadline)throw new Error('Crawl budget exceeded');
    if(delay)await pause(delay);
    lastRequest=Date.now();
    const r=await fetcher(url,{redirect:'error',headers:{'User-Agent':'AniApp/0.3.4 (+https://github.com/Tabtii/AniApp)',Accept:'text/html, application/rss+xml, text/plain'},signal:AbortSignal.timeout(Math.min(8000,deadline-Date.now()))});
    if(!r.ok)throw new SourceError(r.status);
    const reader=r.body?.getReader();if(!reader)throw new Error('Empty response');
    const decoder=new TextDecoder();let text='',size=0;
    for(;;){const {done,value}=await reader.read();if(done)break;size+=value.length;
      if(size>1500000){await reader.cancel();throw new Error('Crawl response too large');}text+=decoder.decode(value,{stream:true});}
    return text+decoder.decode();
  };
  try{robots=await read(origin+'/robots.txt',true);}catch(e){if(!(e instanceof SourceError && e.status===404))throw e;}
  let urls:string[];
  try{
    const feed=await read(origin+'/de/feed/');
    if(!feed.includes('<rss')||/<!DOCTYPE/i.test(feed))throw new Error('Invalid ADN feed');
    urls=discoverArticles(feed);
  }catch(e){
    // A missing feed may use the public index; blocked/rate-limited requests stop.
    if(!(e instanceof SourceError && e.status===404))throw e;
    urls=discoverArticles(await read(origin+'/de/'),true);
  }
  if(!urls.length)throw new Error('No article URLs found');
  const rows:Row[]=[],failed:string[]=[];let cached=0;
  for(const url of urls){
    if(known.some(r=>r.source_url===url && now.getTime()-Date.parse(r.checked_at)<86400000 && Date.parse(r.checked_at)<=now.getTime())){cached++;continue;}
    try{rows.push(parseArticle(await read(url),url,now));}
    catch(e){failed.push(url);if(e instanceof SourceError && [401,403,429].includes(e.status))break;}
  }
  return {rows,failed,cached};
}
