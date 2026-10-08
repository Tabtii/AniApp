type Json = Record<string, any>;
export function kitsuLookupUrl(malId:number):string {
  if(!Number.isSafeInteger(malId)||malId<1)throw new Error('Invalid MAL ID');
  const u=new URL('https://kitsu.app/api/edge/mappings');
  u.search=new URLSearchParams({'filter[externalSite]':'myanimelist/anime','filter[externalId]':String(malId),include:'item','page[limit]':'20'}).toString();
  return u.href;
}
const image=(value:unknown):string|null=>{
  try{const u=new URL(String(value));return u.protocol==='https:' && ['media.kitsu.app','media.kitsu.io'].includes(u.hostname) && !u.username && !u.password?u.href:null;}catch{return null;}
};
const count=(v:unknown)=>Number.isSafeInteger(v)&&Number(v)>0?v:null;
const text=(v:unknown)=>typeof v==='string' && v.trim()?v.trim():null;
export function kitsuDetails(payload:Json,malId:number):Json|null {
  if(!Array.isArray(payload.data)||!Array.isArray(payload.included ?? []))throw new Error('Invalid Kitsu response');
  // Validate even if the upstream were to ignore a filter. Never fuzzy-match titles.
  const matches=payload.data.filter((m:Json)=>m.type==='mappings' && m.attributes?.externalSite==='myanimelist/anime' &&
    m.attributes?.externalId===String(malId) && m.relationships?.item?.data?.type==='anime');
  const ids=new Set(matches.map((m:Json)=>m.relationships.item.data.id));
  if(ids.size!==1 || payload.links?.next)return null;
  const id=[...ids][0];if(typeof id!=='string'||!/^\d+$/.test(id))return null;
  const entries=(payload.included ?? []).filter((a:Json)=>a.type==='anime'&&a.id===id);
  if(entries.length!==1)return null;
  const a=entries[0].attributes;
  if(!a || a.nsfw!==false || a.ageRating==='R18' || !text(a.canonicalTitle))return null;
  const source=`https://kitsu.app/anime/${id}`;
  return {source,mal_id:malId,kitsu_id:id,title:text(a.titles?.en)||a.canonicalTitle,
    synopsis:text(a.synopsis),poster:image(a.posterImage?.large),banner:image(a.coverImage?.large),
    episodes:count(a.episodeCount),episode_minutes:count(a.episodeLength),
    start_date:/^\d{4}-\d{2}-\d{2}$/.test(a.startDate??'')?a.startDate:null,
    end_date:/^\d{4}-\d{2}-\d{2}$/.test(a.endDate??'')?a.endDate:null,
    airing_status:['current','finished','upcoming','tba','unreleased'].includes(a.status)?a.status:null,
    trailer_url:typeof a.youtubeVideoId==='string' && /^[\w-]{11}$/.test(a.youtubeVideoId)?`https://www.youtube.com/watch?v=${a.youtubeVideoId}`:null};
}
