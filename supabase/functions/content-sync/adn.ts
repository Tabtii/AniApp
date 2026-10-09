import {sourceImage, type Row} from './content.ts';

// Reviewed show + season mappings, 2026-10-08. Never match by fuzzy title or
// reuse a series ID for a later season. New/unmapped titles are reported.
export const adnMappings = [
  {show:1381,season:'1',mal:60153,title:'Rilakkuma'},
  {show:1311,season:'2',mal:63181,title:'Tougen Anki: Nikko Kegon Falls Arc'},
  {show:970,season:'2',mal:53913,title:'Reincarnated as a Sword · Staffel 2'},
  {show:1431,season:'1',mal:63382,title:'Nia Liston: The Merciless Maiden'},
  {show:1433,season:'1',mal:61140,title:'Suikoden: The Anime'},
  {show:1432,season:'1',mal:63367,title:'Dragon Ball Super: Beerus'},
  {show:197,season:null,mal:1686,title:'Bleach: Memories of Nobody'},
  {show:198,season:null,mal:2889,title:'Bleach: The DiamondDust Rebellion'},
  {show:352,season:null,mal:4835,title:'Bleach: Fade to Black'},
  {show:361,season:null,mal:8247,title:'Bleach: Hell Verse'},
  // Additional identities checked against official ADN descriptions and MAL, 2026-10-09.
  {show:213,season:'1',mal:440,title:'Revolutionary Girl Utena',catalog:true},
  {show:1338,season:null,mal:441,title:'Revolutionary Girl Utena – The Movie'},
  {show:1319,season:null,mal:11977,title:'Puella Magi Madoka Magica – Film 1: Beginnings'},
  {show:1434,season:'1',mal:64717,title:'Yuusanchi! from Yuu-hachi'},
];
export const adnHeaders = {'x-target-distribution':'de','Accept-Language':'de','x-i18n-platform':'1'};
export function berlinDay(date:Date):string {
  return new Intl.DateTimeFormat('sv-SE',{timeZone:'Europe/Berlin',year:'numeric',month:'2-digit',day:'2-digit'}).format(date);
}
export function adnDays(value:Row,now=new Date()):string[] {
  if(!Array.isArray(value.dateRules) || value.dateRules.some((d:unknown)=>typeof d!=='string' || !/^\d{4}-\d{2}-\d{2}$/.test(d))) throw new Error('Invalid ADN calendar dates');
  const first=berlinDay(now),last=berlinDay(new Date(now.getTime()+14*86400000));
  return [...new Set<string>(value.dateRules)].filter(d=>d>=first&&d<=last).sort();
}
export function adnEvents(value:Row,day:string,now=new Date()) {
  if(!Array.isArray(value.videos)) throw new Error('Invalid ADN videos');
  const rows:Row[]=[]; const unmapped=new Set<string>();
  let localVideos=0;
  for(const video of value.videos) {
    const show=video.show;
    // Locale headers alone are insufficient: the API sometimes returns French
    // records. Require both a German distribution and a German episode URL.
    if(!show || show.distributions!=='de') continue;
    const source=sourceImage(video.url,'animationdigitalnetwork.com');
    if(!source || !new URL(source).pathname.startsWith(`/de/video/${show.id}-`)) continue;
    localVideos++;
    const mapping=adnMappings.find(m=>m.show===show.id && m.season===(video.season??null));
    if(!mapping){unmapped.add(`${show.id}:${video.season??''}`);continue;}
    const date=new Date(video.releaseDate);
    if(!/^\d{4}-\d{2}-\d{2}T.*(?:Z|[+-]\d\d:\d\d)$/.test(video.releaseDate??'') || !Number.isFinite(date.getTime()) || berlinDay(date)!==day) throw new Error('Invalid ADN release timestamp');
    const episode=video.type==='MOV'?null:/^[1-9]\d*$/.test(video.shortNumber??'')?Number(video.shortNumber):null;
    if(video.type!=='MOV'&&episode===null)continue;
    const languages=Array.isArray(video.languages)?video.languages:[];
    // A planned catalog addition is not the premiere of a newly produced dub.
    const note=video.type==='MOV'?'Film · Aufnahme in den ADN-Katalog':mapping.catalog?'Aufnahme in den ADN-Katalog':null;
    const image=[show.image2x,show.image].map(v=>sourceImage(v,'image.animationdigitalnetwork.com')??sourceImage(v,'media.animationdigitalnetwork.com')).find(Boolean)??null;
    const base={mal_id:mapping.mal,title:mapping.title,episode,starts_at:date.toISOString(),starts_on:null,provider:'ADN',region:'DE',status:'confirmed',source_url:source,image_url:image,checked_at:now.toISOString(),published:true};
    if(languages.includes('vde')) rows.push({...base,kind:'dub',audio_language:'de',release_note:note??'Deutsche Fassung laut ADN-Folgenkalender.'});
    if(languages.includes('vostde')) rows.push({...base,kind:'streaming',audio_language:'ja',release_note:note?`${note} · Japanisch mit deutschen Untertiteln`:'Japanisch mit deutschen Untertiteln.'});
    if(!languages.includes('vde')&&!languages.includes('vostde')) rows.push({...base,kind:'streaming',audio_language:null,release_note:'Sprachfassung im ADN-Kalender noch nicht angegeben.'});
  }
  if(value.videos.length && !localVideos) throw new Error('ADN returned no verified German records');
  return {rows:[...new Map(rows.map(r=>[`${r.source_url}|${r.kind}|${r.audio_language}`,r])).values()],unmapped:[...unmapped]};
}

