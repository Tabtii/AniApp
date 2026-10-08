export type Row = Record<string, any>;
const days = ['Sundays','Mondays','Tuesdays','Wednesdays','Thursdays','Fridays','Saturdays'];
export function broadcastEvents(anime: Row[], now = new Date()): Row[] {
  const result: Row[] = [];
  const jst = new Date(now.getTime() + 9 * 3600000);
  for (const a of anime) {
    const b = a.broadcast, day = days.indexOf(b?.day);
    if (!a.airing || !Number.isInteger(a.mal_id) || a.mal_id <= 0 || day < 0 || b.timezone !== 'Asia/Tokyo' || !/^([01]\d|2[0-3]):[0-5]\d$/.test(b.time ?? '')) continue;
    if (!a.title || (a.explicit_genres?.length ?? 0) > 0) continue;
    const [h,m] = b.time.split(':').map(Number);
    let time = Date.UTC(jst.getUTCFullYear(),jst.getUTCMonth(),jst.getUTCDate(),h,m) - 9 * 3600000;
    time += ((day - jst.getUTCDay() + 7) % 7) * 86400000;
    if (time < now.getTime()) time += 7 * 86400000;
    const end = Date.parse(a.aired?.to ?? '');
    if (Number.isFinite(end) && time > end + 86400000) continue;
    result.push({mal_id:a.mal_id,title:a.title_english || a.title,episode:null,kind:'japan',starts_at:new Date(time).toISOString(),provider:'Tenrai / MyAnimeList',region:'JP',audio_language:'ja',status:'estimated',source_url:`https://myanimelist.net/anime/${a.mal_id}`,checked_at:now.toISOString(),published:true});
  }
  return [...new Map(result.map(r=>[r.mal_id,r])).values()];
}
export function cleanText(text: string): string {
  return text.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g,'$1').replace(/<[^>]*>/g,' ').replace(/&(#x[\da-f]+|#\d+|amp|lt|gt|quot|apos|nbsp);/gi,(_,k:string)=> {
    const named:Record<string,string>={amp:'&',lt:'<',gt:'>',quot:'"',apos:"'",nbsp:' '};
    if (k[0] !== '#') return named[k.toLowerCase()] ?? '';
    const n=k[1].toLowerCase()==='x'?parseInt(k.slice(2),16):parseInt(k.slice(1),10);
    return n>0 && n<=0x10ffff?String.fromCodePoint(n):'';
  }).replace(/\s+/g,' ').trim();
}
function category(title:string) {
  if (/synchro|\bdub\b/i.test(title)) return 'dub';
  if (/staffel|season/i.test(title)) return 'season';
  if (/stream|crunchyroll|netflix|simulcast|\bADN\b/i.test(title)) return 'streaming';
  return 'announcement';
}
export function rssNews(xml:string, now=new Date()):Row[] {
  if (!xml.includes('<rss') || xml.length>2000000 || /<!DOCTYPE/i.test(xml)) throw new Error('Invalid RSS document');
  const items=[...xml.matchAll(/<item\b[^>]*>([\s\S]*?)<\/item>/g)];
  const get=(item:string,tag:string)=>cleanText(new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`).exec(item)?.[1] ?? '');
  const rows:Row[]=[];
  for(const match of items.slice(0,40)) {
    const headline=get(match[1],'title'), link=get(match[1],'link'), date=new Date(get(match[1],'pubDate'));
    let url:URL; try {url=new URL(link);} catch {continue;}
    if(url.protocol!=='https:' || url.hostname!=='www.anime2you.de' || !url.pathname.startsWith('/news/') || !headline || !Number.isFinite(date.getTime()) || date>now || now.getTime()-date.getTime()>30*86400000) continue;
    rows.push({headline:headline.slice(0,250),summary:'Meldung von Anime2You. Den vollständigen Artikel findest du über „Original lesen“.',category:category(headline),source_name:'Anime2You',source_url:url.href,published_at:date.toISOString(),checked_at:now.toISOString(),published:true,language:'de'});
  }
  if (!rows.length) throw new Error('RSS has no recent news');
  return rows;
}
export function malNews(data:Row[],now=new Date()):Row[] {
  return data.flatMap(n=> {
    const date=new Date(n.date); let url:URL; try {url=new URL(n.url);} catch{return [];}
    if(url.protocol!=='https:' || url.hostname!=='myanimelist.net' || !url.pathname.startsWith('/news/') || typeof n.title!=='string' || !Number.isFinite(date.getTime()) || date>now || now.getTime()-date.getTime()>30*86400000) return [];
    return [{headline:cleanText(n.title).slice(0,250),summary:'Internationale Anime-Meldung von MyAnimeList. Der Originalartikel ist auf Englisch.',category:category(n.title),source_name:'MyAnimeList',source_url:url.href,published_at:date.toISOString(),checked_at:now.toISOString(),published:true,language:'en'}];
  });
}
