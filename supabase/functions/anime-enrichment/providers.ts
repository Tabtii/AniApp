// Read-only enrichment. MAL identity stays canonical; no title-based matches.
export type Json = Record<string, any>;
export const mappingSource = 'https://github.com/Fribb/anime-lists';
const mappingUrl = 'https://raw.githubusercontent.com/Fribb/anime-lists/master/anime-list-mini.json';
const languages: Record<string, string> = {de:'german', en:'english', fr:'french', es:'spanish', it:'italian'};
const positive = (n: unknown): n is number => Number.isSafeInteger(n) && Number(n) > 0;
export function validateInput(body: Json): {mode:'detail'|'calendar'; malId:number; language:string; region:string} {
  if (!body || typeof body !== 'object') throw new Error('Invalid input');
  const mode = body.mode ?? 'detail';
  if (!['detail','calendar'].includes(mode) || (mode === 'detail' && !positive(body.mal_id))) throw new Error('Invalid ID');
  const language = body.language ?? 'de', region = body.region ?? 'DE';
  if (!['de','en','ja','fr','es','it'].includes(language) || !['DE','AT','CH','US'].includes(region)) throw new Error('Invalid preference');
  return {mode, malId:body.mal_id, language, region};
}
export function dubStatus(data: Json, malId: number): string {
  if (!Array.isArray(data?.dubbed) || !Array.isArray(data?.partial) ||
      ![...data.dubbed,...data.partial].every(positive)) throw new Error('Invalid dub dataset');
  // Absence is unknown, never proof that a dub does not exist.
  return data.partial.includes(malId) ? 'partial' : data.dubbed.includes(malId) ? 'available' : 'unknown';
}
export type Mapping = {type:'tv'|'movie'; id:number; season:number|null};
export function tmdbMapping(rows: Json[], malId: number): Mapping|null {
  const candidates = rows.filter(r => r.mal_id === malId);
  if (!candidates.length) return null;
  const resolved: Mapping[] = [];
  for (const r of candidates) {
    const ids = r.themoviedb_id;
    if (r.type === 'MOVIE' && Array.isArray(ids?.movie) && ids.movie.length === 1 && positive(ids.movie[0]) && !ids.tv) {
      resolved.push({type:'movie', id:ids.movie[0], season:null});
    } else if (['TV','ONA','OVA','SPECIAL'].includes(r.type) && positive(ids?.tv) && !ids.movie) {
      const season = r.season?.tmdb;
      if (season != null && (!Number.isInteger(season) || season < 0)) return null;
      resolved.push({type:'tv', id:ids.tv, season:season ?? null});
    } else return null;
  }
  const unique = new Map(resolved.map(x => [JSON.stringify(x),x]));
  return unique.size === 1 ? [...unique.values()][0] : null;
}
function safeUrl(value: unknown, host: string): string|null {
  try { const u = new URL(String(value)); return u.protocol === 'https:' && u.hostname === host && !u.username && !u.password ? u.href : null; } catch {return null;}
}
export function watchProviders(value: Json, region: string, mapping: Mapping, now: string): Json[] {
  if (!value || typeof value.results !== 'object' || value.results === null || Array.isArray(value.results)) throw new Error('Invalid watch providers');
  const local = value.results[region];
  if (!local) return [];
  const link = safeUrl(local.link, 'www.themoviedb.org');
  if (!link) throw new Error('Missing provider source');
  const found = new Map<number, Json>();
  for (const offer of ['flatrate','free','ads','rent','buy']) {
    if (local[offer] != null && !Array.isArray(local[offer])) throw new Error('Invalid offers');
    for (const p of local[offer] ?? []) {
      if (!positive(p.provider_id) || typeof p.provider_name !== 'string' || !p.provider_name.trim()) continue;
      const entry = found.get(p.provider_id) ?? {provider:p.provider_name, provider_id:p.provider_id,
        region, scope:mapping.type === 'movie' ? 'movie' : mapping.season == null ? 'series' : 'season',
        season_number:mapping.season, audio_languages:null, subtitle_languages:null, status:'available',
        source_name:'TMDb / JustWatch', source_url:link, watch_url:link, checked_at:now, offers:[]};
      entry.offers.push(offer); found.set(p.provider_id,entry);
    }
  }
  return [...found.values()];
}
export function airingEvent(media: Json, airing: Json, now = new Date()): Json|null {
  if (!positive(media?.idMal) || !positive(media.id) || media.isAdult !== false || !positive(airing?.episode) ||
      !positive(airing.airingAt) || airing.mediaId !== media.id || airing.airingAt * 1000 < now.getTime()) return null;
  const title = media.title?.english || media.title?.romaji;
  if (typeof title !== 'string' || !title.trim()) return null;
  return {mal_id:media.idMal, title, episode:airing.episode, kind:'japan', starts_at:new Date(airing.airingAt*1000).toISOString(),
    provider:'AniList', region:'JP', audio_language:'ja', status:'estimated',
    image_url:safeUrl(media.coverImage?.large,'s4.anilist.co'), source_url:`https://anilist.co/anime/${media.id}`,
    checked_at:now.toISOString(), published:true,
    release_note:'Episodentermin laut AniList; japanische Ausstrahlung, kein deutscher Streaming- oder Dub-Termin. Änderungen möglich.'};
}
type Cached = {until:number; value:Json; checkedAt:string};
export class Enrichment {
  private cache = new Map<string,Cached>();
  private pending = new Map<string,Promise<Cached>>();
  private aniNext = 0;
  private aniCooldown = 0;
  constructor(private options:{tmdbToken?:string; tmdbKey?:string; anilistApproved?:boolean}, private fetcher:typeof fetch = fetch) {}
  private async json(url:string, init:RequestInit = {}, maxBytes=1_000_000):Promise<Json> {
    const r = await this.fetcher(url,{...init,signal:AbortSignal.timeout(9000)});
    if (url === 'https://graphql.anilist.co' && r.status === 429) {
      const seconds = Number(r.headers.get('Retry-After'));
      this.aniCooldown = Date.now()+Math.max(60000,Number.isFinite(seconds)?seconds*1000:60000);
    }
    if (!r.ok) throw new Error(`Upstream HTTP ${r.status}`);
    if (!r.body) throw new Error('Empty upstream');
    const reader = r.body.getReader(); const chunks:Uint8Array[]=[]; let size=0;
    for (;;) {const {done,value}=await reader.read(); if(done)break; size+=value.length;
      if(size>maxBytes){await reader.cancel();throw new Error('Upstream too large');} chunks.push(value);}
    const bytes=new Uint8Array(size); let offset=0; for(const c of chunks){bytes.set(c,offset);offset+=c.length;}
    return JSON.parse(new TextDecoder().decode(bytes));
  }
  private cached(key:string, ttl:number, load:()=>Promise<Json>):Promise<Cached> {
    const existing=this.cache.get(key); if(existing && existing.until>Date.now()) return Promise.resolve(existing);
    const pending=this.pending.get(key);if(pending)return pending;
    const task=load().then(value=>{
      const entry={value,checkedAt:new Date().toISOString(),until:Date.now()+ttl};
      if(this.cache.size>=300)this.cache.delete(this.cache.keys().next().value!);
      this.cache.set(key,entry);return entry;
    }).finally(()=>this.pending.delete(key));
    this.pending.set(key,task);return task;
  }
  async dub(malId:number, language:string):Promise<Json> {
    if(language==='ja')return {status:'original_language'};
    const name=languages[language];if(!name)return {status:'unsupported'};
    try {
      const data=await this.cached(`dub:${language}`,86400000,async()=>{
        const value=await this.json(`https://raw.githubusercontent.com/Joelis57/MyDubList/main/dubs/confidence/normal/dubbed_${name}.json`);
        if(value.language?.toLowerCase()!==name)throw new Error('Wrong dub language');
        dubStatus(value,malId);return value;
      });
      return {status:dubStatus(data.value,malId), language, checked_at:data.checkedAt,
        source:'https://mydublist.com', license:'https://creativecommons.org/licenses/by/4.0/',
        confidence:'multiple_sources_or_curated'};
    } catch {return {status:'unavailable',language};}
  }
  async tmdb(malId:number, region:string):Promise<Json> {
    if(!this.options.tmdbToken && !this.options.tmdbKey)return {status:'unconfigured',providers:[]};
    try {
      const mappings=await this.cached('mapping',86400000,async()=>{
        const rows=await this.json(mappingUrl,{},12_000_000);
        if(!Array.isArray(rows))throw new Error('Invalid mappings');return {rows};
      });
      const mapping=tmdbMapping(mappings.value.rows,malId);
      if(!mapping)return {status:'unmapped',providers:[]};
      const path=`${mapping.type}/${mapping.id}${mapping.type==='tv' && mapping.season!=null?`/season/${mapping.season}`:''}`;
      const result=await this.cached(`tmdb:${path}`,3600000,async()=>{
        const get=(suffix:string)=>{
          const url=new URL(`https://api.themoviedb.org/3/${path}${suffix}`);url.searchParams.set('language','de-DE');
          if(!this.options.tmdbToken)url.searchParams.set('api_key',this.options.tmdbKey!);
          return this.json(url.href,{headers:this.options.tmdbToken?{Authorization:`Bearer ${this.options.tmdbToken}`}:{}});
        };
        const providers=await get('/watch/providers');
        if(!providers.results || typeof providers.results!=='object')throw new Error('Invalid providers');
        // Descriptions are optional; they cannot hide a successful provider result.
        let overview:null|string=null;try{const info=await get('');if(typeof info.overview==='string' && info.overview.trim())overview=info.overview;}catch{/* keep providers */}
        return {providers,overview};
      });
      return {status:'ok',mapping,mapping_source:mappingSource,
        providers:watchProviders(result.value.providers,region,mapping,result.checkedAt),
        overview:result.value.overview,source:`https://www.themoviedb.org/${path}`,checked_at:result.checkedAt};
    } catch {return {status:'unavailable',providers:[]};}
  }
  private async aniQuery(query:string,variables:Json):Promise<Json> {
    if(!this.options.anilistApproved)throw new Error('AniList approval required');
    if(Date.now()<this.aniCooldown)throw new Error('AniList cooldown');
    const wait=Math.max(0,this.aniNext-Date.now());
    if(wait>8000)throw new Error('AniList busy');
    this.aniNext=Math.max(Date.now(),this.aniNext)+2200;
    if(wait)await new Promise(r=>setTimeout(r,wait));
    if(Date.now()<this.aniCooldown)throw new Error('AniList cooldown');
    const data=await this.json('https://graphql.anilist.co',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({query,variables})});
    if(data.errors?.length || !data.data)throw new Error('Invalid AniList response');return data.data;
  }
  async anilist(malId:number):Promise<Json> {
    if(!this.options.anilistApproved)return {status:'approval_required'};
    try {
      const result=await this.cached(`ani:${malId}`,900000,()=>this.aniQuery(`query($id:Int!){Media(idMal:$id,type:ANIME,isAdult:false){id idMal isAdult title{english romaji} bannerImage coverImage{large} nextAiringEpisode{episode airingAt mediaId}}}`,{id:malId}));
      const m=result.value.Media;
      if(!m || m.idMal!==malId || m.isAdult!==false || !positive(m.id))return {status:'unmapped'};
      return {status:'ok',source:`https://anilist.co/anime/${m.id}`,checked_at:result.checkedAt,
        banner:safeUrl(m.bannerImage,'s4.anilist.co'),next_release:airingEvent(m,m.nextAiringEpisode)};
    }catch{return {status:'unavailable'};}
  }
  async calendar():Promise<Json> {
    if(!this.options.anilistApproved)return {status:'approval_required',events:[]};
    try {
      const result=await this.cached('ani:calendar',900000,async()=>{
        const now=new Date(), from=Math.floor(now.getTime()/1000), to=from+7*86400;
        const events:Json[]=[];let complete=false;
        for(let page=1;page<=12;page++){
          const data=await this.aniQuery(`query($page:Int!,$from:Int!,$to:Int!){Page(page:$page,perPage:50){pageInfo{hasNextPage} airingSchedules(airingAt_greater:$from,airingAt_lesser:$to,sort:TIME){episode airingAt mediaId media{id idMal isAdult title{english romaji} coverImage{large}}}}}`,{page,from,to});
          if(!Array.isArray(data.Page?.airingSchedules) || typeof data.Page?.pageInfo?.hasNextPage!=='boolean')throw new Error('Invalid schedule');
          for(const a of data.Page.airingSchedules){const e=airingEvent(a.media,a,now);if(e && a.airingAt<to)events.push(e);}
          if(!data.Page.pageInfo.hasNextPage){complete=true;break;}
        }
        if(!complete)throw new Error('Incomplete schedule');
        return {events:[...new Map(events.map(e=>[`${e.mal_id}:${e.episode}`,e])).values()]};
      });
      return {status:'ok',events:result.value.events.filter((e:Json)=>Date.parse(e.starts_at)>Date.now()),checked_at:result.checkedAt};
    }catch{return {status:'unavailable',events:[]};}
  }
  async detail(malId:number, language:string,region:string):Promise<Json>{
    const [dub,streaming,anilist]=await Promise.all([this.dub(malId,language),this.tmdb(malId,region),this.anilist(malId)]);
    return {mal_id:malId,language,region,dub,streaming,anilist};
  }
}