export async function loadAdn(fetchSource:(url:string,headers?:Record<string,string>)=>Promise<string>,now=new Date()) {
  const days=adnDays(JSON.parse(await fetchSource('https://gw.api.animationdigitalnetwork.com/video/calendar/rule',adnHeaders)),now);
  if(!days.length) throw new Error('ADN has no upcoming calendar dates');
  const rows:Row[]=[],accepted:string[]=[],failed:Row[]=[],unmapped=new Set<string>();
  // At most three public requests concurrently; no credentials/player requests.
  for(let i=0;i<days.length;i+=3) {
    const batch=await Promise.allSettled(days.slice(i,i+3).map(async day=>({day,...adnEvents(JSON.parse(await fetchSource(`https://gw.api.animationdigitalnetwork.com/video/calendar?date=${day}`,adnHeaders)),day,now)})));
    for(let j=0;j<batch.length;j++) {
      const result=batch[j];
      if(result.status==='fulfilled'){accepted.push(result.value.day);rows.push(...result.value.rows);result.value.unmapped.forEach(m=>unmapped.add(m));}
      else failed.push({day:days[i+j],error:result.reason instanceof Error?result.reason.message:'Unavailable'});
    }
  }
  if(!accepted.length)throw new Error('No valid ADN calendar pages');
  return {rows,days:accepted,failed,unmapped:[...unmapped]};
}

// Upsert first, then unpublish stale provider entries only for complete days.
// This uses existing service-role permissions and leaves manual news-source
// announcements untouched. A failed cleanup is reported and retried next hour.
export async function saveAdn(data:Awaited<ReturnType<typeof loadAdn>>,write:(path:string,body:unknown,method?:string)=>Promise<unknown>) {
  if(!data.days.length)return;
  const checkedAt=new Date().toISOString();
  if(data.rows.length)await write('release_events?on_conflict=mal_id,episode,kind,provider,region,audio_language,source_url',data.rows.map(r=>({...r,checked_at:checkedAt})));
  const midnight=(day:string)=>{
    const utc=new Date(`${day}T00:00:00Z`);
    const hours=Number(new Intl.DateTimeFormat('en-GB',{timeZone:'Europe/Berlin',hour:'2-digit',hourCycle:'h23'}).format(utc));
    return new Date(utc.getTime()-hours*3600000).toISOString();
  };
  const ranges=data.days.map(day=>{
    const next=new Date(Date.parse(`${day}T00:00:00Z`)+86400000).toISOString().slice(0,10);
    return `and(starts_at.gte.${midnight(day)},starts_at.lt.${midnight(next)})`;
  });
  const params=new URLSearchParams({provider:'eq.ADN',region:'eq.DE',source_url:'like.https://animationdigitalnetwork.com/de/video/*',checked_at:`lt.${checkedAt}`,or:`(${ranges.join(',')})`});
  await write(`release_events?${params}`,{published:false},'PATCH');
}
