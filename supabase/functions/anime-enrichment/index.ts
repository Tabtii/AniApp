import {acceptsPublishableKey} from '../catalog/auth.ts';
import {Enrichment,validateInput} from './providers.ts';
const service=new Enrichment({tmdbToken:Deno.env.get('TMDB_READ_ACCESS_TOKEN'),tmdbKey:Deno.env.get('TMDB_API_KEY'),
  anilistApproved:Deno.env.get('ANILIST_USAGE_APPROVED')==='true'});
const headers={'Content-Type':'application/json','Access-Control-Allow-Origin':'*',
  'Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info'};
const clients=new Map<string,{until:number;count:number}>();
let active=0;
Deno.serve(async(req:Request)=>{
  const reply=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers});
  if(req.method==='OPTIONS')return new Response('ok',{headers});
  if(req.method!=='POST')return reply({error:'POST required'},405);
  if(!acceptsPublishableKey(req.headers.get('apikey'),Deno.env.get('SUPABASE_PUBLISHABLE_KEYS')))return reply({error:'Invalid project key'},401);
  const now=Date.now(),ip=req.headers.get('x-forwarded-for')?.split(',')[0]?.trim()??'unknown';
  const old=clients.get(ip),bucket=old && old.until>now?old:{until:now+60000,count:0};
  if(++bucket.count>30)return reply({error:'Please retry shortly'},429);
  if(clients.size>5000)for(const[k,v]of clients)if(v.until<now)clients.delete(k);
  clients.set(ip,bucket);
  let input;
  try{const body=await req.text();if(body.length>2048)return reply({error:'Request too large'},413);input=validateInput(JSON.parse(body));}
  catch{return reply({error:'Invalid enrichment request'},400);}
  if(active>=8)return reply({error:'Please retry shortly'},429);
  active++;
  try{return reply(input.mode==='calendar'?await service.calendar():await service.detail(input.malId,input.language,input.region));}
  catch{return reply({error:'Enrichment temporarily unavailable'},503);}
  finally{active--;}
});
