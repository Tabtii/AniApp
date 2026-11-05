// Reference descriptions from Wikidata (CC0), the German Wikipedia (CC BY-SA 4.0)
// and the Anime News Network encyclopedia API (free with credit and link).
// The MAL ID is the only key: Wikidata items are found by their MAL anime ID
// statement, never by title.
type Json = Record<string, any>;
export const wikidataApi = 'https://www.wikidata.org/w/api.php';
// Property IDs are checked against their English labels before use, so a wrong
// ID fails closed instead of matching some other identifier with the same number.
export const malProperty = 'P4086';
export const annProperty = 'P1985';
export const expectedLabels: Record<string, string> = {
  [malProperty]: 'myanimelist anime id', [annProperty]: 'anime news network anime id'};
export const wikipediaLicense = 'https://creativecommons.org/licenses/by-sa/4.0/deed.de';
// Wikimedia asks automated clients to identify themselves with a contact URL.
export const wikimediaHeaders = {'User-Agent': 'AniApp/0.5 (https://github.com/Tabtii/AniApp)', Accept: 'application/json'};

const positive = (n: unknown): n is number => Number.isSafeInteger(n) && Number(n) > 0;
const text = (v: unknown) => typeof v === 'string' && v.trim() ? v.trim() : null;

export function propertyLabelsUrl(): string {
  return `${wikidataApi}?${new URLSearchParams({action:'wbgetentities', ids:`${malProperty}|${annProperty}`,
    props:'labels', languages:'en', format:'json'})}`;
}
export function propertiesMatch(payload: Json): boolean {
  return Object.entries(expectedLabels).every(([id, label]) =>
    payload?.entities?.[id]?.labels?.en?.value?.trim().toLowerCase() === label);
}
export function wikidataSearchUrl(malId: number): string {
  if (!positive(malId)) throw new Error('Invalid MAL ID');
  return `${wikidataApi}?${new URLSearchParams({action:'query', list:'search',
    srsearch:`haswbstatement:${malProperty}=${malId}`, srlimit:'5', format:'json'})}`;
}
// Exactly one item may carry the MAL ID; anything else counts as unmapped.
export function wikidataItem(payload: Json): string|null {
  const hits = payload?.query?.search;
  if (!Array.isArray(hits)) throw new Error('Invalid Wikidata search');
  const ids = [...new Set(hits.map((h: Json) => h?.title).filter((t: unknown) => typeof t === 'string' && /^Q\d+$/.test(t)))];
  return ids.length === 1 ? ids[0] as string : null;
}
export function wikidataEntityUrl(qid: string): string {
  if (!/^Q\d+$/.test(qid)) throw new Error('Invalid Wikidata item');
  return `${wikidataApi}?${new URLSearchParams({action:'wbgetentities', ids:qid,
    props:'claims|sitelinks', sitefilter:'dewiki', format:'json'})}`;
}
const claimValues = (entity: Json, property: string): string[] =>
  (Array.isArray(entity?.claims?.[property]) ? entity.claims[property] : [])
    .filter((c: Json) => c?.rank !== 'deprecated')
    .map((c: Json) => c?.mainsnak?.datavalue?.value)
    .filter((v: unknown): v is string => typeof v === 'string');
export type Reference = {qid: string; annId: number|null; dewiki: string|null};
// Re-checks the MAL statement on the item itself; the search index is only a hint.
export function readEntity(payload: Json, qid: string, malId: number): Reference|null {
  const entity = payload?.entities?.[qid];
  if (!entity || entity.missing !== undefined) return null;
  if (!claimValues(entity, malProperty).includes(String(malId))) return null;
  const ann = [...new Set(claimValues(entity, annProperty).filter(v => /^[1-9]\d{0,7}$/.test(v)))];
  return {qid, annId: ann.length === 1 ? Number(ann[0]) : null, dewiki: text(entity.sitelinks?.dewiki?.title)};
}

export function wikipediaSummaryUrl(title: string): string {
  return `https://de.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(title.replace(/ /g, '_'))}`;
}
export function wikipediaSummary(payload: Json): Json|null {
  // Disambiguation and missing pages carry no usable description.
  if (payload?.type !== 'standard') return null;
  const extract = text(payload.extract), title = text(payload.title);
  let url: string|null = null;
  try {
    const u = new URL(String(payload.content_urls?.desktop?.page));
    if (u.protocol === 'https:' && u.hostname === 'de.wikipedia.org' && !u.username && !u.password) url = u.href;
  } catch { /* rejected below */ }
  if (!extract || !title || !url) return null;
  return {title, extract, url, license: wikipediaLicense,
    history_url: `https://de.wikipedia.org/w/index.php?${new URLSearchParams({title, action:'history'})}`};
}

export function annUrl(annId: number): string {
  if (!positive(annId)) throw new Error('Invalid ANN ID');
  return `https://cdn.animenewsnetwork.com/encyclopedia/api.xml?anime=${annId}`;
}
const entities: Record<string, string> = {amp:'&', lt:'<', gt:'>', quot:'"', apos:"'"};
export function decodeXml(value: string): string {
  return value.replace(/<[^>]*>/g, ' ')
    .replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (match, code: string) => {
      if (code[0] !== '#') return entities[code.toLowerCase()] ?? match;
      const n = code[1].toLowerCase() === 'x' ? parseInt(code.slice(2), 16) : parseInt(code.slice(1), 10);
      return Number.isSafeInteger(n) && n > 0 && n <= 0x10ffff ? String.fromCodePoint(n) : match;
    })
    .replace(/\s+/g, ' ').trim();
}
// Only the entry with the requested ID counts; a plot summary is optional.
export function annDetails(xml: string, annId: number): Json|null {
  if (typeof xml !== 'string' || !/<ann[\s>]/.test(xml)) throw new Error('Invalid ANN response');
  const open = new RegExp(`<anime\\b[^>]*\\bid="${annId}"[^>]*>`).exec(xml);
  if (!open) return null;
  const end = xml.indexOf('</anime>', open.index);
  const body = xml.slice(open.index, end < 0 ? undefined : end);
  const name = /\bname="([^"]*)"/.exec(open[0])?.[1];
  const plot = /<info\b[^>]*\btype="Plot Summary"[^>]*>([\s\S]*?)<\/info>/.exec(body)?.[1];
  const synopsis = plot ? decodeXml(plot) : '';
  return {ann_id: annId, title: name ? decodeXml(name) : null, synopsis: synopsis || null,
    source: `https://www.animenewsnetwork.com/encyclopedia/anime.php?id=${annId}`};
}
