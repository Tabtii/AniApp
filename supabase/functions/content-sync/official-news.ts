import {cleanText,type Row} from './content.ts';
import {robotPolicy} from './adn-news.ts';
export const officialSources={
 hidive:{name:'HIDIVE',index:'https://news.hidive.com/dubs',language:'en',path:/^\/20\d\d\/\d{1,2}\/\d{1,2}\/[a-z0-9-]+\/?$/},
 netflix:{name:'Netflix Tudum',index:'https://www.netflix.com/tudum/articles/new-anime-shows-on-netflix',language:'en',path:/^\/tudum\/articles\/[a-z0-9-]+\/?$/},
 maxx:{name:'Joyn / ProSieben MAXX',index:'https://www.joyn.de/bts/themen/anime',language:'de',path:/^\/bts\/serien\/[a-z0-9-]+\/[a-z0-9-]+\/?$/},
 ann:{name:'Anime News Network',index:'https://www.animenewsnetwork.com/news/',language:'en',path:/^\/news\/20\d\d-\d\d-\d\d\/[a-z0-9_./-]+$/},
} as const;
export type OfficialKey=keyof typeof officialSources;
export function officialUrl(value:string,key:OfficialKey):string|null{
 try{const config=officialSources[key],u=new URL(cleanText(value),config.index),base=new URL(config.index);
 if(u.origin!==base.origin||u.username||u.password||u.search||!config.path.test(u.pathname))return null;
 u.hash='';return u.href;
 }catch{return null;}
}
function metadata(html:string){
 const fields:Record<string,string>={};
 for(const tag of html.matchAll(/<(meta|link)\b[^>]*>/gi)){
  const a=Object.fromEntries([...tag[0].matchAll(/([\w:-]+)\s*=\s*(["'])([\s\S]*?)\2/g)].map(m=>[m[1].toLowerCase(),cleanText(m[3])]));
  if(tag[1].toLowerCase()==='meta')fields[a.property??a.name]=a.content;
  else if(a.rel==='canonical')fields.canonical=a.href;
 }
 return fields;
}
export function parseOfficialPage(html:string,url:string,key:OfficialKey,now=new Date()):Row{
 const config=officialSources[key],id=officialUrl(url,key),m=metadata(html);
 if(!id||officialUrl(m.canonical??m['og:url']??'',key)!==id||m['og:type']!=='article')throw new Error('Article identity missing');
 const date=new Date(m['article:published_time']);
 if(!m['og:title']||!Number.isFinite(date.getTime())||date>now||now.getTime()-date.getTime()>60*86400000)throw new Error('Article date missing/stale');
 // Headlines are not dub evidence. No episode, language or territory is guessed.
 return {headline:m['og:title'].slice(0,250),summary:`${config.name} · ${config.language==='de'?'Originalmeldung öffnen':'Read the original announcement'}`,
 source_name:config.name,source_url:id,published_at:date.toISOString(),checked_at:now.toISOString(),language:config.language,
 category:/\bdub\b|synchro/i.test(m['og:title'])?'dub':'announcement',image_url:null,published:true};
}
export async function collectOfficialNews(key:OfficialKey,permission:Row|undefined,fetcher:typeof fetch=fetch,known:Row[]=[],now=new Date(),pause=(ms:number)=>new Promise(r=>setTimeout(r,ms))){
 if(permission?.status!=='approved'||permission?.ingestion_enabled!==true)return {state:'pending',rows:[] as Row[],failed:0};
 const config=officialSources[key],origin=new URL(config.index).origin;let robots='',last=0;const deadline=Date.now()+18000;
 async function read(url:string,isRobots=false){
  if(url!==config.index&&url!==origin+'/robots.txt'&&!officialUrl(url,key))throw new Error('Unapproved URL');
  const policy=robotPolicy(robots,new URL(url).pathname);if(!isRobots&&!policy.allowed)throw new Error('Robots denied');
  const delay=Math.max(0,policy.delay*1000-(Date.now()-last));if(delay>5000||Date.now()+delay>deadline)throw new Error('Budget reached');
  if(delay)await pause(delay);last=Date.now();
  const response=await fetcher(url,{redirect:'error',headers:{'User-Agent':'AniApp/0.4 (+https://github.com/Tabtii/AniApp)',Accept:'text/html, text/plain'},signal:AbortSignal.timeout(5000)});
  if(isRobots&&response.status===404)return '';
  if(!response.ok)throw new Error(`HTTP ${response.status}`);
  const reader=response.body?.getReader();if(!reader)throw new Error('No body');let body='',size=0;const decoder=new TextDecoder();
  for(;;){const {done,value}=await reader.read();if(done)break;size+=value.length;if(size>1500000){await reader.cancel();throw new Error('Too large');}body+=decoder.decode(value,{stream:true});}
  return body+decoder.decode();
 }
 robots=await read(origin+'/robots.txt',true);
 const index=await read(config.index);
 const urls=[...new Set([...index.matchAll(/\bhref=["']([^"']+)["']/gi)].map(m=>officialUrl(m[1],key)).filter((v):v is string=>!!v))].filter(url=>!known.some(n=>n.source_url===url&&now.getTime()-Date.parse(n.checked_at)<86400000)).slice(0,3);
 if(!urls.length && !known.length)throw new Error('No readable announcement links');
 const rows:Row[]=[];let failed=0;
 for(const url of urls){try{rows.push(parseOfficialPage(await read(url),url,key,now));}catch{failed++;break;}}
 return {state:failed?'degraded':'ok',rows,failed};
}
