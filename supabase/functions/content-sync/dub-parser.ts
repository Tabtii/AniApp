import {cleanText, type Row} from './content.ts';

export const PARSER_VERSION = 1;
export type DubSource = 'cr_de' | 'cr_en' | 'adn' | 'anime2you' | 'aninews';
export type Document = {url:string; source:DubSource; headline:string; published_at:string; body:string; image_url?:string|null};
export type Candidate = {title:string; provider:string|null; region:string|null; language:'de'|'en';
  episode:number|null; starts_on:string|null; status:'confirmed'|'announced'|'delayed'; evidence:string; reason:string|null};

export function text(value:string):string {
  // Feeds sometimes double-encode entities. Never execute markup or scripts.
  return cleanText(cleanText(value.replace(/<(script|style)\b[^>]*>[\s\S]*?<\/\1>/gi,' ')))
    .replace(/&(?:bdquo|ldquo|rdquo);/g,'"').replace(/&(?:raquo|laquo);/g,'"').replace(/\s+/g,' ').trim();
}
export function titleKey(value:string):string {
  return text(value).normalize('NFKC').toLowerCase().replace(/staffel\s*(\d+)/g,'season $1')
    .replace(/(\d+)(?:st|nd|rd|th) season/g,'season $1').replace(/[^\p{L}\p{N}]+/gu,' ').trim();
}
const months = ['januar|january','februar|february','märz|march','april','mai|may','juni|june',
  'juli|july','august','september','oktober|october','november','dezember|december'];
