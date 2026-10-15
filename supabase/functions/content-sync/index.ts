import {collectOfficialNews,officialSources,type OfficialKey} from './official-news.ts';
import {collectAnime2You} from './anime2you.ts';
import {loadAdn,saveAdn} from './adn.ts';
import {crawlAdnNews} from './adn-news.ts';
import {reviewedPauses} from './reviewed-pauses.ts';
import {loadAniNews} from './aninews.ts';
import {syncDubAnnouncements} from './dub-sync.ts';
import {broadcastEvents, malNews, type Row} from './content.ts';
import {blockedSources} from '../_shared/source-rights.ts';
const url=Deno.env.get('SUPABASE_URL')!;
const secret=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
async function db(path:string,body:unknown,method='POST') {
  const r=await fetch(`${url}/rest/v1/${path}`,{method,headers:{apikey:secret,Authorization:`Bearer ${secret}`,'Content-Type':'application/json',Prefer:'resolution=merge-duplicates'},body:JSON.stringify(body),signal:AbortSignal.timeout(12000)});
  if(!r.ok) throw new Error(`Database ${r.status}: ${(await r.text()).slice(0,240)}`);
  const t=await r.text();return t?JSON.parse(t):null;
}
async function source(url:string,headers:Record<string,string>={}) {
  const r=await fetch(url,{headers:{Accept:'application/json, application/rss+xml', 'User-Agent':'AniApp/0.3.4 (+https://github.com/Tabtii/AniApp)',...headers},signal:AbortSignal.timeout(18000)});
  if(!r.ok) throw new Error(`Source HTTP ${r.status}`);
  const text=await r.text();if(text.length>2500000) throw new Error('Source too large'); return text;
}
Deno.serve(async req=> {
  const reply=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{'Content-Type':'application/json'}});
  if(req.method!=='POST') return reply({error:'POST required'},405);
  const token=req.headers.get('x-sync-token');
  if(!token || token.length>100) return reply({error:'Unauthorized'},401);
  let scope:string;
  try{const body=await req.json();scope=body?.scope??'all';}catch{return reply({error:'Invalid JSON'},400);}
  if(!['all','anime2you'].includes(scope))return reply({error:'Invalid scope'},400);
  let claim;
  try{claim=await db('rpc/begin_content_sync',{p_token:token});}catch{return reply({error:'Sync unavailable'},503);}
  if(claim==='denied') return reply({error:'Unauthorized'},401);
  if(claim!=='ready') return reply({status:'already_running_or_recent'},202);
  const report:Record<string,unknown>={};
  let successes=0;
  // Sources fail independently; existing published data survives failed imports.
  // Quarter-hour jobs refresh only Anime2You; other providers keep hourly cadence.
  const sources=scope==='anime2you'?['anime2you']:['anime2you','myanimelist','schedule','adn','adn_news','aninews','dub_announcements'];
  try{report.anime2you_retention=await db('rpc/prune_anime2you_content',{});}catch{return reply({error:'Content retention unavailable'},503);}
  // Kill switch: test-phase sources stop as soon as the register marks them blocked.
  const registerKey:Record<string,string>={myanimelist:'tenrai',schedule:'tenrai',adn:'adn',adn_news:'adn'};
  let blocked:Set<string>;
  try{blocked=blockedSources(await db('source_rights?select=source_key,status',undefined,'GET'));}catch{return reply({error:'Source register unavailable'},503);}
  for(const name of sources) {
    if(registerKey[name]&&blocked.has(registerKey[name])){report[name]={state:'blocked'};successes++;continue;}
    try {
      if(name==='anime2you') {
        const rights=await db('source_rights?source_key=eq.anime2you&select=*',undefined,'GET');
        const known=await db('news?source_name=eq.Anime2You&select=*&order=published_at.desc&limit=1000',undefined,'GET');
        const result=await collectAnime2You(rights[0],known);
        if(result.rows.length)await db('news?on_conflict=source_url',result.rows);
        for(const url of result.removed)await db(`news?source_name=eq.Anime2You&source_url=eq.${encodeURIComponent(url)}`,undefined,'DELETE');
        report[name]={state:result.state,count:result.rows.length,metadata_checked:result.checked,removed:result.removed.length,failed:result.failed};
      } else if(name==='myanimelist') {
        const value=JSON.parse(await source('https://api.tenrai.org/v1/news?limit=15'));
        if(!Array.isArray(value.data))throw new Error('Invalid news response');
        const rows=malNews(value.data);if(!rows.length)throw new Error('No recent news');
        await db('news?on_conflict=source_url',rows);report[name]={count:rows.length};
      } else if(name==='aninews') {
        const rights=await db('source_rights?source_key=eq.aninews&select=status,ingestion_enabled',undefined,'GET');
        const known=await db('news?source_name=eq.AniNews&select=source_url,checked_at&limit=100',undefined,'GET');
        const data=await loadAniNews(rights[0],fetch,known);
        if(data.rows.length)await db('news?on_conflict=source_url',data.rows);
        report[name]={...('state' in data?{state:data.state}:{}),count:data.rows.length,cached:data.cached,failed:data.failed};
      } else if(name==='adn_news') {
        const known=await db('news?source_name=eq.ADN%20News&select=source_url,checked_at&order=checked_at.desc&limit=100',undefined,'GET');
        const data=await crawlAdnNews(fetch,known);
        if(data.rows.length)await db('news?on_conflict=source_url',data.rows);
        report[name]={count:data.rows.length,cached:data.cached,failed:data.failed};
        if(!data.rows.length && !data.cached)throw new Error('No ADN news imported');
      } else if(name==='dub_announcements') {
        report[name]=await syncDubAnnouncements(db);
      } else if(name==='adn') {
        const data=await loadAdn(source);
        await saveAdn(data,db);
        report[name]={count:data.rows.length,days:data.days.length,failed:data.failed,unmapped:data.unmapped};
      } else {
        const all:Row[]=[];let complete=false;
        for(let page=1;page<=8;page++) {
          const value=JSON.parse(await source(`https://api.tenrai.org/v1/schedules?sfw=true&limit=50&page=${page}`));
          if(!Array.isArray(value.data))throw new Error('Invalid schedule response');
          all.push(...value.data);
          if(!value.pagination?.has_next_page){complete=true;break;}
          await new Promise(r=>setTimeout(r,1100));
        }
        if(!complete)throw new Error('Schedule pagination incomplete');
        const rows=broadcastEvents(all);if(!rows.length)throw new Error('No broadcast times');
        await db('rpc/replace_broadcast_events',{p_rows:rows});
        const pauses=reviewedPauses.filter(p=>Date.parse(p.from)<=Date.now()).map(({from,...p})=>({...p,
          episode:null,kind:'japan',starts_at:null,starts_on:null,provider:'ADN News',region:'JP',audio_language:'ja',status:'delayed',published:true}));
        if(pauses.length)await db('release_events?on_conflict=mal_id,episode,kind,provider,region,audio_language,source_url',pauses);
        report[name]={count:rows.length,reviewed_pauses:pauses.length};
      }
      successes++;
    }catch(e){report[name]={error:e instanceof Error?e.message:'Unavailable'};}
  }
  // Additional publishers are strictly permission-gated, including the first fetch.
  // The existing prototype sources retain their documented review-required status.
  if(scope==='all')try {
    const rights=await db('source_rights?select=source_key,status,ingestion_enabled',undefined,'GET');
    for(const key of Object.keys(officialSources) as OfficialKey[]) {
      try {
        const permission=rights.find((r:Row)=>r.source_key===key);
        if(permission?.status!=='approved'||!permission.ingestion_enabled) {report[key]={state:'permission_pending'};continue;}
        const known=await db(`news?source_name=eq.${encodeURIComponent(officialSources[key].name)}&select=source_url,checked_at&limit=100`,undefined,'GET');
        const result=await collectOfficialNews(key,permission,fetch,known);
        if(result.rows.length)await db('news?on_conflict=source_url',result.rows);
        await db('source_status?on_conflict=source_key',{source_key:key,checked_at:new Date().toISOString(),state:result.state,review_count:0});
        report[key]={state:result.state,count:result.rows.length,failed:result.failed};
      } catch {report[key]={state:'degraded'};await db('source_status?on_conflict=source_key',{source_key:key,state:'degraded',review_count:0});}
    }
  }catch{report.additional_sources={state:'unavailable'};}
  try { report.dub_alerts={delivered:await db('rpc/deliver_due_dub_alerts',{})}; await db('rpc/refresh_source_status',{}); } catch { report.dub_alerts={error:'Inbox/status refresh unavailable'}; }
  await db('rpc/finish_content_sync',{p_report:report});
  return reply({status:successes===sources.length && !Object.values(report).some(r=>(r as {failed?:unknown[]})?.failed?.length)?'ok':'partial',sources:report},successes?200:503);
});
