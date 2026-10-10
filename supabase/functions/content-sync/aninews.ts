import {rssNews,sourceImage,cleanText,type Row} from './content.ts';
import {robotPolicy} from './adn-news.ts';
const origin='https://www.aninews.de';
export async function loadAniNews(fetcher:typeof fetch=fetch,known:Row[]=[],now=new Date(),pause=(ms:number)=>new Promise(r=>setTimeout(r,ms))) {
  let robots='',last=0;const deadline=Date.now()+45000;
  const read=async(path:string)=>{
    if(!['/robots.txt','/feed'].includes(path)&&!/^\/news\/\d+\/[a-z0-9-]+\/?$/.test(path))throw new Error('Unapproved AniNews path');
    const policy=robotPolicy(robots,path);
    if(!policy.allowed)throw new Error('AniNews robots disallow');
    const delay=Math.max(0,policy.delay*1000-(Date.now()-last));
    if(delay>8000||Date.now()+delay+1000>deadline)throw new Error('AniNews crawl budget');
    if(delay)await pause(delay);last=Date.now();
    const r=await fetcher(origin+path,{redirect:'error',headers:{'User-Agent':'AniApp/0.3.5 (+https://github.com/Tabtii/AniApp)'},signal:AbortSignal.timeout(Math.min(8000,deadline-Date.now()))});
    if(path==='/robots.txt'&&r.status===404)return '';
    if(!r.ok)throw new Error(`AniNews HTTP ${r.status}`);
    const reader=r.body?.getReader();if(!reader)throw new Error('Empty AniNews response');
    let size=0,text='';const decoder=new TextDecoder();
    for(;;){const {done,value}=await reader.read();if(done)break;size+=value.length;if(size>1500000){await reader.cancel();throw new Error('AniNews response too large');}text+=decoder.decode(value,{stream:true});}
    return text+decoder.decode();
  };
  robots=await read('/robots.txt');
  const incoming=rssNews(await read('/feed'),now,'AniNews').slice(0,8);
  const rows:Row[]=[],failed:string[]=[];let cached=0;
  for(const row of incoming){
    const old=known.find(r=>r.source_url===row.source_url);
    if(old&&Date.parse(old.checked_at)<=now.getTime()&&now.getTime()-Date.parse(old.checked_at)<86400000){cached++;continue;}
    try{
      const html=await read(new URL(row.source_url).pathname);
      const meta:Record<string,string>={};
      for(const tag of html.matchAll(/<meta\b[^>]*>/gi)){
        const attrs:Record<string,string>={};for(const m of tag[0].matchAll(/([\w:-]+)\s*=\s*(["'])([\s\S]*?)\2/g))attrs[m[1].toLowerCase()]=cleanText(m[3]);
        meta[attrs.property??attrs.name]=attrs.content;
      }
      if(meta['og:url']!==row.source_url||meta['og:type']!=='article'||!meta['og:locale']?.startsWith('de'))throw new Error('AniNews article mismatch');
      rows.push({...row,image_url:sourceImage(meta['og:image'],'www.aninews.de')});
    }catch(e){failed.push(row.source_url);if(/HTTP (401|403|429)/.test(String(e)))break;}
  }
  if(!rows.length&&!cached)throw new Error('No AniNews articles verified');
  return {rows,failed,cached};
}
