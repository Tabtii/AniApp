import {broadcastEvents, rssNews, malNews, type Row} from './content.ts';
const url=Deno.env.get('SUPABASE_URL')!;
const secret=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
async function db(path:string,body:unknown) {
  const r=await fetch(`${url}/rest/v1/${path}`,{method:'POST',headers:{apikey:secret,Authorization:`Bearer ${secret}`,'Content-Type':'application/json',Prefer:'resolution=merge-duplicates'},body:JSON.stringify(body),signal:AbortSignal.timeout(12000)});
  if(!r.ok) throw new Error(`Database ${r.status}: ${(await r.text()).slice(0,240)}`);
  const t=await r.text();return t?JSON.parse(t):null;
}
async function source(url:string) {
  const r=await fetch(url,{headers:{Accept:'application/json, application/rss+xml', 'User-Agent':'AniApp/0.2.4 (+https://github.com/Tabtii/AniApp)'},signal:AbortSignal.timeout(18000)});
  if(!r.ok) throw new Error(`Source HTTP ${r.status}`);
  const text=await r.text();if(text.length>2500000) throw new Error('Source too large'); return text;
}
Deno.serve(async req=> {
  const reply=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{'Content-Type':'application/json'}});
  if(req.method!=='POST') return reply({error:'POST required'},405);
  const token=req.headers.get('x-sync-token');
  if(!token || token.length>100) return reply({error:'Unauthorized'},401);
  let claim;
  try{claim=await db('rpc/begin_content_sync',{p_token:token});}catch{return reply({error:'Sync unavailable'},503);}
  if(claim==='denied') return reply({error:'Unauthorized'},401);
  if(claim!=='ready') return reply({status:'already_running_or_recent'},202);
  const report:Record<string,unknown>={};
  let successes=0;
  // Sources fail independently; existing published data survives failed imports.
  for(const name of ['anime2you','myanimelist','schedule']) {
    try {
      if(name==='anime2you') {
        const rows=rssNews(await source('https://www.anime2you.de/feed/'));
        await db('news?on_conflict=source_url',rows);report[name]={count:rows.length};
      } else if(name==='myanimelist') {
        const value=JSON.parse(await source('https://api.tenrai.org/v1/news?limit=15'));
        if(!Array.isArray(value.data))throw new Error('Invalid news response');
        const rows=malNews(value.data);if(!rows.length)throw new Error('No recent news');
        await db('news?on_conflict=source_url',rows);report[name]={count:rows.length};
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
        await db('rpc/replace_broadcast_events',{p_rows:rows});report[name]={count:rows.length};
      }
      successes++;
    }catch(e){report[name]={error:e instanceof Error?e.message:'Unavailable'};}
  }
  await db('rpc/finish_content_sync',{p_report:report});
  return reply({status:successes===3?'ok':'partial',sources:report},successes?200:503);
});
