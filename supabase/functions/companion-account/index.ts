// Authenticated account operations. The actor is always obtained from Auth;
// neither client-supplied IDs nor editable user_metadata can grant a role.
const base = Deno.env.get('SUPABASE_URL')!;
const service = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const cors = {'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info','Access-Control-Allow-Methods':'POST, OPTIONS'};
async function db(path:string,body?:unknown) {
 const r=await fetch(`${base}/rest/v1/${path}`,{method:body===undefined?'GET':'POST',headers:{apikey:service,Authorization:`Bearer ${service}`,'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(12000)});
 if(!r.ok) throw new Error('Database operation failed');
 const text=await r.text();return text?JSON.parse(text):null;
}
Deno.serve(async req=>{
 const reply=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,'Content-Type':'application/json','Cache-Control':'no-store'}});
 if(req.method==='OPTIONS')return new Response(null,{headers:cors});
 if(req.method!=='POST')return reply({error:'POST required'},405);
 const bearer=req.headers.get('authorization');
 if(!bearer?.startsWith('Bearer ')||bearer.length>12000)return reply({error:'Sign in required'},401);
 try{
  const auth=await fetch(`${base}/auth/v1/user`,{headers:{apikey:service,Authorization:bearer},signal:AbortSignal.timeout(10000)});
  if(!auth.ok)return reply({error:'Invalid session'},401);
  const user=await auth.json();
  if(typeof user.id!=='string'||!/^[a-f0-9-]{36}$/.test(user.id))return reply({error:'Invalid session'},401);
  const raw=await req.text();if(raw.length>20000)return reply({error:'Request too large'},413);
  const body=JSON.parse(raw);
  if(body.action==='export'){
   const tables=['watchlist','dub_follows','release_inbox'];const result:Record<string,unknown>={format:'aniapp-account-v1',exported_at:new Date().toISOString()};
   for(const table of tables){
    const rows:unknown[]=[];
    for(let offset=0;offset<100000;offset+=500){const page=await db(`${table}?user_id=eq.${user.id}&order=${table==='watchlist'?'mal_id':table==='dub_follows'?'mal_id,region,audio_language':'id'}&limit=500&offset=${offset}`);rows.push(...page);if(page.length<500)break;if(offset===99500)throw new Error('Export exceeds limit');}
    result[table]=rows;
   }
   return reply(result);
  }
  if(body.action==='delete'){
   // Account deletion is separate from logout and requires a recent sign-in.
   if(body.confirm!=='DELETE'||!user.last_sign_in_at||Date.now()-Date.parse(user.last_sign_in_at)>600000)return reply({error:'Sign in again, then confirm deletion within 10 minutes'},409);
   const r=await fetch(`${base}/auth/v1/admin/users/${user.id}`,{method:'DELETE',headers:{apikey:service,Authorization:`Bearer ${service}`},signal:AbortSignal.timeout(12000)});
   if(!r.ok)return reply({error:'Deletion failed'},503);
   // A reviewer invitation is keyed by e-mail address and has no user foreign key.
   if(typeof user.email==='string')await fetch(`${base}/rest/v1/companion_reviewer_invitations?email=eq.${encodeURIComponent(user.email.toLowerCase())}`,
    {method:'DELETE',headers:{apikey:service,Authorization:`Bearer ${service}`},signal:AbortSignal.timeout(12000)}).catch(()=>undefined);
   return reply({deleted:true});
  }
  if(user.email_confirmed_at && typeof user.email==='string'){
   const invitations=await db(`companion_reviewer_invitations?email=eq.${encodeURIComponent(user.email.toLowerCase())}&select=email&limit=1`);
   if(invitations.length) {
    const existing=await db(`companion_reviewers?user_id=eq.${user.id}&select=user_id&limit=1`);
    if(!existing.length)await db('companion_reviewers',{user_id:user.id});
   }
  }
  const roles=await db(`companion_reviewers?user_id=eq.${user.id}&select=user_id&limit=1`);
  const reviewer=roles.length===1;
  if(body.action==='role')return reply({reviewer});
  if(!reviewer)return reply({error:'Reviewer required'},403);
  if(body.action==='queue')return reply({candidates:await db('dub_candidates?decision=in.(review,conflict)&order=checked_at.asc,source_url.asc,candidate_key.asc&limit=100')});
  if(body.action==='review'){
   if(typeof body.note!=='string'||!body.note.trim()||body.note.length>1000||typeof body.approve!=='boolean')return reply({error:'Review note and decision required'},400);
   return reply(await db('rpc/review_dub_candidate',{p_actor:user.id,p_source_url:body.source_url,p_key:body.candidate_key,p_checked_at:body.checked_at,p_approve:body.approve,p_event:body.event??null,p_note:body.note}));
  }
  return reply({error:'Unknown action'},400);
 }catch{return reply({error:'Operation failed. Reload before retrying; the candidate may have changed.'},409);}
});