export function dates(value:string,published:string):string[] {
  const result:string[]=[];
  for(let i=0;i<months.length;i++){
    const patterns=[new RegExp(`\\b(\\d{1,2})(?!\\d)\\.?(?:st|nd|rd|th)?\\s+(?:${months[i]})(?:\\s+(20\\d{2}))?`,'gi'),
      new RegExp(`\\b(?:${months[i]})\\s+(\\d{1,2})(?!\\d)(?:st|nd|rd|th)?(?:,?\\s+(20\\d{2}))?`,'gi')];
    for(const re of patterns)for(const m of value.matchAll(re)){
      let year=m[2]?Number(m[2]):new Date(published).getUTCFullYear();
      // A yearless January following a December article means next year; otherwise
      // do not roll past dates forward just to make them look upcoming.
      if(!m[2]&&new Date(published).getUTCMonth()===11&&i===0)year++;
      const d=new Date(Date.UTC(year,i,Number(m[1])));
      if(d.getUTCMonth()===i&&d.getUTCDate()===Number(m[1]))result.push(d.toISOString().slice(0,10));
    }
  }
  return [...new Set(result)];
}
const dubLanguage = /(?:deutsch\w*\s+(?:Synchro\w*|Sprachfassung|Vertonung|Fassung)|German[- ](?:language )?dub|englisch\w*\s+(?:Synchro\w*|Sprachfassung|Vertonung)|English[- ](?:language )?dub)/gi;
const launch = /\b(?:start\w*|erscheint|erscheinen|veröffentlicht|verfügbar|angekündigt|ankündigt|premier\w*|launch\w*|release\w*|debut\w*|stream\w*|arriv\w*|begin\w*|ab|on|zu sehen)\b/i;
const unknown = /(?:Termin|Start|Datum).{0,30}(?:offen|unbekannt|noch nicht)|später\w* Zeitpunkt|(?:date|schedule).{0,25}(?:TBA|unknown|not.{0,10}announced)|\bTBA\b|coming soon/i;
const negated = /\b(?:kein\w*|nicht|no|not|unconfirmed|rumou?r|Gerücht)\b/i;
function provider(value:string,source:DubSource):string|null {
  const names = [...value.matchAll(/Crunchyroll|Netflix|\bADN\b|aniverse|HIDIVE|ProSieben MAXX|Disney\+|Paramount\+/gi)]
    .map(m=>({'crunchyroll':'Crunchyroll','netflix':'Netflix','adn':'ADN','aniverse':'aniverse / Prime Video','hidive':'HIDIVE',
      'prosieben maxx':'ProSieben MAXX','disney+':'Disney+','paramount+':'Paramount+'})[m[0].toLowerCase()]!);
  const unique=[...new Set(names)];
  if(unique.length===1)return unique[0];
  if(unique.length>1)return null;
  return source.startsWith('cr_')?'Crunchyroll':source==='adn'?'ADN':null;
}
function regions(value:string,source:DubSource):string[] {
  // DE editorial editions cover the German market, not automatically AT/CH.
  // English article/audio is NOT evidence of US/GB distribution.
  if(/(?:worldwide|weltweit)(?!\s+(?:except|außer))/i.test(value)&&!/(?:except|excluding|außer)/i.test(value))return ['DE','AT','CH','US','GB'];
  const r:string[]=[];
  if(/\b(?:United States|USA|U\.S\.|North America)\b/i.test(value))r.push('US');
  if(/\b(?:United Kingdom|UK|U\.K\.|Great Britain)\b/i.test(value))r.push('GB');
  if(/\b(?:Germany|Deutschland)\b/i.test(value))r.push('DE');
  if(/\b(?:Austria|Österreich)\b/i.test(value))r.push('AT');
  if(/\b(?:Switzerland|Schweiz)\b/i.test(value))r.push('CH');
  return r.length?r:source!=='cr_en'?['DE']:[];
}
function quotedTitles(s:string):string[]{
  return [...s.matchAll(/[»„“"]([^»«„“”"]{2,200})[«“”"]/g)].map(m=>m[1]);
}
export function headlineTitle(doc:Document):string|null {
  const quotes=quotedTitles(doc.headline);
  if(quotes.length===1)return quotes[0];
  // Official solo-title dub announcements use this headline format. Never strip
  // arbitrary suffixes off lineup/list articles or guess a season number.
  const m=/^(.+?)\s+(?:Anime\s+)?(?:English|German)\s+Dub\b/i.exec(doc.headline)
    ?? /^(.+?)(?:\s+–|\s+-|:)?\s+[Dd]eutsche\s+(?:Synchro\w*|Sprachfassung)\b/.exec(doc.headline);
  return m?.[1]?.trim()??null;
}
function build(doc:Document,title:string,claim:string,language:'de'|'en',context=claim):Candidate[] {
  const dateValues=dates(claim,doc.published_at);
  const open=unknown.test(claim);
  const delayed=/verschoben|verzöger|postponed|delayed/i.test(claim);
  let reason:string|null=null;
  if(negated.test(claim)&&!open)reason='negated_or_uncertain';
  if(/(?:keine?\w*\s+(?:deutsche?\w*\s+)?Synchro|\bno\s+(?:English\s+|German\s+)?dub|(?:dub|Synchro).{0,25}(?:not planned|abgesagt|cancelled))/i.test(claim))reason='negated_or_uncertain';
  if(dateValues.length>1)reason='multiple_dates';
  // Dates must belong to the dub claim; never lift a simulcast date from another paragraph.
  if(!launch.test(claim)&&!open&&!delayed)reason='no_release_statement';
  if(/\b(?:DVD|Blu-ray|Kino|cinema|theater)\b/i.test(claim))reason='non_streaming_release';
  const p=provider(context,doc.source),rr=regions(context,doc.source);
  if(!p)reason='provider_ambiguous';
  if(!rr.length)reason='region_unconfirmed';
  const episodeMatch=/\b(?:Folge[n]?|Episoden?|Episodes?)\s+(\d+)(?:\s*[-–]\s*(\d+))?/i.exec(claim);
  let episodes:(number|null)[]=[null];
  if(episodeMatch){
    const a=Number(episodeMatch[1]),b=Number(episodeMatch[2]??a);
    if(a<1||b<a||b-a>99)reason='episode_range_invalid';
    else episodes=Array.from({length:b-a+1},(_,i)=>a+i);
  }else if(/(?:\d+|ersten?|first|beiden|drei)\s+(?:Folgen|Episoden|episodes)|ganze Staffel|complete season/i.test(claim))reason='batch_scope_unconfirmed';
  const seasonText=claim.replace(/\b(first|second|third|erste[nr]?|zweite[nr]?|dritte[nr]?)\s+(?:season|Staffel)\b/gi,
    (_,ordinal:string)=>`season ${/first|erste/i.test(ordinal)?1:/second|zweite/i.test(ordinal)?2:3}`);
  for(const m of seasonText.matchAll(/\b(?:Staffel|Season)\s+(\d+)/gi))
    if(!new RegExp(`\\bseason ${m[1]}\\b`).test(titleKey(title)))reason='season_scope_unconfirmed';
  // Date-only is deliberate: a bare local clock time is not a verified timezone.
  const day=!open&&dateValues.length===1?dateValues[0]:null;
  if(day&&(Date.parse(day)<Date.parse(doc.published_at)-14*86400000||Date.parse(day)>Date.parse(doc.published_at)+550*86400000))reason='date_out_of_range';
  if(!day&&!open&&!/angekündigt|announced|startet|will (?:stream|launch|premiere)|coming/i.test(claim))reason??='date_unresolved';
  return (rr.length?rr:[null]).flatMap(region=>episodes.map(episode=>({title,provider:p,region,language,episode,
    starts_on:day,status:delayed?'delayed':day?'confirmed':'announced',evidence:claim.slice(0,1200),reason})));
}

export function extractDubs(doc:Document):Candidate[] {
  const out:Candidate[]=[];
  // ADN's lineup cards expose title + day + SYNC, but SYNC alone is not a language.
  // Require an explicit German-dub sentence naming that SAME title in the article.
  if(doc.source==='adn'){
    const intro=text(doc.body).slice(0,10000);
    for(const card of doc.body.split(/<div\b[^>]*class=["'][^"']*\badn-lineup-card\b[^"']*["'][^>]*>/i).slice(1)){
      const title=text(/<h6\b[^>]*>([\s\S]*?)<\/h6>/i.exec(card)?.[1]??'');
      const label=[...card.matchAll(/<p\b[^>]*>([\s\S]*?)<\/p>/gi)].map(m=>text(m[1])).find(s=>/\(SYNC\)/.test(s))??'';
      if(!title||!label)continue;
      const languageEvidence=[...intro.matchAll(/deutsche\s+Synchro(?:n\w*)?\s+(?:zu|von|für)\s+([^.!?]{2,250})/gi)]
        .find(m=>titleKey(m[1]).startsWith(titleKey(title)));
      if(languageEvidence)out.push(...build(doc,title,`${title}: deutsche Synchro startet am ${label}`, 'de')
        .map(c=>({...c,evidence:`${languageEvidence[0]} | ${title} | ${label}`.slice(0,1200)})));
    }
  }
  const title=headlineTitle(doc);
  // Only complete paragraphs/sentences carrying both the subject and dub claim.
  // The fallback headline title is allowed solely for solo-title dub headlines.
  const blocks=doc.body.includes('<p')?[...doc.body.matchAll(/<p\b[^>]*>([\s\S]*?)<\/p>/gi)].map(m=>text(m[1])):[text(doc.body)];
  for(const block of blocks){
    // Keep numeric dates intact when splitting sentences.
    const sentences=block.split(/(?<=[!?])\s+|(?<=[a-zäöüß"»“”)])\.\s+(?=[A-ZÄÖÜ])/);
    for(const sentence of sentences){
      if(sentence.length>1600)continue;
      const languages=[...sentence.matchAll(dubLanguage)].map(m=>/englisch|English/i.test(m[0])?'en' as const:'de' as const);
      if(!languages.length)continue;
      const subjects=quotedTitles(sentence);
      const subject=subjects.length===1?subjects[0]:title;
      if(!subject||subjects.length>1)continue;
      if(title && titleKey(subject)!==titleKey(title))continue;
      // A general series headline cannot confer identity on an unrelated dub mention.
      if(!subjects.length&&!/(?:English|German) Dub|deutsche.*(?:Synchro|Sprachfassung)/i.test(doc.headline))continue;
      for(const language of [...new Set(languages)])out.push(...build(doc,subject,sentence,language,
        doc.source==='cr_en'?sentence:sentence+' '+doc.headline));
    }
  }
  return [...new Map(out.map(c=>[JSON.stringify([titleKey(c.title),c.provider,c.region,c.language,c.episode,c.starts_on]),c])).values()];
}

export function exactAnime(title:string,rows:Row[]):Row|null {
  const key=titleKey(title);
  const matches=rows.filter(a=>Number.isInteger(a.mal_id)&&a.mal_id>0&&
    [a.title,a.title_english,...(Array.isArray(a.titles)?a.titles.map((t:Row)=>t.title):[]),...(a.title_synonyms??[])]
      .some(t=>typeof t==='string'&&titleKey(t)===key));
  const unique=[...new Map(matches.map(a=>[a.mal_id,a])).values()];
  return unique.length===1?unique[0]:null;
}
