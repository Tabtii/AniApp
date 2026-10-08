export type Json = Record<string, any>;
export function validateRequest(body: Json): {path: string; query: Record<string, string>} {
  const path = String(body.path ?? '');
  if (!/^(anime|anime\/[1-9][0-9]*\/full|seasons\/[0-9]{4}\/(winter|spring|summer|fall))$/.test(path)) throw new Error('Invalid path');
  const input = body.query ?? {};
  const page = Number(input.page ?? 1);
  if (!Number.isInteger(page) || page < 1 || page > 100) throw new Error('Invalid page');
  const q = String(input.q ?? '').trim();
  if (q.length > 120) throw new Error('Query too long');
  const query: Record<string, string> = {page: String(page), limit: '25', sfw: 'true'};
  if (path === 'anime') {
    if (q) query.q = q;
    query.order_by = 'score'; query.sort = 'desc';
    if (input.genres != null) {
      if (!/^[0-9]{1,2}$/.test(String(input.genres))) throw new Error('Invalid genre');
      query.genres = String(input.genres);
    }
  }
  if (path.startsWith('seasons/')) {
    const year = Number(path.split('/')[1]);
    if (year < 1917 || year > new Date().getUTCFullYear() + 1) throw new Error('Invalid year');
  }
  return {path, query};
}
export function malAnime(node: Json): Json {
  return {mal_id: node.id, title: node.title, title_english: node.alternative_titles?.en || null,
    images: {jpg: {image_url: node.main_picture?.medium ?? null, large_image_url: node.main_picture?.large ?? node.main_picture?.medium ?? null}},
    score: node.mean ?? null, episodes: node.num_episodes || null, synopsis: node.synopsis ?? null,
    genres: node.genres ?? [], broadcast: {string: node.broadcast
      ? `${node.broadcast.day_of_the_week ?? ''} ${node.broadcast.start_time ?? ''} (Japan)` : null}};
}
export function malUrl(path: string, query: Record<string, string>): URL | null {
  // MAL search does not support these genre filters; use Tenrai to preserve semantics.
  if (query.genres) return null;
  const fields = 'id,title,main_picture,alternative_titles,mean,num_episodes,synopsis,genres,broadcast';
  let target: string;
  if (path === 'anime') {
    if (!query.q || query.q.length < 3) return null;
    target = 'anime';
  } else if (path.startsWith('seasons/')) target = `anime/season/${path.split('/').slice(1).join('/')}`;
  else target = path.replace('/full', '');
  const url = new URL(`https://api.myanimelist.net/v2/${target}`);
  url.searchParams.set('fields', fields); url.searchParams.set('nsfw', 'false');
  if (!/^anime\/[0-9]+$/.test(target)) {
    url.searchParams.set('limit', '25'); url.searchParams.set('offset', String((Number(query.page) - 1) * 25));
    if (query.q) url.searchParams.set('q', query.q);
    if (path.startsWith('seasons/')) url.searchParams.set('sort', 'anime_score');
  }
  return url;
}
export function normalizeMal(data: Json, detail: boolean): Json {
  if (detail) return {data: malAnime(data), source: 'myanimelist'};
  return {data: (data.data ?? []).map((entry: Json) => malAnime(entry.node)),
    pagination: {has_next_page: Boolean(data.paging?.next)}, source: 'myanimelist'};
}
export async function fetchCatalog(path: string, query: Record<string, string>, clientId?: string,
  fetcher: typeof fetch = fetch): Promise<Json> {
  const official = clientId ? malUrl(path, query) : null;
  if (official) {
    try {
      const result = await fetcher(official, {headers: {'X-MAL-CLIENT-ID': clientId!}, signal: AbortSignal.timeout(8000)});
      if (result.ok) return normalizeMal(await result.json(), /\/full$/.test(path));
      // All errors fall back to read-only Tenrai, including missing catalog entries.
    } catch { /* Fallback below. */ }
  }
  const tenrai = new URL(`https://api.tenrai.org/v1/${path}`);
  Object.entries(query).forEach(([key, value]) => tenrai.searchParams.set(key, value));
  const result = await fetcher(tenrai, {headers: {'Accept': 'application/json'}, signal: AbortSignal.timeout(8000)});
  if (!result.ok) throw new Error(`Catalog upstream ${result.status}`);
  const value = await result.json();
  if (path.endsWith('/full') ? !value?.data || !Number.isInteger(value.data.mal_id) : !Array.isArray(value?.data)) {
    throw new Error('Invalid catalog response');
  }
  return {...value, source: 'tenrai'};
}
