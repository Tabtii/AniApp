import {fetchCatalog, validateRequest} from './providers.ts';
import {acceptsPublishableKey} from './auth.ts';

const headers = {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info'};
const cache = new Map<string, {until: number; value: unknown}>();
const clients = new Map<string, {until: number; count: number}>();
let nextUpstreamAt = 0;
Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', {headers});
  if (req.method !== 'POST') return new Response('{}', {status: 405, headers});
  const respond = (value: unknown, status = 200) => new Response(JSON.stringify(value), {status, headers});
  if (!acceptsPublishableKey(req.headers.get('apikey'), Deno.env.get('SUPABASE_PUBLISHABLE_KEYS'))) {
    return respond({error: 'A valid project publishable key is required'}, 401);
  }
  const ip = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown';
  const now = Date.now();
  const bucket = clients.get(ip);
  if (bucket && bucket.until > now && bucket.count >= 30) return respond({error: 'Too many requests'}, 429);
  clients.set(ip, {until: bucket && bucket.until > now ? bucket.until : now + 60000, count: bucket && bucket.until > now ? bucket.count + 1 : 1});
  if (clients.size > 5000) for (const [key, value] of clients) if (value.until < now) clients.delete(key);
  let input;
  try {
    const text = await req.text();
    if (text.length > 4096) return respond({error: 'Request too large'}, 413);
    input = validateRequest(JSON.parse(text));
  } catch { return respond({error: 'Invalid catalog request'}, 400); }
  const key = JSON.stringify(input);
  const found = cache.get(key);
  if (found && found.until > now) return respond(found.value);
  // Isolate-wide upstream budget; persistent gateway quotas are required at larger scale.
  if (now < nextUpstreamAt) return respond({error: 'Please retry shortly'}, 429);
  nextUpstreamAt = now + 1000;
  try {
    const value = await fetchCatalog(input.path, input.query, Deno.env.get('MAL_CLIENT_ID'));
    if (cache.size >= 500) cache.delete(cache.keys().next().value!);
    cache.set(key, {until: Date.now() + 15 * 60000, value});
    return respond(value);
  } catch (error) {
    console.error('Catalog upstream failed:', error instanceof Error ? error.message : 'Unknown error');
    return respond({error: 'Catalog is temporarily unavailable'}, 503);
  }
});
